import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../services/firestore_service.dart';
import '../../models/book_model.dart';
import '../../models/user_preference_model.dart';

class HomeRecommendationService {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _userName = "Pengguna";

  // List genre untuk bagian "Jelajahi" (akan dipilih secara acak)
  final List<String> _exploreGenres = [
    'History',
    'Fiction',
    'Mystery',
    'Fantasy',
    'Science',
    'Business',
    'Romance',
    'Horror',
    'Comedy',
    'Self-Help',
    'Technology',
    'Art',
    'Biography',
    'Philosophy',
  ];

  // List genre untuk bagian "Sedang Tren" (akan dipilih secara acak)
  final List<String> _trendingGenres = [
    'Bestseller',
    'Novel',
    'Fantasy',
    'Science Fiction',
    'Romance',
    'Thriller',
    'Mystery',
    'Biography',
    'Self-Help',
  ];

  String? _currentExploreGenre;
  String? _currentTrendingGenre;

  Future<HomeData> loadHomeData() async {
    try {
      // Load user data
      final user = _auth.currentUser;
      if (user != null) {
        _userName = user.displayName ?? "Pengguna";
      }

      // Load user preferences
      final prefs = await _firestoreService.getUserPreferences();

      // 1. COCOK UNTUKMU - berdasarkan preferensi user
      final recommendedBooks = await _getRecommendedBooks(prefs);

      // 2. SEDANG TREN - genre acak
      _currentTrendingGenre = _getRandomTrendingGenre();
      final trendingBooks = await _getTrendingBooks();

      // 3. JELAJAHI - genre acak
      _currentExploreGenre = _getRandomExploreGenre();
      final exploreBooks = await _getExploreBooks();

      return HomeData(
        userName: _userName,
        recommendedBooks: recommendedBooks,
        trendingBooks: trendingBooks,
        exploreBooks: exploreBooks,
        exploreGenre: _currentExploreGenre!,
        trendingGenre: _currentTrendingGenre!,
      );
    } catch (e) {
      rethrow;
    }
  }

  String _getRecommendedQuery(UserPreference prefs) {
    if (prefs.favoriteGenres.isNotEmpty) {
      // Ambil 2 genre pertama dari preferensi user
      final selectedGenres = prefs.favoriteGenres.take(2).toList();

      // Coba gabungkan dengan "+" untuk pencarian yang lebih spesifik
      return selectedGenres.join('+');
    } else {
      return 'Best+Seller'; // Default jika tidak ada preferensi
    }
  }

  Future<List<Book>> _getRecommendedBooks(UserPreference prefs) async {
    final query = _getRecommendedQuery(prefs);

    final books = await _apiService.fetchBooks(query);

    // Filter buku yang memiliki cover dan rating
    final filteredBooks = books.where((book) {
      return book.thumbnailUrl.isNotEmpty &&
          book.thumbnailUrl.startsWith('http');
    }).toList();

    // Jika tidak ada buku dengan cover, ambil semua
    return filteredBooks.isNotEmpty ? filteredBooks : books;
  }

  Future<List<Book>> _getTrendingBooks() async {
    final books = await _apiService.fetchBooks(_currentTrendingGenre!);

    // Filter buku yang memiliki cover
    final filteredBooks = books.where((book) {
      return book.thumbnailUrl.isNotEmpty &&
          book.thumbnailUrl.startsWith('http');
    }).toList();

    return filteredBooks.isNotEmpty ? filteredBooks : books;
  }

  Future<List<Book>> _getExploreBooks() async {
    final books = await _apiService.fetchBooks(_currentExploreGenre!);

    // Filter buku yang memiliki cover
    final filteredBooks = books.where((book) {
      return book.thumbnailUrl.isNotEmpty &&
          book.thumbnailUrl.startsWith('http');
    }).toList();

    return filteredBooks.isNotEmpty ? filteredBooks : books;
  }

  String _getRandomTrendingGenre() {
    final random =
        DateTime.now().millisecondsSinceEpoch % _trendingGenres.length;
    return _trendingGenres[random];
  }

  String _getRandomExploreGenre() {
    final random =
        DateTime.now().millisecondsSinceEpoch % _exploreGenres.length;
    return _exploreGenres[random];
  }

  // Refresh data dengan genre baru
  Future<HomeData> refreshHomeData() async {
    // Generate genre baru untuk Tren dan Jelajahi
    _currentTrendingGenre = _getRandomTrendingGenre();
    _currentExploreGenre = _getRandomExploreGenre();

    return await loadHomeData();
  }
}

class HomeData {
  final String userName;
  final List<Book> recommendedBooks;
  final List<Book> trendingBooks;
  final List<Book> exploreBooks;
  final String exploreGenre;
  final String trendingGenre;

  HomeData({
    required this.userName,
    required this.recommendedBooks,
    required this.trendingBooks,
    required this.exploreBooks,
    required this.exploreGenre,
    required this.trendingGenre,
  });
}
