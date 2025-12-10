import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/book_list_model.dart'; // <-- PENTING: Untuk data list buku
import '../services/api_service.dart';
import 'book_list_detail_screen.dart';
import 'detail_screen.dart';
import 'genre_books_screen.dart'; // Import file baru tadi
import '../services/firestore_service.dart'; // <-- PENTING: Untuk akses database
import '../models/user_model.dart'; // <-- PENTING: Untuk data user
import '../models/review_model.dart';
import 'public_profile_screen.dart'; // <-- PENTING: Untuk data review

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

  // PERBAIKAN: Default false, tapi tidak otomatis mati saat hilang fokus
  bool _isSearching = false;

  // State Tabs
  late TabController _tabController;

  final List<Map<String, dynamic>> _genres = const [
    {'name': 'Fiction', 'color': Color(0xFFEF5350), 'icon': Icons.auto_stories},
    {'name': 'Science', 'color': Color(0xFF42A5F5), 'icon': Icons.science},
    {'name': 'History', 'color': Color(0xFFFFA726), 'icon': Icons.history_edu},
    {'name': 'Romance', 'color': Color(0xFFEC407A), 'icon': Icons.favorite},
    {
      'name': 'Horror',
      'color': Color(0xFF7E57C2),
      'icon': Icons.nightlight_round
    },
    {'name': 'Business', 'color': Color(0xFF26A69A), 'icon': Icons.trending_up},
    {'name': 'Biography', 'color': Color(0xFF78909C), 'icon': Icons.person},
    {'name': 'Technology', 'color': Color(0xFF5C6BC0), 'icon': Icons.computer},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // PERBAIKAN LOGIKA LISTENER:
    // Kita hanya mengaktifkan search saat fokus didapat.
    // Tapi KITA TIDAK MEMATIKANNYA saat fokus hilang (biar bisa klik Tab).
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isSearching = true;
        });
      }
    });
  }

  // Fungsi saat tombol "X" ditekan (Satu-satunya cara keluar mode search)
  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _isSearching = false); // Baru di sini kita matikan manual
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // PERBAIKAN TAMPILAN: AppBar sedikit lebih tinggi biar TabBar tidak sempit
        toolbarHeight: _isSearching ? 110 : 70,
        title: _buildSearchBar(),
        bottom: _isSearching
            ? TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF5C6BC0),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF5C6BC0),
                isScrollable: true,
                // Tambahkan onTap agar keyboard turun saat pilih tab (Opsional, biar rapi)
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
      // PERBAIKAN: Paksa aktifkan mode search saat ditekan
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
        // Tombol X hanya muncul jika mode searching aktif
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

  // ... (Sisa kode _buildGenreBrowser dan _buildSearchResults SAMA SEPERTI SEBELUMNYA)
  // Pastikan Anda menyalin sisa kode (method _buildGenreBrowser, _buildGenreCard, dll)
  // yang sudah ada sebelumnya. Jika perlu saya kirim ulang full 1 file, beritahu saya.

  // WIDGET 2: MODE NORMAL (BROWSE GENRE) - SCROLL MENYATU
  Widget _buildGenreBrowser() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Text(
              "Browse by Genre",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
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

  Widget _buildGenreCard(Map<String, dynamic> genre) {
    return Container(
      decoration: BoxDecoration(
        color: genre['color'].withValues(alpha : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: genre['color'].withValues(alpha : 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(genre['icon'], size: 32, color: genre['color']),
              const SizedBox(height: 8),
              Text(
                genre['name'],
                style: TextStyle(
                  color: genre['color'],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
        _SearchResultList(query: query, type: "people"), // <-- Tambah Ini
        _SearchResultList(query: query, type: "reviews"),
        _SearchResultList(query: query, type: "authors"),
        _SearchResultList(query: query, type: "lists"),
        // Center(child: Text("Search Lists (Coming Soon)")),
      ],
    );
  }
}

// Helper Widget untuk Menampilkan Hasil Search (Biar kode rapi)
// Helper Widget untuk Menampilkan Hasil Search
class _SearchResultList extends StatefulWidget {
  final String query;
  final String type; // "books", "authors", dll

  const _SearchResultList({required this.query, required this.type});

  @override
  State<_SearchResultList> createState() => _SearchResultListState();
}

// Tambahkan 'AutomaticKeepAliveClientMixin' agar Tab tidak hancur saat digeser
class _SearchResultListState extends State<_SearchResultList>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService =
      FirestoreService(); // Panggil Firestore

  List<dynamic> _results =
      []; // Dynamic karena isinya bisa Book, User, atau Review
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

      // LOGIKA SWITCH SESUAI TAB
      switch (widget.type) {
        case 'books':
          res = await _apiService.fetchBooks(widget.query);
          break;

        case 'authors':
          // Google Books support pencarian khusus penulis "inauthor:nama"
          res = await _apiService.fetchBooks('inauthor:${widget.query}');
          break;

        case 'people':
          res = await _firestoreService.searchUsers(widget.query);
          break;

        case 'reviews':
          res = await _firestoreService.searchReviews(widget.query);
          break;

        case 'lists': // <-- Tambahkan Case ini
          // Pastikan Anda sudah uncomment Tab 'Lists' di AppBar
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

        // TAMPILAN 1: BUKU & AUTHOR (Strukturnya sama: Book Model)
        if (widget.type == 'books' || widget.type == 'authors') {
          return _buildBookTile(item);
        }
        // TAMPILAN 2: PEOPLE (User Model)
        else if (widget.type == 'people') {
          return _buildUserTile(item);
        }
        // TAMPILAN 3: REVIEWS (Review Model)
        else if (widget.type == 'reviews') {
          return _buildReviewTile(item);
        }
        // TAMPILAN 4: LISTS / SHELVES
        else if (widget.type == 'lists') {
          return _buildBookListModelTile(item);
        }

        return const SizedBox();
      },
    );
  }

  // --- WIDGET TILE KHUSUS ---

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
      // Foto Profil
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        backgroundImage:
            user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
        child: user.photoUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      // Nama (Sekarang pasti muncul Ricardo)
      title: Text(user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      // Navigasi saat ditekan (Tanpa tombol View)
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey
                .withValues(alpha: 0.05), // Perbaikan sintaks opacity modern
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Foto Profil & Nama User (Penulis Review)
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              // Karena kita belum simpan displayName di Review, kita pakai 'User' dulu
              // Saran: Nanti update review_model untuk simpan 'userDisplayName' juga
              const Text(
                "Bibliomate User",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              Icon(Icons.star, size: 14, color: Colors.amber[700]),
              Text(
                " ${review.rating}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 16),

          // Body: Cover Buku & Isi Review
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Buku Kecil
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

              // Teks Review
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
    );
  }

 Widget _buildBookListModelTile(BookListModel list) {
    return GestureDetector(
      onTap: () {
        // NAVIGASI KE DETAIL LIST
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookListDetailScreen(bookList: list),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview Tumpukan (Stack Effect)
            SizedBox(
              width: 80,
              height: 100,
              child: Stack(
                children: [
                  if (list.previewImages.length > 1)
                    Positioned(
                      top: 0,
                      left: 10,
                      child: Container(
                        width: 60,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  if (list.previewImages.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          list.previewImages[0],
                          width: 70,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey[400]),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 70,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.collections_bookmark,
                          size: 40, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Info List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Text(
                    list.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${list.bookCount} books",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
