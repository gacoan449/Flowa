import 'package:flutter/material.dart';
import 'features/video_community/presentation/screens/video_feed_screen.dart';
import 'features/video_community/presentation/screens/upload_video_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

class AppNavigation extends StatefulWidget {
  final String overrideRole; // Menerima lemparan data kuncian dari login_screen
  
  const AppNavigation({super.key, required this.overrideRole});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Membaca peran pengguna secara dinamis dari hasil login
    final String currentRole = widget.overrideRole;
    final isCreatorOrAdmin = currentRole == 'creator' || currentRole == 'admin';

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
          if (isCreatorOrAdmin)
            BottomNavigationBarItem(
              icon: Container(
                width: 45,
                height: 30,
                decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(8)),
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
