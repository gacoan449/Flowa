import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import baru

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance; // Instance baru

  // 1. KONEKSI ASLI: Mengambil daftar video dari Firestore Cloud
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
        };
      }).toList();
    } catch (e) {
      print("ERROR_FIREBASE_FETCH: $e");
      return [];
    }
  }

  // 2. FUNGSI SAKTI BARU: Mengunggah Berkas Fisik `.mp4` ke Gudang Cloud Firebase Storage Anda
  static Future<String?> uploadVideoFileToStorage(File videoFile) async {
    try {
      // Membuat nama file acak berdasarkan waktu unik agar tidak saling bertabrakan di server
      String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // Menunjuk lokasi penyimpanan di Cloud Storage desapay-10614
      Reference ref = _storage.ref().child(fileName);
      
      // Memulai proses pengunggahan berkas digital dari HP ke awan internet
      UploadTask uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'), // Mengunci ekstensi file sebagai video mp4 bersih
      );
      
      // Menunggu sampai berkas video selesai terunggah 100%
      TaskSnapshot snapshot = await uploadTask;
      
      // Mengambil link URL internet resmi dari video tersebut (Inilah yang nanti diputar warga)
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("ERROR_STORAGE_UPLOAD: $e");
      return null;
    }
  }

  // 3. Update jumlah Like secara real-time langsung ke dokumen dokumen di Cloud
  static Future<void> updateLikeToCloud(String videoId, bool isLiked) async {
    try {
      DocumentReference videoRef = _firestore.collection('flowa_videos').doc(videoId);
      await videoRef.update({
        'likes': isLiked ? FieldValue.increment(1) : FieldValue.increment(-1),
      });
    } catch (e) {
      print("ERROR_FIREBASE_LIKE: $e");
    }
  }
}
