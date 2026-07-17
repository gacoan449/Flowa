import 'package:flutter/material.dart';
import 'package:flowa/features/video_community/presentation/screens/video_feed_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/friends_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/upload_video_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/inbox_screen.dart';
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

    // Mendefinisikan daftar layar berdasarkan role
    final List<Widget> screens = [
      const VideoFeedScreen(),
      const FriendsScreen(),
      if (isCreatorOrAdmin) const UploadVideoScreen(), 
      const InboxScreen(),
      ProfileScreen(userRole: currentRole), 
    ];

    return Scaffold(
      // [UPGRADE CTO] Menggunakan IndexedStack untuk performa tinggi: 
      // Layar tidak akan di-rebuild (dimuat ulang) saat berpindah menu.
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      
      // [UPGRADE CTO] Bottom Bar dengan desain "Floating" modern & transparan
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.black,
          selectedItemColor: Colors.amber, 
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_filled, 'Beranda'),
            _buildNavItem(Icons.people_alt_rounded, 'Teman'),
            
            if (isCreatorOrAdmin)
              BottomNavigationBarItem(
                icon: Container(
                  height: 32,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
                ),
                label: '',
              ),
              
            _buildNavItem(Icons.chat_bubble_rounded, 'Kotak Masuk'),
            _buildNavItem(Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  // [UPGRADE CTO] Helper untuk standarisasi ikon agar kode utama bersih (Clean Code)
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
