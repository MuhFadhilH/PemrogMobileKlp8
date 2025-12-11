import 'package:flutter/material.dart';

class ProfileMenuButton extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onEditPreferences;

  const ProfileMenuButton({
    super.key,
    required this.onEditProfile,
    required this.onEditPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF5C6BC0).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Color(0xFF5C6BC0), size: 20),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit_profile':
            onEditProfile();
            break;
          case 'edit_preferences':
            onEditPreferences();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'edit_profile',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.black, size: 18),
              SizedBox(width: 12),
              Text("Edit Profil"),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit_preferences',
          child: Row(
            children: [
              Icon(Icons.tune, color: Colors.black, size: 18),
              SizedBox(width: 12),
              Text("Edit Preferensi"),
            ],
          ),
        ),
      ],
    );
  }
}
