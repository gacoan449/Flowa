import 'package:flutter/material.dart';
import 'package:flowa/features/video_community/presentation/screens/video_feed_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/friends_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/upload_video_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/inbox_screen.dart';
import 'package:flowa/features/profile/presentation/screens/profile_screen.dart';

class AppNavigation extends StatefulWidget {
  // overrideRole tetap diterima untuk keperluan admin, tapi tidak lagi memblokir fitur upload warga
  final String overrideRole; 
  
  const AppNavigation({super.key, required this.overrideRole});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // SEMUA ORANG ADALAH KREATOR. Layar UploadVideoScreen langsung dimasukkan tanpa syarat 'if'.
    final List<Widget> screens = [
      const VideoFeedScreen(),
      const FriendsScreen(),
      const UploadVideoScreen(), // Akses penuh untuk semua user
      const InboxScreen(),
      ProfileScreen(userRole: widget.overrideRole), 
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white, // Meniru standar UI TikTok (Putih saat aktif)
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_filled, 'Beranda'),
            _buildNavItem(Icons.people_alt_outlined, 'Teman'),
            
            // TOMBOL "+" ALA TIKTOK UNTUK SEMUA PENGGUNA
            BottomNavigationBarItem(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 28,
                    decoration: BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.circular(8)),
                  ),
                  Positioned(
                    left: 4,
                    child: Container(
                      width: 42,
                      height: 28,
                      decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
                  ),
                ],
              ),
              label: '',
            ),
              
            _buildNavItem(Icons.chat_bubble_outline_rounded, 'Kotak Masuk'),
            _buildNavItem(Icons.person_outline_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(icon, size: 26),
      ),
      label: label,
    );
  }
}
