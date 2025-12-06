import 'package:flutter/material.dart';
// Import halaman-halaman yang akan ditampilkan
import 'screens/home_screen.dart';
import 'screens/placeholder_screens.dart'; // Import dummy screens tadi

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;

  // Daftar halaman untuk Tab 0, 1, 3, 4 (Tab 2 adalah tombol Log)
  final List<Widget> _screens = [
    const HomeScreen(), // 0: Home
    const ExploreScreen(), // 1: Explore
    const SizedBox(), // 2: Placeholder untuk tombol tengah
    const JournalScreen(), // 3: Journal
    const ProfileScreen(), // 4: Profile
  ];

  // Fungsi saat item navbar ditekan
  void _onItemTapped(int index) {
    if (index == 2) {
      // Jika tombol tengah (Log) ditekan, jangan ganti halaman.
      // Tampilkan Modal "Log Book" (ala Letterboxd)
      _showLogModal();
    } else {
      // Selain itu, ganti halaman biasa
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Biar bisa full screen kalau mau
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.8, // Tinggi 80% layar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Modal
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "Log a Book",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Search Bar Dummy
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Cari judul buku...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                  child: Text("Hasil pencarian akan muncul di sini...")),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack menjaga halaman tetap hidup (tidak reload saat pindah tab)
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // Navbar Bawah
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Wajib fixed karena ada 5 item
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5C6BC0), // Warna aktif
          unselectedItemColor: Colors.grey[400], // Warna mati
          showSelectedLabels: false, // Gaya modern (tanpa label)
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Explore',
            ),
            // Tombol Tengah (Log) yang Menonjol
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF5C6BC0), // Background Biru
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              label: 'Log',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Journal',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
