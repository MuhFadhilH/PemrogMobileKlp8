import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/book_status.dart'; // Pastikan import ini ada
import '../services/firestore_service.dart';

class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key});

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen> {
  final FirestoreService firestoreService = FirestoreService();

  // Default filter: Tampilkan semua buku
  BookStatus _selectedFilter = BookStatus.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Koleksi Saya"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // --- 1. FILTER BAR (Bagian Atas) ---
          Container(
            color: Colors.white,
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _buildFilterChip(BookStatus.none, 'Semua'),
                _buildFilterChip(BookStatus.wantToRead, 'Ingin Dibaca'),
                _buildFilterChip(BookStatus.currentlyReading, 'Sedang Baca'),
                _buildFilterChip(BookStatus.finished, 'Selesai'),
              ],
            ),
          ),

          // --- 2. LIST BUKU (Bagian Bawah) ---
          Expanded(
            // PERBAIKAN UTAMA ADA DISINI 👇
            // Ganti <QuerySnapshot> menjadi <List<Book>>
            child: StreamBuilder<List<Book>>(
              stream: firestoreService.getReadingList(
                filterStatus: _selectedFilter,
              ),
              builder: (context, snapshot) {
                // A. Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // B. Data Kosong / Error
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmarks_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada buku di kategori ini",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // C. Data Ada (List<Book>)
                List<Book> books = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        // Thumbnail
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book.thumbnailUrl,
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 75,
                              color: Colors.grey[200],
                            ),
                          ),
                        ),
                        // Judul
                        title: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Status (Subtitle)
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Badge Status Kecil
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6BC0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                book.readingStatus.toDisplayString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF5C6BC0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Tombol Hapus
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            // Hapus buku lewat service
                            firestoreService.saveBookToReadingList(
                              book,
                              BookStatus.none,
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

  // Widget Helper untuk Tombol Filter (Chip)
  Widget _buildFilterChip(BookStatus status, String label) {
    bool isSelected = _selectedFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF5C6BC0),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[100],
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedFilter = status;
            });
          }
        },
      ),
    );
  }
}
