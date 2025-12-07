import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart'; // Pastikan ada untuk navigasi ke detail buku

class GenreBooksScreen extends StatefulWidget {
  final String genreName;
  final Color genreColor;

  const GenreBooksScreen(
      {super.key, required this.genreName, required this.genreColor});

  @override
  State<GenreBooksScreen> createState() => _GenreBooksScreenState();
}

class _GenreBooksScreenState extends State<GenreBooksScreen> {
  final ApiService _apiService = ApiService();
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGenreBooks();
  }

  Future<void> _fetchGenreBooks() async {
    try {
      // Menambahkan kata "subject:" agar pencarian spesifik ke genre
      final results =
          await _apiService.fetchBooks('subject:${widget.genreName}');
      if (mounted) {
        setState(() {
          _books = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.genreColor, // Header warna-warni sesuai genre
        foregroundColor: Colors.white,
        title: Text(widget.genreName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(child: Text("Tidak ada buku ditemukan."))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Kolom
                    childAspectRatio: 0.65, // Rasio buku
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailScreen(book: book)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                book.thumbnailUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[200]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
