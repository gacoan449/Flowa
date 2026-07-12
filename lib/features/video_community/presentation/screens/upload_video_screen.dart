import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowa/core/services/firebase_service.dart'; // Import jembatan layanan cloud
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

  // ALUR PROSES ASLI SEKELAS TIKTOK & DESAPAY NYATA:
  void _uploadVideoToFirebase() async {
    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih berkas video dulu dari galeri!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TAHAP 1: Unggah berkas fisik .mp4 ke Google Storage untuk mendapatkan URL internet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sedang mengompres dan mengirim video ke cloud storage...')),
      );
      
      String? videoCloudUrl = await FirebaseService.uploadVideoFileToStorage(_selectedVideoFile!);

      if (videoCloudUrl == null) {
        throw Exception("Gagal mendapatkan link URL video dari server storage.");
      }

      // TAHAP 2: Masukkan URL resmi dan teks caption ke Firestore database agar langsung muncul di FYP warga
      await FirebaseFirestore.instance.collection('flowa_videos').add({
        'creator': 'Hilwa_Kreatif', 
        'caption': _captionController.text.trim(),
        'category': _tagsController.text.trim().replaceAll('#', ''),
        'type': 'content',
        'videoUrl': videoCloudUrl, // <-- URL ASLI INTERNET RESMI SUDAH TERKUNCI DI SINI!
        'likes': 0,
        'comments': 0,
        'bookmarks': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hore! Video karya Anda resmi mengudara di Flowa!')),
      );

      setState(() {
        _selectedVideoFile = null;
        _captionController.clear();
        _tagsController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal publikasi konten: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat Konten Baru', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purple),
                SizedBox(height: 16),
                Text("Memproses berkas video ke internet...", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                Text("Mohon jangan tutup aplikasi", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickVideoFromGallery,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _selectedVideoFile == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library, size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Ketuk untuk Pilih Video', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 50, color: Colors.green),
                              SizedBox(height: 10),
                              Text('Video Siap Dipublikasikan!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text('Caption Video', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Tulis deskripsi konten video...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Hashtag Kategori Algoritma', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Contoh: #tani, #hiburan, #kuliner',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    onPressed: _uploadVideoToFirebase,
                    child: const Text('Bagikan Video Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
