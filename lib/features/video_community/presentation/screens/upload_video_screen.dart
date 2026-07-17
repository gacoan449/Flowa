import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowa/core/services/firebase_service.dart';
import 'dart:io';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideoFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    
    if (video != null) {
      setState(() {
        _selectedVideoFile = File(video.path);
      });
    }
  }

  void _uploadVideoToFirebase() async {
    if (_selectedVideoFile == null) {
      _showSnackBar('Pilih video terlebih dahulu!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? videoCloudUrl = await FirebaseService.uploadVideoFileToStorage(_selectedVideoFile!);

      if (videoCloudUrl == null) throw Exception("Upload gagal ke Storage.");

      await FirebaseFirestore.instance.collection('flowa_videos').add({
        'creator': 'Hilwa_Kreatif', 
        'caption': _captionController.text.trim(),
        'category': _tagsController.text.trim().replaceAll('#', ''),
        'type': 'content',
        'videoUrl': videoCloudUrl,
        'likes': 0,
        'comments': 0,
        'bookmarks': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnackBar('Video berhasil tayang di Flowa!');

      setState(() {
        _selectedVideoFile = null;
        _captionController.clear();
        _tagsController.clear();
      });
    } catch (e) {
      _showSnackBar('Gagal publikasi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.purple,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Studio Kreator', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.purple),
                const SizedBox(height: 16),
                Text("Mengunggah ke Cloud...", style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoPickerArea(),
                const SizedBox(height: 30),
                _buildTextField(_captionController, 'Deskripsi Konten', 'Ceritakan video Anda...'),
                const SizedBox(height: 20),
                _buildTextField(_tagsController, 'Hashtag (#tani, #desa)', 'Contoh: #hiburan'),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _uploadVideoToFirebase,
                    child: const Text('Publikasikan Sekarang', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildVideoPickerArea() => GestureDetector(
        onTap: _pickVideoFromGallery,
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _selectedVideoFile == null ? Colors.grey[300]! : Colors.green),
          ),
          child: _selectedVideoFile == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Pilih Video dari Galeri', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.check_circle_rounded, size: 60, color: Colors.green),
                  SizedBox(height: 10),
                  Text('Video Siap!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ]),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String label, String hint) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple)),
            ),
          ),
        ],
      );
}
