import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; // Import Model Baru
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

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      await _firestoreService.addReview(
          book: widget.book,
          rating: 0.0,
          reviewText: _commentController.text.trim());
      _commentController.clear();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Komentar terkirim!")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- MODAL PILIHAN STATUS & BOOKLIST ---
  void _showStatusSelectionModal(
      BuildContext context, Book book, BookStatus currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Bacaan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _radioOption(
                  BookStatus.wantToRead, "Ingin Dibaca", currentStatus),
              _radioOption(
                  BookStatus.currentlyReading, "Sedang Dibaca", currentStatus),
              _radioOption(
                  BookStatus.finished, "Selesai Dibaca", currentStatus),
              const Divider(height: 30),
              const Text('Simpan ke BookList',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading:
                    const Icon(Icons.playlist_add, color: Color(0xFF5C6BC0)),
                title: const Text("Tambahkan ke Custom BookList"),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToBookListDialog(context, book);
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
                    _firestoreService.saveBookToReadingList(
                        book, BookStatus.none);
                  },
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  // --- MODAL PILIH BOOKLIST ---
  void _showAddToBookListDialog(BuildContext context, Book book) {
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
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    var bookLists = snapshot.data!;
                    if (bookLists.isEmpty)
                      return const Center(
                          child:
                              Text("Belum ada BookList. Buat di Profil dulu!"));

                    return ListView.builder(
                      itemCount: bookLists.length,
                      itemBuilder: (context, index) {
                        final list = bookLists[index];
                        return ListTile(
                          leading:
                              const Icon(Icons.folder, color: Colors.amber),
                          title: Text(list.name),
                          subtitle: Text("${list.bookCount} buku"),
                          onTap: () async {
                            await _firestoreService.addBookToBookList(
                                list.id, book);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text("Ditambahkan ke ${list.name}")));
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

  Widget _radioOption(BookStatus status, String label, BookStatus current) {
    return RadioListTile<BookStatus>(
      title: Text(label),
      value: status,
      groupValue: current,
      activeColor: _primaryColor,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        Navigator.pop(context);
        if (val != null)
          _firestoreService.saveBookToReadingList(widget.book, val);
      },
    );
  }

  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;
    final Uri url = Uri.parse(widget.book.infoLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
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
                    onPressed: () =>
                        _showStatusSelectionModal(context, widget.book, status),
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
                                  color: Colors.black12,
                                  blurRadius: 15,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(widget.book.thumbnailUrl,
                                  fit: BoxFit.cover)),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(widget.book.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold))),
                        Text(widget.book.author,
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
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
                            child: const Text("Beli Ebook"))),
                  ]),
                  const SizedBox(height: 24),
                  const Text("Tentang Buku",
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
                  StreamBuilder<List<Review>>(
                    stream: _firestoreService.getBookReviews(widget.book.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text("Belum ada diskusi.",
                              style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final review = snapshot.data![index];
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
                                ]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(review.username,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      if (review.rating > 0)
                                        Row(children: [
                                          const Icon(Icons.star,
                                              size: 14, color: Colors.amber),
                                          Text(" ${review.rating}",
                                              style:
                                                  const TextStyle(fontSize: 12))
                                        ]),
                                    ]),
                                const SizedBox(height: 4),
                                Text(review.reviewText),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                                hintText: "Tulis pendapatmu..."))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        onPressed: _sendComment,
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                            backgroundColor: _primaryColor)),
                  ]),
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
