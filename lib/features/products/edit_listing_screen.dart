import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditListingScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const EditListingScreen({super.key, required this.id, required this.data});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late final TextEditingController title;
  late final TextEditingController description;
  late final TextEditingController price;
  late String status;
  late List<String> urls;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.data['title'] ?? '');
    description = TextEditingController(text: widget.data['description'] ?? '');
    price = TextEditingController(text: (widget.data['price'] ?? 0).toString());
    status = widget.data['status'] ?? 'active';
    urls = List<String>.from(widget.data['imageUrls'] ?? []);
  }

  Future<void> addPhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Silakan login kembali.');
      final files = await ImagePicker().pickMultiImage(imageQuality: 85);
      for (final file in files) {
        final ref = FirebaseStorage.instance.ref(
          'product_images/${user.uid}/${widget.id}/edit_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        await ref.putFile(
          File(file.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await ref.getDownloadURL());
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan foto: $e')),
        );
      }
    }
  }

  Future<void> save() async {
    final parsedPrice = int.tryParse(price.text.trim());
    if (title.text.trim().isEmpty || parsedPrice == null || parsedPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa judul dan harga iklan.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.id).update({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'price': parsedPrice,
        'imageUrls': urls,
        'imageUrl': urls.isEmpty ? '' : urls.first,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Iklan')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...urls.map((url) => Stack(
                      children: [
                        Image.network(
                          url,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 90, height: 90, child: Icon(Icons.broken_image)),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            onPressed: () => setState(() => urls.remove(url)),
                            icon: const CircleAvatar(
                              radius: 12,
                              child: Icon(Icons.close, size: 14),
                            ),
                          ),
                        ),
                      ],
                    )),
                OutlinedButton.icon(
                  onPressed: saving ? null : addPhoto,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Tambah Foto'),
                ),
              ],
            ),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul')),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            TextField(
              controller: description,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                DropdownMenuItem(value: 'sold', child: Text('Terjual')),
                DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
              ],
              onChanged: saving ? null : (value) => setState(() => status = value ?? 'active'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Menyimpan...' : 'Simpan Perubahan'),
            ),
          ],
        ),
      );
}
