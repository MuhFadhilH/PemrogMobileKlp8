import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart'; // Import Review Model
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

  // ... (Kode _showStatusSelectionModal dan _buildRadioOption TETAP SAMA, tidak diubah) ...
  // ... (Silakan copy-paste bagian Modal Status dari file lama jika perlu) ...
  // Agar ringkas, saya fokus ke bagian yang berubah di bawah ini:

  void _showStatusSelectionModal(
    BuildContext context,
    Book book,
    BookStatus currentStatus,
  ) {
    // ... Copy logika modal dari file sebelumnya ...
    // (Isinya sama persis dengan file kamu yang lama)
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
              const Text(
                'Status Bacaan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRadioOption(
                  BookStatus.wantToRead, "Ingin Dibaca", currentStatus),
              _buildRadioOption(
                  BookStatus.currentlyReading, "Sedang Dibaca", currentStatus),
              _buildRadioOption(
                  BookStatus.finished, "Selesai Dibaca", currentStatus),
              const Divider(height: 30),
              if (currentStatus != BookStatus.none)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Hapus dari Koleksi',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _firestoreService.saveBookToReadingList(
                        book, BookStatus.none);
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Dihapus dari koleksi")));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioOption(
      BookStatus status, String label, BookStatus currentGroupValue) {
    return RadioListTile<BookStatus>(
      title: Text(label),
      value: status,
      groupValue: currentGroupValue,
      activeColor: _primaryColor,
      contentPadding: EdgeInsets.zero,
      onChanged: (newValue) async {
        if (newValue != null) {
          Navigator.pop(context);
          await _firestoreService.saveBookToReadingList(widget.book, newValue);
          if (mounted)
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Status: $label")));
        }
      },
    );
  }

  // REVISI: Menggunakan addReview dengan rating 0
  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    // Kita anggap komentar biasa sebagai Review dengan Rating 0
    await _firestoreService.addReview(
      book: widget.book,
      rating: 0.0,
      reviewText: _commentController.text.trim(),
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
          // ... (SliverAppBar TETAP SAMA) ...
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
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
                    onPressed: () => _showStatusSelectionModal(
                        context, widget.book, currentStatus),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.book.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[200])),
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
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(widget.book.thumbnailUrl,
                                fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(widget.book.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ),
                        Text(widget.book.author,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
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
                              onPressed: () {}, child: const Text("Sample"))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _launchPlayStore,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white),
                          child: const Text("Beli Ebook"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text("Tentang Buku Ini",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.book.description,
                      style: TextStyle(color: Colors.grey[700], height: 1.6),
                      textAlign: TextAlign.justify),
                  const SizedBox(height: 32),

                  const Text("Diskusi & Review",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // REVISI: StreamBuilder menggunakan getBookReviews (Model Review)
                  StreamBuilder<List<Review>>(
                    stream: _firestoreService.getBookReviews(widget.book.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                              style: TextStyle(color: Colors.grey)),
                        );
                      }
                      var reviews = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review
                                          .username, // Sekarang kita punya Username!
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    // Tampilkan bintang jika rating > 0
                                    if (review.rating > 0)
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 14, color: Colors.amber),
                                          Text(" ${review.rating}",
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(review.reviewText,
                                    style: TextStyle(color: Colors.grey[800])),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Komentar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                              hintText: "Tulis pendapatmu..."),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendComment,
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                            backgroundColor: _primaryColor),
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
