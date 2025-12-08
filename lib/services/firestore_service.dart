import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import 'notification_service.dart'; // Pastikan file ini ada

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // 1. FITUR READING LIST & STATUS (BOOKMARK)
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
        .map((snapshot) {
      if (snapshot.exists) {
        return BookStatusExtension.fromFirestoreString(
          snapshot.data()?['readingStatus'],
        );
      }
      return BookStatus.none;
    });
  }

  // Simpan Buku dengan Status (Ingin dibaca, Selesai, dll)
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

  // Hapus Buku dari Reading List
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

  // Ambil List Bacaan (Bisa difilter)
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

  // ===========================================================================
  // 2. FITUR CUSTOM LIST (BUATAN USER) --- [BARU]
  // ===========================================================================

  // Buat Custom List Baru
  Future<void> createCustomList(String listName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).collection('custom_lists').add({
      'name': listName,
      'createdAt': FieldValue.serverTimestamp(),
      'bookCount': 0, // Inisialisasi jumlah buku 0
    });
  }

  // Ambil Daftar Custom List User
  Stream<QuerySnapshot> getCustomLists() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_lists')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Simpan Buku ke dalam Custom List Tertentu
  Future<void> addBookToCustomList(String listId, Book book) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // 1. Simpan buku ke sub-collection 'books' di dalam list tersebut
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_lists')
        .doc(listId)
        .collection('books')
        .doc(book.id)
        .set(book.toMap());
    
    // (Opsional) Update jumlah buku di dokumen list induk bisa ditambahkan di sini
  }

  // ===========================================================================
  // 3. FITUR JADWAL BACA (SCHEDULE / PLANNER) --- [UPDATED]
  // ===========================================================================

  // Tambah Jadwal Baru (Start, Deadline, Time) & Set Notifikasi
  Future<void> addSchedule({
    required Book book,
    required DateTime startDate,
    required DateTime deadlineDate,
    required int hour,
    required int minute,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Buat ID unik berbasis waktu (integer) agar bisa dipakai ID notifikasi
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

    // 2. Pasang notifikasi di HP menggunakan Service
    await NotificationService().scheduleReadingPlan(
      idBase: notificationId,
      bookTitle: book.title,
      startDate: startDate,
      deadlineDate: deadlineDate,
      hour: hour,
      minute: minute,
    );
  }

  // Ambil List Jadwal (Stream Realtime)
  Stream<QuerySnapshot> getSchedules() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    // Mengambil jadwal yang deadline-nya belum lewat (masih berlaku)
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('schedules')
        .where('deadlineDate', isGreaterThan: Timestamp.now()) 
        .orderBy('deadlineDate', descending: false) 
        .snapshots();
  }

  // ===========================================================================
  // 4. FITUR KOMENTAR (DISKUSI)
  // ===========================================================================

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

  // ===========================================================================
  // 5. FITUR REVIEW (LETTERBOXD STYLE)
  // ===========================================================================

  // Fungsi Create Review
  Future<void> addReview({
    required Book book,
    required double rating,
    required String reviewText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

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

    await docRef.set(newReview.toMap());
  }

  // Fungsi Read Review Milik User Sendiri (Profile)
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

  // Fungsi Read Review Milik Semua Orang untuk Buku Tertentu (Detail Screen)
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