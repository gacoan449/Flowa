import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Unsigned Cloudinary uploads. API Secret must never be embedded in the app.
class CloudinaryService {
  static const String cloudName = 'mgr0ynav';
  static const String uploadPreset = 'ml_default';

  static Future<String> uploadImage(File file, {String folder = 'flowa'}) {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    return _upload(file, uri, folder);
  }

  static Future<String> uploadImageBytes(List<int> bytes, String filename, {String folder = 'flowa'}) {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    return _uploadBytes(bytes, filename, uri, folder);
  }

  static Future<String> _uploadBytes(List<int> bytes, String filename, Uri uri, String folder) async {
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respons Cloudinary tidak dapat dibaca.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] is Map
          ? (body['error']['message'] ?? 'Upload Cloudinary gagal').toString()
          : 'Upload Cloudinary gagal (${response.statusCode})';
      throw Exception(message);
    }
    final secureUrl = body['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) throw Exception('Cloudinary tidak mengembalikan URL file.');
    return secureUrl;
  }

  static Future<String> uploadAudio(File file, {String folder = 'flowa/chat/audio'}) {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');
    return _upload(file, uri, folder);
  }

  static Future<String> _upload(File file, Uri uri, String folder) async {
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respons Cloudinary tidak dapat dibaca.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] is Map
          ? (body['error']['message'] ?? 'Upload Cloudinary gagal').toString()
          : 'Upload Cloudinary gagal (${response.statusCode})';
      throw Exception(message);
    }
    final secureUrl = body['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary tidak mengembalikan URL file.');
    }
    return secureUrl;
  }
}
