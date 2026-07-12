import 'package:flutter/material.dart';

class FirebaseService {
  // 1. Fungsi Simulasi Mengambil Daftar Video & Iklan dari Firestore Cloud
  static Future<List<Map<String, dynamic>>> fetchFlowaVideosFromCloud() async {
    // Di masa depan, baris ini akan diganti dengan kueri asli:
    // FirebaseFirestore.instance.collection('videos').orderBy('createdAt').get();
    
    await Future.delayed(const Duration(seconds: 2)); // Simulasi jeda loading internet

    return [
      {
        "id": "cloud_v1", 
        "creator": "Hilwa_Kreatif", 
        "caption": "Pemandangan alam segar dari database cloud! ✨ #flowa",
        "category": "nature",
        "type": "content", 
        "videoUrl": "https://mixkit.co",
        "likes": 1250,
        "comments": 84
      },
      {
        "id": "cloud_ads_1", 
        "creator": "Sponsor_Desa", 
        "caption": "Solusi cerdas transaksi warga desa! Kirim uang tanpa admin pakai #DesaPay dan belanja hasil bumi di #PetaniDesa 🌾💳",
        "category": "ads",
        "type": "ads", // Ini slot iklan rahasia Anda yang bisa Anda ganti kapan saja di server Firebase!
        "videoUrl": "https://mixkit.co",
        "likes": 5400,
        "comments": 310
      },
    ];
  }

  // 2. Fungsi Mengirim Jumlah Like Terbaru ke Server Firebase secara Real-time
  static Future<void> updateLikeToCloud(String videoId, bool isLiked) async {
    // Di masa depan, kodenya akan mengupdate dokumen Firestore:
    // FirebaseFirestore.instance.collection('videos').doc(videoId).update({...});
    print("FIREBASE_CLOUD: Berhasil memperbarui status Like untuk video $videoId menjadi: $isLiked");
  }
}
