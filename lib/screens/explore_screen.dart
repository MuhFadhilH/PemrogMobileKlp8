import 'package:flutter/material.dart';
import 'dart:math' as math; // Import math untuk rotasi icon
import '../models/book_model.dart';
import '../models/book_list_model.dart';
import '../services/api_service.dart';
import 'book_list_detail_screen.dart';
import 'detail_screen.dart';
import 'genre_books_screen.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import 'public_profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  // State Pencarian
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;

  // State Tabs
  late TabController _tabController;

  // DATA GENRE DENGAN WARNA VIBRANT (Solid)
  final List<Map<String, dynamic>> _genres = const [
    {
      'name': 'Fiction',
      'color': Color(0xFFE91E63),
      'icon': Icons.auto_stories
    }, // Pink
    {
      'name': 'Science',
      'color': Color(0xFF2196F3),
      'icon': Icons.science
    }, // Blue
    {
      'name': 'History',
      'color': Color(0xFFE65100),
      'icon': Icons.history_edu
    }, // Orange Dark
    {
      'name': 'Romance',
      'color': Color(0xFFD81B60),
      'icon': Icons.favorite
    }, // Dark Pink
    {
      'name': 'Horror',
      'color': Color(0xFF512DA8),
      'icon': Icons.nightlight_round
    }, // Deep Purple
    {
      'name': 'Business',
      'color': Color(0xFF00695C),
      'icon': Icons.trending_up
    }, // Teal Dark
    {
      'name': 'Biography',
      'color': Color(0xFF455A64),
      'icon': Icons.person
    }, // Blue Grey
    {
      'name': 'Tech',
      'color': Color(0xFF1565C0),
      'icon': Icons.computer
    }, // Blue Dark
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isSearching = true;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: _isSearching ? 110 : 70,
        title: _buildSearchBar(),
        bottom: _isSearching
            ? TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF5C6BC0),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF5C6BC0),
                isScrollable: true,
                onTap: (_) => _searchFocusNode.unfocus(),
                tabs: const [
                  Tab(text: "Books"),
                  Tab(text: "People"),
                  Tab(text: "Reviews"),
                  Tab(text: "Authors"),
                  Tab(text: "Lists"),
                ],
              )
            : null,
      ),
      body: _isSearching ? _buildSearchResults() : _buildGenreBrowser(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onTap: () {
        setState(() => _isSearching = true);
      },
      onChanged: (val) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: "Search titles, authors, lists...",
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
        suffixIcon: _isSearching
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _clearSearch,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // --- REVISI UTAMA: BROWSER GENRE GAYA SPOTIFY ---
  Widget _buildGenreBrowser() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Text(
              "Browse by Genre",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Kotak per baris
              crossAxisSpacing: 12, // Jarak antar kolom
              mainAxisSpacing: 12, // Jarak antar baris
              childAspectRatio: 1.65, // Rasio lebar:tinggi (Persegi Panjang)
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final genre = _genres[index];
                return _buildGenreCard(genre);
              },
              childCount: _genres.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  // --- CARD STYLE BARU (MIRIP GAMBAR REFERENSI) ---
  Widget _buildGenreCard(Map<String, dynamic> genre) {
    return Container(
      decoration: BoxDecoration(
        color: genre['color'], // Warna Solid Vibrant
        borderRadius:
            BorderRadius.circular(8), // Sudut melengkung sedikit (4-8px)
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GenreBooksScreen(
                  genreName: genre['name'],
                  genreColor: genre['color'],
                ),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.hardEdge, // Memotong icon yang keluar batas
            children: [
              // 1. TEKS JUDUL (Kiri Atas)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  genre['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Font Besar
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // 2. ICON BESAR (Kanan Bawah & Miring)
              Positioned(
                bottom: -10,
                right: -15,
                child: Transform.rotate(
                  angle: 25 * (math.pi / 180), // Rotasi 25 derajat
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.2), // Kotak transparan
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(4, 4),
                          )
                        ]),
                    child: Icon(
                      genre['icon'],
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text;

    return TabBarView(
      controller: _tabController,
      children: [
        _SearchResultList(query: query, type: "books"),
        _SearchResultList(query: query, type: "people"),
        _SearchResultList(query: query, type: "reviews"),
        _SearchResultList(query: query, type: "authors"),
        _SearchResultList(query: query, type: "lists"),
      ],
    );
  }
}

// --- HELPER CLASS SEARCH (TIDAK BERUBAH) ---
class _SearchResultList extends StatefulWidget {
  final String query;
  final String type;

  const _SearchResultList({required this.query, required this.type});

  @override
  State<_SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends State<_SearchResultList>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();

  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) _fetchResults();
  }

  @override
  void didUpdateWidget(covariant _SearchResultList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      if (widget.query.isNotEmpty) {
        _fetchResults();
      } else {
        setState(() => _results = []);
      }
    }
  }

  Future<void> _fetchResults() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<dynamic> res = [];
      switch (widget.type) {
        case 'books':
          res = await _apiService.fetchBooks(widget.query);
          break;
        case 'authors':
          res = await _apiService.fetchBooks('inauthor:${widget.query}');
          break;
        case 'people':
          res = await _firestoreService.searchUsers(widget.query);
          break;
        case 'reviews':
          res = await _firestoreService.searchReviews(widget.query);
          break;
        case 'lists':
          res = await _firestoreService.searchBookListModels(widget.query);
          break;
      }

      if (mounted) setState(() => _results = res);
    } catch (e) {
      debugPrint("Err: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.query.isEmpty) {
      return const Center(child: Text("Start typing to search..."));
    }
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasSearched && _results.isEmpty) {
      return Center(child: Text("No results found for '${widget.query}'"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _results[index];

        if (widget.type == 'books' || widget.type == 'authors') {
          return _buildBookTile(item);
        } else if (widget.type == 'people') {
          return _buildUserTile(item);
        } else if (widget.type == 'reviews') {
          return _buildReviewTile(item);
        } else if (widget.type == 'lists') {
          return _buildBookListModelTile(item);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildBookTile(Book book) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          book.thumbnailUrl,
          width: 45,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(width: 45, color: Colors.grey[200]),
        ),
      ),
      title: Text(book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(book.author, maxLines: 1),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailScreen(book: book)));
      },
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        backgroundImage:
            user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
        child: user.photoUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(user: user),
          ),
        );
      },
    );
  }

  Widget _buildReviewTile(Review review) {
    return GestureDetector(
      onTap: () {
        final bookFromReview = Book(
          id: review.bookId,
          title: review.bookTitle,
          author: review.bookAuthor,
          thumbnailUrl: review.bookThumbnailUrl,
          description: "Deskripsi tidak tersedia dari review.",
          averageRating: 0,
          infoLink: '',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(book: bookFromReview),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  review.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.star, size: 14, color: Colors.amber[700]),
                Text(
                  " ${review.rating}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    review.bookThumbnailUrl,
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[200]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.bookTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.reviewText,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookListModelTile(BookListModel list) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookListDetailScreen(bookList: list),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: list.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(list.coverUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.folder, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(list.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${list.bookCount} books",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
