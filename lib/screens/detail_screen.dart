import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book_model.dart';
import '../models/book_status.dart'; // <--- Pastikan import ini ada
import '../services/firestore_service.dart';

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

  // --- LOGIC BARU: POPUP PILIHAN STATUS ---
  // Menggantikan fungsi _addToReadList yang lama
  void _showStatusSelectionModal(
    BuildContext context,
    Book book,
    BookStatus currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Bacaan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Pilihan Status
              _buildRadioOption(
                BookStatus.wantToRead,
                "Ingin Dibaca",
                currentStatus,
              ),
              _buildRadioOption(
                BookStatus.currentlyReading,
                "Sedang Dibaca",
                currentStatus,
              ),
              _buildRadioOption(
                BookStatus.finished,
                "Selesai Dibaca",
                currentStatus,
              ),

              const Divider(height: 30),

              // Tombol Hapus (Hanya muncul jika buku sudah ada di list)
              if (currentStatus != BookStatus.none)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Hapus dari Koleksi',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // Panggil fungsi BARU: saveBookToReadingList dengan status none
                    await _firestoreService.saveBookToReadingList(
                      book,
                      BookStatus.none,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Dihapus dari koleksi")),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Widget Helper untuk Radio Button
  Widget _buildRadioOption(
    BookStatus status,
    String label,
    BookStatus currentGroupValue,
  ) {
    return RadioListTile<BookStatus>(
      title: Text(label),
      value: status,
      groupValue: currentGroupValue,
      activeColor: _primaryColor,
      contentPadding: EdgeInsets.zero,
      onChanged: (newValue) async {
        if (newValue != null) {
          Navigator.pop(context);
          // Panggil fungsi BARU di sini
          await _firestoreService.saveBookToReadingList(widget.book, newValue);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Status: $label")));
          }
        }
      },
    );
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    await _firestoreService.addComment(
      widget.book.id,
      _commentController.text.trim(),
    );
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;
    final Uri url = Uri.parse(widget.book.infoLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              // --- ICON BOOKMARK DINAMIS ---
              StreamBuilder<BookStatus>(
                stream: _firestoreService.getBookStatusStream(widget.book.id),
                builder: (context, snapshot) {
                  final currentStatus = snapshot.data ?? BookStatus.none;
                  return IconButton(
                    icon: Icon(
                      currentStatus != BookStatus.none
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: currentStatus != BookStatus.none
                          ? _primaryColor
                          : Colors.black87,
                    ),
                    onPressed: () {
                      _showStatusSelectionModal(
                        context,
                        widget.book,
                        currentStatus,
                      );
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.book.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[200]),
                  ),
                  Container(color: Colors.white.withOpacity(0.85)),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          height: 180,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.book.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.book, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            widget.book.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          widget.book.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text("Sample"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _launchPlayStore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Beli Ebook"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Tentang Buku Ini",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book.description,
                    style: TextStyle(color: Colors.grey[700], height: 1.6),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Diskusi Pembaca",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getComments(widget.book.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Text(
                            "Belum ada diskusi. Mulai sekarang!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      var comments = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var data = comments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['username'] ?? 'Anon',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: "Tulis pendapatmu...",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendComment,
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
