import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/location_service.dart';
import 'product_service.dart';

class ProductUploadScreen extends StatefulWidget {
  const ProductUploadScreen({super.key});

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final images = <File>[];
  bool loading = false;
  String locationStatus = 'GPS penjual akan diambil saat iklan diterbitkan.';
  String category = 'Lainnya';

  Future<void> pick() async {
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      setState(() => images.addAll(files.map((x) => File(x.path))));
    } catch (e) {
      if (mounted) _show('Gagal memilih foto: $e');
    }
  }

  Future<void> save() async {
    final parsedPrice = int.tryParse(price.text.trim());
    if (title.text.trim().isEmpty) return _show('Judul produk wajib diisi.');
    if (parsedPrice == null || parsedPrice < 0) return _show('Masukkan harga yang valid.');
    if (images.isEmpty) return _show('Pilih minimal satu foto produk.');

    setState(() {
      loading = true;
      locationStatus = 'Mengambil lokasi GPS penjual...';
    });
    try {
      // Koordinat diambil sekali ketika iklan dibuat; proses edit tidak mengubahnya.
      final position = await LocationService().current();
      if (!mounted) return;
      setState(() => locationStatus = 'GPS ditemukan. Lokasi awal iklan akan disimpan.');
      await ProductService().createProduct(
        title: title.text,
        description: description.text,
        price: parsedPrice,
        images: images,
        latitude: position.latitude,
        longitude: position.longitude,
        category: category,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iklan berhasil diterbitkan dengan lokasi GPS.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _show('Produk gagal diterbitkan: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        appBar: AppBar(title: const Text('Pasang Iklan')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: loading ? null : pick,
              icon: const Icon(Icons.photo),
              label: Text('Pilih Foto (${images.length})'),
            ),
            if (images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: images.map((file) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.file(file, width: 100, fit: BoxFit.cover),
                  )).toList(),
                ),
              ),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul produk *')),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga (Rp) *'),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('categories')
                  .where('active', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                final options = (snapshot.data?.docs ?? [])
                    .map((doc) => (doc.data()['name'] ?? '').toString())
                    .where((name) => name.isNotEmpty)
                    .toSet()
                    .toList();
                if (!options.contains('Lainnya')) options.add('Lainnya');
                final selected = options.contains(category) ? category : options.first;
                return DropdownButtonFormField<String>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Kategori produk'),
                  items: options.map((name) => DropdownMenuItem(
                    value: name, child: Text(name),
                  )).toList(),
                  onChanged: loading ? null : (value) {
                    if (value != null) setState(() => category = value);
                  },
                );
              },
            ),
            TextField(
              controller: description,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF1769E8)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$locationStatus Koordinat disimpan sebagai lokasi perkiraan untuk menjaga privasi alamat penjual.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : save,
              child: Text(loading ? 'Mengambil GPS & mengunggah...' : 'Terbitkan'),
            ),
          ],
        ),
      );
}
