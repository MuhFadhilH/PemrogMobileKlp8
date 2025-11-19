class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String thumbnailUrl;
  final String infoLink;      // Link ke Google Play
  final double averageRating; // Rating Bintang (Real Data)
  final int ratingsCount;     // Jumlah Review (Real Data)

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.thumbnailUrl,
    required this.infoLink,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    
    return Book(
      id: json['id'],
      title: volumeInfo['title'] ?? 'Tanpa Judul',
      author: (volumeInfo['authors'] as List?)?.join(', ') ?? 'Penulis Tidak Diketahui',
      description: volumeInfo['description'] ?? 'Tidak ada deskripsi.',
      thumbnailUrl: volumeInfo['imageLinks']?['thumbnail'] ?? 
          'https://via.placeholder.com/150',
      infoLink: volumeInfo['infoLink'] ?? '',
      // Ambil data rating (Jika null, default jadi 0.0)
      averageRating: (volumeInfo['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (volumeInfo['ratingsCount'] as int?) ?? 0,
    );
  }
}