import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart';
import '../services/firestore_service.dart';
import 'book_review_screen.dart';
import 'log_search_page.dart';

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
                      // --- ITEM 1: READING LIST (MAIN) ---
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _handleReadingListSelection();
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
                                          image: (list.previewImages.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      list.previewImages[0]),
                                                  fit: BoxFit.cover)
                                              : null),
                                      child: list.previewImages.isEmpty
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

  void _addBookToCustomList(BookListModel list, BuildContext context) async {
    try {
      setState(() {
        _isAddingToList = true;
      });

      await _firestoreService.addBookToCustomList(widget.book, list.id!);
      _safeShowSnackBar("Ditambahkan ke '${list.title}'");
    } catch (e) {
      String errorMessage = e.toString().replaceAll("Exception: ", "");
      _safeShowSnackBar(errorMessage, isError: true);
    } finally {
      setState(() {
        _isAddingToList = false;
      });
      if (mounted) {
        Navigator.pop(context);
      }
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
                Navigator.pop(context);
                // TODO: Implement create list
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
                Navigator.pop(context);

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
                final selectedHour = tempTime.hour;
                final selectedMinute = tempTime.minute;

                Navigator.pop(context);

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;

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

  @override
  void dispose() {
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

                      // --- BAGIAN REVIEW ---
                      StreamBuilder<List<Review>>(
                        stream: _firestoreService.getBookReviews(widget.book.id,
                            limit: 3),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator()));
                          }

                          final reviews = snapshot.data ?? [];

                          if (reviews.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 40, color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  const Text("Belum ada diskusi.",
                                      style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  const Text("Jadilah yang pertama mereview!",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              // List Review (Max 3)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviews.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final review = reviews[index];
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.grey.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      Colors.grey[200],
                                                  child: Text(
                                                    review.username.isNotEmpty
                                                        ? review.username[0]
                                                        : '?',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: _primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(review.username,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13)),
                                              ],
                                            ),
                                            // Rating Bintang Kecil
                                            Row(
                                              children: [
                                                const Icon(Icons.star,
                                                    color: Colors.amber,
                                                    size: 14),
                                                const SizedBox(width: 4),
                                                Text(review.rating.toString(),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          review.reviewText,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.grey[800],
                                              height: 1.5,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // TOMBOL LIHAT SEMUA REVIEW
                              if (reviews.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BookReviewsScreen(
                                                    book: widget.book),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: const Text("Lihat Semua Review",
                                          style:
                                              TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- FOOTER BUTTONS ---
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
                      child: _isAddingToList || _isSavingSchedule
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Tambah ke List",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // SMART REVIEW BUTTON
                  Expanded(
                    child: StreamBuilder<Review?>(
                      stream: _firestoreService
                          .streamUserReviewForBook(widget.book.id),
                      builder: (context, snapshot) {
                        final isReviewed =
                            snapshot.hasData && snapshot.data != null;

                        return ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LogFormPage(book: widget.book),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isReviewed ? Colors.green : _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isReviewed ? Icons.check : Icons.edit,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                  isReviewed
                                      ? "Sudah Direview"
                                      : "Tulis Review",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
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
