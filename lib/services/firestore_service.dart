import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/book_list_model.dart'; 
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
  Future<void> updateUserProfile({required String username, required String bio}) async {
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
        .orderBy('addedAt', descending: true);

    if (filterStatus != null && filterStatus != BookStatus.none) {
      query = query.where('readingStatus', isEqualTo: filterStatus.toFirestoreString());
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
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
      'addedAt': FieldValue.serverTimestamp(),
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
      'targetTime': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
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
  // 4. FITUR CUSTOM BOOKLIST (KOLEKSI PRIBADI)
  // ===========================================================================

  Future<void> createCustomList(String listName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Membuat dokumen list baru
    await _db.collection('users').doc(user.uid).collection('custom_book_lists').add({
      'name': listName,
      'userId': user.uid,
      'bookCount': 0,
      'coverUrl': null, // Nanti diisi otomatis saat buku pertama masuk
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BookList>> getCustomLists() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => BookList.fromFirestore(doc)).toList());
  }

  // FIX: Menambah buku ke dalam List Spesifik dengan Cek Duplikasi (Transactional)
  Future<void> addBookToBookList(String listId, Book book) async {
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
      String? currentCover = listData.containsKey('coverUrl') ? listData['coverUrl'] : null;

      transaction.update(listRef, {
        'bookCount': currentCount + 1,
        // Jika belum ada cover, pakai thumbnail buku ini sebagai cover list
        'coverUrl': currentCover ?? book.thumbnailUrl,
      });
      
      // 4. Tulis buku baru ke sub-collection 'books'
      transaction.set(bookRef, book.toMap());
    });
  }

  // Melihat isi buku dalam list tertentu
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

  // Ambil Review user sendiri (History Review)
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

  // Ambil Review orang lain pada buku tertentu
  Stream<List<Review>> getBookReviews(String bookId) {
    return _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }
  // 6. FITUR STREAK & JADWAL HARIAN (BARU)
  // ===========================================================================

  // 1. Update Hari Baca Pilihan User (Contoh: [1, 3, 7] = Senin, Rabu, Minggu)
  Future<void> updateReadingDays(List<int> days) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    await _db.collection('users').doc(user.uid).set({
      'readingDays': days, // List integer (1=Senin, 7=Minggu)
    }, SetOptions(merge: true));
  }

  // 2. Ambil Log Bacaan Minggu Ini (Untuk UI Bulat-bulat)
  Stream<List<DateTime>> getWeeklyLogs(DateTime startOfWeek) {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_logs')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('date', isLessThan: Timestamp.fromDate(endOfWeek))
        .snapshots()
        .map((snap) => snap.docs.map((doc) => (doc['date'] as Timestamp).toDate()).toList());
  }

  // 3. Tandai Hari Ini Sudah Baca (Klik Bulatan)
  Future<void> markDayAsRead() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Jam 00:00

    final userRef = _db.collection('users').doc(user.uid);
    final logRef = userRef.collection('reading_logs').doc(today.toIso8601String().split('T')[0]);

    await _db.runTransaction((transaction) async {
      // Cek apakah hari ini sudah absen
      final logSnap = await transaction.get(logRef);
      if (logSnap.exists) return; // Sudah absen, jangan double count

      // Update Streak
      final userSnap = await transaction.get(userRef);
      int currentStreak = userSnap.data()?['currentStreak'] ?? 0;

      transaction.update(userRef, {'currentStreak': currentStreak + 1});
      transaction.set(logRef, {'date': Timestamp.fromDate(today)});
    });
  }

  // 4. Cek & Reset Streak (Dijalankan saat loading halaman)
  // Logic: Jika ada jadwal KEMARIN atau sebelumnya yang bolong, reset streak jadi 0.
  Future<void> validateStreak() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;

    List<dynamic> readingDays = userDoc.data()?['readingDays'] ?? [];
    int currentStreak = userDoc.data()?['currentStreak'] ?? 0;
    
    if (currentStreak == 0 || readingDays.isEmpty) return;

    // Cek log terakhir
    final logs = await _db.collection('users').doc(user.uid).collection('reading_logs')
        .orderBy('date', descending: true).limit(1).get();
    
    if (logs.docs.isEmpty) return;

    DateTime lastLogDate = (logs.docs.first['date'] as Timestamp).toDate();
    DateTime today = DateTime.now();
    
    // Normalisasi ke jam 00:00
    lastLogDate = DateTime(lastLogDate.year, lastLogDate.month, lastLogDate.day);
    today = DateTime(today.year, today.month, today.day);

    // Jika log terakhir adalah hari ini, aman.
    if (lastLogDate.isAtSameMomentAs(today)) return;

    // Loop dari sehari setelah log terakhir sampai KEMARIN
    // Jika ada hari yang masuk 'readingDays' tapi tidak ada log, RESET.
    bool broken = false;
    DateTime checkDate = lastLogDate.add(const Duration(days: 1));

    while (checkDate.isBefore(today)) {
      // .weekday return 1 (Senin) - 7 (Minggu)
      if (readingDays.contains(checkDate.weekday)) {
        broken = true;
        break;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    if (broken) {
      await _db.collection('users').doc(user.uid).update({'currentStreak': 0});
    }
  }
}