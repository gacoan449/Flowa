import 'package:flutter/material.dart';
import '../widgets/interaction_buttons.dart';
import '../widgets/video_card.dart';
import '../widgets/video_feed_controller.dart'; // [PERBAIKAN PATH] Menyesuaikan letak file sesuai gambar terbaru Anda
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
  final Map<String, bool> _bookmarkedVideosStatus = {};
  late Future<List<Map<String, dynamic>>> _videoFuture;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _videoFuture = FirebaseService.fetchFlowaVideosFromCloud();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _videoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent, strokeWidth: 3));
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(0.5), size: 50),
                  const SizedBox(height: 16),
                  const Text("Gagal memuat video", style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            );
          }

          final flowaVideos = snapshot.data!;

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: flowaVideos.length,
            allowImplicitScrolling: true, 
            itemBuilder: (context, index) {
              final video = flowaVideos[index];
              final isAds = video['type'] == 'ads';
              final videoId = video['id'] as String;
              final videoCategory = video['category']?.toString() ?? 'general'; // Mengamankan parameter category
              
              final isLiked = _likedVideosStatus[videoId] ?? false;
              final isBookmarked = _bookmarkedVideosStatus[videoId] ?? false;

              final initialLikes = video['likes'] ?? 0;
              final initialComments = video['comments'] ?? 0;
              final initialBookmarks = video['bookmarks'] ?? 15;

              return Stack(
                children: [
                  VideoCard(videoUrl: video['videoUrl']),
                  
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  if (isAds)
                    Positioned(
                      bottom: 150,
                      left: 16,
                      right: 90,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                          label: const Text("Buka Aplikasi DesaPay", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          onPressed: () {
                            // [PERBAIKAN] Menambahkan parameter category yang diwajibkan oleh kompiler
                            VideoFeedController.logUserEngagement(
                              videoId: videoId, 
                              category: videoCategory,
                              actionType: 'click_ads',
                            );
                          },
                        ),
                      ),
                    ),

                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 80,
                    child: Column(
                      cross CrossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("@${video['creator']}", style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1))])),
                        const SizedBox(height: 8),
                        Text(video['caption'], style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3, shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1))]), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 24,
                    right: 12,
                    child: InteractionButtons(
                      likes: isLiked ? initialLikes + 1 : initialLikes,
                      comments: initialComments,
                      bookmarks: isBookmarked ? initialBookmarks + 1 : initialBookmarks,
                      isLiked: isLiked,
                      isBookmarked: isBookmarked,
                      onLikePressed: () {
                        setState(() { _likedVideosStatus[videoId] = !isLiked; });
                        FirebaseService.updateLikeToCloud(videoId, !isLiked);
                        
                        // [PERBAIKAN] Menambahkan parameter category yang diwajibkan oleh kompiler
                        VideoFeedController.logUserEngagement(
                          videoId: videoId, 
                          category: videoCategory,
                          actionType: !isLiked ? 'like' : 'unlike',
                        );
                      },
                      onCommentPressed: () {
                        // [PERBAIKAN] Menambahkan parameter category yang diwajibkan oleh kompiler
                        VideoFeedController.logUserEngagement(
                          videoId: videoId, 
                          category: videoCategory,
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
                        setState(() { _bookmarkedVideosStatus[videoId] = !isBookmarked; });
                        
                        // [PERBAIKAN] Menambahkan parameter category yang diwajibkan oleh kompiler
                        VideoFeedController.logUserEngagement(
                          videoId: videoId, 
                          category: videoCategory,
                          actionType: isBookmarked ? 'unbookmark' : 'bookmark',
                        );
                      },
                      onSharePressed: () {
                        // [PERBAIKAN] Menambahkan parameter category yang diwajibkan oleh kompiler
                        VideoFeedController.logUserEngagement(
                          videoId: videoId, 
                          category: videoCategory,
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
