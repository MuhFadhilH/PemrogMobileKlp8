import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';

class BookProvider with ChangeNotifier {
  // State
  List<Book> _books = []; // Hasil pencarian
  List<Book> _readingList = []; // Daftar bacaan saya
  bool _isLoading = false;
  
  // Getters
  List<Book> get books => _books;
  List<Book> get readingList => _readingList;
  bool get isLoading => _isLoading;

  // Logika 1: Cari Buku
  Future<void> searchBooks(String query) async {
    _isLoading = true;
    notifyListeners(); // Kabari UI bahwa sedang loading

    try {
      _books = await ApiService().searchBooks(query);
    } catch (e) {
      print(e);
      _books = [];
    }

    _isLoading = false;
    notifyListeners(); // Kabari UI bahwa data sudah siap
  }

  // Logika 2: Tambah/Hapus dari Daftar Bacaan
  void toggleReadingList(Book book) {
    final isExist = _readingList.contains(book);
    if (isExist) {
      _readingList.remove(book);
    } else {
      _readingList.add(book);
    }
    notifyListeners(); // Kabari UI bahwa daftar bacaan berubah
  }

  // Cek apakah buku sudah ada di list (untuk ikon bookmark)
  bool isInReadingList(Book book) {
    return _readingList.any((item) => item.id == book.id);
  }
}