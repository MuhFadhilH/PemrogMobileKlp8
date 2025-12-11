import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Pastikan file-file ini ada di folder yang sesuai
import 'providers/book_provider.dart';
import 'screens/login_page.dart';
import 'main_nav.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi Notifikasi (PENTING untuk jadwal baca)
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Daftarkan Provider di sini agar bisa diakses di seluruh aplikasi
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bibliomate',

        // --- TEMA SOFT & MODERN ---
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0), // Indigo Lembut
            surface: const Color(0xFFF5F7FA), // Putih Kebiruan (Soft)
          ),

          // Style App Bar
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
          ),

          // Style Input Form (TextField)
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 2),
            ),
          ),
        ),

        // --- LOGIKA NAVIGASI OTOMATIS (STREAM BUILDER) ---
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // 1. Jika sedang loading (memeriksa status login)
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF5C6BC0),
                  ),
                ),
              );
            }

            // 2. Jika User Ada (Sudah Login) -> Masuk ke MainNav (Home)
            if (snapshot.hasData) {
              return const MainNav();
            }

            // 3. Jika User Kosong (Belum Login) -> Masuk ke LoginPage
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
