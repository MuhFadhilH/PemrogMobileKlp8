import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class ApiService {
  // URL Google Books API
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // Fungsi fetchBooks yang dicari-cari oleh HomeScreen
  Future<List<Book>> fetchBooks(String query) async {
    // Kalau query kosong, jangan request ke internet
    if (query.trim().isEmpty) return [];

    try {
      // Request ke Google Books API
      final response = await http.get(Uri.parse('$_baseUrl?q=$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cek apakah ada buku yang ditemukan
        if (data['items'] != null) {
          final List<dynamic> items = data['items'];

          // Convert JSON API menjadi List of Book Objects
          return items.map((json) => Book.fromJson(json)).toList();
        } else {
          return []; // Tidak ada buku ditemukan
        }
      } else {
        throw Exception('Gagal mengambil data buku: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }
}
