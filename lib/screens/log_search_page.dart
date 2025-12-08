import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'components/log_modal.dart'; // Import Modal yang benar

class LogSearchPage extends StatefulWidget {
  const LogSearchPage({super.key});

  @override
  State<LogSearchPage> createState() => _LogSearchPageState();
}

class _LogSearchPageState extends State<LogSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Book> _searchResults = [];
  bool _isSearching = false;

  void _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _apiService.fetchBooks(query);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // Buka LogModal dengan buku yang dipilih
  void _openLogModal(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogBookModal(preSelectedBook: book), // Kirim buku ke modal
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _searchBooks,
          decoration: const InputDecoration(hintText: "Name of book...", border: InputBorder.none),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final book = _searchResults[index];
                return ListTile(
                  leading: Image.network(book.thumbnailUrl, width: 40, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.book)),
                  title: Text(book.title, maxLines: 1),
                  subtitle: Text(book.author, maxLines: 1),
                  onTap: () => _openLogModal(book), // Trigger Modal
                );
              },
            ),
    );
  }
}