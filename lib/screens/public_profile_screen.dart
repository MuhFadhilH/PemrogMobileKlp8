import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; // Pastikan pakai BookListModel
import '../services/firestore_service.dart';
import 'detail_screen.dart'; // Navigasi ke detail buku
import 'book_list_detail_screen.dart'; // Navigasi ke detail list

class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Review & Lists
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          // Area Actions kosong (Tidak ada tombol Edit/Logout)
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. Foto Profil Besar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl)
                            : null,
                        child: user.photoUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // 2. Nama & Bio
                      Text(
                        user.displayName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          user.bio.isNotEmpty ? user.bio : " - ",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Stats Row (Statistik Sederhana)
                      // Kita pakai StreamBuilder untuk menghitung jumlah Review & List real-time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _AsyncStatItem(
                            label: "Reviews",
                            stream: FirestoreService()
                                .getUserReviews(userId: user.id),
                          ),
                          _AsyncStatItem(
                            label: "Lists",
                            stream:
                                FirestoreService().getUserBookLists(user.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Tab Bar (Sticky)
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Color(0xFF5C6BC0),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF5C6BC0),
                    tabs: [
                      Tab(text: "Reviews"),
                      Tab(text: "Lists"),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          // Isi Konten Tab
          body: TabBarView(
            children: [
              _UserReviewsTab(userId: user.id),
              _UserListsTab(userId: user.id),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET STATISTIK (Menghitung jumlah data) ---
class _AsyncStatItem extends StatelessWidget {
  final String label;
  final Stream<List<dynamic>> stream;

  const _AsyncStatItem({required this.label, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}

// --- TAB 1: REVIEW ORANG LAIN ---
class _UserReviewsTab extends StatelessWidget {
  final String userId;
  const _UserReviewsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: FirestoreService().getUserReviews(userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const Center(
            child:
                Text("Belum ada review.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0, // Flat design agar lebih bersih
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Buku
                    GestureDetector(
                      onTap: () {
                        // Navigasi ke detail buku saat cover ditekan (Opsional)
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          review.bookThumbnailUrl,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(width: 50, color: Colors.grey[200]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Review
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.bookTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 14, color: Colors.amber[700]),
                              Text(" ${review.rating}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review.reviewText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: Colors.grey[700], height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- TAB 2: LIST ORANG LAIN (Updated Design) ---
// --- TAB 2: LIST ORANG LAIN (GRID VIEW) ---
class _UserListsTab extends StatelessWidget {
  final String userId;
  const _UserListsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookListModel>>(
      stream: FirestoreService().getUserBookLists(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final lists = snapshot.data ?? [];

        if (lists.isEmpty) {
          return const Center(
            child:
                Text("Belum ada list.", style: TextStyle(color: Colors.grey)),
          );
        }

        // PERUBAHAN: Menggunakan GridView.builder
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 Kolom ke samping
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
                0.75, // Mengatur tinggi kartu (makin kecil makin tinggi)
          ),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookListDetailScreen(bookList: list),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Preview Tumpukan (Stack Effect) - Diperbesar untuk Grid
                    SizedBox(
                      width: 80,
                      height: 100,
                      child: Stack(
                        children: [
                          if (list.previewImages.length > 1)
                            Positioned(
                              top: 0,
                              left: 10,
                              child: Container(
                                width: 60,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          if (list.previewImages.isNotEmpty)
                            Positioned(
                              top: 10,
                              left: 0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  list.previewImages[0],
                                  width: 70,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey[400]),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 70,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.collections_bookmark,
                                  size: 40, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Info List (Judul & Jumlah Buku)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            list.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${list.bookCount} books",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Helper agar TabBar bisa nempel (sticky)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
