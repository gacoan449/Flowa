import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> pick() async {
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      setState(() => images.addAll(files.map((x) => File(x.path))));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> save() async {
    final parsedPrice = int.tryParse(price.text.trim());
    if (title.text.trim().isEmpty) {
      _show('Judul produk wajib diisi.');
      return;
    }
    if (parsedPrice == null || parsedPrice < 0) {
      _show('Masukkan harga berupa angka yang valid.');
      return;
    }
    if (images.isEmpty) {
      _show('Pilih minimal satu foto produk.');
      return;
    }
    setState(() => loading = true);
    try {
      await ProductService().createProduct(
        title: title.text,
        description: description.text,
        price: parsedPrice,
        images: images,
        latitude: 0,
        longitude: 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iklan berhasil diterbitkan. Buka Iklan Saya untuk melihatnya.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _show('Produk gagal diterbitkan: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
                  children: images
                      .map((file) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.file(file, width: 100, fit: BoxFit.cover),
                          ))
                      .toList(),
                ),
              ),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Judul produk *'),
            ),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga (Rp) *'),
            ),
            TextField(
              controller: description,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : save,
              child: Text(loading ? 'Mengunggah...' : 'Terbitkan'),
            ),
          ],
        ),
      );
}
