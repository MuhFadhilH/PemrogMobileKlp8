import 'package:flutter/cupertino.dart'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; 
import '../services/firestore_service.dart';
import '../screens/components/log_modal.dart';

class DetailScreen extends StatefulWidget {
  final Book book;
  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Color _primaryColor = const Color(0xFF5C6BC0);

  // ===========================================================================
  // LOGIC 1: SUPER MODAL (STATUS + CUSTOM LIST + CREATE LIST)
  // ===========================================================================
  
  void _showCollectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Stack(
              children: [
                ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- BAGIAN 1: STATUS BACA UTAMA ---
                    const Text("Status Bacaan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    StreamBuilder<BookStatus>(
                      stream: _firestoreService.getBookStatusStream(widget.book.id),
                      builder: (context, snapshot) {
                        final currentStatus = snapshot.data ?? BookStatus.none;
                        return Column(
                          children: [
                            _radioOption(BookStatus.wantToRead, "Ingin Dibaca (Reading List)", currentStatus),
                            _radioOption(BookStatus.currentlyReading, "Sedang Dibaca", currentStatus),
                            _radioOption(BookStatus.finished, "Selesai Dibaca", currentStatus),
                            if (currentStatus != BookStatus.none)
                              ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.red),
                                title: const Text('Hapus Status Baca', style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  _firestoreService.saveBookToReadingList(widget.book, BookStatus.none);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dihapus dari status.")));
                                },
                              ),
                          ],
                        );
                      }
                    ),

                    const Divider(height: 30, thickness: 1),

                    // --- BAGIAN 2: CUSTOM LISTS ---
                    const Text("Simpan ke Koleksi Pribadi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    // FIX: Menggunakan getCustomLists()
                    StreamBuilder<List<BookList>>( 
                      stream: _firestoreService.getCustomLists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text("Belum ada list kustom.", style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),
                          );
                        }

                        var lists = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lists.length,
                          itemBuilder: (context, index) {
                            final list = lists[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                // FIX: withValues menggantikan withOpacity
                                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.folder_special, color: Colors.amber),
                              ),
                              title: Text(list.name),
                              subtitle: Text("${list.bookCount} buku"),
                              trailing: const Icon(Icons.add_circle_outline, color: Colors.grey),
                              onTap: () async {
                                await _firestoreService.addBookToBookList(list.id, widget.book);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ditambahkan ke ${list.name}")));
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                // --- TOMBOL BUAT LIST BARU ---
                Positioned(
                  bottom: 20, right: 20, left: 20,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); 
                      _showCreateListDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Buat List Baru"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _radioOption(BookStatus status, String label, BookStatus current) {
    return RadioListTile<BookStatus>(
      title: Text(label),
      value: status,
      groupValue: current,
      activeColor: _primaryColor,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (val) {
        Navigator.pop(context);
        if (val != null) {
          if (val == BookStatus.wantToRead) {
             _showSchedulePrompt(); // Pemicu Jadwal
          } else {
             _firestoreService.saveBookToReadingList(widget.book, val);
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status: $label")));
          }
        }
      },
    );
  }

  // Dialog Buat List Baru
  void _showCreateListDialog() {
    final TextEditingController listNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buat List Baru"),
        content: TextField(
          controller: listNameController,
          decoration: const InputDecoration(hintText: "Nama List (contoh: Sad Novel)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (listNameController.text.isNotEmpty) {
                // FIX: Menggunakan createCustomList
                _firestoreService.createCustomList(listNameController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("List berhasil dibuat!")));
                Future.delayed(const Duration(milliseconds: 300), _showCollectionModal);
              }
            },
            child: const Text("Buat"),
          ),
        ],
      ),
    );
  }

  // ... (Sisa kode Jadwal & Review sama, tetapi pastikan withOpacity di bawah ini juga diperbaiki) ...

  void _showSchedulePrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Atur Jadwal Baca?"),
        content: const Text("Tentukan target mulai baca dan deadline selesai agar kamu lebih disiplin."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firestoreService.saveBookToReadingList(widget.book, BookStatus.wantToRead);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Masuk Reading List (Tanpa Jadwal)")));
            },
            child: const Text("Lewati"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickDateRange(); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            child: const Text("Atur Jadwal"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      saveText: "LANJUT",
      helpText: "PILIH MULAI & DEADLINE",
    );

    if (pickedRange != null) {
      if (!mounted) return;
      _showTimeScrollPicker(pickedRange);
    }
  }

  void _showTimeScrollPicker(DateTimeRange range) {
    DateTime tempTime = DateTime.now();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 350,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tentukan Jam Pengingat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor)),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _firestoreService.addSchedule(
                        book: widget.book,
                        startDate: range.start,
                        deadlineDate: range.end,
                        hour: tempTime.hour,
                        minute: tempTime.minute,
                      );
                      await _firestoreService.saveBookToReadingList(widget.book, BookStatus.wantToRead);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jadwal & Pengingat dipasang!")));
                      }
                    },
                    child: Text("SIMPAN", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (val) => tempTime = val,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;
    final Uri url = Uri.parse(widget.book.infoLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
  }

  void _showReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogBookModal(preSelectedBook: widget.book),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                actions: [
                  StreamBuilder<BookStatus>(
                    stream: _firestoreService.getBookStatusStream(widget.book.id),
                    builder: (context, snapshot) {
                      final status = snapshot.data ?? BookStatus.none;
                      return IconButton(
                        icon: Icon(
                          status != BookStatus.none ? Icons.bookmark : Icons.bookmark_border,
                          color: status != BookStatus.none ? _primaryColor : Colors.black87
                        ),
                        onPressed: _showCollectionModal,
                      );
                    },
                  ),
                  IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.book.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                      ),
                      // FIX: withValues menggantikan withOpacity
                      Container(color: Colors.white.withValues(alpha: 0.9)),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 160, width: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  // FIX: withValues menggantikan withOpacity
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(widget.book.thumbnailUrl, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                widget.book.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.book.author, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              child: const Text("Sample", style: TextStyle(color: Colors.black))
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _launchPlayStore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              child: const Text("Beli Ebook"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      const Text("Tentang Buku Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.book.description,
                        style: TextStyle(color: Colors.grey[700], height: 1.6),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 40),
                      
                      const Text("Diskusi Pembaca", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      _buildReviewList(),
                      
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                  stops: const [0.6, 1.0]
                )
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showCollectionModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _primaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Atur Koleksi", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showReviewModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Tulis Review", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return StreamBuilder<List<Review>>(
      stream: _firestoreService.getBookReviews(widget.book.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text("Belum ada review. Jadilah yang pertama!", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final reviews = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  // FIX: withValues menggantikan withOpacity
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16, backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, size: 18, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      Text(review.username.isNotEmpty ? review.username : "User", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      if (review.rating > 0) ...[
                        Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(review.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(review.reviewText, style: TextStyle(color: Colors.grey[800], height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text("Suka", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      Text(DateFormat('d MMM y').format(review.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}