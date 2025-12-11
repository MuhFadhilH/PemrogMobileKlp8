import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
// import 'collection_screen.dart'; // Aktifkan jika file sudah ada

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. DEFINISI VARIABEL YANG SEBELUMNYA HILANG
  final ScrollController _scrollController = ScrollController();
  String _userName = "Pengguna";

  List<Book> _recommendedBooks = [];
  List<Book> _trendingBooks = [];
  List<Book> _historyBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? "Pengguna";
        });
      }

      final prefs = await _firestoreService.getUserPreferences();

      String recommendedQuery = 'Psychology';
      if (prefs.favoriteGenres.isNotEmpty) {
        recommendedQuery = prefs.favoriteGenres.take(2).join(' ');
      } else {
        recommendedQuery = 'Best Seller';
      }

      final recommended = await _apiService.fetchBooks(recommendedQuery);
      final trending = await _apiService.fetchBooks('Fiction');

      String otherGenre = 'History';
      if (prefs.favoriteGenres.length >= 3) {
        otherGenre = prefs.favoriteGenres[2];
      }
      final history = await _apiService.fetchBooks(otherGenre);

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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5C6BC0),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: const Color(0xFF5C6BC0),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // HEADER
                    SliverAppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      // 2. PERBAIKAN ACTIONS (Harus di dalam SliverAppBar)
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded,
                              color: Colors.grey),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: Container(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Halo, $_userName",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Selamat Datang",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    // 3. SECTION: COCOK UNTUKMU
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionTitle("Cocok Untukmu"),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: _buildHorizontalList(
                        books: _recommendedBooks,
                        height: 300, // DITAMBAH dari 280 agar tidak overflow
                        itemBuilder: (context, book) {
                          return _buildFeaturedBookCard(context, book);
                        },
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // 4. SECTION: SEDANG TREN
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionTitle("Sedang Tren"),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: _buildHorizontalList(
                        books: _trendingBooks,
                        height: 260, // DITAMBAH dari 230 agar tidak overflow
                        itemBuilder: (context, book) {
                          return _buildTrendingBookCard(context, book);
                        },
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 5. SECTION: GENRE HISTORY
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSectionTitle("Jelajahi Sejarah"),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        height: 240, // DITAMBAH dari 200 agar tidak overflow
                        margin: const EdgeInsets.only(top: 10),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _historyBooks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 0),
                          itemBuilder: (context, index) {
                            final book = _historyBooks[index];
                            return _buildExploreBookCard(context, book);
                          },
                        ),
                      ),
                    ),

                    // SPACER BOTTOM
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 30),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // WIDGET HELPER PENGGANTI InfiniteBookListModel
  Widget _buildHorizontalList({
    required List<Book> books,
    required double height,
    required Widget Function(BuildContext, Book) itemBuilder,
  }) {
    if (books.isEmpty) {
      return SizedBox(
        height: 100,
        child: const Center(child: Text("Tidak ada data")),
      );
    }
    return Container(
      height: height,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return itemBuilder(context, books[index]);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: 0.5,
      ),
    );
  }

  // --- CARD WIDGETS ---

  Widget _buildFeaturedBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BOOK COVER
            Container(
              height: 220,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      book.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.book, color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  ),

                  // RATING BADGE
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            book.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // TITLE
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BOOK COVER
            Container(
              height: 160,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.book, color: Colors.grey, size: 30),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // BOOK INFO
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 12),
                const SizedBox(width: 4),
                Text(
                  book.averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BOOK COVER
            Container(
              height: 160,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  book.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.book, color: Colors.grey, size: 24),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // BOOK TITLE
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
