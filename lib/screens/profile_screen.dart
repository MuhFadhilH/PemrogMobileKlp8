import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; 
import '../services/firestore_service.dart';
import 'login_page.dart';
import 'edit_profile_screen.dart';
import 'book_list_detail_screen.dart'; 

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
          title: const Text("Profile",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => EditProfileScreen(
                                            currentName: username,
                                            currentBio: bio)),
                                  ),
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
                              const _StatItem(label: "Lists", value: "3"),
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
                    tabs: [
                      Tab(text: "Reviews"),
                      Tab(text: "My BookLists")
                    ], 
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: const TabBarView(
            children: [
              _ReviewsTab(),
              _MyBookListsTab(), 
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

// --- TAB 1: REVIEWS ---
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();
  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    return StreamBuilder<List<Review>>(
      stream: firestoreService.getUserReviews(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("Belum ada aktivitas.",
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final review = snapshot.data![index];
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
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(review.bookThumbnailUrl,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 90,
                                color: Colors.grey[200]))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review.bookTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            if (review.rating > 0)
                              Row(
                                  children: List.generate(
                                      5,
                                      (s) => Icon(
                                          s < review.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber))),
                            const SizedBox(height: 8),
                            Text(review.reviewText,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[800])),
                          ]),
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

// --- TAB 2: MY BOOKLISTS ---
class _MyBookListsTab extends StatelessWidget {
  const _MyBookListsTab();

  void _showCreateListDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buat BookList Baru"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              hintText: "Nama List (cth: Wajib Baca 2024 🔥)"),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // FIX: Menggunakan createCustomList
                await FirestoreService().createCustomList(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Buat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    // FIX: Menggunakan getCustomLists
    return StreamBuilder<List<BookList>>(
      stream: firestoreService.getCustomLists(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final bookLists = snapshot.data ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: bookLists.length + 1, // +1 untuk tombol Create
          itemBuilder: (context, index) {
            // ITEM PERTAMA: TOMBOL CREATE
            if (index == 0) {
              return GestureDetector(
                onTap: () => _showCreateListDialog(context),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 40, color: Color(0xFF5C6BC0)),
                      SizedBox(height: 8),
                      Text("New BookList",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C6BC0))),
                    ],
                  ),
                ),
              );
            }

            // ITEM SELANJUTNYA: LIST BOOKLIST
            final bookList = bookLists[index - 1];
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          BookListDetailScreen(bookList: bookList))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                        image: bookList.coverUrl != null
                            ? DecorationImage(
                                image: NetworkImage(bookList.coverUrl!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: bookList.coverUrl == null
                          ? const Icon(Icons.folder_open,
                              size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(bookList.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("${bookList.bookCount} Books",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}