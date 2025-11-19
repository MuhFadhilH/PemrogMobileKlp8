// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Pastikan ini tetap ada jika BookProvider dipakai di tempat lain
import '../models/book_model.dart';
import '../models/book_status.dart'; // Import ini
import '../providers/book_provider.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart'; // Import ini
import 'detail_screen.dart';
import 'reading_list_screen.dart'; // Import ini

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService =
      FirestoreService(); // Inisialisasi FirestoreService
  List<Book> _books = [];
  bool _isLoading = false;
  String _currentQuery = 'Flutter programming'; // Default query

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedBooks = await _apiService.fetchBooks(_currentQuery);
      setState(() {
        _books = fetchedBooks;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load books: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliomate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_added_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReadingListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigasi ke ProfileScreen
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return BookListItem(
                  book: book,
                  firestoreService: _firestoreService,
                ); // Menggunakan widget baru
              },
            ),
    );
  }
}

// --- WIDGET BARU: BOOK LIST ITEM (Untuk tampilan Soft UI) ---
class BookListItem extends StatelessWidget {
  final Book book;
  final FirestoreService firestoreService; // Terima FirestoreService

  const BookListItem({
    super.key,
    required this.book,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(book: book)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.thumbnailUrl,
                width: 70,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                        book.averageRating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${book.ratingsCount} review)',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- ICON BOOKMARK DINAMIS ---
            StreamBuilder<BookStatus>(
              stream: firestoreService.getBookStatusStream(book.id),
              builder: (context, snapshot) {
                final currentStatus = snapshot.data ?? BookStatus.none;
                return IconButton(
                  icon: Icon(
                    currentStatus != BookStatus.none
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: currentStatus != BookStatus.none
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed: () {
                    // Ketika ditekan, munculkan modal pilihan status
                    _showStatusSelectionModal(
                      context,
                      book,
                      currentStatus,
                      firestoreService,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSelectionModal(
    BuildContext context,
    Book book,
    BookStatus currentStatus,
    FirestoreService firestoreService,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atur Status Buku: ${book.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...BookStatus.values.where((s) => s != BookStatus.none).map((
                status,
              ) {
                return RadioListTile<BookStatus>(
                  title: Text(status.toDisplayString()),
                  value: status,
                  groupValue: currentStatus,
                  onChanged: (newValue) async {
                    if (newValue != null) {
                      await firestoreService.saveBookToReadingList(
                        book,
                        newValue,
                      );
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Status diubah ke ${newValue.toDisplayString()}',
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
              // Opsi untuk menghapus dari daftar
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus dari Daftar'),
                onTap: () async {
                  await firestoreService.saveBookToReadingList(
                    book,
                    BookStatus.none,
                  );
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Buku dihapus dari daftar')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
