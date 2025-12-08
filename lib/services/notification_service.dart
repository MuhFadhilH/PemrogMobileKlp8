import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // ... (Init Settings Android & iOS sama seperti sebelumnya) ...
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // --- LOGIC BARU: START DATE & DEADLINE ---
  Future<void> scheduleReadingPlan({
    required int idBase,
    required String bookTitle,
    required DateTime startDate,
    required DateTime deadlineDate,
    required int hour,
    required int minute,
  }) async {
    
    // Helper untuk menggabungkan Tanggal + Jam Pilihan
    tz.TZDateTime makeSchedule(DateTime date) {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduled = tz.TZDateTime(
          tz.local, date.year, date.month, date.day, hour, minute);
      // Jika waktu sudah lewat hari ini, jangan jadwalkan (atau bisa dijadwalkan tahun depan, tapi disini kita skip)
      return scheduled;
    }

    // 1. Notifikasi HARI MULAI (Start Date)
    await _scheduleOne(
      id: idBase + 1,
      title: "Mulai Baca '$bookTitle' Hari Ini! 🚀",
      body: "Target bacaanmu dimulai sekarang. Semangat!",
      time: makeSchedule(startDate),
    );

    // 2. Notifikasi H-1 DEADLINE
    final hMin1 = deadlineDate.subtract(const Duration(days: 1));
    if (hMin1.isAfter(startDate)) { // Cek biar gak duplikat kalau durasi cuma 1 hari
      await _scheduleOne(
        id: idBase + 2,
        title: "Besok Deadline '$bookTitle'! ⏳",
        body: "Ayo kejar target bacamu sebelum besok.",
        time: makeSchedule(hMin1),
      );
    }

    // 3. Notifikasi HARI DEADLINE
    await _scheduleOne(
      id: idBase + 3,
      title: "Deadline Hari Ini: '$bookTitle' 🎯",
      body: "Pastikan kamu menyelesaikan bacaanmu hari ini ya!",
      time: makeSchedule(deadlineDate),
    );
  }

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
  }) async {
    if (time.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, title, body, time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_channel', 'Reading Reminders',
          importance: Importance.max, priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}