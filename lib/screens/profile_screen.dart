import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';
import 'login_page.dart'; // Pastikan import login page untuk fitur Logout

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Fungsi Logout
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Reset ke halaman Login (Hapus semua stack navigasi)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Default Tab Controller untuk Tabs (Reviews / Lists)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            user?.displayName ?? "Profile", // Ambil nama dari Google/Auth
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                // Sementara kita taruh logout di sini
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
        body: NestedScrollView(
          // Header yang bisa discroll
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. Foto Profil
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          user?.photoURL ??
                              "https://i.pravatar.cc/300", // Dummy jika null
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Nama & Bio
                      Text(
                        user?.displayName ?? "User Bibliomate",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Book enthusiast. Coffee lover. 📚☕", // Nanti bisa diedit
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 24),

                      // 3. Stats Row
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(label: "Books", value: "12"),
                          _StatItem(label: "Reviews", value: "5"),
                          _StatItem(label: "Lists", value: "3"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Tab Bar (Menu)
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Color(0xFF5C6BC0),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF5C6BC0),
                    tabs: [
                      Tab(text: "Reviews"),
                      Tab(text: "My Shelves"),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          // Isi Tab (Body)
          body: const TabBarView(
            children: [
              _ReviewsTab(), // Kita buat widget terpisah di bawah
              Center(child: Text("Fitur Rak Buku (Next Step)")),
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

// --- WIDGET PENDUKUNG ---

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    // STREAM BUILDER: Mendengarkan data langsung dari Firebase
    return StreamBuilder<List<Review>>(
      stream: firestoreService.getUserReviews(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data ?? [];

        // Kosong State
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("Belum ada review. Yuk mulai nulis!",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Ada Data State
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Kecil
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.bookThumbnailUrl,
                        width: 50,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(width: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Konten Review
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.bookTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.reviewText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[800]),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
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

// Helper agar TabBar bisa nempel (sticky) saat discroll
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
      color: Colors.white, // Background TabBar
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
