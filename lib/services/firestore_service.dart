import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/book_list_model.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // 1. FITUR USER PROFILE (BIO, STATS)
  // ===========================================================================

  // Mendapatkan data user realtime
  Stream<DocumentSnapshot> getUserProfileStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots();
  }

  // Update bio dan username
  Future<void> updateUserProfile(
      {required String username, required String bio}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Update di Firestore
    await _db.collection('users').doc(user.uid).update({
      'username': username,
      'bio': bio,
    });

    // Update di Auth (agar displayName sinkron)
    await user.updateDisplayName(username);
  }

  // Hitung total buku di Reading List (Efisien menggunakan count aggregation)
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

  // Hitung total review yang pernah dibuat user
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

  // Cek Status Buku (Want to Read / Currently Reading / Finished) untuk icon Bookmark
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
      return BookStatus.values.firstWhere(
        (e) => e.toFirestoreString() == doc.data()?['readingStatus'],
        orElse: () => BookStatus.none,
      );
    });
  }

  // Ambil semua buku di Reading List (bisa difilter per status)
  Stream<List<Book>> getReadingList({BookStatus? filterStatus}) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .orderBy('createdAt', descending: true);

    if (filterStatus != null && filterStatus != BookStatus.none) {
      query = query.where('readingStatus',
          isEqualTo: filterStatus.toFirestoreString());
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Simpan atau Hapus buku dari Reading List utama
  Future<void> saveBookToReadingList(Book book, BookStatus status) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .doc(book.id);

    // Jika status "none", berarti dihapus dari list
    if (status == BookStatus.none) {
      await docRef.delete();
      return;
    }

    // Simpan/Update data buku beserta status barunya
    await docRef.set({
      ...book.toMap(),
      'readingStatus': status.toFirestoreString(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // 3. FITUR JADWAL BACA (SCHEDULE / NOTIFIKASI)
  // ===========================================================================

  // Menambah jadwal & trigger notifikasi lokal
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

    // 1. Simpan ke Firestore
    await _db.collection('users').doc(user.uid).collection('schedules').add({
      'bookId': book.id,
      'bookTitle': book.title,
      'bookAuthor': book.author,
      'thumbnailUrl': book.thumbnailUrl,
      'startDate': Timestamp.fromDate(startDate),
      'deadlineDate': Timestamp.fromDate(deadlineDate),
      'targetTime':
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      'notificationId': notificationId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Pasang Notifikasi Lokal
    await NotificationService().scheduleReadingPlan(
      idBase: notificationId,
      bookTitle: book.title,
      startDate: startDate,
      deadlineDate: deadlineDate,
      hour: hour,
      minute: minute,
    );
  }

  // Mengambil jadwal yang belum lewat deadline
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
  // 4. FITUR CUSTOM BookListModel (KOLEKSI PRIBADI)
  // ===========================================================================

  Future<void> createCustomList(String listName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Membuat dokumen list baru
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .add({
      'name': listName,
      'userId': user.uid,
      'bookCount': 0,
      'coverUrl': null, // Nanti diisi otomatis saat buku pertama masuk
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BookListModel>> getCustomLists() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookListModel.fromFirestore(doc)).toList());
  }

  // FIX: Menambah buku ke dalam List Spesifik dengan Cek Duplikasi (Transactional)
  Future<void> addBookToBookListModel(String listId, Book book) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final listRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId);

    // Referensi ke dokumen buku di dalam sub-collection list tersebut
    final bookRef = listRef.collection('books').doc(book.id);

    // Menggunakan Transaction untuk keamanan data (Atomic Operation)
    await _db.runTransaction((transaction) async {
      // 1. Cek apakah buku SUDAH ADA di dalam list ini
      DocumentSnapshot bookSnap = await transaction.get(bookRef);

      if (bookSnap.exists) {
        // Jika sudah ada, lempar error agar bisa ditangkap di UI
        throw Exception("Buku ini sudah ada di dalam list.");
      }

      // 2. Baca data list induk saat ini
      DocumentSnapshot listSnap = await transaction.get(listRef);
      if (!listSnap.exists) {
        throw Exception("List tidak ditemukan.");
      }

      // 3. Siapkan data update untuk list induk (Counter & Cover)
      // Menggunakan casting ke Map agar aman saat akses field
      Map<String, dynamic> listData = listSnap.data() as Map<String, dynamic>;

      int currentCount = listData['bookCount'] ?? 0;
      String? currentCover =
          listData.containsKey('coverUrl') ? listData['coverUrl'] : null;

      transaction.update(listRef, {
        'bookCount': currentCount + 1,
        // Jika belum ada cover, pakai thumbnail buku ini sebagai cover list
        'coverUrl': currentCover ?? book.thumbnailUrl,
      });

      // 4. Tulis buku baru ke sub-collection 'books'
      transaction.set(bookRef, {
        ...book.toMap(), // Spread operator untuk ambil semua data buku
        'createdAt':
            FieldValue.serverTimestamp(), // <--- WAJIB ADA untuk sorting!
      });
    });
  }

  // Melihat isi buku dalam list tertentu
  Stream<List<Book>> getBooksInBookListModel(String listId) {
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
  Future<void> deleteBookListModel(String listId) async {
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

  // Tambah Review Baru
  Future<void> addReview({
    required Book book,
    required double rating,
    required String reviewText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Ambil Username terbaru agar tidak null
    String username = user.displayName ?? 'Pengguna Bibliomate';
    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        username = userDoc.get('username') ?? username;
      }
    } catch (e) {
      // Fallback jika gagal ambil username
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

// ===========================================================================
  // UPDATE: REVIEWS & LISTS (Agar bisa lihat punya orang lain)
  // ===========================================================================

  // Fungsi READ: Ambil review (Bisa punya sendiri, bisa punya orang lain)
  // Tambahkan parameter opsional {String? userId}
  Stream<List<Review>> getUserReviews({String? userId}) {
    // Jika userId diisi (Public Profile), pakai itu.
    // Jika kosong (Profile Sendiri), pakai _auth.currentUser.uid
    String? targetUid = userId ?? _auth.currentUser?.uid;

    if (targetUid == null) return const Stream.empty();

    return _db
        .collection('reviews')
        .where('userId', isEqualTo: targetUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Fungsi BARU: Ambil Custom List milik orang lain (Public Profile)
  Stream<List<BookListModel>> getUserBookLists(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('custom_book_lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookListModel.fromFirestore(doc)).toList());
  }
  // --- FITUR CUSTOM LIST (SHELF) ---

  // 1. Ambil Buku di dalam List Tertentu
  Stream<List<Book>> getBooksInList(
      {required String listId, required String ownerId}) {
    // Path: users/{ownerId}/custom_book_lists/{listId}/books
    return _db
        .collection('users')
        .doc(ownerId)
        .collection('custom_book_lists')
        .doc(listId)
        .collection('books')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Book.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
  // ... (KODE LAMA TETAP DISINI: User Profile, Reading List, Schedule, Custom List) ...

  // ===========================================================================
  // TAMBAHAN PERBAIKAN (Agar tidak error di ExploreScreen & DetailScreen)
  // ===========================================================================

  // 1. Mengambil Review berdasarkan ID Buku (Dipakai di DetailScreen)
  Stream<List<Review>> getBookReviews(String bookId) {
    return _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 2. Search Users (Dipakai di ExploreScreen)
  // Catatan: Firestore tidak support partial text search (LIKE %query%) secara native.
  // Ini adalah trik sederhana untuk prefix search.
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    // Pastikan field 'username' di firestore konsisten lowercase jika ingin case-insensitive
    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '${query}z')
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 3. Search Reviews (Dipakai di ExploreScreen)
  Future<List<Review>> searchReviews(String query) async {
    if (query.isEmpty) return [];

    // Mencari review berdasarkan isi text (Case sensitive & Prefix only)
    final snapshot = await _db
        .collection('reviews')
        .where('reviewText', isGreaterThanOrEqualTo: query)
        .where('reviewText', isLessThan: '${query}z')
        .get();

    return snapshot.docs
        .map((doc) => Review.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 4. Search Book Lists (Dipakai di ExploreScreen)
  Future<List<BookListModel>> searchBookListModels(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _db
        .collectionGroup(
            'custom_book_lists') // Menggunakan collectionGroup karena list ada di sub-collection user
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .get();

    return snapshot.docs
        .map((doc) => BookListModel.fromFirestore(doc))
        .toList();
  }

  // ===========================================================================
  // 6. FITUR JURNAL & STREAK (Tambahan Baru)
  // ===========================================================================

  // Validasi Streak: Cek apakah user melewatkan satu hari
  Future<void> validateStreak() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final userDocRef = _db.collection('users').doc(user.uid);
    final doc = await userDocRef.get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final lastReadTimestamp = data['lastReadDate'] as Timestamp?;

    // Jika belum pernah baca, tidak perlu validasi
    if (lastReadTimestamp == null) return;

    final lastRead = lastReadTimestamp.toDate();
    final now = DateTime.now();

    // Normalisasi tanggal (hilangkan jam/menit/detik) untuk perbandingan hari
    final dateLastRead = DateTime(lastRead.year, lastRead.month, lastRead.day);
    final dateNow = DateTime(now.year, now.month, now.day);

    final difference = dateNow.difference(dateLastRead).inDays;

    // Jika selisih > 1 hari (artinya kemarin tidak baca), reset streak jadi 0
    if (difference > 1) {
      await userDocRef.update({'currentStreak': 0});
    }
  }

  // Update hari komitmen membaca (misal: Senin, Rabu, Jumat)
  Future<void> updateReadingDays(List<int> days) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({'readingDays': days});
  }

  // Tandai hari ini sudah membaca (Tombol Api ditekan)
  Future<void> markDayAsRead() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateNow = DateTime(now.year, now.month, now.day);
    final userDocRef = _db.collection('users').doc(user.uid);

    // 1. Cek apakah hari ini sudah absen (Log) agar tidak duplikat
    final startOfDay = Timestamp.fromDate(dateNow);
    final endOfDay = Timestamp.fromDate(dateNow.add(const Duration(days: 1)));

    final logsQuery = await userDocRef
        .collection('reading_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (logsQuery.docs.isNotEmpty) {
      // User sudah absen hari ini, hentikan proses
      return;
    }

    // 2. Tambah Log baru ke sub-collection
    await userDocRef.collection('reading_logs').add({
      'date': FieldValue.serverTimestamp(),
    });

    // 3. Update Streak & Last Read Date
    final doc = await userDocRef.get();
    final data = doc.data() as Map<String, dynamic>;
    final lastReadTimestamp = data['lastReadDate'] as Timestamp?;
    int currentStreak = data['currentStreak'] ?? 0;

    if (lastReadTimestamp != null) {
      final lastRead = lastReadTimestamp.toDate();
      final dateLastRead =
          DateTime(lastRead.year, lastRead.month, lastRead.day);

      final diff = dateNow.difference(dateLastRead).inDays;

      if (diff == 1) {
        // Jika terakhir baca kemarin, streak bertambah
        currentStreak++;
      } else if (diff > 1) {
        // Jika terlewat, reset jadi 1
        currentStreak = 1;
      }
      // Jika diff == 0 (hari yang sama), streak tetap (seharusnya sudah dicek di logsQuery)
    } else {
      // Pertama kali baca
      currentStreak = 1;
    }

    await userDocRef.update({
      'lastReadDate': FieldValue.serverTimestamp(),
      'currentStreak': currentStreak,
    });
  }

  // Ambil data log mingguan untuk tampilan 'Week Bubbles'
  Stream<List<DateTime>> getWeeklyLogs(DateTime startOfWeek) {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_logs')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return (doc['date'] as Timestamp).toDate();
            }).toList());
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting user: $e");
      }
      return null;
    }
  }
}
