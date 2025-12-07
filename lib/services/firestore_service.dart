import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Ambil Status Real-time (untuk icon Bookmark berubah-ubah)
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
          snapshot.data()?['readingStatus'],
        );
      }
      return BookStatus.none;
    });
  }

  // 2. Simpan Buku dengan Status (Ingin dibaca, Selesai, dll)
  Future<void> saveBookToReadingList(Book book, BookStatus status) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    if (status == BookStatus.none) {
      await removeFromReadingList(book.id); // Hapus kalau statusnya None
      return;
    }

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .doc(book.id)
        .set({
      ...book.toMap(),
      'readingStatus': status.toFirestoreString(), // Simpan status string
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Hapus Buku
  Future<void> removeFromReadingList(String bookId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .doc(bookId)
        .delete();
  }

  // 4. Ambil List Bacaan (Bisa difilter)
  Stream<List<Book>> getReadingList({BookStatus? filterStatus}) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .orderBy('addedAt', descending: true);

    if (filterStatus != null && filterStatus != BookStatus.none) {
      query = query.where(
        'readingStatus',
        isEqualTo: filterStatus.toFirestoreString(),
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  // 5. Fitur Komentar (Tetap sama)
  Future<void> addComment(String bookId, String commentText) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await _db.collection('users').doc(user.uid).get();
    String username = 'User';
    if (userDoc.exists && (userDoc.data() as Map).containsKey('username')) {
      username = userDoc['username'];
    } else {
      username = user.email?.split('@')[0] ?? 'Anonymous';
    }

    await _db.collection('books').doc(bookId).collection('comments').add({
      'userId': user.uid,
      'username': username,
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getComments(String bookId) {
    return _db
        .collection('books')
        .doc(bookId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Fungsi Create Review (Memenuhi Syarat CRUD)
  Future<void> addReview({
    required Book book,
    required double rating,
    required String reviewText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    // Kita buat ID dokumen secara otomatis
    final docRef = _db.collection('reviews').doc();

    final newReview = Review(
      id: docRef.id,
      userId: user.uid,
      bookId: book.id,
      bookTitle: book.title,
      bookAuthor: book.author,
      bookThumbnailUrl: book.thumbnailUrl,
      rating: rating,
      reviewText: reviewText,
      createdAt: DateTime.now(),
    );

    // Simpan ke Firestore
    await docRef.set(newReview.toMap());
  }

  // Fungsi READ: Ambil semua review milik user yang login
  Stream<List<Review>> getUserReviews() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('reviews')
        .where('userId', isEqualTo: user.uid) // Filter cuma punya dia
        .orderBy('createdAt', descending: true) // Yang terbaru di atas
        .snapshots() // Stream: kalau ada update, UI berubah otomatis
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
