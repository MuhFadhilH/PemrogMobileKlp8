import 'package:flutter/material.dart';
import '../../../models/book_model.dart';
import '../../../services/api_service.dart';
// import '../../services/firestore_service.dart'; // Nanti diaktifkan saat save

class LogBookModal extends StatefulWidget {
  const LogBookModal({super.key});

  @override
  State<LogBookModal> createState() => _LogBookModalState();
}

class _LogBookModalState extends State<LogBookModal> {
  // State untuk Pencarian
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Book> _searchResults = [];
  bool _isSearching = false;

  // State untuk Form Review
  Book? _selectedBook;
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  // 1. FUNGSI CARI BUKU
  Future<void> _searchBooks() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final results = await _apiService.fetchBooks(_searchController.text);
      setState(() => _searchResults = results);
    } catch (e) {
      // Handle error tipis-tipis
      debugPrint("Error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // 2. FUNGSI SAAT BUKU DIPILIH
  void _onBookSelected(Book book) {
    setState(() {
      _selectedBook = book; // Ini akan memicu perubahan UI ke mode "Form"
    });
  }

  // 3. FUNGSI SIMPAN (CRUD CREATE)
  void _submitReview() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jangan lupa kasih bintang! ⭐")),
      );
      return;
    }

    // TODO: Panggil FirestoreService.addReview di sini
    // Data yang dikirim: _selectedBook, _rating, _reviewController.text

    Navigator.pop(context); // Tutup modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Review '${_selectedBook!.title}' berhasil disimpan!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tinggi modal menyesuaikan keyboard
    return Container(
      padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              24 // Biar gak ketutup keyboard
          ),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indikator Geser (Garis kecil di atas)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // LOGIKA UI: Tampilkan Form Review jika buku sudah dipilih
          if (_selectedBook != null) _buildReviewForm() else _buildSearchUI(),
        ],
      ),
    );
  }

  // --- TAMPILAN 1: PENCARIAN BUKU ---
  Widget _buildSearchUI() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Log a Book",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: _searchController,
            autofocus: true, // Keyboard langsung muncul
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchBooks(), // Cari saat tekan Enter
            decoration: InputDecoration(
              hintText: "Cari judul, penulis, atau ISBN...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _searchBooks,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 20),

          // Hasil Pencarian
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          "Cari buku yang baru saja kamu baca.",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final book = _searchResults[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                book.thumbnailUrl,
                                width: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.book),
                              ),
                            ),
                            title: Text(book.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(book.author, maxLines: 1),
                            trailing: const Icon(Icons.add_circle_outline,
                                color: Color(0xFF5C6BC0)),
                            onTap: () => _onBookSelected(book),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // --- TAMPILAN 2: FORM REVIEW (Letterboxd Style) ---
  Widget _buildReviewForm() {
    // Kita pakai tanggal hari ini sebagai default
    String dateLabel = "Today";

    return Expanded(
      child: Column(
        children: [
          // Header: Back Button & Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => setState(() => _selectedBook = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              const Text(
                "I Read...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              TextButton(
                onPressed: _submitReview,
                child: const Text(
                  "Save",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BAGIAN ATAS: Poster + Meta Data
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Poster Buku (Kiri)
                      Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _selectedBook!.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[300]),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 2. Meta Data (Kanan)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedBook!.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Judul Besar
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedBook!.author,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),

                            const SizedBox(height: 16),

                            // Tanggal Baca
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Read on $dateLabel",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // BAGIAN TENGAH: Rating & Review
                  const Text("Rating",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  Row(
                    children: [
                      // Bintang
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(), // Biar bintangnya rapet
                            icon: Icon(
                              index < _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color:
                                  const Color(0xFF5C6BC0), // Warna Indigo/Biru
                              size: 36,
                            ),
                            onPressed: () =>
                                setState(() => _rating = index + 1.0),
                          );
                        }),
                      ),
                      const Spacer(),
                      // Tombol Like (Heart)
                      IconButton(
                        icon: const Icon(Icons.favorite_border,
                            color: Colors.grey),
                        onPressed: () {
                          // Logic Like toggle nanti disini
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Input Text Review (Tanpa Border biar bersih ala Notepad)
                  TextField(
                    controller: _reviewController,
                    maxLines: null, // Unlimited lines
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: "Add a review...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      border: InputBorder.none, // Hilangkan kotak
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 100), // Space bawah biar enak scroll
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
