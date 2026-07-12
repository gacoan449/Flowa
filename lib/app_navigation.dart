import 'package:flutter/material.dart';
import 'package:flowa/features/video_community/presentation/screens/video_feed_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/friends_screen.dart'; // Menu baru
import 'package:flowa/features/video_community/presentation/screens/upload_video_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/inbox_screen.dart';   // Menu baru
import 'package:flowa/features/profile/presentation/screens/profile_screen.dart';

class AppNavigation extends StatefulWidget {
  final String overrideRole;
  
  const AppNavigation({super.key, required this.overrideRole});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String currentRole = widget.overrideRole;
    final isCreatorOrAdmin = currentRole == 'creator' || currentRole == 'admin';

    // STRUKTUR 5 HALAMAN: Menyusun list halaman utama secara runtut ala TikTok
    final List<Widget> screens = [
      const VideoFeedScreen(),     // Indeks 0: Beranda FYP
      const FriendsScreen(),       // Indeks 1: Teman
      if (isCreatorOrAdmin) const UploadVideoScreen(), // Indeks 2: Ngonten (Hanya tampil jika Admin/Kreator)
      const InboxScreen(),         // Indeks 3: Kotak Masuk
      ProfileScreen(userRole: currentRole), // Indeks 4: Profil
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
        selectedItemColor: Colors.amber, // Warna emas khas DesaPay untuk menu aktif
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 24),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 24),
            label: 'Teman',
          ),
          
          // TOMBOL "+" ICONIK TIKTOK: Hanya disisipkan jika akun adalah Admin/Kreator
          if (isCreatorOrAdmin)
            BottomNavigationBarItem(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    child: Container(
                      width: 41,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.magenta,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Container(
                    width: 37,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                ],
              ),
              label: '', // TikTok mengosongkan teks label pada tombol tengah "+"
            ),
            
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: 24),
            label: 'Kotak Masuk',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
