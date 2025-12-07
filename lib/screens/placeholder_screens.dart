import 'package:flutter/material.dart';

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

