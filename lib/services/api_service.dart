import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class ApiService {
  // URL Google Books API
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // Update: Menambahkan parameter startIndex & maxResults untuk Infinite Scroll
  // Default values diset agar kode lama di file lain tetap jalan tanpa error.
  Future<List<Book>> fetchBooks(String query,
      {int startIndex = 0, int maxResults = 20}) async {
    // Kalau query kosong, jangan request ke internet
    if (query.trim().isEmpty) return [];

    try {
      // Request ke Google Books API dengan parameter pagination
      final response = await http.get(Uri.parse(
          '$_baseUrl?q=$query&startIndex=$startIndex&maxResults=$maxResults'));

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
