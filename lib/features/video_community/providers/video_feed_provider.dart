import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class VideoFeedController {
  // Memblokir instansiasi kelas (Private Constructor) karena kelas ini murni utilitas statis.
  // Ini menghemat alokasi memori di background.
  VideoFeedController._();

  /// Fungsi untuk menambah atau mengurangi jumlah Like secara real-time
  /// Menggunakan pendekatan Immutability (pembuatan objek baru) agar State Management (Provider) mendeteksi perubahan dengan akurat.
  static Map<String, dynamic> handleLikeAction({
    required Map<String, dynamic> videoData,
    required bool isCurrentlyLiked,
  }) {
    try {
      // Defensive Programming: Mengamankan tipe data dan mencegah nilai null (Null Safety)
      final currentLikes = (videoData['likes'] as num?)?.toInt() ?? 0;
      
      return {
        ...videoData,
        // Logika validasi ekstra: Mencegah bug fatal di mana jumlah like menjadi minus (kurang dari 0)
        'likes': isCurrentlyLiked 
            ? (currentLikes > 0 ? currentLikes - 1 : 0) 
            : currentLikes + 1,
      };
    } catch (e, stackTrace) {
      // Menangkap error secara internal tanpa membuat aplikasi crash (merusak pengalaman pengguna)
      developer.log(
        'CRITICAL ERROR: Gagal memproses Like',
        name: 'VideoFeedController',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback: Mengembalikan data asli jika terjadi kegagalan sistem
      return videoData;
    }
  }

  /// Fungsi untuk mencatat aktivitas durasi tonton pengguna demi Algoritma Rekomendasi
  static void logUserEngagement({
    required String videoId,
    required String category,
    required String actionType,
  }) {
    try {
      // TODO: Titik injeksi untuk API Node.js / Firebase Analytics di masa depan
      
      // Menggunakan pustaka dart:developer untuk log, bukan print() biasa.
      developer.log(
        'Action: $actionType | Video: $videoId | Category: $category',
        name: 'ALGORITMA_TRACKING',
      );
    } catch (e) {
      debugPrint('Gagal mencatat engagement log: $e');
    }
  }
}
