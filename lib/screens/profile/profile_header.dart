import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ProfileHeader extends StatelessWidget {
  final FirestoreService firestoreService;

  const ProfileHeader({
    super.key,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.getUserProfileStream(),
      builder: (context, snapshot) {
        String bio = "Book enthusiast. Coffee lover. 📚☕";
        String username = user?.displayName ?? "User";
        String avatarUrl = user?.photoURL ?? "assets/avatars/avatar1.png";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          bio = data['bio'] ?? bio;
          username = data['username'] ?? username;
          avatarUrl = data['photoUrl'] ?? avatarUrl;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar TANPA ikon edit
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarUrl.startsWith('assets/')
                    ? AssetImage(avatarUrl) as ImageProvider
                    : NetworkImage(avatarUrl),
              ),
            ),

            const SizedBox(width: 20),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
