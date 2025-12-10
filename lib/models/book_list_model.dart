import 'package:cloud_firestore/cloud_firestore.dart';

class BookListModel {
  final String id;
  final String title;
  final String ownerId;
  final String ownerName;
  final int bookCount;
  final List<String> previewImages;

  BookListModel({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.ownerName,
    required this.bookCount,
    required this.previewImages,
  });

  // --- TAMBAHKAN GETTER INI ---
  // Ini akan otomatis mengambil gambar pertama sebagai cover, atau null jika kosong
  String? get coverUrl => previewImages.isNotEmpty ? previewImages.first : null;
  // -----------------------------

  factory BookListModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookListModel.fromMap(data, doc.id);
  }

  factory BookListModel.fromMap(Map<String, dynamic> data, String id) {
    List<String> images = [];
    // Cek apakah ada field 'coverUrl' lama (single string)
    if (data['coverUrl'] != null && data['coverUrl'].toString().isNotEmpty) {
      images.add(data['coverUrl']);
    }
    // Atau pakai 'previewImages' (list string)
    else if (data['previewImages'] != null) {
      images = List<String>.from(data['previewImages']);
    }

    return BookListModel(
      id: id,
      title: data['name'] ?? data['title'] ?? 'Untitled List',
      ownerId: data['userId'] ?? data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Bibliomate User',
      bookCount: data['bookCount'] ?? 0,
      previewImages: images,
    );
  }
}
