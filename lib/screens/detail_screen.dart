import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Untuk efek Blur
import 'package:url_launcher/url_launcher.dart'; // Buka link asli
import '../models/book_model.dart';
import '../providers/book_provider.dart';

class DetailScreen extends StatefulWidget {
  final Book book;

  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Data Review Lokal (Simulasi agar UI terlihat penuh)
  // Karena API tidak menyediakan TEXT review, kita pakai ini untuk demo tugas.
  final List<Map<String, dynamic>> _localReviews = [
    {
      'name': 'Pengguna Google',
      'avatar': 'P',
      'color': Colors.orange,
      'rating': 5,
      'date': 'Bulan lalu',
      'content': 'Buku yang sangat bagus untuk referensi belajar.'
    },
    {
      'name': 'Ahmad Z.',
      'avatar': 'A',
      'color': Colors.blue,
      'rating': 4,
      'date': '2 minggu lalu',
      'content': 'Pengiriman cepat (jika beli fisik), konten ebook rapi.'
    },
  ];

  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;

  // Fungsi Tambah Review (Tugas Kuliah Friendly)
  void _addReview() {
    if (_reviewController.text.isEmpty) return;
    setState(() {
      _localReviews.insert(0, {
        'name': 'Saya',
        'avatar': 'U',
        'color': Colors.green,
        'rating': _selectedRating,
        'date': 'Baru saja',
        'content': _reviewController.text,
      });
    });
    _reviewController.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ulasan Anda berhasil ditambahkan!")),
    );
  }

  // Fungsi Buka Play Store Asli
  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;
    final Uri url = Uri.parse(widget.book.infoLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak bisa membuka link")),
      );
    }
  }

  void _showWriteReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tulis Ulasan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(index < _selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                    onPressed: () => setModalState(() => _selectedRating = index + 1),
                  )),
                ),
                TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(hintText: "Bagaimana pendapatmu?", border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _addReview, child: const Text("Kirim"))),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan data rating asli dari API jika ada, jika 0 pakai default dummy untuk tampilan
    final double displayRating = widget.book.averageRating > 0 ? widget.book.averageRating : 4.5;
    final int displayCount = widget.book.ratingsCount > 0 ? widget.book.ratingsCount : 120;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- HEADER BLUR ---
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.blue.shade900,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.book.thumbnailUrl, fit: BoxFit.cover),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          height: 180, width: 120,
                          decoration: BoxDecoration(
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.book.thumbnailUrl, fit: BoxFit.cover)),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            widget.book.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(widget.book.author, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.arrow_back, color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<BookProvider>(builder: (context, provider, child) {
                final isSaved = provider.isInReadingList(widget.book);
                return IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Colors.blueAccent : Colors.white),
                  ),
                  onPressed: () => provider.toggleReadingList(widget.book),
                );
              }),
              const SizedBox(width: 10),
            ],
          ),

          // --- KONTEN ---
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text("Contoh Gratis"))),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton(onPressed: _launchPlayStore, child: const Text("Beli Ebook"))),
                      ],
                    ),
                    const Divider(height: 30),
                    const Text("Tentang Ebook ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(widget.book.description, style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5), textAlign: TextAlign.justify),
                    
                    const Divider(height: 40, thickness: 5, color: Color(0xFFF0F0F0)),
                    
                    // --- STATISTIK RATING ---
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$displayRating", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                            Row(children: List.generate(5, (i) => Icon(i < displayRating.round() ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
                            Text("$displayCount ulasan", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [5, 4, 3, 2, 1].map((star) => Row(
                            children: [
                              Text("$star", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 5),
                              Container(width: 100, height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3)),
                                child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: star == 5 ? 0.8 : 0.1, child: Container(color: Colors.blue))),
                            ],
                          )).toList(),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    OutlinedButton(onPressed: _showWriteReviewModal, child: const Text("Tulis ulasan Anda")),
                    const SizedBox(height: 20),

                    // --- LIST REVIEW ---
                    ..._localReviews.map((review) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(backgroundColor: review['color'], child: Text(review['avatar'], style: const TextStyle(color: Colors.white))),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    ...List.generate(5, (i) => Icon(i < review['rating'] ? Icons.star : Icons.star_border, size: 14, color: Colors.amber)),
                                    const SizedBox(width: 8),
                                    Text(review['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(review['content']),
                              ],
                            ),
                          )
                        ],
                      ),
                    )),
                    
                    const SizedBox(height: 30),
                    Center(
                      child: TextButton(
                        onPressed: _launchPlayStore,
                        child: const Text("Lihat semua ulasan di Google Play Store"),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}