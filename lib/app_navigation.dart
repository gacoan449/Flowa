import 'package:flutter/material.dart';
import 'package:flowa/features/video_community/presentation/screens/video_feed_screen.dart';
import 'package:flowa/features/video_community/presentation/screens/upload_video_screen.dart';
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

    // Menyusun halaman secara dinamis berdasarkan jumlah menu bawah yang muncul
    final List<Widget> screens = [
      const VideoFeedScreen(),
      if (isCreatorOrAdmin) const UploadVideoScreen(), 
      ProfileScreen(userRole: currentRole), 
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
          // SEKAT KETAT: Tombol "+" hanya dimasukkan ke dalam daftar menu jika user adalah admin/kreator
          if (isCreatorOrAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box, color: Colors.purple, size: 28),
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
