import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add package intl di pubspec
import '../services/firestore_service.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Schedule", // Ganti Judul
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER READING STREAK (Tetap Dipertahankan)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
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
                  // Indikator Hari (Dummy Visual)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["M", "T", "W", "T", "F", "S", "S"]
                        .asMap()
                        .entries
                        .map((entry) {
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
          ),

          // 2. JUDUL SECTION
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Upcoming Reading Plans",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),

          // 3. LIST JADWAL (Infinite Stream)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getSchedules(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("Belum ada jadwal baca.",
                            style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: () {
                            // Logic untuk arahkan ke explore jika mau
                          },
                          child: const Text("Cari buku untuk dijadwal"),
                        ),
                      ],
                    ),
                  );
                }

                final schedules = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: schedules.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = schedules[index].data() as Map<String, dynamic>;
                    final Timestamp ts = data['scheduledTime'];
                    final DateTime date = ts.toDate();
                    final String formattedDate =
                        DateFormat('EEE, d MMM y').format(date);
                    final String formattedTime =
                        DateFormat('HH:mm').format(date);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Cover Buku
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['thumbnailUrl'] ?? '',
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 50, height: 75, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Detail Jadwal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['bookTitle'] ?? 'No Title',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Color(0xFF5C6BC0)),
                                    const SizedBox(width: 6),
                                    Text(formattedDate,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700])),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 14, color: Color(0xFF5C6BC0)),
                                    const SizedBox(width: 6),
                                    Text("Pukul $formattedTime",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5C6BC0))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Icon Lonceng
                          const Icon(Icons.notifications_active_outlined,
                              color: Colors.grey),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}