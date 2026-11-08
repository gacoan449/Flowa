import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<String>> uploadImages(List<File> files, String id) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sesi login berakhir. Silakan login kembali.');
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = FirebaseStorage.instance
          .ref('product_images/${user.uid}/$id/$i.jpg');
      await ref.putFile(
        files[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> createProduct({
    required String title,
    required String description,
    required int price,
    required List<File> images,
    required double latitude,
    required double longitude,
    String category = 'Lainnya',
    String locationName = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sesi login berakhir. Silakan login kembali.');
    if (title.trim().isEmpty) throw ArgumentError('Judul produk wajib diisi.');
    if (price < 0) throw ArgumentError('Harga tidak boleh negatif.');

    final ref = _db.collection('products').doc();
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final urls = await uploadImages(images, ref.id);
    try {
      await ref.set({
        'sellerId': user.uid,
        'sellerName': userDoc.data()?['name'] ??
            user.displayName ??
            user.email ??
            'Pengguna Flowa',
        'title': title.trim(),
        'description': description.trim(),
        'price': price,
        'imageUrl': urls.isEmpty ? '' : urls.first,
        'imageUrls': urls,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'category': category,
        'status': 'active',
        'reportCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 30));
    } catch (_) {
      for (final url in urls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> deleteProduct(String id, List<dynamic> urls) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Silakan login kembali.');
    final ref = _db.collection('products').doc(id);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?['sellerId'] != user.uid) {
      throw StateError('Iklan tidak ditemukan atau bukan milik akun ini.');
    }
    await ref.delete();
    for (final url in urls) {
      try {
        await FirebaseStorage.instance.refFromURL(url.toString()).delete();
      } catch (_) {}
    }
  }

  Future<void> report(String id, String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Silakan login kembali.');
    await _db.collection('reports').add({
      'productId': id,
      'reason': reason,
      'reporterId': user.uid,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('products').doc(id).update({
      'reportCount': FieldValue.increment(1),
    });
  }
}
