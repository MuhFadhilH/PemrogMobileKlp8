import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; // Model List Custom
import 'notification_service.dart'; // Service Notifikasi

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // 1. FITUR USER PROFILE (BIO, STATS)
  // ===========================================================================

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

  // ===========================================================================
  // 2. FITUR READING LIST & STATUS (BOOKMARK UTAMA)
  // ===========================================================================

  // Ambil Status Real-time (untuk icon Bookmark berubah-ubah)
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
      if (!doc.exists) return BookStatus.none;
      // Pastikan string dari firestore cocok dengan enum, jika tidak return none
      return BookStatus.values.firstWhere(
        (e) => e.toFirestoreString() == doc.data()?['readingStatus'],
        orElse: () => BookStatus.none,
      );
    });
  }

  // Ambil List Bacaan Utama
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

  // Simpan/Update Status Buku
  Future<void> saveBookToReadingList(Book book, BookStatus status) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Jika status "none", hapus dari list
    if (status == BookStatus.none) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('reading_list')
          .doc(book.id)
          .delete();
      return;
    }

    // Jika status ada (Want to Read / Finished), simpan/update
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

  // ===========================================================================
  // 3. FITUR JADWAL BACA (SCHEDULE / NOTIFIKASI)
  // ===========================================================================

  Future<void> addSchedule({
    required Book book,
    required DateTime startDate,
    required DateTime deadlineDate,
    required int hour,
    required int minute,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Simpan data ke Firestore
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('schedules')
        .add({
      'bookId': book.id,
      'bookTitle': book.title,
      'bookAuthor': book.author,
      'thumbnailUrl': book.thumbnailUrl,
      'startDate': Timestamp.fromDate(startDate),
      'deadlineDate': Timestamp.fromDate(deadlineDate),
      'targetTime': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      'notificationId': notificationId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Pasang notifikasi lokal
    await NotificationService().scheduleReadingPlan(
      idBase: notificationId,
      bookTitle: book.title,
      startDate: startDate,
      deadlineDate: deadlineDate,
      hour: hour,
      minute: minute,
    );
  }

  // Ambil Jadwal yang masih aktif
  Stream<QuerySnapshot> getSchedules() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('schedules')
        .where('deadlineDate', isGreaterThan: Timestamp.now()) 
        .orderBy('deadlineDate', descending: false) 
        .snapshots();
  }

  // ===========================================================================
  // 4. FITUR CUSTOM BOOKLIST (KOLEKSI BUATAN USER)
  // ===========================================================================

  // Buat List Baru (Folder)
  Future<void> createBookList(String listName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final newList = BookList(
      id: '', // Placeholder, nanti ID digenerate Firestore
      name: listName,
      userId: user.uid,
      createdAt: DateTime.now(),
      bookCount: 0,
    );

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .add(newList.toMap());
  }

  // Ambil Daftar List User
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

  // Tambah Buku ke dalam List Tertentu
  Future<void> addBookToBookList(String listId, Book book) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final listRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId);

    // 1. Simpan buku ke sub-collection 'books'
    await listRef.collection('books').doc(book.id).set(book.toMap());

    // 2. Update jumlah buku & cover di parent list
    await _db.runTransaction((transaction) async {
      DocumentSnapshot listSnap = await transaction.get(listRef);
      if (!listSnap.exists) return;

      int currentCount = listSnap.get('bookCount') ?? 0;
      // Ambil cover url yang ada sekarang, jika null pakai cover buku baru ini
      String? currentCover;
      try {
        currentCover = listSnap.get('coverUrl');
      } catch (e) {
        currentCover = null;
      }

      transaction.update(listRef, {
        'bookCount': currentCount + 1,
        'coverUrl': currentCover ?? book.thumbnailUrl,
      });
    });
  }

  // Ambil Buku di dalam Custom List
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

  // Hapus Custom List
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

  // ===========================================================================
  // 5. FITUR REVIEW & DISKUSI
  // ===========================================================================

  Future<void> addReview({
    required Book book,
    required double rating,
    required String reviewText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Ambil Username terbaru dari profil
    String username = user.displayName ?? 'Anonymous';
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      username = userDoc.data()?['username'] ?? username;
    }

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

  // Review milik User sendiri (untuk Profile)
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

  // Review orang lain di Detail Buku
  Stream<List<Review>> getBookReviews(String bookId) {
    return _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }
}