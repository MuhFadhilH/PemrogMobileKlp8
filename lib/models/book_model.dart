// lib/models/book_model.dart
import 'book_status.dart'; // <--- Tambahkan ini

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String thumbnailUrl;
  final String infoLink;
  final double averageRating;
  final int ratingsCount;
  BookStatus readingStatus; // <--- FIELD BARU

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.thumbnailUrl,
    required this.infoLink,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.readingStatus = BookStatus.none, // <--- DEFAULT BARU
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};

    String imageUrl = '';
    if (volumeInfo['imageLinks'] != null &&
        volumeInfo['imageLinks']['thumbnail'] != null) {
      imageUrl = volumeInfo['imageLinks']['thumbnail'];
      if (imageUrl.startsWith('http://')) {
        imageUrl = imageUrl.replaceFirst('http://', 'https://');
      }
    } else {
      imageUrl = 'https://picsum.photos/seed/${json['id'] ?? 'book'}/150/220';
    }

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Judul Tidak Diketahui',
      author:
          (volumeInfo['authors'] as List<dynamic>?)?.join(', ') ??
          'Penulis Tidak Diketahui',
      description:
          volumeInfo['description'] ?? 'Belum ada deskripsi untuk buku ini.',
      thumbnailUrl: imageUrl,
      infoLink: volumeInfo['infoLink'] ?? '',
      averageRating: (volumeInfo['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (volumeInfo['ratingsCount'] as int?) ?? 0,
      // readingStatus tidak diinisialisasi dari JSON API Google Books, karena itu status lokal
    );
  }

  // Fungsi untuk membuat Book dari Firestore (lengkap dengan status)
  factory Book.fromFirestore(Map<String, dynamic> data, String id) {
    return Book(
      id: id,
      title: data['title'] ?? 'Judul Tidak Diketahui',
      author: data['author'] ?? 'Penulis Tidak Diketahui',
      description: data['description'] ?? 'Belum ada deskripsi untuk buku ini.',
      thumbnailUrl:
          data['thumbnailUrl'] ?? 'https://picsum.photos/seed/$id/150/220',
      infoLink: data['infoLink'] ?? '',
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (data['ratingsCount'] as int?) ?? 0,
      readingStatus: BookStatusExtension.fromFirestoreString(
        data['readingStatus'],
      ), // <--- AMBIL DARI FIRESTORE
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'infoLink': infoLink,
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
      'readingStatus': readingStatus.toFirestoreString(), // <--- SIMPAN STATUS
    };
  }
}
