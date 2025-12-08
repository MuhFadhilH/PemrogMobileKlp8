import 'package:flutter/material.dart';
import '../models/book_list_model.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
import 'log_search_page.dart'; // Pastikan import ini

class BookListDetailScreen extends StatelessWidget {
  final BookList bookList;
  const BookListDetailScreen({super.key, required this.bookList});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    // Fungsi Navigasi ke Search Page dengan ID BookList
    void goToAddBooks() {
      Navigator.push(
        context,
        MaterialPageRoute(
          // KITA PASSING ID BOOKLIST DI SINI
          builder: (_) => LogSearchPage(targetBookListId: bookList.id),
        ),
      );
    }

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
                  content: const Text("Daftar ini akan dihapus permanen."),
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

      // TOMBOL TAMBAH MELAYANG (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: goToAddBooks,
        backgroundColor: const Color(0xFF5C6BC0),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: StreamBuilder<List<Book>>(
        stream: firestoreService.getBooksInBookList(bookList.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data ?? [];

          // TAMPILAN KOSONG
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("BookList ini masih kosong.",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),

                  // Tombol di tengah layar (alternatif FAB)
                  OutlinedButton.icon(
                    onPressed: goToAddBooks,
                    icon: const Icon(Icons.search),
                    label: const Text("Cari buku untuk ditambahkan"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5C6BC0),
                      side: const BorderSide(color: Color(0xFF5C6BC0)),
                    ),
                  ),
                ],
              ),
            );
          }

          // TAMPILAN LIST BUKU
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

                // Opsi Hapus Buku dari List (Bisa ditambah nanti)
                trailing:
                    const Icon(Icons.more_vert, size: 20, color: Colors.grey),

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
