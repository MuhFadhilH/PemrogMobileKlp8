import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';
import 'detail_screen.dart';
import 'login_page.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: firestoreService.getUserProfileStream(),
                    builder: (context, snapshot) {
                      String bio = "Book enthusiast. Coffee lover. 📚☕";
                      String username = user?.displayName ?? "User";

                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        bio = data['bio'] ?? bio;
                        username = data['username'] ?? username;
                      }

                      return Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: NetworkImage(user?.photoURL ??
                                    "https://i.pravatar.cc/300"),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(
                                              currentName: username,
                                              currentBio: bio),
                                        ));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF5C6BC0),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.edit,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(username,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(bio,
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 24),

                          // STATISTIK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FutureBuilder<int>(
                                future: firestoreService.getBookCount(),
                                builder: (context, snap) => _StatItem(
                                    label: "Books",
                                    value: (snap.data ?? 0).toString()),
                              ),
                              FutureBuilder<int>(
                                future: firestoreService.getReviewCount(),
                                builder: (context, snap) => _StatItem(
                                    label: "Reviews",
                                    value: (snap.data ?? 0).toString()),
                              ),
                              const _StatItem(label: "Shelves", value: "3"),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Color(0xFF5C6BC0),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF5C6BC0),
                    tabs: [Tab(text: "Reviews"), Tab(text: "My Shelves")],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: const TabBarView(
            children: [
              _ReviewsTab(),
              _MyShelvesTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
              onPressed: () => _logout(context),
              child: const Text("Keluar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

// --- WIDGET HELPER ---

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Colors.white, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// --- TAB 1: REVIEWS (REVISI: Mendukung Komentar & Review) ---
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<Review>>(
      stream: firestoreService.getUserReviews(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Belum ada aktivitas.",
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Buku (Thumbnail)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.bookThumbnailUrl,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 60, height: 90, color: Colors.grey[200]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Detail Review
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.bookTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(review.bookAuthor,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),

                          // --- LOGIKA TAMPILAN BINTANG ---
                          // Hanya tampilkan bintang jika rating > 0
                          if (review.rating > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(
                                  5,
                                  (star) => Icon(
                                        star < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 16,
                                        color: Colors.amber,
                                      )),
                            ),
                          ],

                          const SizedBox(height: 8),
                          // Isi Review / Komentar
                          Text(
                            review.reviewText,
                            maxLines: 4, // Sedikit lebih panjang
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[800]),
                          ),

                          // Tampilkan Tanggal (Agar terlihat seperti history)
                          const SizedBox(height: 6),
                          Text(
                            "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 10),
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

// --- TAB 2: MY SHELVES (Grid Buku) ---
class _MyShelvesTab extends StatelessWidget {
  const _MyShelvesTab();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<Book>>(
      stream: firestoreService.getReadingList(),
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
                Icon(Icons.bookmarks_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Rak bukumu masih kosong.",
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetailScreen(book: book))),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          book.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey[200]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
