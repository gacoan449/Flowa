import 'package:flutter/material.dart';
// Import halaman pemutar video agar kotak grid bisa dipencet
import '../../video_community/presentation/screens/video_feed_screen.dart';
// Import halaman dashboard admin untuk tombol rahasia Anda
import '../../admin/presentation/screens/admin_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  // Simulasi data pengguna yang sedang dilihat profilnya
  final Map<String, dynamic> _mockUserData = {
    "username": "Hilwa_Kreatif",
    "role": "creator", // Jika 'creator' tampilkan grid video, jika 'user' sembunyikan grid
    "isVerified": true,
    "bio": "Suka ngonten seru seputar desa dan teknologi digital 🌟",
    "avatarUrl": "https://unsplash.com",
    "followers": 15400,
    "following": 182,
    "totalLikes": "45.2K"
  };

  // Simulasi daftar video yang pernah diunggah oleh kreator ini (menggunakan gambar thumbnail acak)
  final List<String> _mockThumbnails = [
    "https://unsplash.com",
    "https://unsplash.com",
    "https://unsplash.com",
    "https://unsplash.com",
    "https://unsplash.com",
    "https://unsplash.com"
  ];

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isCreator = _mockUserData['role'] == 'creator';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _mockUserData['username'],
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 1. Foto Profil dengan Tombol Rahasia Akses Masuk Ruang Admin
            GestureDetector(
              onTap: () {
                // Trik Rahasia Pemilik: Jika foto profil diklik, langsung arahkan ke Dashboard Pengawasan Admin
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
                  if (_mockUserData['isVerified'])
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 2. Teks Bio Pengguna
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _mockUserData['bio'],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 25),

            // 3. Baris Statistik (Following, Followers, Likes)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Following", _mockUserData['following'].toString()),
                _buildStatItem("Followers", _mockUserData['followers'] > 1000 
                    ? "${(_mockUserData['followers'] / 1000).toStringAsFixed(1)}K" 
                    : _mockUserData['followers'].toString()),
                _buildStatItem("Suka", _mockUserData['totalLikes']),
              ],
            ),
            const SizedBox(height: 30),

            // 4. Tombol Aksi (Edit Profil)
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
                  child: const Text(
                    "Edit Profil",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Divider(height: 1, thickness: 1),

            // 5. Bagian Grid Video (Sudah Responsif Bisa Dipencet)
            if (isCreator) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Agar scroll menyatu smooth dengan halaman utama
                  itemCount: _mockThumbnails.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Menampilkan 3 kolom grid kesamping ala Instagram/TikTok
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 3 / 4, // Rasio vertikal mirip thumbnail video nyata
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // AKSI NYATA: Saat kotak video di-klik, otomatis beralih ke halaman pemutar video utama (FYP)
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
                                  Text(
                                    "12K", // Simulasi jumlah views video
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
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
              // Jika user biasa dan belum punya kiriman konten video
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.video_camera_back_outlined, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "Belum ada kiriman video",
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
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
