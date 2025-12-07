import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String bookThumbnailUrl;
  final double rating;
  final String reviewText;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookThumbnailUrl,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  // Mengubah Data Firebase (Map) menjadi Object Dart
  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      bookAuthor: map['bookAuthor'] ?? '',
      bookThumbnailUrl: map['bookThumbnailUrl'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewText: map['reviewText'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Mengubah Object Dart menjadi Data Firebase (Map) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookAuthor': bookAuthor,
      'bookThumbnailUrl': bookThumbnailUrl,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
