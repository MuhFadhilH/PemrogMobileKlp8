import 'dart:math'; // Import wajib buat ngacak
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
import 'reading_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Book> _books = [];
  bool _isLoading = false;
  String _currentQuery = ''; // Nanti diisi otomatis

  // --- DAFTAR TOPIK ACAK ---
  final List<String> _randomTopics = [
    'Technology',
    'Programming',
    'History',
    'Fiction',
    'Horror',
    'Science',
    'Business',
    'Design',
    'Cooking',
    'Travel',
    'Biography',
    'Fantasy',
  ];

  @override
  void initState() {
    super.initState();
    _pickRandomTopicAndFetch(); // Jalankan fungsi acak saat mulai
  }

  // Fungsi pilih topik acak lalu ambil data
  Future<void> _pickRandomTopicAndFetch() async {
    // Pilih 1 topik acak dari list
    final randomTopic = _randomTopics[Random().nextInt(_randomTopics.length)];

    setState(() {
      _currentQuery = randomTopic; // Set judul agar user tau ini topik apa
    });

    await _fetchBooks(randomTopic);
  }

  Future<void> _fetchBooks(String query) async {
    setState(() => _isLoading = true);
    try {
      final fetchedBooks = await _apiService.fetchBooks(query);
      setState(() {
        _books = fetchedBooks;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background Soft
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Bibliomate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // Menampilkan topik apa yang sedang tampil
            Text(
              'Topik Hari Ini: $_currentQuery',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Tombol Refresh (Kalau mau ganti topik manual)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _pickRandomTopicAndFetch,
            tooltip: "Ganti Topik",
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_added_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReadingListScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh:
                  _pickRandomTopicAndFetch, // Tarik layar buat ganti topik
              child: _books.isEmpty
                  ? const Center(child: Text("Tidak ada buku ditemukan"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        return BookListItem(
                          book: _books[index],
                          firestoreService: _firestoreService,
                        );
                      },
                    ),
            ),
    );
  }
}

// --- WIDGET ITEM BUKU (Soft UI + Bookmark Dinamis) ---
class BookListItem extends StatelessWidget {
  final Book book;
  final FirestoreService firestoreService;

  const BookListItem({
    super.key,
    required this.book,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Buku
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.thumbnailUrl,
                width: 70,
                height: 105,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 105,
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info Buku
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        book.averageRating > 0
                            ? book.averageRating.toString()
                            : 'N/A',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bookmark Button
            StreamBuilder<BookStatus>(
              stream: firestoreService.getBookStatusStream(book.id),
              builder: (context, snapshot) {
                final status = snapshot.data ?? BookStatus.none;
                return IconButton(
                  icon: Icon(
                    status != BookStatus.none
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: status != BookStatus.none
                        ? const Color(0xFF5C6BC0)
                        : Colors.grey[400],
                  ),
                  onPressed: () => _showStatusModal(context, book, status),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusModal(
    BuildContext context,
    Book book,
    BookStatus currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Simpan ke Koleksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _option(
              context,
              book,
              BookStatus.wantToRead,
              "Ingin Dibaca",
              currentStatus,
            ),
            _option(
              context,
              book,
              BookStatus.currentlyReading,
              "Sedang Dibaca",
              currentStatus,
            ),
            _option(
              context,
              book,
              BookStatus.finished,
              "Selesai Dibaca",
              currentStatus,
            ),
            if (currentStatus != BookStatus.none) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Hapus dari koleksi",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  firestoreService.saveBookToReadingList(book, BookStatus.none);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context,
    Book book,
    BookStatus status,
    String label,
    BookStatus current,
  ) {
    return RadioListTile<BookStatus>(
      title: Text(label),
      value: status,
      groupValue: current,
      activeColor: const Color(0xFF5C6BC0),
      onChanged: (val) {
        firestoreService.saveBookToReadingList(book, val!);
        Navigator.pop(context);
      },
    );
  }
}
