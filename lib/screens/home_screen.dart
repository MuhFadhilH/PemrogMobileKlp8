import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<Book> _recommendedBooks = [];
  List<Book> _trendingBooks = [];
  List<Book> _historyBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      final recommended = await _apiService.fetchBooks('Psychology');
      final trending = await _apiService.fetchBooks('Best Seller Fiction');
      final history = await _apiService.fetchBooks('History Indonesia');

      if (mounted) {
        setState(() {
          _recommendedBooks = recommended;
          _trendingBooks = trending;
          _historyBooks = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching books: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HEADER
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: AppBar(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            centerTitle: false,
                            title: const Row(
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    color: Color(0xFF5C6BC0), size: 28),
                                SizedBox(width: 12),
                                Text(
                                  "Bibliomate",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            actions:  [
                              IconButton(
                                icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.grey),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 16),
                            ],
                          )),

                      const SizedBox(height: 10),

                      // 2. SECTION: COCOK UNTUKMU
                      _buildSectionTitle("Cocok Untukmu"),
                      InfiniteBookListModel(
                        books: _recommendedBooks,
                        height: 280,
                        itemBuilder: (context, book) {
                          return _buildBigBookCard(context, book);
                        },
                      ),

                      const SizedBox(height: 30),

                      // 3. SECTION: SEDANG TREN
                      _buildSectionTitle("Sedang Tren "),
                      InfiniteBookListModel(
                        books: _trendingBooks,
                        height: 200,
                        itemBuilder: (context, book) {
                          return _buildSmallBookCard(context, book);
                        },
                      ),

                      const SizedBox(height: 20),

                      // 4. SECTION: GENRE HISTORY
                      _buildSectionTitle("Jelajahi Sejarah"),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          // Padding History (Sudah Benar)
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _historyBooks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final book = _historyBooks[index];
                            return _buildSmallBookCard(context, book);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- WIDGET PENDUKUNG ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildBigBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                book.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 140,
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                book.averageRating.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.book),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PERBAIKAN DI SINI ---
class InfiniteBookListModel extends StatelessWidget {
  final List<Book> books;
  final double height;
  final Widget Function(BuildContext, Book) itemBuilder;

  const InfiniteBookListModel({
    super.key,
    required this.books,
    required this.height,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text("Belum ada data")),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        // Menambahkan padding agar item pertama tidak nempel kiri layar
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 10000,
        itemBuilder: (context, index) {
          final int realIndex = index % books.length;
          final book = books[realIndex];

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: itemBuilder(context, book),
          );
        },
      ),
    );
  }
}
