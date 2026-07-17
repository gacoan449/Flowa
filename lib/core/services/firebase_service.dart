import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // [UPGRADE] Menggunakan debugPrint

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. KONEKSI ASLI: Mengambil daftar video (diurutkan berdasarkan waktu)
  static Future<List<Map<String, dynamic>>> fetchFlowaVideosFromCloud() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('flowa_videos')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "creator": data['creator'] ?? 'Kreator Flowa',
          "caption": data['caption'] ?? '',
          "category": data['category'] ?? 'general',
          "type": data['type'] ?? 'content', 
          "videoUrl": data['videoUrl'] ?? '',
          "likes": data['likes'] ?? 0,
          "comments": data['comments'] ?? 0,
          "bookmarks": data['bookmarks'] ?? 0,
          "isSponsored": data['isSponsored'] ?? false, // [UPGRADE] Flag Iklan
        };
      }).toList();
    } catch (e) {
      debugPrint("ERROR_FIREBASE_FETCH: $e");
      return [];
    }
  }

  // 2. FUNGSI SAKTI: Unggah Berkas Fisik `.mp4`
  static Future<String?> uploadVideoFileToStorage(File videoFile) async {
    try {
      String fileName = 'videos/${_auth.currentUser?.uid ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("ERROR_STORAGE_UPLOAD: $e");
      return null;
    }
  }

  // 3. FUNGSI MONETISASI: Kreator bisa mengajukan Iklan
  // [UPGRADE] Admin bisa menyetujui video menjadi 'Sponsored'
  static Future<void> markVideoAsSponsored(String videoId, bool isSponsored) async {
    try {
      await _firestore.collection('flowa_videos').doc(videoId).update({
        'isSponsored': isSponsored,
        'type': isSponsored ? 'ads' : 'content',
      });
    } catch (e) {
      debugPrint("ERROR_ADS_MONETIZE: $e");
    }
  }

  // 4. Update jumlah Like real-time
  static Future<void> updateLikeToCloud(String videoId, bool isLiked) async {
    try {
      await _firestore.collection('flowa_videos').doc(videoId).update({
        'likes': isLiked ? FieldValue.increment(1) : FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint("ERROR_FIREBASE_LIKE: $e");
    }
  }
}
