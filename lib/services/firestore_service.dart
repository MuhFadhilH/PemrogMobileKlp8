import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================
  // 1. FITUR PROFIL USER & STATISTIK
  // =========================================================

  Stream<DocumentSnapshot> getUserProfileStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots();
  }

  Future<void> updateUserProfile(
      {required String username, required String bio}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'username': username,
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await user.updateDisplayName(username);
  }

  Future<int> getBookCount() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;
    final aggregateQuery = await _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .count()
        .get();
    return aggregateQuery.count ?? 0;
  }

  Future<int> getReviewCount() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;
    final aggregateQuery = await _db
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .count()
        .get();
    return aggregateQuery.count ?? 0;
  }

  // =========================================================
  // 2. FITUR RAK BUKU (MY SHELVES)
  // =========================================================

  Stream<List<Book>> getReadingList({BookStatus? filterStatus}) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .orderBy('addedAt', descending: true);

    if (filterStatus != null && filterStatus != BookStatus.none) {
      query = query.where('readingStatus',
          isEqualTo: filterStatus.toFirestoreString());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> saveBookToReadingList(Book book, BookStatus status) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    if (status == BookStatus.none) {
      await removeFromReadingList(book.id);
      return;
    }
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .doc(book.id)
        .set({
      ...book.toMap(),
      'readingStatus': status.toFirestoreString(),
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromReadingList(String bookId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('reading_list')
          .doc(bookId)
          .delete();
    }
  }

  Stream<BookStatus> getBookStatusStream(String bookId) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(BookStatus.none);
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .doc(bookId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return BookStatusExtension.fromFirestoreString(
            snapshot.data()?['readingStatus']);
      }
      return BookStatus.none;
    });
  }

  // =========================================================
  // 3. FITUR REVIEW & DISKUSI (DIGABUNG)
  // =========================================================

  // Create Review / Komentar Baru
  Future<void> addReview({
    required Book book,
    required double rating, // Kirim 0 jika hanya komentar teks
    required String reviewText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    // 1. Ambil Username terbaru dulu
    String username = user.displayName ?? 'Anonymous';
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      username = data['username'] ?? username;
    }

    final docRef = _db.collection('reviews').doc();

    final newReview = Review(
      id: docRef.id,
      userId: user.uid,
      username: username, // <--- Disimpan disini
      bookId: book.id,
      bookTitle: book.title,
      bookAuthor: book.author,
      bookThumbnailUrl: book.thumbnailUrl,
      rating: rating,
      reviewText: reviewText,
      createdAt: DateTime.now(),
    );

    await docRef.set(newReview.toMap());
  }

  // Ambil Review User (Untuk Halaman Profil)
  Stream<List<Review>> getUserReviews() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Ambil Review Buku Tertentu (Untuk Halaman Detail Buku)
  // INI PENGGANTI getComments
  Stream<List<Review>> getBookReviews(String bookId) {
    return _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
