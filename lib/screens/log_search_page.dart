import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart'; // Pastikan import DetailScreen ada

// --- HALAMAN 1: PENCARIAN ---
class LogSearchPage extends StatefulWidget {
  // Parameter untuk menentukan mode pencarian
  final bool isGeneralSearch;

  const LogSearchPage({super.key, this.isGeneralSearch = false});

  @override
  State<LogSearchPage> createState() => _LogSearchPageState();
}

class _LogSearchPageState extends State<LogSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Book> _searchResults = [];
  bool _isSearching = false;

  // Dummy Recent Searches
  final List<String> _recentSearches = [
    "Laut Bercerita",
    "Atomic Habits",
    "Filosofi Teras",
    "Pulang - Leila S. Chudori",
    "Cantik Itu Luka",
  ];

  void _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _apiService.fetchBooks(query);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // Fungsi saat buku diklik
  void _onBookTap(Book book) {
    if (widget.isGeneralSearch) {
      // MODE 1: Buka Detail Buku (Untuk Add to BookList)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      );
    } else {
      // MODE 2: Buka Form Review (Log a Book) - Default
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LogFormPage(book: book)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _searchBooks,
          decoration: InputDecoration(
            // Hint text berubah sesuai mode
            hintText:
                widget.isGeneralSearch ? "Cari buku..." : "Name of book...",
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _searchBooks("");
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // KASUS 1: Lagi Loading
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // KASUS 2: Belum ngetik apa-apa (Tampilkan Recent Searches)
    if (_searchController.text.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text(
            "RECENT SEARCHES",
            style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ..._recentSearches.map((text) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  text,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                onTap: () {
                  _searchController.text = text;
                  _searchBooks(text);
                },
              )),
        ],
      );
    }

    // KASUS 3: Ada Hasil Pencarian
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return ListTile(
          leading: Image.network(
            book.thumbnailUrl,
            width: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.book),
          ),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(book.author, maxLines: 1),
          onTap: () => _onBookTap(book), // Panggil fungsi _onBookTap yang baru
        );
      },
    );
  }
}

// --- HALAMAN 2: FORM REVIEW (Letterboxd Style) ---
class LogFormPage extends StatefulWidget {
  final Book book;
  const LogFormPage({super.key, required this.book});

  @override
  State<LogFormPage> createState() => _LogFormPageState();
}

class _LogFormPageState extends State<LogFormPage> {
  bool _isSubmitting = false;
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  void _saveReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beri rating minimal 1 bintang ⭐")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirestoreService().addReview(
        book: widget.book,
        rating: _rating,
        reviewText: _reviewController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review berhasil disimpan!"),
          backgroundColor: Color(0xFF5C6BC0),
        ),
      );

      Navigator.pop(context); // Tutup Form
      Navigator.pop(context); // Tutup Search
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "I Read...",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveReview,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
                    "Save",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF5C6BC0)),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Row Layout (Poster + Judul)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(widget.book.thumbnailUrl,
                        fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(widget.book.author,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            SizedBox(width: 8),
                            Text("Read on Today",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Rating
            const Text("Rating",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (index) => IconButton(
                        icon: Icon(
                          index < _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFF5C6BC0),
                          size: 40,
                        ),
                        onPressed: () => setState(() => _rating = index + 1.0),
                      )),
            ),

            const Divider(height: 40),

            // Textfield Luas
            TextField(
              controller: _reviewController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Add a review...",
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
