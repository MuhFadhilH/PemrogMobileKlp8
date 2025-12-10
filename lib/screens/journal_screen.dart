import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _firestoreService.validateStreak();
  }

  // --- LOGIC HELPER: WARNA KARTU (Hijau -> Merah) ---
  Color _getCardColor(DateTime start, DateTime end) {
    final now = DateTime.now();

    // 1. Belum Mulai -> Putih
    if (now.isBefore(start)) return Colors.white;

    // 2. Lewat Deadline -> Merah Pudar
    if (now.isAfter(end)) return Colors.red.shade50;

    // 3. Sedang Berjalan (Active) -> Gradasi Hijau ke Merah
    final totalDuration = end.difference(start).inMinutes;
    final elapsed = now.difference(start).inMinutes;

    // Hitung progres (0.0 sampai 1.0)
    double progress = 0.0;
    if (totalDuration > 0) {
      progress = (elapsed / totalDuration).clamp(0.0, 1.0);
    }

    // Fase Awal (0% - 50%): Hijau Muda -> Kuning
    if (progress < 0.5) {
      return Color.lerp(
          Colors.lightGreen.shade100, Colors.yellow.shade100, progress * 2)!;
    }
    // Fase Akhir (50% - 100%): Kuning -> Merah Muda
    else {
      return Color.lerp(
          Colors.yellow.shade100, Colors.red.shade100, (progress - 0.5) * 2)!;
    }
  }

  // --- LOGIC HELPER: TEKS SISA WAKTU (Kanan) ---
  Widget _buildTrailingInfo(DateTime start, DateTime end) {
    final now = DateTime.now();
    bool isUpcoming = now.isBefore(start);
    bool isOverdue = now.isAfter(end);

    String text;
    IconData icon;
    Color color;

    if (isUpcoming) {
      Duration diff = start.difference(now);
      // Jika kurang dari 24 jam, tampilkan jam
      if (diff.inHours < 24) {
        text = "Starts in ${diff.inHours}h";
      } else {
        text = "Starts in ${diff.inDays}d";
      }
      icon = Icons.access_time;
      color = Colors.grey; // Warna abu untuk upcoming
    } else if (isOverdue) {
      text = "Overdue";
      icon = Icons.warning_amber_rounded;
      color = Colors.red;
    } else {
      Duration diff = end.difference(now);
      if (diff.inDays > 0) {
        text = "${diff.inDays} days left";
      } else {
        text = "${diff.inHours} hours left";
      }
      icon = Icons.timer_outlined;
      color = Colors.black87; // Warna tegas untuk active
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // --- LOGIC DIALOG HARI ---
  void _showDaySelectorDialog(List<int> currentDays) {
    List<int> selectedDays = List.from(currentDays);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Jadwal Baca Mingguan",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Pilih hari komitmen bacamu.",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _dayChip(1, "Sen", selectedDays, setStateDialog),
                      _dayChip(2, "Sel", selectedDays, setStateDialog),
                      _dayChip(3, "Rab", selectedDays, setStateDialog),
                      _dayChip(4, "Kam", selectedDays, setStateDialog),
                      _dayChip(5, "Jum", selectedDays, setStateDialog),
                      _dayChip(6, "Sab", selectedDays, setStateDialog),
                      _dayChip(7, "Min", selectedDays, setStateDialog),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () {
                    _firestoreService.updateReadingDays(selectedDays);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Jadwal diperbarui!")));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                      foregroundColor: Colors.white),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dayChip(int dayIndex, String label, List<int> selectedDays,
      StateSetter setStateDialog) {
    bool isSelected = selectedDays.contains(dayIndex);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF5C6BC0).withValues(),
      checkmarkColor: const Color(0xFF5C6BC0),
      onSelected: (val) => setStateDialog(() =>
          val ? selectedDays.add(dayIndex) : selectedDays.remove(dayIndex)),
    );
  }

  DateTime _getStartOfWeek() {
    DateTime now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("My Schedule",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER STREAK
            _buildStreakHeader(),

            // 2. JUDUL
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text("Upcoming Reading Plans",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),

            // 3. LIST JADWAL (UPDATED COLOR & ICON)
            _buildScheduleList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserProfileStream(),
        builder: (context, userSnap) {
          int streak = 0;
          List<int> readingDays = [];
          if (userSnap.hasData && userSnap.data!.exists) {
            final data = userSnap.data!.data() as Map<String, dynamic>;
            streak = data['currentStreak'] ?? 0;
            readingDays = List<int>.from(data['readingDays'] ?? []);
          }

          return GestureDetector(
            onTap: () => _showDaySelectorDialog(readingDays),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF5C6BC0).withValues(),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Current Streak",
                            style: TextStyle(color: Colors.white70)),
                        Icon(Icons.edit_calendar,
                            color: Colors.white.withValues(), size: 18),
                      ]),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(streak.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1)),
                    const SizedBox(width: 8),
                    const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text("days reading",
                            style: TextStyle(color: Colors.white70))),
                    const Spacer(),
                    const Icon(Icons.local_fire_department,
                        color: Colors.orangeAccent, size: 36),
                  ]),
                  const SizedBox(height: 24),
                  _buildWeekBubbles(readingDays),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekBubbles(List<int> readingDays) {
    DateTime startOfWeek = _getStartOfWeek();
    return StreamBuilder<List<DateTime>>(
      stream: _firestoreService.getWeeklyLogs(startOfWeek),
      builder: (context, snapshot) {
        List<DateTime> logs = snapshot.data ?? [];
        DateTime today = DateTime.now();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            DateTime date = startOfWeek.add(Duration(days: index));
            int weekday = date.weekday;
            String label = ["M", "T", "W", "T", "F", "S", "S"][index];
            bool isScheduled = readingDays.contains(weekday);
            bool isCompleted = logs.any((log) =>
                log.year == date.year &&
                log.month == date.month &&
                log.day == date.day);
            bool isToday = (date.year == today.year &&
                date.month == today.month &&
                date.day == today.day);
            bool isPast =
                date.isBefore(DateTime(today.year, today.month, today.day));

            Color circleColor;
            Widget? circleContent;
            bool isClickable = false;

            if (isCompleted) {
              circleColor = Colors.white;
              circleContent =
                  const Icon(Icons.check, size: 16, color: Color(0xFF5C6BC0));
            } else if (isScheduled && isPast) {
              circleColor = Colors.redAccent.withValues();
              circleContent =
                  const Icon(Icons.close, size: 16, color: Colors.white);
            } else if (isScheduled && isToday) {
              circleColor = Colors.white.withValues();
              isClickable = true;
            } else if (isScheduled) {
              circleColor = Colors.white.withValues();
            } else {
              circleColor = Colors.black.withValues();
            }

            return Column(
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: isClickable
                      ? () {
                          _firestoreService.markDayAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Streak +1! 🔥")));
                        }
                      : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                      border: isToday && isScheduled
                          ? Border.all(color: Colors.white, width: 1.5)
                          : null,
                    ),
                    child: Center(child: circleContent),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  // --- LIST JADWAL DENGAN WARNA & SORTING BENAR ---
  Widget _buildScheduleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Column(children: [
            Icon(Icons.event_note, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Belum ada jadwal aktif.",
                style: TextStyle(color: Colors.grey)),
          ]));
        }

        final docs = snapshot.data!.docs;
        final now = DateTime.now();

        // 1. PISAHKAN DATA: UPCOMING vs ACTIVE
        List<DocumentSnapshot> upcoming = [];
        List<DocumentSnapshot> active = [];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final start = (data['startDate'] as Timestamp).toDate();
          if (now.isBefore(start)) {
            upcoming.add(doc); // Belum mulai -> Upcoming (Putih)
          } else {
            active.add(doc); // Sudah mulai -> Active (Berwarna)
          }
        }

        // 2. SORTING
        // Upcoming: Urutkan berdasarkan tanggal mulai terdekat
        upcoming.sort((a, b) {
          DateTime da = (a['startDate'] as Timestamp).toDate();
          DateTime db = (b['startDate'] as Timestamp).toDate();
          return da.compareTo(db);
        });

        // Active: Urutkan berdasarkan deadline terdekat (urgensi)
        active.sort((a, b) {
          DateTime da = (a['deadlineDate'] as Timestamp).toDate();
          DateTime db = (b['deadlineDate'] as Timestamp).toDate();
          return da.compareTo(db);
        });

        // Gabungkan: Upcoming di ATAS (sesuai request), lalu Active
        final allPlans = [...upcoming, ...active];

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: allPlans.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = allPlans[index].data() as Map<String, dynamic>;
            final start = (data['startDate'] as Timestamp).toDate();
            final end = (data['deadlineDate'] as Timestamp).toDate();
            final targetTimeStr = data['targetTime'] ?? "09:00";
            final thumbUrl = data['thumbnailUrl'] ?? '';

            // Tentukan Warna & Widget Kanan
            final cardColor = _getCardColor(start, end);
            final trailingWidget = _buildTrailingInfo(start, end);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor, // Warna Dinamis
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200), // Border halus
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withValues(),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (thumbUrl.isNotEmpty)
                        ? Image.network(thumbUrl,
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 75,
                                color: Colors.grey[300],
                                child:
                                    const Icon(Icons.broken_image, size: 20)))
                        : Container(
                            width: 50,
                            height: 75,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['bookTitle'] ?? 'No Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.alarm,
                              size: 14, color: Colors.black87),
                          const SizedBox(width: 4),
                          Text("Reminder: $targetTimeStr",
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 2),
                        Text(
                            "${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey))
                      ],
                    ),
                  ),
                  // Widget Kanan (Sisa Hari)
                  trailingWidget,
                ],
              ),
            );
          },
        );
      },
    );
  }
}
