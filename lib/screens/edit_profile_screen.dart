import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'avatar_picker_screen.dart'; // Import baru

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String currentAvatarUrl; // Tambah parameter ini

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentBio,
    required this.currentAvatarUrl, // Tambah di constructor
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _selectedAvatarUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _bioController.text = widget.currentBio;
    _selectedAvatarUrl = widget.currentAvatarUrl;
  }

  Future<void> _pickAvatar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(
          currentAvatarUrl: _selectedAvatarUrl,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAvatarUrl = result;
      });
    }
  }

  // Helper untuk menampilkan gambar (assets atau network)
  ImageProvider _getAvatarImage() {
    if (_selectedAvatarUrl.startsWith('assets/')) {
      return AssetImage(_selectedAvatarUrl);
    } else {
      return NetworkImage(_selectedAvatarUrl);
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nama tidak boleh kosong")));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Update di Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': name,
        'bio': _bioController.text.trim(),
        'photoUrl': _selectedAvatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update di Firebase Auth
      await user.updateDisplayName(name);
      await user.updatePhotoURL(_selectedAvatarUrl);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil berhasil diperbarui")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _updateProfile,
            icon: const Icon(Icons.check),
            tooltip: "Simpan",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarImage(),
                            child: _selectedAvatarUrl.isEmpty
                                ? const Icon(Icons.person,
                                    size: 40, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF5C6BC0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Bio",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Ganti Avatar"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
