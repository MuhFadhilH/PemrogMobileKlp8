import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class ApiService {
  static const String baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // Cari Buku (Search)
  Future<List<Book>> searchBooks(String query) async {
    final url = Uri.parse('$baseUrl?q=$query&maxResults=20');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['totalItems'] == 0 || data['items'] == null) return [];
      
      final List items = data['items'];
      return items.map((item) => Book.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  // Ambil Detail Buku (Supaya dapat Rating/Desc lebih lengkap)
  Future<Book> getBookDetails(String bookId) async {
    final url = Uri.parse('$baseUrl/$bookId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Book.fromJson(data);
    } else {
      throw Exception('Gagal ambil detail');
    }
  }
}