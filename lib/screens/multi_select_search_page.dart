import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/api_service.dart'; // GANTI INI
import '../services/firestore_service.dart';

class MultiSelectSearchPage extends StatefulWidget {
  final String targetBookListId;
  final String targetOwnerId;

  const MultiSelectSearchPage({
    super.key,
    required this.targetBookListId,
    required this.targetOwnerId,
  });

  @override
  State<MultiSelectSearchPage> createState() => _MultiSelectSearchPageState();
}

class _MultiSelectSearchPageState extends State<MultiSelectSearchPage> {
  final ApiService _apiService = ApiService(); // GANTI INI
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _searchResults = [];
  List<String> _selectedBookIds = [];
  bool _isLoading = false;

  void _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // GANTI INI: pakai fetchBooks dari ApiService
      final results = await _apiService.fetchBooks(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Optional: tampilkan error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mencari buku: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleBookSelection(Book book) {
    setState(() {
      if (_selectedBookIds.contains(book.id)) {
        _selectedBookIds.remove(book.id);
      } else {
        _selectedBookIds.add(book.id);
      }
    });
  }

  Future<void> _addSelectedBooks() async {
    if (_selectedBookIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal satu buku")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int addedCount = 0;
      for (String bookId in _selectedBookIds) {
        final book = _searchResults.firstWhere((b) => b.id == bookId);
        await _firestoreService.addBookToList(
          listId: widget.targetBookListId,
          ownerId: widget.targetOwnerId,
          book: book,
        );
        addedCount++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$addedCount buku berhasil ditambahkan"),
            duration: const Duration(seconds: 2),
          ),
        );

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Buku ke List"),
        actions: [
          if (_selectedBookIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addSelectedBooks,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari buku...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchBooks('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchBooks,
            ),
          ),
          if (_selectedBookIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Text(
                    "${_selectedBookIds.length} buku terpilih",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _addSelectedBooks,
                    child: const Text("Tambah Semua"),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? "Cari buku untuk ditambahkan"
                                  : "Tidak ada hasil untuk '${_searchController.text}'",
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final book = _searchResults[index];
                          final isSelected = _selectedBookIds.contains(book.id);

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      book.thumbnailUrl,
                                      width: 50,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 50,
                                        height: 70,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.book),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                book.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  _toggleBookSelection(book);
                                },
                              ),
                              onTap: () {
                                _toggleBookSelection(book);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _selectedBookIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addSelectedBooks,
              icon: const Icon(Icons.add),
              label: Text("Tambah (${_selectedBookIds.length})"),
            )
          : null,
    );
  }
}
