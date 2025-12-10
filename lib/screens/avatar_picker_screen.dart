import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarPickerScreen extends StatefulWidget {
  final String currentAvatarUrl;

  const AvatarPickerScreen({super.key, required this.currentAvatarUrl});

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  String? _selectedAvatar;
  bool _isLoading = false;

  // Daftar avatar yang tersedia (sesuaikan dengan file di assets)
  final List<String> _availableAvatars = [
    'avatar1.png',
    'avatar2.png',
    'avatar3.png',
    'avatar4.png',
    'avatar5.png',
    'avatar6.png',
    'avatar7.png',
    'avatar8.png',
  ];

  @override
  void initState() {
    super.initState();
    // Cari avatar mana yang sedang dipakai user
    _findCurrentAvatar();
  }

  void _findCurrentAvatar() {
    final currentAvatar = widget.currentAvatarUrl;
    if (currentAvatar.contains('avatar')) {
      // Ekstrak nama file dari URL
      final fileName = currentAvatar.split('/').last;
      if (_availableAvatars.contains(fileName)) {
        _selectedAvatar = fileName;
      }
    }
  }

  Future<void> _updateAvatar() async {
    if (_selectedAvatar == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Format path untuk avatar
      final avatarUrl = 'assets/avatars/$_selectedAvatar';

      // Update di Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'photoUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update di Firebase Auth
      await user.updatePhotoURL(avatarUrl);

      if (context.mounted) {
        Navigator.pop(context, avatarUrl);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Avatar"),
        actions: [
          if (_selectedAvatar != null && !_isLoading)
            IconButton(
              onPressed: _updateAvatar,
              icon: const Icon(Icons.check),
              tooltip: "Simpan",
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _availableAvatars.length,
              itemBuilder: (context, index) {
                final avatarName = _availableAvatars[index];
                final isSelected = _selectedAvatar == avatarName;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatarName;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5C6BC0)
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF5C6BC0).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/avatars/$avatarName',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
