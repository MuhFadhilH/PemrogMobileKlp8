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

  bool _isAddingToList = false;
  bool _isSavingSchedule = false;

  // Helper untuk safely show snackbar
  void _safeShowSnackBar(String message, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.redAccent : _primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // ===========================================================================
  // LOGIC 1: MODAL LIST
  // ===========================================================================

  void _showCollectionModal() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text("Simpan ke List",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _handleReadingListSelection();
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
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
                                onTap: () =>
                                    _addBookToCustomList(list, context),
                                child: Row(
                                  children: [
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _showCreateListDialog();
                        });
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

  // PERBAIKAN UTAMA: Tambah parameter context dan ganti urutan operasi
  Future<void> _addBookToCustomList(
      BookListModel list, BuildContext modalContext) async {
    // Tutup modal DULU sebelum operasi async
    Navigator.of(modalContext).pop();

    // Set loading state
    if (mounted) {
      setState(() {
        _isAddingToList = true;
      });
    }

    try {
      await _firestoreService.addBookToBookListModel(list.id, widget.book);

      // Tampilkan snackbar dengan delay untuk memastikan UI stabil
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil ditambahkan ke ${list.title}"),
              backgroundColor: _primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    } catch (e) {
      String errorMessage = e.toString().replaceAll("Exception: ", "");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isAddingToList = false;
          });
        }
      });
    }
  }

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
                // Tutup dialog
                Navigator.pop(context);

                // Buat list
                _firestoreService.createCustomList(listNameController.text);

                // Tampilkan snackbar konfirmasi
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("List berhasil dibuat"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });

                // Buka kembali modal koleksi setelah delay
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (mounted) {
                    _showCollectionModal();
                  }
                });
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

  void _handleReadingListSelection() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Atur Jadwal Baca?"),
          content: const Text(
              "Tentukan target mulai baca dan deadline selesai agar kamu lebih disiplin."),
          actions: [
            TextButton(
              onPressed: () async {
                // Tutup dialog dulu
                Navigator.pop(context);

                // Operasi async setelah dialog ditutup
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;

                  setState(() {
                    _isSavingSchedule = true;
                  });

                  try {
                    await _firestoreService.saveBookToReadingList(
                        widget.book, BookStatus.wantToRead);

                    if (mounted) {
                      _safeShowSnackBar("Masuk Reading List (Tanpa Jadwal)");
                    }
                  } catch (e) {
                    if (mounted) {
                      _safeShowSnackBar("Error: ${e.toString()}",
                          isError: true);
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSavingSchedule = false;
                      });
                    }
                  }
                });
              },
              child: const Text("Lewati", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _pickDateRange();
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white),
              child: const Text("Atur Jadwal"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    if (!mounted) return;

    final DateTimeRange? pickedRange = await showDateRangePicker(
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
      },
    );

    if (pickedRange != null && mounted) {
      _showCompactTimePicker(pickedRange);
    }
  }

  void _showCompactTimePicker(DateTimeRange range) {
    if (!mounted) return;

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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pukul berapa kamu ingin membaca?",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
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
                // Simpan waktu dulu SEBELUM menutup dialog
                final selectedHour = tempTime.hour;
                final selectedMinute = tempTime.minute;

                // Tutup dialog
                Navigator.pop(context);

                // Operasi async setelah dialog ditutup
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;

                  // Gunakan variabel lokal untuk setState di widget utama
                  if (mounted) {
                    setState(() {
                      _isSavingSchedule = true;
                    });
                  }

                  try {
                    await _firestoreService.addSchedule(
                      book: widget.book,
                      startDate: range.start,
                      deadlineDate: range.end,
                      hour: selectedHour,
                      minute: selectedMinute,
                    );
                    await _firestoreService.saveBookToReadingList(
                        widget.book, BookStatus.wantToRead);

                    if (mounted) {
                      _safeShowSnackBar(
                          "Buku dijadwalkan & masuk Reading List!");
                    }
                  } catch (e) {
                    if (mounted) {
                      _safeShowSnackBar("Error: ${e.toString()}",
                          isError: true);
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSavingSchedule = false;
                      });
                    }
                  }
                });
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

  // ===========================================================================
  // FUNGSI BANTUAN LAINNYA
  // ===========================================================================

  Future<void> _launchPlayStore() async {
    if (widget.book.infoLink.isEmpty) return;

    final Uri url = Uri.parse(widget.book.infoLink);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _safeShowSnackBar("Tidak dapat membuka link", isError: false);
      }
    } catch (e) {
      _safeShowSnackBar("Error: $e", isError: true);
    }
  }

  void _showReviewModal() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogBookModal(preSelectedBook: widget.book),
    );
  }

  @override
  void dispose() {
    // Pastikan semua operasi dibersihkan
    super.dispose();
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
                  IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        // TODO: Implement share
                      }),
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
                      Container(color: Colors.white.withOpacity(0.6)),
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
                                      color: Colors.black.withOpacity(0.2),
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
                      if (_isAddingToList || _isSavingSchedule)
                        const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF5C6BC0)),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () {
                                    // TODO: Implement sample
                                  },
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
                      const Text("Diskusi Pembaca",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      StreamBuilder<List<Review>>(
                          stream:
                              _firestoreService.getBookReviews(widget.book.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text("Belum ada review.",
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              );
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
                      colors: [Colors.white, Colors.white.withOpacity(0.0)],
                      stops: const [0.6, 1.0])),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAddingToList || _isSavingSchedule
                          ? null
                          : _showCollectionModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _primaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isAddingToList
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Tambah ke List",
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
