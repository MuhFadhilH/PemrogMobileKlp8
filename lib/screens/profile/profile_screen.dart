import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_page.dart';
import '../edit_profile_screen.dart';
import '../book_list_detail_screen.dart';
import '../reading_list_screen.dart';
import '../preference_screen.dart';
import '../../services/firestore_service.dart';
import 'profile_header.dart';
import 'profile_statistics.dart';
import 'profile_reviews_tab.dart';
import 'profile_booklists_tab.dart';
import 'profile_menu_button.dart';
import 'logout_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _currentTabIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  void _handleStatClick(String type, BuildContext context) {
    switch (type) {
      case 'books':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReadingListScreen()),
        );
        break;
      case 'reviews':
        setState(() {
          _currentTabIndex = 0;
        });
        break;
      case 'lists':
        setState(() {
          _currentTabIndex = 1;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Burger Menu untuk Edit Profil dan Preferensi
          ProfileMenuButton(
            onEditProfile: () async {
              final user = FirebaseAuth.instance.currentUser;
              final snapshot = await _firestoreService.getUserProfile();

              String bio = "Book enthusiast. Coffee lover. 📚☕";
              String username = user?.displayName ?? "User";
              String avatarUrl = user?.photoURL ?? "assets/avatars/avatar1.png";

              if (snapshot.exists) {
                var data = snapshot.data() as Map<String, dynamic>;
                bio = data['bio'] ?? bio;
                username = data['username'] ?? username;
                avatarUrl = data['photoUrl'] ?? avatarUrl;
              }

              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      currentName: username,
                      currentBio: bio,
                      currentAvatarUrl: avatarUrl,
                    ),
                  ),
                );
                setState(() {});
              }
            },
            onEditPreferences: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PreferenceScreen(),
                ),
              );
            },
          ),

          // Tombol Logout
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            ),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        initialIndex: _currentTabIndex,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header (tanpa ikon edit di avatar)
                      ProfileHeader(firestoreService: _firestoreService),

                      const SizedBox(height: 24),

                      // Statistics
                      ProfileStatistics(
                        onBooksTap: () => _handleStatClick('books', context),
                        onReviewsTap: () =>
                            _handleStatClick('reviews', context),
                        onListsTap: () => _handleStatClick('lists', context),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Tab Bar
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: const Color(0xFF5C6BC0),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF5C6BC0),
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.reviews, size: 20),
                          text: "Reviews",
                        ),
                        Tab(
                          icon: Icon(Icons.list, size: 20),
                          text: "BookLists",
                        ),
                      ],
                    ),
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: const [
              ProfileReviewsTab(),
              ProfileBookListsTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => LogoutDialog(
        onCancel: () => Navigator.pop(ctx),
        onLogout: () => _logout(context),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      child;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
