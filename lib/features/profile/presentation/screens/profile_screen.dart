import 'package:flutter/material.dart';
import 'package:flowa/features/video_community/presentation/screens/video_feed_screen.dart';
import 'package:flowa/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:flowa/features/auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userRole;

  final Map<String, dynamic> _mockUserData = {
    "username": "Hilwa_Kreatif",
    "isVerified": true,
    "bio": "Menikmati aliran hiburan video seru di aplikasi Flowa ✨",
    "avatarUrl": "https://unsplash.com",
    "followers": 15400,
    "following": 182,
    "totalLikes": "45.2K"
  };

  final List<String> _mockThumbnails = [
    "https://unsplash.com",
    "https://unsplash.com",
    "https://unsplash.com",
  ];

  ProfileScreen({super.key, required this.userRole});

  // FUNGSI NYATA: Memunculkan menu opsi pengaturan akun dan tombol Logout dari bawah HP
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.black87),
                title: const Text("Ubah Foto & Profil", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                // PERBAIKAN: Mengganti Icons.whatsapp menjadi Icons.support_agent (Ikon Customer Service Resmi) agar lolos kompilasi
                leading: const Icon(Icons.support_agent, color: Colors.green),
                title: const Text("Hubungi Bantuan Pusat", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Keluar Aplikasi (Logout)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context); // Tutup panel bottom sheet
                  // AKSI LOGOUT NYATA: Menendang keluar pengguna ke halaman LoginScreen awal
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = userRole == 'creator' || userRole == 'admin';
    final isAdminOwner = userRole == 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isCreator ? _mockUserData['username'] : "Profil Saya",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: () {
                if (isAdminOwner) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_mockUserData['avatarUrl']),
                    backgroundColor: Colors.grey,
                  ),
                  if (isCreator && _mockUserData['isVerified'])
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isCreator ? _mockUserData['bio'] : "Selamat datang di Flowa! Nikmati aliran hiburan tanpa batas.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 25),

            if (isCreator) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem("Following", _mockUserData['following'].toString()),
                  _buildStatItem("Followers", "${(_mockUserData['followers'] / 1000).toStringAsFixed(1)}K"),
                  _buildStatItem("Suka", _mockUserData['totalLikes']),
                ],
              ),
              const SizedBox(height: 30),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showSettingsMenu(context), // Memicu pembukaan menu bottom sheet di atas
                  child: Text(
                    isCreator ? "Edit Profil Kreator" : "Pengaturan Akun",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Divider(height: 1, thickness: 1),

            if (isCreator) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mockThumbnails.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 3 / 4,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VideoFeedScreen()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          image: DecorationImage(
                            image: NetworkImage(_mockThumbnails[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Stack(
                          children: [
                            Positioned(
                              bottom: 5,
                              left: 5,
                              child: Row(
                                children: [
                                  Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                  SizedBox(width: 2),
                                  Text("12K", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "Anda berada di mode penonton resmi Flowa",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
