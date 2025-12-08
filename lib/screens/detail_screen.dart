import 'package:flutter/cupertino.dart'; // Untuk Scroll Time Picker
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
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

  // --- LOGIC 1: MODAL ADD TO LIST (REAL DATA) ---
  void _showAddToListModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 400,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 10),
                    child: Text("Tambahkan ke...",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  
                  // LIST UTAMA (Reading List)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.bookmarks_rounded, color: _primaryColor),
                    ),
                    title: const Text("Reading List (Main)",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("List utama & terjadwal"),
                    onTap: () {
                      Navigator.pop(context);
                      _showSchedulePrompt(); // Memicu jadwal
                    },
                  ),
                  const Divider(indent: 24, endIndent: 24),

                  // LIST CUSTOM USER
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getCustomLists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text("Belum ada list buatanmu.",
                                  style: TextStyle(color: Colors.grey[400])));
                        }

                        var lists = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: lists.length,
                          itemBuilder: (context, index) {
                            var data = lists[index].data() as Map<String, dynamic>;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                              leading: Icon(Icons.list_alt, color: Colors.grey[600]),
                              title: Text(data['name'] ?? 'List'),
                              onTap: () {
                                _firestoreService.addBookToCustomList(lists[index].id, widget.book);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Ditambahkan ke ${data['name']}")));
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 60), 
                ],
              ),

              // TOMBOL TAMBAH LIST BARU
              Positioned(
                bottom: 20,
                left: 20,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context); 
                    _showCreateListDialog(); 
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text("List Baru",
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
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
                _firestoreService.createCustomList(listNameController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("List berhasil dibuat!")));
              }
            },
            child: const Text("Buat"),
          ),
        ],
      ),
    );
  }

  // --- LOGIC 2: JADWAL (START - DEADLINE - TIME) ---
  
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
              // Simpan tanpa jadwal
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
              _pickDateRange(); // Lanjut pilih tanggal
            },
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

  // --- LOGIC 3: LAUNCHER & MODAL REVIEW ---
  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;
    final Uri url = Uri.parse(widget.book.infoLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
  }

  // REVISI DISINI: Mengirim data buku ke Modal LogBookModal
  void _showReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Pass widget.book ke LogBookModal agar langsung masuk mode form review
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
              // 1. APP BAR & GAMBAR
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                actions: [
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
                      const Text("Tentang Buku Ini",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.book.description,
                        style: TextStyle(color: Colors.grey[700], height: 1.6),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 40),
                      const Text("Diskusi Pembaca",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // LIST REVIEW
                      _buildReviewSection(),
                      
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. FLOATING BUTTONS
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showAddToListModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Tambah ke List",
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Tambah Review",
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

  // WIDGET: List Review
  Widget _buildReviewSection() {
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
                      const Text("User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(review.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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