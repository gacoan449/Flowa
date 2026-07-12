import 'package:flutter/material.dart';
import '../widgets/interaction_buttons.dart';
import '../widgets/video_card.dart';
import '../../providers/video_feed_provider.dart';
import '../../../../core/services/firebase_service.dart';
import 'comment_sheet.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final Map<String, bool> _likedVideosStatus = {};
  final Map<String, bool> _bookmarkedVideosStatus = {}; // Menyimpan status simpan video di HP
  late Future<List<Map<String, dynamic>>> _videoFuture;

  @override
  void initState() {
    super.initState();
    _videoFuture = FirebaseService.fetchFlowaVideosFromCloud();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _videoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purple));
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Gagal memuat video dari server", style: TextStyle(color: Colors.white)));
          }

          final flowaVideos = snapshot.data!;

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: flowaVideos.length,
            itemBuilder: (context, index) {
              final video = flowaVideos[index];
              final isAds = video['type'] == 'ads';
              final videoId = video['id'] as String;
              
              // Status aktif tombol secara real-time
              final isLiked = _likedVideosStatus[videoId] ?? false;
              final isBookmarked = _bookmarkedVideosStatus[videoId] ?? false;

              // Ambil data angka awal atau set default jika kosong di cloud database
              final initialLikes = video['likes'] ?? 0;
              final initialComments = video['comments'] ?? 0;
              final initialBookmarks = video['bookmarks'] ?? 15; // Set dummy awal agar menarik dilihat

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
                        ),
                        onPressed: () {
                          VideoFeedController.logUserEngagement(
                            videoId: videoId, 
                            category: video['category'], 
                            actionType: 'click_ads',
                          );
                          showDialog(
                            context: context,
                            builder: (context) => const AlertDialog(
                              title: Text("Mengalihkan..."),
                              content: Text("Membuka Aplikasi Petani Desa Berkah & DesaPay..."),
                            ),
                          );
                        },
                        child: const Text("Buka Aplikasi Sekarang", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                        Text("@${video['creator']}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(video['caption'], style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),

                  // PANEL TOMBOL MELAYANG SEBELAH KANAN
                  Positioned(
                    bottom: 40,
                    right: 16,
                    child: InteractionButtons(
                      likes: isLiked ? initialLikes + 1 : initialLikes,
                      comments: initialComments,
                      bookmarks: isBookmarked ? initialBookmarks + 1 : initialBookmarks, // Hitungan dinamis bertambah otomatis
                      isLiked: isLiked,
                      isBookmarked: isBookmarked,
                      onLikePressed: () {
                        setState(() {
                          _likedVideosStatus[videoId] = !isLiked;
                        });
                        FirebaseService.updateLikeToCloud(videoId, !isLiked);
                      },
                      onCommentPressed: () {
                        VideoFeedController.logUserEngagement(
                          videoId: videoId, 
                          category: video['category'], 
                          actionType: 'open_comment',
                        );
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CommentSheet(videoId: videoId),
                        );
                      },
                      onBookmarkPressed: () {
                        // LOGIKA SIMPAN: Mengubah warna ikon menjadi emas dan mencatat poin minat ke Algoritma FYP
                        setState(() {
                          _bookmarkedVideosStatus[videoId] = !isBookmarked;
                        });
                        
                        VideoFeedController.logUserEngagement(
                          videoId: videoId, 
                          category: video['category'], 
                          actionType: isBookmarked ? 'unbookmark' : 'bookmark',
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
          );
        },
      ),
    );
  }
}
