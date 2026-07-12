import 'package:flutter/material.dart';
// Import widget tombol interaksi yang baru kita buat tadi
import '../widgets/interaction_buttons.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  // Data simulasi video Flowa lengkap dengan jumlah interaksinya
  final List<Map<String, dynamic>> _flowaVideos = [
    {
      "id": "1", 
      "creator": "Hilwa_Kreatif", 
      "caption": "Serunya main game hari ini! #flowa #hiburan",
      "type": "content", 
      "color": Colors.purple,
      "likes": 1250,
      "comments": 84
    },
    {
      "id": "2", 
      "creator": "Sponsor_Desa", 
      "caption": "Solusi cerdas transaksi warga desa! #DesaPay #PetaniDesa",
      "type": "ads", 
      "color": Colors.teal,
      "likes": 5400,
      "comments": 310
    }, // Slot Iklan Rahasia Anda!
    {
      "id": "3", 
      "creator": "Anak_Desa_Ngonten", 
      "caption": "Pemandangan sawah sore hari adem bgt 🌾",
      "type": "content", 
      "color": Colors.blueGrey,
      "likes": 920,
      "comments": 45
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical, // Geser ke bawah mirip TikTok/FB Watch
        itemCount: _flowaVideos.length,
        itemBuilder: (context, index) {
          final video = _flowaVideos[index];
          final isAds = video['type'] == 'ads';

          return Container(
            color: video['color'],
            child: Stack(
              children: [
                // 1. Area Pemutar Video Utama (Simulasi teks tengah)
                Center(
                  child: Text(
                    isAds ? "PROMO: Belanja di Petani Desa\nPakai DesaPay Lebih Murah!" : "Video Flowa dari @${video['creator']}",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // 2. Tombol Aksi Rahasia Khusus Iklan Anda (Melayang di bawah tengah)
                if (isAds)
                  Positioned(
                    bottom: 160,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

                // 3. Deskripsi & Nama Kreator (Melayang di kiri bawah)
                Positioned(
                  bottom: 30,
                  left: 16,
                  right: 80, // Diberi jarak kanan agar tidak tabrakan dengan tombol ikon
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
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 4. Komponen Tombol Interaksi (Melayang di kanan bawah)
                Positioned(
                  bottom: 40,
                  right: 16,
                  child: InteractionButtons(
                    likes: video['likes'],
                    comments: video['comments'],
                    onLikePressed: () {
                      // Logika ketika tombol like ditekan (tambah angka & kirim data ke algoritma)
                    },
                    onCommentPressed: () {
                      // Logika untuk memunculkan kolom komentar pop-up
                    },
                    onSharePressed: () {
                      // Logika bagikan video
                    },
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
