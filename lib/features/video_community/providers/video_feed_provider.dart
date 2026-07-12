import 'package:flutter/material.dart';

class VideoFeedController {
  // Fungsi untuk menambah atau mengurangi jumlah Like secara real-time
  static Map<String, dynamic> handleLikeAction({
    required Map<String, dynamic> videoData,
    required bool isCurrentlyLiked,
  }) {
    final currentLikes = videoData['likes'] as int;
    
    return {
      ...videoData,
      'likes': isCurrentlyLiked ? currentLikes - 1 : currentLikes + 1,
    };
  }

  // Fungsi untuk mencatat aktivitas durasi tonton pengguna demi Algoritma Rekomendasi
  static void logUserEngagement({
    required String videoId,
    required String category,
    required String actionType, // 'watch_completed', 'share', 'comment'
  }) {
    // Di sini nanti kode disambungkan ke Firebase / API Node.js Anda
    // Mengirimkan data: ID User + Kategori Video + Jenis Aksi
    print("ALGORITMA_TRACKING: User melakukan $actionType pada video $videoId (Kategori: $category)");
  }
}
