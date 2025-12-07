import 'package:flutter/material.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Journal",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.black),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER READING STREAK (Jadwal Baca)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF5C6BC0).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Current Streak",
                          style: TextStyle(color: Colors.white70)),
                      Icon(Icons.local_fire_department,
                          color: Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("12",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text("days reading",
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Indikator Hari (Sen-Min)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["M", "T", "W", "T", "F", "S", "S"]
                        .asMap()
                        .entries
                        .map((entry) {
                      // Logic Dummy: Hari ke 0, 1, 3, 4, 6 aktif
                      bool isActive = [0, 1, 3, 4, 6].contains(entry.key);
                      return Column(
                        children: [
                          Text(entry.value,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: isActive
                                ? const Icon(Icons.check,
                                    size: 16, color: Color(0xFF5C6BC0))
                                : null,
                          ),
                        ],
                      );
                    }).toList(),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. RECENT ACTIVITY (Timeline)
            const Text(
              "Recent Activity",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),

            // List Dummy Activity
            _buildActivityItem(
              bookTitle: "Atomic Habits",
              action: "finished reading",
              time: "2 hours ago",
              color: Colors.green,
            ),
            _buildActivityItem(
              bookTitle: "Laut Bercerita",
              action: "rated 5 stars",
              time: "Yesterday",
              color: Colors.amber,
              icon: Icons.star,
            ),
            _buildActivityItem(
              bookTitle: "Sapiens",
              action: "added to wishlist",
              time: "2 days ago",
              color: Colors.blue,
              icon: Icons.bookmark,
            ),
            _buildActivityItem(
              bookTitle: "Dunia Sophie",
              action: "started reading",
              time: "3 days ago",
              color: Colors.purple,
              icon: Icons.book,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String bookTitle,
    required String action,
    required String time,
    required Color color,
    IconData icon = Icons.check_circle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          // Garis Timeline
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: Colors.grey[300],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              Container(
                width: 2,
                height: 30,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 14),
                      children: [
                        const TextSpan(text: "You "),
                        TextSpan(
                            text: action,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.bold)),
                        const TextSpan(text: " "),
                        TextSpan(
                            text: bookTitle,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(time,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
