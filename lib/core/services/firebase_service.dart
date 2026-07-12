import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  // Instance resmi untuk memicu koneksi ke Cloud Firestore dan Auth Anda
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. KONEKSI ASLI: Mengambil daftar video langsung dari Cloud Firestore desapay-10614
  static Future<List<Map<String, dynamic>>> fetchFlowaVideosFromCloud() async {
    try {
      // Mengambil data dari koleksi bernama 'flowa_videos' di database Anda
      // Diurutkan berdasarkan waktu unggah terbaru
      QuerySnapshot snapshot = await _firestore
          .collection('flowa_videos')
          .orderBy('createdAt', descending: true)
          .get();

      // Mengubah dokumen-dokumen di Firebase menjadi bentuk list data Flutter
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "creator": data['creator'] ?? 'Kreator Flowa',
          "caption": data['caption'] ?? '',
          "category": data['category'] ?? 'general',
          "type": data['type'] ?? 'content', // 'content' atau 'ads' (iklan Anda)
          "videoUrl": data['videoUrl'] ?? '',
          "likes": data['likes'] ?? 0,
          "comments": data['comments'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print("ERROR_FIREBASE_FETCH: $e");
      return []; // Mengembalikan list kosong jika koneksi internet terputus
    }
  }

  // 2. KONEKSI ASLI: Update jumlah Like secara real-time langsung ke dokumen dokumen di Cloud
  static Future<void> updateLikeToCloud(String videoId, bool isLiked) async {
    try {
      DocumentReference videoRef = _firestore.collection('flowa_videos').doc(videoId);
      
      // Menggunakan FieldValue.increment agar hitungan angka presisi di server awan
      await videoRef.update({
        'likes': isLiked ? FieldValue.increment(1) : FieldValue.increment(-1),
      });
      print("FIREBASE_SUCCESS: Berhasil sync data like untuk ID: $videoId");
    } catch (e) {
      print("ERROR_FIREBASE_LIKE: $e");
    }
  }

  // 3. KONEKSI ASLI: Mengirim komentar baru dari pop-up sheet ke database cloud
  static Future<void> uploadCommentToCloud(String videoId, String commentText) async {
    try {
      final currentUser = _auth.currentUser;
      String username = currentUser?.displayName ?? "Warga Desa";

      await _firestore
          .collection('flowa_videos')
          .doc(videoId)
          .collection('comments')
          .add({
            'user': username,
            'text': commentText,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
      // Tambah jumlah hitungan komentar di dokumen utama video
      await _firestore.collection('flowa_videos').doc(videoId).update({
        'comments': FieldValue.increment(1),
      });
    } catch (e) {
      print("ERROR_FIREBASE_COMMENT: $e");
    }
  }
}
