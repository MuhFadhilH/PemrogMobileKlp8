import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahkan import Auth
import '../models/book_list_model.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
import 'log_search_page.dart';

class BookListDetailScreen extends StatelessWidget {
  final BookListModel bookList;
  const BookListDetailScreen({super.key, required this.bookList});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    // 1. Cek apakah User yang login adalah Pemilik List ini
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && currentUser.uid == bookList.ownerId;

    void goToAddBooks() {
      Navigator.push(
        context,
        MaterialPageRoute(
          // Kirim ID List dan Owner ID
          builder: (_) => LogSearchPage(
              targetBookListId: bookList.id, targetOwnerId: bookList.ownerId),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(bookList.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // 2. Hanya tampilkan tombol DELETE & ADD jika user adalah PEMILIK
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Hapus List?"),
                    content: const Text("Tindakan ini tidak bisa dibatalkan."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Panggil service delete (pastikan fungsinya ada di service)
                          await firestoreService
                              .deleteBookListModel(bookList.id);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Hapus",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: goToAddBooks,
            ),
          ]
        ],
      ),
      body: StreamBuilder<List<Book>>(
        // Menggunakan fungsi yang membutuhkan ownerId agar bisa baca list orang lain
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
                  // Tombol tambah di tengah juga hanya muncul jika owner
                  if (isOwner)
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

                // Tombol Hapus per Buku (Hanya muncul jika Owner)
                trailing: isOwner
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () {
                          // Tampilkan dialog konfirmasi
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Hapus Buku?"),
                              content:
                                  Text("Hapus '${book.title}' dari list ini?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx); // Tutup dialog
                                    try {
                                      await firestoreService.removeBookFromList(
                                        listId: bookList.id,
                                        ownerId: bookList.ownerId,
                                        bookId: book.id,
                                      );
                                      // StreamBuilder akan otomatis refresh
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text("Buku berhasil dihapus"),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text("Error: ${e.toString()}"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text("Hapus",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : null, // Jika bukan owner, tidak ada tombol hapus

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
