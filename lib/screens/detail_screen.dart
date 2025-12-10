import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart';
import '../services/firestore_service.dart';
import '../screens/components/log_modal.dart';

class DetailScreen extends StatefulWidget {
  final Book book;
  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Color _primaryColor = const Color(0xFF5C6BC0);

  // ===========================================================================
  // LOGIC 1: MODAL LIST (READING LIST MAIN + CUSTOM LISTS)
  // ===========================================================================

  void _showCollectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Ukuran awal sedang
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Indikator Drag (Garis Kecil)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                // Judul Modal
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text("Simpan ke List",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),

                // ISI LIST
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    children: [
                      // --- ITEM 1: READING LIST (MAIN) ---
                      // List bawaan sistem yang terintegrasi jadwal
                      InkWell(
                        onTap: () {
                          Navigator.pop(context); // Tutup modal dulu
                          _handleReadingListSelection(); // Masuk logic jadwal
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: _primaryColor.withValues(),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.bookmark_added,
                                  color: _primaryColor),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Reading List (Main)",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text("List utama & Jadwal baca",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.add_circle_outline,
                                color: Colors.grey[400]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),

                      const Text("Koleksi Pribadi",
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(height: 10),

                      // --- ITEM 2 DST: CUSTOM LISTS DARI DATABASE ---
// ... kode sebelumnya ...
                      StreamBuilder<List<BookListModel>>(
                        stream: _firestoreService.getCustomLists(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator()));
                          }

                          var lists = snapshot.data ?? [];

                          if (lists.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                  child: Text("Belum ada list kustom.",
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontStyle: FontStyle.italic))),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lists.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final list = lists[index];
                              return InkWell(
                                onTap: () => _addBookToCustomList(list),
                                child: Row(
                                  children: [
                                    // Cover List
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: list.coverUrl != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      list.coverUrl!),
                                                  fit: BoxFit.cover)
                                              : null),
                                      child: list.coverUrl == null
                                          ? const Icon(Icons.folder_special,
                                              color: Colors.amber)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // PERBAIKAN DISINI: Gunakan .title, bukan .name
                                          Text(list.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          Text("${list.bookCount} buku",
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.add_circle_outline,
                                        color: Colors.grey[400]),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // --- FOOTER: TOMBOL BUAT LIST BARU ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateListDialog();
                      },
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey[300]!)),
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text("Buat List Baru",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // LOGIC: TAMBAH KE CUSTOM LIST (Dengan Cek Duplikasi via Service)
// LOGIC: TAMBAH KE CUSTOM LIST
  Future<void> _addBookToCustomList(BookListModel list) async {
    Navigator.pop(context); // Tutup modal

    try {
      await _firestoreService.addBookToBookListModel(list.id, widget.book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          // PERBAIKAN DISINI: Gunakan .title
          content: Text("Berhasil ditambahkan ke ${list.title}"),
          backgroundColor: _primaryColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // Dialog Buat List Baru
  void _showCreateListDialog() {
    final TextEditingController listNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buat List Baru"),
        content: TextField(
          controller: listNameController,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: "Nama List (contoh: Sad Novel)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (listNameController.text.isNotEmpty) {
                _firestoreService.createCustomList(listNameController.text);
                Navigator.pop(context);
                // Buka kembali modal koleksi setelah membuat list
                Future.delayed(
                    const Duration(milliseconds: 300), _showCollectionModal);
              }
            },
            child: const Text("Buat"),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOGIC 2: READING LIST SCHEDULE FLOW
  // ===========================================================================

  // Step 1: Konfirmasi Jadwal (Pop Up seperti foto ke 6)
  void _handleReadingListSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Atur Jadwal Baca?"),
        content: const Text(
            "Tentukan target mulai baca dan deadline selesai agar kamu lebih disiplin."),
        actions: [
          // Pilihan LEWATI: Masuk Reading List TANPA Jadwal
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firestoreService.saveBookToReadingList(
                  widget.book, BookStatus.wantToRead);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Masuk Reading List (Tanpa Jadwal)")));
            },
            child: const Text("Lewati", style: TextStyle(color: Colors.grey)),
          ),
          // Pilihan YA: Lanjut ke Kalender
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickDateRange();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, foregroundColor: Colors.white),
            child: const Text("Atur Jadwal"),
          ),
        ],
      ),
    );
  }

  // Step 2: Pilih Rentang Tanggal (Mulai - Selesai)
  Future<void> _pickDateRange() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        saveText: "LANJUT",
        helpText: "PILIH MULAI & DEADLINE",
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: _primaryColor,
              colorScheme: ColorScheme.light(primary: _primaryColor),
            ),
            child: child!,
          );
        });

    if (pickedRange != null) {
      if (!mounted) return;
      // Setelah tanggal dipilih, tampilkan Time Picker Pop-up
      _showCompactTimePicker(pickedRange);
    }
  }

  // Step 3: Pilih Jam (Compact Pop-up Ditengah)
  void _showCompactTimePicker(DateTimeRange range) {
    DateTime tempTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          title: const Text("Jam Pengingat Harian",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Agar dialog menyesuaikan konten
            children: [
              const Text("Pukul berapa kamu ingin membaca?",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),

              // Widget Time Picker yang dipaksa pendek (Compact)
              // Tinggi 100-120 cukup untuk menampilkan 3 baris (atas, tengah/selected, bawah)
              SizedBox(
                height: 120,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (val) => tempTime = val,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Simpan Jadwal & Status
                await _firestoreService.addSchedule(
                  book: widget.book,
                  startDate: range.start,
                  deadlineDate: range.end,
                  hour: tempTime.hour,
                  minute: tempTime.minute,
                );
                await _firestoreService.saveBookToReadingList(
                    widget.book, BookStatus.wantToRead);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Buku dijadwalkan & masuk Reading List!")));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white),
              child: const Text("Simpan"),
            )
          ],
        );
      },
    );
  }

  // ... (Sisa fungsi pendukung seperti _launchPlayStore, _showReviewModal TETAP SAMA)

  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;
    final Uri url = Uri.parse(widget.book.infoLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
  }

  void _showReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogBookModal(preSelectedBook: widget.book),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                actions: [
                  // --- MODIFIKASI 1: MENGHAPUS ICON BOOKMARK ---
                  // Hanya menyisakan icon share
                  IconButton(
                      icon: const Icon(Icons.share_outlined), onPressed: () {}),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.book.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey[200]),
                      ),
                      // Pakai withOpacity atau withValues tergantung versi Flutter
                      Container(color: Colors.white.withValues()),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 160,
                              width: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(widget.book.thumbnailUrl,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                widget.book.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.book.author,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tombol Sample & Beli
                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                      side:
                                          BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  child: const Text("Sample",
                                      style: TextStyle(color: Colors.black)))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _launchPlayStore,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text("Beli Ebook"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Deskripsi
                      const Text("Tentang Buku Ini",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.book.description,
                        style: TextStyle(color: Colors.grey[700], height: 1.6),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 40),

                      // Review Section
                      const Text("Diskusi Pembaca",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Dummy widget review jika belum ada stream
                      StreamBuilder<List<Review>>(
                          stream:
                              _firestoreService.getBookReviews(widget.book.id),
                          builder: (context, snapshot) {
                            // ... kode list review sama seperti sebelumnya ...
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text("Belum ada review.");
                            }
                            return const Text(
                                "Review ada (tampilkan list disini)");
                          }),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- MODIFIKASI 2: TOMBOL BAWAH ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.white, Colors.white.withValues()],
                      stops: const [0.6, 1.0])),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showCollectionModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _primaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      // Ganti Text Tombol
                      child: const Text("Tambah ke List",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showReviewModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Tulis Review",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
