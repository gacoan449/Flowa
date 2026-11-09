import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'cloudinary_service.dart';

class StorageService {
  Future<String> uploadProductImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Silakan login kembali.');
    return CloudinaryService.uploadImage(file, folder: 'flowa/products/${user.uid}');
  }
}
