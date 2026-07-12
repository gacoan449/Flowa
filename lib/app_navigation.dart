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

    final List<Widget> screens = [
      const VideoFeedScreen(),
      const FriendsScreen(),
      if (isCreatorOrAdmin) const UploadVideoScreen(), 
      const InboxScreen(),
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
                        // PERBAIKAN: Mengganti Colors.magenta menjadi Colors.pink resmi bawaan Flutter
                        color: Colors.pink,
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
              label: '',
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
