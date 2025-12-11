import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_list_model.dart';
import '../models/book_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
import 'log_search_page.dart';
import 'public_profile_screen.dart';

class BookListDetailScreen extends StatelessWidget {
  final BookListModel bookList;
  const BookListDetailScreen({super.key, required this.bookList});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner =
        currentUser != null && currentUser.uid == bookList.ownerId;

    void goToAddBooks() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LogSearchPage(
              targetBookListId: bookList.id!, targetOwnerId: bookList.ownerId),
        ),
      );
    }

    void goToOwnerProfile() async {
      final user = await firestoreService.getUserById(bookList.ownerId);
      if (context.mounted && user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PublicProfileScreen(user: user)),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil pengguna tidak ditemukan")),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          bookList.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
                          await firestoreService
                              .deleteBookListModel(bookList.id!);
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
        stream: firestoreService.getBooksInListForUser(
          listId: bookList.id!,
          ownerId: bookList.ownerId,
        ),
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
                  Icon(Icons.playlist_add, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("List ini masih kosong."),
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
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    book.thumbnailUrl,
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(width: 50, color: Colors.grey[200]),
                  ),
                ),
                title: Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(book.author, maxLines: 1),
                trailing: isOwner
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.grey),
                        onPressed: () {
                          _showDeleteBookDialog(
                              context, firestoreService, bookList.id!, book.id);
                        },
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(book: book),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteBookDialog(BuildContext context, FirestoreService service,
      String listId, String bookId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Buku dari List?"),
        content: const Text("Buku ini akan dihapus dari list ini."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteBookFromList(listId, bookId);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Buku berhasil dihapus")),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
