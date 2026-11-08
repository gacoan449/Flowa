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
    final files = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    setState(() => images.addAll(files.map((x) => File(x.path))));
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty || images.isEmpty) return;
    setState(() => loading = true);
    try {
      await ProductService().createProduct(
        title: title.text.trim(),
        description: description.text.trim(),
        price: int.tryParse(price.text) ?? 0,
        images: images,
        latitude: 0,
        longitude: 0,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pasang Iklan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: pick,
            icon: const Icon(Icons.photo),
            label: Text('Pilih Foto (' + images.length.toString() + ')'),
          ),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul')),
          TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
          TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Deskripsi')),
          const SizedBox(height: 16),
          FilledButton(onPressed: loading ? null : save, child: Text(loading ? 'Mengunggah...' : 'Terbitkan')),
        ],
      ),
    );
  }
}