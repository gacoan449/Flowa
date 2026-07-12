import 'package:flutter/material.dart';
import '../widgets/interaction_buttons.dart';
import '../widgets/video_card.dart';
// Import controller logika yang baru kita buat
import '../../providers/video_feed_provider.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  // Menyimpan status video yang disukai oleh user (ID Video : Status Like)
  final Map<String, bool> _likedVideosStatus = {};

  final List<Map<String, dynamic>> _flowaVideos = [
    {
      "id": "1", 
      "creator": "Hilwa_Kreatif", 
      "caption": "Pemandangan alam yang sangat indah luar biasa! ✨ #flowa #nature",
      "category": "nature",
      "type": "content", 
      "videoUrl": "https://mixkit.co",
      "likes": 1250,
      "comments": 84
    },
    {
      "id": "2", 
      "creator": "Sponsor_Desa", 
      "caption": "Solusi cerdas transaksi warga desa! Kirim uang tanpa admin pakai #DesaPay dan belanja hasil bumi di #PetaniDesa 🌾💳",
      "category": "ads",
      "type": "ads", 
      "videoUrl": "https://mixkit.co",
      "likes": 5400,
      "comments": 310
    },
    {
      "id": "3", 
      "creator": "Anak_Desa_Ngonten", 
      "caption": "Suasana sore hari yang menenangkan di tepi sungai 🌊",
      "category": "entertainment",
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
        scrollDirection: Axis.vertical,
        itemCount: _flowaVideos.length,
        itemBuilder: (context, index) {
          final video = _flowaVideos[index];
          final isAds = video['type'] == 'ads';
          final videoId = video['id'] as String;
          final isLiked = _likedVideosStatus[videoId] ?? false;

          return Stack(
            children: [
              VideoCard(videoUrl: video['videoUrl']),
              
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
                      // Memicu pencatatan algoritma bahwa iklan diklik
                      VideoFeedController.logUserEngagement(
                        videoId: videoId, 
                        category: video['category'], 
                        actionType: 'click_ads',
                      );
                      // Tampilkan dialog simulasi pengalihan ke ekosistem toko Anda
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Mengalihkan..."),
                          content: const Text("Membuka Aplikasi Petani Desa Berkah & DesaPay..."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            )
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      "Buka Aplikasi Sekarang", 
                      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              Positioned(
                bottom: 30,
                left: 16,
                right: 80,
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

              Positioned(
                bottom: 40,
                right: 16,
                child: InteractionButtons(
                  likes: video['likes'],
                  comments: video['comments'],
                  onLikePressed: () {
                    setState(() {
                      // 1. Balikkan status like di UI HP
                      _likedVideosStatus[videoId] = !isLiked;
                      
                      // 2. Kalkulasi angka menggunakan controller bisnis
                      final updatedVideo = VideoFeedController.handleLikeAction(
                        videoData: video, 
                        isCurrentlyLiked: isLiked,
                      );
                      video['likes'] = updatedVideo['likes'];
                    });

                    // 3. Kirim data interaksi ke server penentu algoritma FYP
                    VideoFeedController.logUserEngagement(
                      videoId: videoId, 
                      category: video['category'], 
                      actionType: isLiked ? 'unlike' : 'like',
                    );
                  },
                  onCommentPressed: () {
                    VideoFeedController.logUserEngagement(
                      videoId: videoId, 
                      category: video['category'], 
                      actionType: 'open_comment',
                    );
                  },
                  onSharePressed: () {
                    VideoFeedController.logUserEngagement(
                      videoId: videoId, 
                      category: video['category'], 
                      actionType: 'share',
                    );
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
