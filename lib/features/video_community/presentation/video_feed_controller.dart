import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class VideoFeedController {
  // Private constructor agar kelas ini tidak bisa di-instance (Singleton Pattern)
  VideoFeedController._();

  static Map<String, dynamic> handleLikeAction({
    required Map<String, dynamic> videoData,
    required bool isCurrentlyLiked,
  }) {
    try {
      final currentLikes = (videoData['likes'] as num?)?.toInt() ?? 0;
      return {
        ...videoData,
        'likes': isCurrentlyLiked ? (currentLikes > 0 ? currentLikes - 1 : 0) : currentLikes + 1,
      };
    } catch (e) {
      debugPrint('Error memproses Like: $e');
      return videoData;
    }
  }

  static void logUserEngagement({
    required String videoId,
    required String actionType,
  }) {
    developer.log('Action: $actionType | Video: $videoId', name: 'FLOWA_ENGAGEMENT');
  }
}
