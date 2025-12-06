import 'package:flutter/material.dart';

// Halaman Pencarian (Explore)
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: const Center(child: Text('Halaman Pencarian & Genre')),
    );
  }
}

// Halaman Jadwal/Activity (Journal)
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: const Center(child: Text('Halaman Reading Streak & Activity')),
    );
  }
}

// Halaman Profil (Me)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Halaman Profil User')),
    );
  }
}
