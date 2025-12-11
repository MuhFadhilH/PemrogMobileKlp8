import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/book_list_model.dart';
import '../models/book_model.dart';
import '../models/book_status.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../models/user_preference_model.dart';
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // HELPER: Get Current User ID
  // ===========================================================================
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // ============================
  // METHOD USER PREFERENCE BARU
  // ============================

  // Save user preferences
  Future<void> saveUserPreferences(UserPreference preference) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'preferences': preference.toMap(),
    });
  }

  // Get user preferences stream
  Stream<UserPreference> getUserPreferencesStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(UserPreference());

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return UserPreference();
      final data = doc.data() as Map<String, dynamic>;

      if (data.containsKey('preferences')) {
        return UserPreference.fromMap(data['preferences']);
      }
      return UserPreference();
    });
  }

  // Get user preferences once
  Future<UserPreference> getUserPreferences() async {
    User? user = _auth.currentUser;
    if (user == null) return UserPreference();

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return UserPreference();

    final data = doc.data() as Map<String, dynamic>;
    if (data.containsKey('preferences')) {
      return UserPreference.fromMap(data['preferences']);
    }
    return UserPreference();
  }

  // Method yang sudah ada sebelumnya dengan sedikit perbaikan
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
      'preferences': FieldValue.arrayUnion([]),
    });

    await user.updateDisplayName(username);
  }

  // Hitung total buku di Reading List
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

  // Hitung total review user
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

  // Hitung total book list user - METHOD BARU
  Future<int> getBookListCount() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;

    final agg = await _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .count()
        .get();
    return agg.count ?? 0;
  }

  // ===========================================================================
  // 2. FITUR READING LIST & STATUS
  // ===========================================================================

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

  Future<void> saveBookToReadingList(Book book, BookStatus status) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('reading_list')
        .doc(book.id);

    if (status == BookStatus.none) {
      await docRef.delete();
      return;
    }

    await docRef.set({
      ...book.toMap(),
      'readingStatus': status.toFirestoreString(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // 3. FITUR JADWAL BACA
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

    await NotificationService().scheduleReadingPlan(
      idBase: notificationId,
      bookTitle: book.title,
      startDate: startDate,
      deadlineDate: deadlineDate,
      hour: hour,
      minute: minute,
    );
  }

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
  // 4. FITUR CUSTOM LIST
  // ===========================================================================

  Future<void> createCustomList(String listName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .add({
      'name': listName,
      'userId': user.uid,
      'ownerId': user.uid,
      'ownerName': user.displayName ?? 'Bibliomate User',
      'bookCount': 0,
      'coverUrl': null,
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

  Future<void> addBookToCustomList(Book book, String listId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final listRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId);

    final bookRef = listRef.collection('books').doc(book.id);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot bookSnap = await transaction.get(bookRef);
      if (bookSnap.exists) {
        throw Exception("Buku ini sudah ada di dalam list.");
      }

      DocumentSnapshot listSnap = await transaction.get(listRef);
      if (!listSnap.exists) {
        throw Exception("List tidak ditemukan.");
      }

      Map<String, dynamic> listData = listSnap.data() as Map<String, dynamic>;
      int currentCount = listData['bookCount'] ?? 0;
      String? currentCover =
          listData.containsKey('coverUrl') ? listData['coverUrl'] : null;

      transaction.update(listRef, {
        'bookCount': currentCount + 1,
        'coverUrl': currentCover ?? book.thumbnailUrl,
      });

      transaction.set(bookRef, {
        ...book.toMap(),
        'addedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Book>> getBooksInList(String listId) {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId)
        .collection('books')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<List<Book>> getBooksInListForUser(
      {required String listId, required String ownerId}) {
    return _db
        .collection('users')
        .doc(ownerId)
        .collection('custom_book_lists')
        .doc(listId)
        .collection('books')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

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

  // METHOD BARU: Hapus buku dari list
  // NOTE: Method ini fungsinya sama dengan removeBookFromList di branch lain
  Future<void> deleteBookFromList(String listId, String bookId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final bookRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId)
        .collection('books')
        .doc(bookId);

    await bookRef.delete();

    // Update book count
    final listRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId);

    await listRef.update({
      'bookCount': FieldValue.increment(-1),
    });
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

    final reviewData = Review(
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

    await docRef.set(reviewData.toMap());
  }

  Stream<List<Review>> getBookReviews(String bookId, {int? limit}) {
    Query query = _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map(
            (doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Stream<List<Review>> getUserReviews({String? userId}) {
    String? targetUid = userId ?? _auth.currentUser?.uid;
    if (targetUid == null) return const Stream.empty();

    return _db
        .collection('reviews')
        .where('userId', isEqualTo: targetUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<Review?> streamUserReviewForBook(String bookId) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Review.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  // ALIAS untuk streamUserReviewForBook - METHOD BARU
  Stream<Review?> getUserReviewForBook(String bookId) {
    return streamUserReviewForBook(bookId);
  }

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

  // ===========================================================================
  // 6. METHOD BARU: Get User by ID
  // ===========================================================================

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(data, doc.id);
    } catch (e) {
      debugPrint("Error getting user by ID: $e");
      return null;
    }
  }

  // ===========================================================================
  // 7. FITUR SEARCH
  // ===========================================================================

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '${query}z')
        .get();
    return snapshot.docs
        .map((doc) =>
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<Review>> searchReviews(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _db
        .collection('reviews')
        .where('reviewText', isGreaterThanOrEqualTo: query)
        .where('reviewText', isLessThan: '${query}z')
        .get();
    return snapshot.docs
        .map(
            (doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<BookListModel>> searchBookListModels(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _db
        .collectionGroup('custom_book_lists')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .get();

    return snapshot.docs
        .map((doc) => BookListModel.fromFirestore(doc))
        .toList();
  }

  // ===========================================================================
  // 8. FITUR JURNAL & STREAK
  // ===========================================================================

  Future<void> validateStreak() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final userDocRef = _db.collection('users').doc(user.uid);
    final doc = await userDocRef.get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final lastReadTimestamp = data['lastReadDate'] as Timestamp?;

    if (lastReadTimestamp == null) return;

    final lastRead = lastReadTimestamp.toDate();
    final now = DateTime.now();

    final dateLastRead = DateTime(lastRead.year, lastRead.month, lastRead.day);
    final dateNow = DateTime(now.year, now.month, now.day);

    final difference = dateNow.difference(dateLastRead).inDays;

    if (difference > 1) {
      await userDocRef.update({'currentStreak': 0});
    }
  }

  Future<void> updateReadingDays(List<int> days) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({'readingDays': days});
  }

  Future<void> markDayAsRead() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateNow = DateTime(now.year, now.month, now.day);
    final userDocRef = _db.collection('users').doc(user.uid);

    final startOfDay = Timestamp.fromDate(dateNow);
    final endOfDay = Timestamp.fromDate(dateNow.add(const Duration(days: 1)));

    final logsQuery = await userDocRef
        .collection('reading_logs')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (logsQuery.docs.isNotEmpty) {
      return;
    }

    await userDocRef.collection('reading_logs').add({
      'date': FieldValue.serverTimestamp(),
    });

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
        currentStreak++;
      } else if (diff > 1) {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    await userDocRef.update({
      'lastReadDate': FieldValue.serverTimestamp(),
      'currentStreak': currentStreak,
    });
  }

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

  // ===========================================================================
  // 9. EXTRA HELPERS (MERGED)
  // ===========================================================================

  // Cek apakah buku ada di list tertentu (Stream agar real-time)
  Stream<bool> isBookInCustomList(String listId, String bookId) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('custom_book_lists')
        .doc(listId)
        .collection('books')
        .doc(bookId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
