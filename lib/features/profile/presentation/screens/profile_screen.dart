import 'package:flutter/material.dart';
import 'package:flowa/features/video_community/presentation/screens/video_feed_screen.dart';
import 'package:flowa/features/admin/presentation/screens/admin_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userRole; // Menerima data role dari halaman navigasi utama

  // Data tiruan profil yang disesuaikan
  final Map<String, dynamic> _mockUserData = {
    "username": "Warga_Flowa_Id",
    "isVerified": true,
    "bio": "Menikmati konten seru di aplikasi Flowa ✨",
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

  ProfileScreen({super.key, required this.userRole}); // Constructor wajib meminta data role

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah yang membuka halaman ini bertindak sebagai kreator atau bukan
    final isCreator = userRole == 'creator';

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
            
            // Foto Profil dengan Akses Ruang Admin Rahasia Anda
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                );
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

            // PANDUAN UTAMA: Baris Statistik ini hanya dimunculkan khusus untuk Konten Kreator
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
                  onPressed: () {},
                  child: Text(
                    isCreator ? "Edit Profil Kreator" : "Pengaturan Akun",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Divider(height: 1, thickness: 1),

            // Grid Video hanya dimunculkan jika status akun adalah 'creator'
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
              // Tampilan bersih minimalis jika yang masuk adalah user biasa (penonton)
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
