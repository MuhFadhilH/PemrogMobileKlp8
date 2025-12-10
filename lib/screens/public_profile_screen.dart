import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart';
import '../services/firestore_service.dart';

class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tab: Reviews & Lists
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
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. Foto Profil
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl)
                            : null,
                        child: user.photoUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 45, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // 2. Nama & Bio
                      Text(
                        user.displayName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Tab Bar
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

// --- TAB 1: REVIEW ORANG LAIN ---
class _UserReviewsTab extends StatelessWidget {
  final String userId;
  const _UserReviewsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Panggil getUserReviews dengan parameter userId
    return StreamBuilder<List<Review>>(
      stream: FirestoreService().getUserReviews(userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const Center(
              child: Text("Pengguna ini belum menulis review."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    review.bookThumbnailUrl,
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[200]),
                  ),
                ),
                title: Text(review.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        Text(" ${review.rating}",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(review.reviewText,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
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

// --- TAB 2: LIST ORANG LAIN ---
class _UserListsTab extends StatelessWidget {
  final String userId;
  const _UserListsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN 1: Gunakan BookListModel (bukan BookListModelModel)
    // PERBAIKAN 2: Panggil getUserBookLists (sesuai yang baru kita buat di service)
    return StreamBuilder<List<BookListModel>>(
      stream: FirestoreService().getUserBookLists(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final shelves = snapshot.data ?? [];

        if (shelves.isEmpty) {
          return const Center(child: Text("Pengguna ini belum membuat list."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: shelves.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final shelf = shelves[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Icon List / Preview
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // PERBAIKAN 3: Gunakan getter .coverUrl atau logika list kosong
                    child: (shelf.previewImages.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(shelf.previewImages[0],
                                fit: BoxFit.cover),
                          )
                        : const Icon(Icons.list, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PERBAIKAN 4: Gunakan .title (bukan .name jika modelmu pakai title)
                      Text(shelf.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${shelf.bookCount} books",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Helper untuk Sticky Header
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
