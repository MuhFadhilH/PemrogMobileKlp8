import 'detail_screen.dart';
import 'dart:math'; // Import ini untuk fitur acak rekomendasi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'reading_list_screen.dart';

// Ubah jadi StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // --- FITUR REKOMENDASI OTOMATIS ---
    // Trik: Kita panggil pencarian otomatis setelah frame pertama selesai dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Kita acak topik agar terlihat seperti rekomendasi dinamis
      final topics = ['technology', 'history', 'fiction', 'cooking', 'science'];
      final randomTopic = topics[Random().nextInt(topics.length)];

      // Panggil fungsi search di Provider
      Provider.of<BookProvider>(
        context,
        listen: false,
      ).searchBooks(randomTopic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari & Rekomendasi'), // Judul kita update sedikit
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks),
            tooltip: 'Daftar Bacaan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReadingListScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Cari judul spesifik...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      Provider.of<BookProvider>(
                        context,
                        listen: false,
                      ).searchBooks(_controller.text);
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (value) {
                // Agar user bisa enter di keyboard hp
                if (value.isNotEmpty) {
                  Provider.of<BookProvider>(
                    context,
                    listen: false,
                  ).searchBooks(value);
                }
              },
            ),
          ),

          // --- Hasil List / Rekomendasi ---
          Expanded(
            child: Consumer<BookProvider>(
              builder: (context, provider, child) {
                // 1. Tampilan Loading
                if (provider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Sedang mengambil rekomendasi..."),
                      ],
                    ),
                  );
                }

                // 2. Tampilan Jika Kosong / Error
                if (provider.books.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        Text('Buku tidak ditemukan.'),
                      ],
                    ),
                  );
                }

                // 3. Tampilan List Buku
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.books.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final book = provider.books[index];
                    final isSaved = provider.isInReadingList(book);

                    return Card(
                      // Pakai Card biar lebih cantik
                      elevation: 2,
                      child: ListTile(
                        onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(book: book),
        ),
      );
    },
                        contentPadding: const EdgeInsets.all(8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book.thumbnailUrl,
                            width: 50,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, _) =>
                                const Icon(Icons.book),
                          ),
                        ),
                        title: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? Colors.blue : Colors.grey,
                            size: 28,
                          ),
                          onPressed: () {
                            provider.toggleReadingList(book);
                            // Opsional: Tampilkan pesan kecil (SnackBar)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isSaved
                                      ? 'Dihapus dari daftar bacaan'
                                      : 'Disimpan ke daftar bacaan',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
