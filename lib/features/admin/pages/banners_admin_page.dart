import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_service.dart';

class BannersAdminPage extends StatelessWidget {
  const BannersAdminPage({super.key});

  Future<void> upload(BuildContext context) async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1800,
        maxHeight: 1000,
      );
      if (x == null) return;
      final url = await CloudinaryService.uploadImage(File(x.path), folder: 'flowa/banners');
      await FirebaseFirestore.instance.collection('banners').add({
        'title': 'Promo',
        'imageUrl': url,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner berhasil diunggah.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah banner: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Banner & Promo')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => upload(context),
      child: const Icon(Icons.add_photo_alternate),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Gagal memuat banner.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            return ListTile(
              leading: (data['imageUrl'] ?? '').toString().isEmpty
                ? const Icon(Icons.image)
                : Image.network(data['imageUrl'].toString(), width: 56, height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
              title: Text(data['title'] ?? 'Banner'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => doc.reference.delete(),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}
