import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Upload gambar publik ke Cloudinary menggunakan unsigned upload preset.
/// Jangan pernah menaruh API Secret Cloudinary di aplikasi Flutter.
class CloudinaryService {
  static const String cloudName = 'mgr0ynav';
  static const String uploadPreset = 'ml_default';

  static Future<String> uploadImage(File file, {String folder = 'flowa'}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respons Cloudinary tidak dapat dibaca.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] is Map
          ? (body['error']['message'] ?? 'Upload gambar gagal').toString()
          : 'Upload gambar gagal (${response.statusCode})';
      throw Exception(message);
    }
    final secureUrl = body['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary tidak mengembalikan URL gambar.');
    }
    return secureUrl;
  }
}
