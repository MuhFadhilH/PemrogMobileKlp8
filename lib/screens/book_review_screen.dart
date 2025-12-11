import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';

class BookReviewsScreen extends StatelessWidget {
  final Book book;

  const BookReviewsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ulasan Pembaca"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Review>>(
        // Panggil TANPA limit untuk menampilkan semua review
        stream: FirestoreService().getBookReviews(book.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada review."));
          }

          final reviews = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewItem(review);
            },
          );
        },
      ),
    );
  }

  // Widget Item Review yang bisa dipakai ulang
  Widget _buildReviewItem(Review review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: Text(
                review.username.isNotEmpty
                    ? review.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.username,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < review.rating
                            ? Icons.star
                            : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],
              ),
            ),
            Text(
              "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          review.reviewText,
          style: TextStyle(color: Colors.grey[800], height: 1.5),
        ),
      ],
    );
  }
}
