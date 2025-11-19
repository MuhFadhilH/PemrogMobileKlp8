import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';

class BookProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Book> _books = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fungsi untuk mencari buku
  Future<void> searchBooks(String query) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // PERBAIKAN UTAMA DISINI:
      // Panggil _apiService.fetchBooks, BUKAN searchBooks
      _books = await _apiService.fetchBooks(query);
    } catch (e) {
      _errorMessage = 'Gagal memuat buku: $e';
      _books = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi helper untuk membersihkan hasil pencarian (opsional)
  void clearBooks() {
    _books = [];
    notifyListeners();
  }
}
