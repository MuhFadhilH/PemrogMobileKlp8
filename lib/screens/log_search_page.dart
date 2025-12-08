import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';

class LogSearchPage extends StatefulWidget {
  // Jika null, berarti mode normal (Log review / Search umum)
  // Jika diisi, berarti mode "Add to Playlist" (Spotify style)
  final String? targetBookListId;
  final bool isGeneralSearch; // Tetap simpan untuk fallback

  const LogSearchPage({
    super.key,
    this.targetBookListId,
    this.isGeneralSearch = false,
  });

  @override
  State<LogSearchPage> createState() => _LogSearchPageState();
}

class _LogSearchPageState extends State<LogSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService =
      FirestoreService(); // Instance Service

  List<Book> _searchResults = [];
  bool _isSearching = false;

  // State Khusus Mode "Add to Playlist"
  final Set<String> _addedBookIds =
      {}; // Menyimpan ID buku yang baru saja ditambah
  int _sessionAddedCount = 0; // Menghitung berapa buku yang ditambah sesi ini

  final List<String> _recentSearches = [
    "Laut Bercerita",
    "Atomic Habits",
    "Filosofi Teras",
    "Pulang - Leila S. Chudori",
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

  // --- LOGIKA UTAMA: ADD TO PLAYLIST (SPOTIFY STYLE) ---
  void _quickAddBook(Book book) async {
    if (widget.targetBookListId == null) return;

    // 1. Cek apakah sudah ditambahkan barusan (biar gak double klik)
    if (_addedBookIds.contains(book.id)) return;

    // 2. Simpan ke Firestore
    await _firestoreService.addBookToBookList(widget.targetBookListId!, book);

    // 3. Update UI Local (Kasih tanda centang & update counter)
    setState(() {
      _addedBookIds.add(book.id);
      _sessionAddedCount++;
    });

    // 4. Opsional: Haptic feedback atau bunyi 'ting'
  }

  void _onBookTap(Book book) {
    // Skenario 1: Mode Add to Playlist -> Klik bukunya langsung nge-add (atau buka detail?)
    // Biasanya di Spotify: Klik baris = Play (disini Add), Klik titik tiga = Detail.
    // Kita buat: Klik baris = Buka Detail (biar bisa baca dulu), Klik Icon (+) = Add.

    // Tapi user minta "kalau di klik lagunya nanti tidak ke page baru".
    // Oke, kita buat: Klik = Add langsung (Quick Add).
    if (widget.targetBookListId != null) {
      _quickAddBook(book);
    }
    // Skenario 2: Mode General Search -> Buka Detail
    else if (widget.isGeneralSearch) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => DetailScreen(book: book)));
    }
    // Skenario 3: Mode Log Review -> Buka Form
    else {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => LogFormPage(book: book)));
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
            hintText: widget.targetBookListId != null
                ? "Tambah ke playlist..."
                : "Cari buku...",
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
      // Menggunakan Column + Expanded agar bisa taruh Info Bar di bawah
      body: Column(
        children: [
          Expanded(child: _buildBody()),

          // --- INFO BAR (POP UP BAWAH) ---
          if (_sessionAddedCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0), // Warna utama
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$_sessionAddedCount buku ditambahkan",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context), // Tombol Selesai
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text("Selesai",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) return const Center(child: CircularProgressIndicator());

    if (_searchController.text.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text("PENCARIAN TERAKHIR",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._recentSearches.map((text) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(text,
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
                onTap: () {
                  _searchController.text = text;
                  _searchBooks(text);
                },
              )),
        ],
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];

        // Cek status apakah sudah ditambahkan di sesi ini
        final bool isAdded = _addedBookIds.contains(book.id);

        return ListTile(
          leading: Image.network(
            book.thumbnailUrl,
            width: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.book),
          ),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(book.author, maxLines: 1),

          // ICON DI KANAN (Visual Feedback)
          trailing: widget.targetBookListId != null
              ? IconButton(
                  icon: Icon(
                    isAdded ? Icons.check_circle : Icons.add_circle_outline,
                    color: isAdded ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  onPressed: () => _quickAddBook(book),
                )
              : null,

          onTap: () => _onBookTap(book),
        );
      },
    );
  }
}

// ... (Class LogFormPage di bawahnya SAMA PERSIS dengan sebelumnya, tidak berubah) ...
class LogFormPage extends StatefulWidget {
  final Book book;
  const LogFormPage({super.key, required this.book});
  @override
  State<LogFormPage> createState() => _LogFormPageState();
}

class _LogFormPageState extends State<LogFormPage> {
  // ... (Code Form Review lama kamu disini) ...
  // Biarkan kosong/copy dari file sebelumnya karena bagian ini tidak berubah
  bool _isSubmitting = false;
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  void _saveReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Beri rating minimal 1 bintang ⭐")));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await FirestoreService().addReview(
          book: widget.book,
          rating: _rating,
          reviewText: _reviewController.text);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Review berhasil disimpan!"),
            backgroundColor: Color(0xFF5C6BC0)));
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text("I Read...",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(
                onPressed: _saveReview,
                child: const Text("Save",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF5C6BC0))))
          ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ... UI Form Review (Poster, Bintang, TextField) SAMA SEPERTI SEBELUMNYA ...
            // (Saya singkat biar tidak kepanjangan, isinya persis LogFormPage kamu yang lama)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.book.thumbnailUrl,
                      width: 100, height: 150, fit: BoxFit.cover)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.book.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.book.author,
                        style: const TextStyle(color: Colors.grey)),
                  ]))
            ]),
            const SizedBox(height: 30),
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
                            size: 40),
                        onPressed: () =>
                            setState(() => _rating = index + 1.0)))),
            const Divider(height: 40),
            TextField(
                controller: _reviewController,
                maxLines: null,
                decoration: const InputDecoration(
                    hintText: "Add a review...", border: InputBorder.none)),
          ],
        ),
      ),
    );
  }
}
