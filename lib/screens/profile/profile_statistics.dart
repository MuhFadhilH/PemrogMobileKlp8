import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class ProfileStatistics extends StatelessWidget {
  final VoidCallback onBooksTap;
  final VoidCallback onReviewsTap;
  final VoidCallback onListsTap;

  const ProfileStatistics({
    super.key,
    required this.onBooksTap,
    required this.onReviewsTap,
    required this.onListsTap,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: "Books",
            value: firestoreService.getBookCount(),
            onTap: onBooksTap,
          ),
          _VerticalDivider(),
          _StatItem(
            label: "Reviews",
            value: firestoreService.getReviewCount(),
            onTap: onReviewsTap,
          ),
          _VerticalDivider(),
          _StatItem(
            label: "Lists",
            value: firestoreService.getBookListCount(),
            onTap: onListsTap,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final Future<int> value;
  final VoidCallback onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<int>(
        future: value,
        builder: (context, snap) => Column(
          children: [
            Text(
              (snap.data ?? 0).toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
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

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey[300],
    );
  }
}
