import 'package:flutter/material.dart';
import '../models/book_list_model.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
import 'log_search_page.dart';

class BookListDetailScreen extends StatelessWidget {
  final BookListModel bookList; // Pastikan pakai BookListModel
  const BookListDetailScreen({super.key, required this.bookList});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    void goToAddBooks() {
      Navigator.push(
        context,
        MaterialPageRoute(
          // Kirim ID List dan ID Pemiliknya agar LogSearchPage tahu mau simpan kemana
          builder: (_) => LogSearchPage(
              targetBookListId: bookList.id, targetOwnerId: bookList.ownerId),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // PERBAIKAN: Gunakan .title (bukan .name)
        title: Text(bookList.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // ... (kode dialog hapus tetap sama)
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: goToAddBooks,
          ),
        ],
      ),
      body: StreamBuilder<List<Book>>(
        // PERBAIKAN: Kirim ownerId juga karena list ada di dalam dokumen user
        stream: firestoreService.getBooksInList(
            listId: bookList.id, ownerId: bookList.ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.playlist_add, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("List ini masih kosong."),
                  TextButton(
                    onPressed: goToAddBooks,
                    child: const Text("Tambah Buku"),
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
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.grey),
                  onPressed: () {
                    // TODO: Tambahkan fungsi hapus buku dari list di sini
                  },
                ),
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
