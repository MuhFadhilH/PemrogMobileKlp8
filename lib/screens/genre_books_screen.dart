import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

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

  // State untuk Data & Loading
  List<Book> _books = [];
  bool _isFirstLoadRunning = true; // Loading awal
  bool _hasNextPage = true; // Cek apakah masih ada data di API
  bool _isLoadMoreRunning = false; // Loading saat scroll bawah
  int _startIndex = 0; // Halaman saat ini (0, 20, 40...)
  final int _limit = 20; // Jumlah buku per request

  // Controller untuk deteksi scroll
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _firstLoad();
    _scrollController = ScrollController()..addListener(_loadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMore);
    _scrollController.dispose();
    super.dispose();
  }

  // 1. Fungsi Load Awal
  void _firstLoad() async {
    setState(() => _isFirstLoadRunning = true);
    try {
      // Panggil API dengan startIndex 0
      final res = await _apiService.fetchBooks('subject:${widget.genreName}',
          startIndex: 0, maxResults: _limit);
      setState(() {
        _books = res;
      });
    } catch (err) {
      debugPrint("Error fetching initial data: $err");
    }
    setState(() => _isFirstLoadRunning = false);
  }

  // 2. Fungsi Load More (Infinite Scroll)
  void _loadMore() async {
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _scrollController.position.extentAfter < 300) {
      // Jika sisa scroll < 300px

      setState(() => _isLoadMoreRunning = true);

      _startIndex += _limit; // Naikkan halaman (0 -> 20 -> 40)

      try {
        final List<Book> fetchedBooks = await _apiService.fetchBooks(
            'subject:${widget.genreName}',
            startIndex: _startIndex,
            maxResults: _limit);

        if (fetchedBooks.isNotEmpty) {
          setState(() {
            _books.addAll(fetchedBooks); // Tambahkan data baru ke list lama
          });
        } else {
          // Jika API balikin kosong, berarti data habis
          setState(() => _hasNextPage = false);
        }
      } catch (err) {
        debugPrint("Error fetching more data: $err");
      }

      setState(() => _isLoadMoreRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.genreColor,
        foregroundColor: Colors.white,
        title: Text(widget.genreName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isFirstLoadRunning
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(child: Text("Tidak ada buku ditemukan."))
              : CustomScrollView(
                  controller: _scrollController, // Pasang controller disini
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final book = _books[index];
                            return _buildBookCard(book);
                          },
                          childCount: _books.length,
                        ),
                      ),
                    ),

                    // Loading Indicator di Bawah (Muncul saat scroll mentok)
                    if (_isLoadMoreRunning)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),

                    // Pesan jika data sudah habis
                    if (_hasNextPage == false)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child: Text("Semua buku telah ditampilkan")),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3))
                  ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  book.thumbnailUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200], child: const Icon(Icons.book)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
