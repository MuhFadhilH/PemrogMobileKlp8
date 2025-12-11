import 'package:flutter/material.dart';
import '../../models/book_model.dart';

class HomeExploreSection extends StatelessWidget {
  final List<Book> books;
  final String genre;
  final Function(Book) onBookTap;

  const HomeExploreSection({
    super.key,
    required this.books,
    required this.genre,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITLE dengan genre yang berubah
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionTitle("Jelajahi $genre"),
        ),

        // BOOK LIST
        Container(
          height: 240,
          margin: const EdgeInsets.only(top: 10),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: books.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildExploreBookCard(context, book);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildExploreBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => onBookTap(book),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BOOK COVER
            Container(
              height: 160,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  book.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.book, color: Colors.grey, size: 24),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // BOOK TITLE
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
