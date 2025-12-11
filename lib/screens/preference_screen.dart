import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_preference_model.dart';
import '../services/firestore_service.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _allGenres = [
    'Fiction',
    'Non-Fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Romance',
    'Thriller',
    'Biography',
    'History',
    'Science',
    'Psychology',
    'Self-Help',
    'Business',
    'Technology',
    'Art',
    'Cooking',
    'Travel',
    'Poetry',
    'Drama',
    'Comedy',
  ];

  late UserPreference _preference;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _firestoreService.getUserPreferences();
    setState(() {
      _preference = prefs;
      _isLoading = false;
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_preference.favoriteGenres.contains(genre)) {
        _preference = _preference.copyWith(
          favoriteGenres: List.from(_preference.favoriteGenres)..remove(genre),
        );
      } else {
        _preference = _preference.copyWith(
          favoriteGenres: List.from(_preference.favoriteGenres)..add(genre),
        );
      }
    });
  }

  Future<void> _savePreferences() async {
    try {
      await _firestoreService.saveUserPreferences(_preference);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferensi berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferensi Buku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Genre
            const Text(
              'Genre Favorit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih minimal 3 genre favorit Anda',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Chip Grid untuk Genre
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allGenres.map((genre) {
                final isSelected = _preference.favoriteGenres.contains(genre);
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (_) => _toggleGenre(genre),
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Bagian Bahasa
            const Text(
              'Preferensi Bahasa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _preference.languagePreference,
              items: const [
                DropdownMenuItem(value: 'id', child: Text('Indonesia')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                setState(() {
                  _preference = _preference.copyWith(languagePreference: value);
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Pilih bahasa preferensi',
              ),
            ),

            const SizedBox(height: 24),

            // Bagian Konten Dewasa
            SwitchListTile(
              title: const Text('Tampilkan konten dewasa'),
              subtitle: const Text(
                  'Aktifkan untuk melihat buku dengan rating dewasa'),
              value: _preference.showAdultContent,
              onChanged: (value) {
                setState(() {
                  _preference = _preference.copyWith(showAdultContent: value);
                });
              },
            ),

            const SizedBox(height: 32),

            // Tombol Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Preferensi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
