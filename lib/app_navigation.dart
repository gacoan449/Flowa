import 'package:flutter/material.dart';
// Import semua halaman yang sudah kita buat sebelumnya
import 'features/video_community/presentation/screens/video_feed_screen.dart';
import 'features/video_community/presentation/screens/upload_video_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  // Daftar halaman yang dihubungkan oleh Navigasi Bawah
  final List<Widget> _screens = [
    const VideoFeedScreen(),  // Indeks 0: Halaman FYP Video
    const UploadVideoScreen(), // Indeks 1: Halaman Unggah Konten (Kreator)
    ProfileScreen(),          // Indeks 2: Halaman Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens, // Menjaga state halaman agar tidak memuat ulang dari nol saat berpindah menu
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black, // Background hitam elegan mirip TikTok/FB Watch
        selectedItemColor: Colors.amber, // Warna menu aktif (khas emas DesaPay)
        unselectedItemColor: Colors.white60, // Warna menu tidak aktif
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 26),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 45,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.purple, // Warna ungu khas Flowa
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            label: 'Ngonten',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 26),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
