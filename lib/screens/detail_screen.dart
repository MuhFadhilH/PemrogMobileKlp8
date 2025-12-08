import 'package:flutter/cupertino.dart'; // Untuk Scroll Time Picker
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; 
import '../services/firestore_service.dart';
import '../screens/components/log_modal.dart'; // Pastikan path ini benar atau hapus jika tidak dipakai

class DetailScreen extends StatefulWidget {
  final Book book;
  const DetailScreen({super.key, required this.book});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  final Color _primaryColor = const Color(0xFF5C6BC0);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- LOGIC 1: KIRIM KOMENTAR/REVIEW ---
  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      await _firestoreService.addReview(
          book: widget.book,
          rating: 0.0, // Default 0 jika hanya komentar teks
          reviewText: _commentController.text.trim());
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Komentar terkirim!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- LOGIC 2: MODAL PILIHAN STATUS & BOOKLIST ---
  void _showStatusSelectionModal(BuildContext context, BookStatus currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SizedBox(
          height: 450,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Status Bacaan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _radioOption(BookStatus.wantToRead, "Ingin Dibaca (Reading List)", currentStatus),
                _radioOption(BookStatus.currentlyReading, "Sedang Dibaca", currentStatus),
                _radioOption(BookStatus.finished, "Selesai Dibaca", currentStatus),
                
                const Divider(height: 30),
                
                const Text('Simpan ke Koleksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ListTile(
                  leading: Icon(Icons.playlist_add, color: _primaryColor),
                  title: const Text("Tambahkan ke Custom BookList"),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddToBookListDialog(context);
                  },
                ),
                
                if (currentStatus != BookStatus.none) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Hapus dari Status Bacaan',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _firestoreService.saveBookToReadingList(widget.book, BookStatus.none);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dihapus dari list.")));
                    },
                  ),
                ]
              ],
            ),
          ),
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
          // Jika user pilih "Ingin Dibaca", tawarkan jadwal (Fitur dari HEAD)
          if (val == BookStatus.wantToRead) {
             _showSchedulePrompt();
          } else {
             _firestoreService.saveBookToReadingList(widget.book, val);
          }
        }
      },
    );
  }

  // --- LOGIC 3: CUSTOM BOOKLIST ---
  void _showAddToBookListDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pilih BookList",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<BookList>>(
                  stream: _firestoreService.getUserBookLists(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Belum ada BookList.", style: TextStyle(color: Colors.grey[600])),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Tambahkan navigasi ke pembuatan list atau dialog buat list disini jika perlu
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buat list di menu Profil.")));
                                }, 
                                child: const Text("Buat Baru")
                            )
                          ],
                        ),
                      );
                    }

                    var bookLists = snapshot.data!;
                    return ListView.builder(
                      itemCount: bookLists.length,
                      itemBuilder: (context, index) {
                        final list = bookLists[index];
                        return ListTile(
                          leading: const Icon(Icons.folder, color: Colors.amber),
                          title: Text(list.name),
                          subtitle: Text("${list.bookCount} buku"),
                          onTap: () async {
                            await _firestoreService.addBookToBookList(list.id, widget.book);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Ditambahkan ke ${list.name}")));
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC 4: JADWAL (Dari HEAD) ---
  void _showSchedulePrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Atur Jadwal Baca?"),
        content: const Text(
            "Tentukan target mulai baca dan deadline selesai agar kamu lebih disiplin."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Simpan sebagai Want to Read tanpa jadwal
              _firestoreService.saveBookToReadingList(widget.book, BookStatus.wantToRead);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Masuk Reading List (Tanpa Jadwal)")),
              );
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
                  Text("Tentukan Jam Pengingat", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor)),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // EKSEKUSI SIMPAN JADWAL
                      await _firestoreService.addSchedule(
                        book: widget.book,
                        startDate: range.start,
                        deadlineDate: range.end,
                        hour: tempTime.hour,
                        minute: tempTime.minute,
                      );
                      // Update status buku
                      await _firestoreService.saveBookToReadingList(widget.book, BookStatus.wantToRead);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Jadwal & Pengingat berhasil dipasang!")),
                        );
                      }
                    },
                    child: Text("SIMPAN",
                        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
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

  // --- LOGIC 5: LAUNCHER ---
  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;
    final Uri url = Uri.parse(widget.book.infoLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR & GAMBAR (Style dari HEAD yang lebih bagus)
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              // Icon Bookmark Dinamis
              StreamBuilder<BookStatus>(
                stream: _firestoreService.getBookStatusStream(widget.book.id),
                builder: (context, snapshot) {
                  final status = snapshot.data ?? BookStatus.none;
                  return IconButton(
                    icon: Icon(
                        status != BookStatus.none
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: status != BookStatus.none
                            ? _primaryColor
                            : Colors.black87),
                    onPressed: () => _showStatusSelectionModal(context, status),
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
                  Container(color: Colors.white.withOpacity(0.9)),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 160,
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.book.thumbnailUrl,
                              fit: BoxFit.cover,
                            ),
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
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.book.author,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. KONTEN BODY
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Aksi
                  Row(
                    children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text("Sample", style: TextStyle(color: Colors.black)))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _launchPlayStore,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text("Beli Ebook"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Deskripsi
                  const Text("Tentang Buku Ini",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    widget.book.description,
                    style: TextStyle(color: Colors.grey[700], height: 1.6),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                  
                  // Review & Diskusi
                  const Text("Diskusi Pembaca",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildReviewList(),
                  
                  const SizedBox(height: 16),
                  
                  // Input Komentar Baru
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30)
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: "Tulis pendapatmu...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16)
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _sendComment, 
                          icon: const Icon(Icons.send, size: 20),
                          style: IconButton.styleFrom(backgroundColor: _primaryColor),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
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
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text("Belum ada review. Jadilah yang pertama!",
                    style: TextStyle(color: Colors.grey[600])),
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
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10, offset: const Offset(0, 4),
                  ),
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