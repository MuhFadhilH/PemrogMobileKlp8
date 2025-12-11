import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class CollectionScreen extends StatefulWidget {
  final Map<String, String> collectionData;

  const CollectionScreen({super.key, required this.collectionData});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    // Ambil keyword dari data yang dikirim, lalu fetch ke API
    final keyword = widget.collectionData['keyword'] ?? 'General';
    _booksFuture = _apiService.fetchBooks(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR YANG BISA MEMANJANG (SLIVER)
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true, // Header tetap nempel saat discroll
            backgroundColor: const Color(0xFF5C6BC0),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.collectionData['subtitle'] ?? 'Collection',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.collectionData['image']!,
                    fit: BoxFit.cover,
                  ),
                  // Overlay gelap biar teks header kebaca
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  // Judul Besar di tengah gambar
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.collectionData['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. DAFTAR BUKU
          FutureBuilder<List<Book>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text("Error: ${snapshot.error}")),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("Buku tidak ditemukan")),
                );
              }

              final books = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = books[index];
                    return _buildBookListItem(context, book);
                  },
                  childCount: books.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookListItem(BuildContext context, Book book) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          book.thumbnailUrl,
          width: 50,
          height: 75,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              width: 50,
              height: 75,
              color: Colors.grey[300],
              child: const Icon(Icons.book)),
        ),
      ),
      title: Text(
        book.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            // Langsung panggil book.authors karena dia sudah berupa String
            book.author.isNotEmpty ? book.author : 'Tanpa Penulis',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                book.averageRating.toString(),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey),
    );
  }
}
