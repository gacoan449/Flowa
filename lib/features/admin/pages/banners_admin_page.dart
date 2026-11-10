import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_service.dart';

class BannersAdminPage extends StatefulWidget {
  const BannersAdminPage({super.key});

  @override
  State<BannersAdminPage> createState() => _BannersAdminPageState();
}

class _BannersAdminPageState extends State<BannersAdminPage> {
  final _db = FirebaseFirestore.instance;
  bool _uploading = false;

  Future<void> _addBanner() async {
    final title = TextEditingController();
    final picked = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Banner baru'),
        content: TextField(
          controller: title,
          decoration: const InputDecoration(
            labelText: 'Judul promo',
            hintText: 'Contoh: Promo akhir pekan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Pilih gambar'),
          ),
        ],
      ),
    );
    if (picked != true || title.text.trim().isEmpty) {
      title.dispose();
      return;
    }
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1800,
        maxHeight: 1000,
      );
      if (image == null) return;
      setState(() => _uploading = true);
      final url = await CloudinaryService.uploadImage(
        File(image.path),
        folder: 'flowa/banners',
      );
      await _db.collection('banners').add({
        'title': title.text.trim(),
        'imageUrl': url,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner berhasil diterbitkan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat banner: $e')),
        );
      }
    } finally {
      title.dispose();
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editBanner(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    final title = TextEditingController(text: (data['title'] ?? '').toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit banner'),
        content: TextField(
          controller: title,
          decoration: const InputDecoration(labelText: 'Judul promo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == true && title.text.trim().isNotEmpty) {
      try {
        await ref.update({
          'title': title.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengubah banner: $e')),
          );
        }
      }
    }
    title.dispose();
  }

  Future<void> _deleteBanner(DocumentReference<Map<String, dynamic>> ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus banner?'),
        content: const Text('Banner akan dihapus dari tampilan beranda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes == true) await ref.delete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Banner & Promo')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _uploading ? null : _addBanner,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(_uploading ? 'Mengunggah...' : 'Tambah banner'),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('banners').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat banner: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('Belum ada banner. Tambahkan promo pertama.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final active = data['active'] == true;
                final image = (data['imageUrl'] ?? '').toString();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (image.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              image,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(height: 80, child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text((data['title'] ?? 'Banner').toString()),
                          subtitle: Text(active ? 'Tayang di beranda' : 'Disembunyikan'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _editBanner(doc.reference, data);
                              if (value == 'delete') _deleteBanner(doc.reference);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit judul')),
                              PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tampilkan di beranda'),
                          value: active,
                          onChanged: (value) => doc.reference.update({
                            'active': value,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
