import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'genre_books_screen.dart'; // Import file baru tadi

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
    _tabController = TabController(length: 4, vsync: this);

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
                  Tab(text: "Lists"),
                  Tab(text: "Reviews"),
                  Tab(text: "Authors"),
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
        color: genre['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: genre['color'].withOpacity(0.3)),
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
        const Center(child: Text("Search Lists (Coming Soon)")),
        const Center(child: Text("Search Reviews (Coming Soon)")),
        const Center(child: Text("Search Authors (Coming Soon)")),
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
  List<Book> _results = [];
  bool _isLoading = false;
  bool _hasSearched =
      false; // Penanda agar tidak fetch berulang kali jika data sudah ada

  @override
  void initState() {
    super.initState();
    // PERBAIKAN UTAMA: Langsung cari saat widget pertama kali dibuat/dibuka kembali
    if (widget.query.isNotEmpty) {
      _fetchResults();
    }
  }

  @override
  void didUpdateWidget(covariant _SearchResultList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika query berubah (user ngetik), cari ulang
    if (oldWidget.query != widget.query) {
      if (widget.query.isNotEmpty) {
        _fetchResults();
      } else {
        // Jika teks dihapus jadi kosong, bersihkan hasil
        setState(() => _results = []);
      }
    }
  }

  Future<void> _fetchResults() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Logic pembeda tipe pencarian (persiapan masa depan)
      if (widget.type == 'books') {
        final res = await _apiService.fetchBooks(widget.query);
        if (mounted) setState(() => _results = res);
      } else {
        // Dummy logic untuk tab lain (Authors/Lists) biar gak error
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _results = []);
      }
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

  // Wajib true agar state tab tersimpan (tidak reload terus saat ganti tab)
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib dipanggil karena pakai Mixin

    if (widget.query.isEmpty) {
      return const Center(child: Text("Ketik sesuatu untuk mencari..."));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Jika sudah mencari tapi hasil kosong
    if (_hasSearched && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text("Tidak ditemukan hasil untuk '${widget.query}'",
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final book = _results[index];
        return ListTile(
          leading: Image.network(
            book.thumbnailUrl,
            width: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.book, color: Colors.grey),
          ),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(book.author, maxLines: 1),
          onTap: () {
            // Pastikan DetailScreen sudah diimport di file ini
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailScreen(book: book)));
          },
        );
      },
    );
  }
}
