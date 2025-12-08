import 'package:cloud_firestore/cloud_firestore.dart';

class BookList {
  final String id;
  final String name;
  final String userId;
  final String? coverUrl; // Cover diambil dari buku pertama
  final int bookCount;
  final DateTime createdAt;

  BookList({
    required this.id,
    required this.name,
    required this.userId,
    this.coverUrl,
    this.bookCount = 0,
    required this.createdAt,
  });

  // Dari Firestore ke Object Dart
  factory BookList.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookList(
      id: doc.id,
      name: data['name'] ?? 'Untitled List',
      userId: data['userId'] ?? '',
      coverUrl: data['coverUrl'],
      bookCount: data['bookCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Dari Object Dart ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
      'coverUrl': coverUrl,
      'bookCount': bookCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
