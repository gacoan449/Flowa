import 'package:flutter/material.dart';
import '../widgets/interaction_buttons.dart';
// Import komponen pemutar video asli yang baru kita buat
import '../widgets/video_card.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  // Data simulasi lengkap dengan URL video online asli untuk pengujian
  final List<Map<String, dynamic>> _flowaVideos = [
    {
      "id": "1", 
      "creator": "Hilwa_Kreatif", 
      "caption": "Pemandangan alam yang sangat indah luar biasa! ✨ #flowa #nature",
      "type": "content", 
      "videoUrl": "https://mixkit.co",
      "likes": 1250,
      "comments": 84
    },
    {
      "id": "2", 
      "creator": "Sponsor_Desa", 
      "caption": "Solusi cerdas transaksi warga desa! Kirim uang tanpa admin pakai #DesaPay dan belanja hasil bumi di #PetaniDesa 🌾💳",
      "type": "ads", 
      "videoUrl": "https://mixkit.co", // Ini slot iklan rahasia Anda!
      "likes": 5400,
      "comments": 310
    },
    {
      "id": "3", 
      "creator": "Anak_Desa_Ngonten", 
      "caption": "Suasana sore hari yang menenangkan di tepi sungai 🌊",
      "type": "content", 
      "videoUrl": "https://mixkit.co",
      "likes": 920,
      "comments": 45
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical, // Geser vertikal ala TikTok/FB Watch
        itemCount: _flowaVideos.length,
        itemBuilder: (context, index) {
          final video = _flowaVideos[index];
          final isAds = video['type'] == 'ads';

          return Stack(
            children: [
              // 1. LAYER UTAMA: Pemutar Video Asli dari Internet
              VideoCard(videoUrl: video['videoUrl']),
              
              // Gelap transparan di bagian bawah agar teks putih lebih mudah dibaca
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. LAYER ELEMEN IKLAN: Muncul jika tipe video adalah 'ads'
              if (isAds)
                Positioned(
                  bottom: 170,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    onPressed: () {
                      // Di sinilah logika dipicu untuk mengarahkan pengguna ke APK Petani Desa/DesaPay
                    },
                    child: const Text(
                      "Buka Aplikasi Sekarang", 
                      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // 3. LAYER INFORMASI: Nama Kreator & Caption (Kiri Bawah)
              Positioned(
                bottom: 30,
                left: 16,
                right: 80, // Jarak aman agar tidak bertabrakan dengan tombol interaksi
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "@${video['creator']}",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video['caption'],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 4. LAYER TOMBOL INTERAKSI: Like, Komen, Share (Kanan Bawah)
              Positioned(
                bottom: 40,
                right: 16,
                child: InteractionButtons(
                  likes: video['likes'],
                  comments: video['comments'],
                  onLikePressed: () {
                    // Masukkan logika penambahan jumlah like di sini
                  },
                  onCommentPressed: () {
                    // Masukkan logika pemicu pop-up kolom komentar di sini
                  },
                  onSharePressed: () {
                    // Masukkan logika fitur share/bagikan tautan video di sini
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
