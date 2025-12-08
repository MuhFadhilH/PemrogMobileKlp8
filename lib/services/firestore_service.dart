import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; // Pastikan import ini benar

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================
  // 1. FITUR PROFIL USER
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
    });
    await user.updateDisplayName(username);
  }

  Future<int> getBookCount() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;
    final agg = await _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .count()
        .get();
    return agg.count ?? 0;
  }

  Future<int> getReviewCount() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;
    final agg = await _db
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .count()
        .get();
    return agg.count ?? 0;
  }

  // =========================================================
  // 2. FITUR RAK BUKU UTAMA (READING LIST / STATUS BACA)
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
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> saveBookToReadingList(Book book, BookStatus status) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    if (status == BookStatus.none) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('reading_list')
          .doc(book.id)
          .delete();
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

  Stream<BookStatus> getBookStatusStream(String bookId) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(BookStatus.none);
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .doc(bookId)
        .snapshots()
        .map((doc) {
      return doc.exists
          ? BookStatusExtension.fromFirestoreString(
              doc.data()?['readingStatus'])
          : BookStatus.none;
    });
  }

  // =========================================================
  // 3. FITUR REVIEW & KOMENTAR
  // =========================================================
  Future<void> addReview(
      {required Book book,
      required double rating,
      required String reviewText}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String username = user.displayName ?? 'Anonymous';
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists) username = userDoc.data()?['username'] ?? username;

    final docRef = _db.collection('reviews').doc();
    final newReview = Review(
      id: docRef.id,
      userId: user.uid,
      username: username,
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

  Stream<List<Review>> getUserReviews() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Review>> getBookReviews(String bookId) {
    return _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }

  // =========================================================
  // 4. FITUR BOOKLIST (DAFTAR BUKU KOSTUM)
  // =========================================================

  // A. Buat BookList Baru
  Future<void> createBookList(String listName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final newList = BookList(
      id: '', // Placeholder
      name: listName,
      userId: user.uid,
      createdAt: DateTime.now(),
    );

    // Ganti nama koleksi jadi 'custom_book_lists'
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .add(newList.toMap());
  }

  // B. Ambil BookList Milik User
  Stream<List<BookList>> getUserBookLists() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookList.fromFirestore(doc)).toList());
  }

  // C. Tambah Buku ke BookList
  Future<void> addBookToBookList(String listId, Book book) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final listRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId);

    // 1. Simpan buku ke sub-collection
    await listRef.collection('books').doc(book.id).set(book.toMap());

    // 2. Update jumlah buku & cover
    await _db.runTransaction((transaction) async {
      DocumentSnapshot listSnap = await transaction.get(listRef);
      if (!listSnap.exists) return;

      int currentCount = listSnap.get('bookCount') ?? 0;
      String? currentCover = listSnap.data().toString().contains('coverUrl')
          ? listSnap.get('coverUrl')
          : null;

      transaction.update(listRef, {
        'bookCount': currentCount + 1,
        'coverUrl':
            currentCover ?? book.thumbnailUrl, // Set cover dari buku pertama
      });
    });
  }

  // D. Ambil Buku di dalam BookList
  Stream<List<Book>> getBooksInBookList(String listId) {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId)
        .collection('books')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Book.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // E. Hapus BookList
  Future<void> deleteBookList(String listId) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId)
        .delete();
  }
}
