import 'package:flutter/material.dart';
import '../models/book_list_model.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
import 'log_search_page.dart'; // Import halaman search

class BookListDetailScreen extends StatelessWidget {
  final BookList bookList;
  const BookListDetailScreen({super.key, required this.bookList});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(bookList.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Hapus BookList?"),
                  content: const Text("Daftar buku ini akan dihapus permanen."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Batal")),
                    TextButton(
                      onPressed: () {
                        firestoreService.deleteBookList(bookList.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text("Hapus",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<List<Book>>(
        stream: firestoreService.getBooksInBookList(bookList.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data ?? [];

          // --- BAGIAN INI YANG KITA UPDATE UNTUK HANDLE EMPTY STATE ---
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("BookList ini masih kosong.",
                      style: TextStyle(color: Colors.grey)),

                  // Tombol Cari Buku
                  TextButton(
                    onPressed: () {
                      // Navigasi ke LogSearchPage dengan mode General Search
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LogSearchPage(isGeneralSearch: true),
                        ),
                      );
                    },
                    child: const Text(
                      "Cari buku untuk ditambahkan",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(book.thumbnailUrl,
                      width: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.book)),
                ),
                title: Text(book.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(book.author, maxLines: 1),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(book: book)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
