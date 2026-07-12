import 'package:flutter/material.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  // Simulasi data video Flowa (Disisipi iklan Petani Desa & DesaPay)
  final List<Map<String, dynamic>> _flowaVideos = [
    {"id": "1", "creator": "Hilwa_Kreatif", "type": "content", "color": Colors.purple},
    {"id": "2", "creator": "Sponsor_Desa", "type": "ads", "color": Colors.teal}, // Slot Iklan Rahasia Anda!
    {"id": "3", "creator": "Anak_Desa_Ngonten", "type": "content", "color": Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical, // Gaya scroll vertikal TikTok/FB Watch
        itemCount: _flowaVideos.length,
        itemBuilder: (context, index) {
          final video = _flowaVideos[index];
          final isAds = video['type'] == 'ads';

          return Container(
            color: video['color'],
            child: Stack(
              children: [
                // Area Pemutar Video Utama
                Center(
                  child: Text(
                    isAds ? "PROMO: Belanja di Petani Desa\nPakai DesaPay Lebih Murah!" : "Video Flowa dari @${video['creator']}",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: Center,
                  ),
                ),
                
                // Tombol Aksi Rahasia Khusus Iklan Anda
                if (isAds)
                  Positioned(
                    bottom: 100,
                    left: 30,
                    right: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Nanti disambungkan untuk buka APK Petani Desa / DesaPay
                      },
                      child: const Text(
                        "Buka Aplikasi Sekarang", 
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
