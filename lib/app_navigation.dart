import 'package:flutter/material.dart';
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

  // SAKELAR SIMULASI AKUN: 
  // Ganti 'user' jika ingin tes tampilan warga biasa, ganti 'creator' jika ingin tes tampilan artis/kreator
  final String _userRole = 'creator'; 

  @override
  Widget build(BuildContext context) {
    // 1. Logika pemisahan halaman berdasarkan Role Pengguna
    final List<Widget> screens = [
      const VideoFeedScreen(),
      if (_userRole == 'creator') const UploadVideoScreen(), // Tombol upload hanya dimasukkan jika dia kreator
      ProfileScreen(userRole: _userRole), // Mengirim info role ke halaman profil
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 26),
            label: 'Beranda',
          ),
          
          // 2. Logika menyembunyikan tombol "+" khusus di HP penonton biasa
          if (_userRole == 'creator')
            BottomNavigationBarItem(
              icon: Container(
                width: 45,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.purple,
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
