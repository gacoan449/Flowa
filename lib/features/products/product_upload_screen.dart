import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/location_service.dart';
import 'product_service.dart';

class ProductUploadScreen extends StatefulWidget {
  const ProductUploadScreen({super.key});

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController(text: '1');
  final brand = TextEditingController();
  final warranty = TextEditingController();
  final images = <File>[];
  bool loading = false, negotiable = false, allowDelivery = true, allowMeetup = true;
  String locationStatus = 'Lokasi GPS penjual akan disimpan saat iklan diterbitkan.';
  String category = 'Lainnya', condition = 'Baru';
  static const blue = Color(0xFF1769E8);
  static const surface = Color(0xFFF5F7FB);

  void showMessage(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pick() async {
    if (images.length >= 10) return showMessage('Maksimal 10 foto untuk satu iklan.');
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1800, maxHeight: 1800);
      if (!mounted || files.isEmpty) return;
      final remaining = 10 - images.length;
      setState(() {
        images.addAll(files.take(remaining).map((x) => File(x.path)));
      });
      if (files.length > remaining) {
        showMessage('Maksimal 10 foto. Foto selebihnya tidak ditambahkan.');
      }
    } catch (e) {
      showMessage('Gagal memilih foto: $e');
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    if (images.isEmpty) return showMessage('Tambahkan minimal satu foto produk.');
    if (!allowDelivery && !allowMeetup) return showMessage('Pilih minimal satu metode serah terima.');
    setState(() { loading = true; locationStatus = 'Mengambil lokasi GPS penjual...'; });
    try {
      final position = await LocationService().current();
      if (!mounted) return;
      setState(() => locationStatus = 'Lokasi berhasil ditemukan dan akan disimpan pada iklan ini.');
      await ProductService().createProduct(
        title: title.text,
        description: description.text,
        price: int.parse(price.text.trim()),
        images: images,
        latitude: position.latitude,
        longitude: position.longitude,
        category: category,
        brand: brand.text.trim(),
        condition: condition,
        stock: int.parse(stock.text.trim()),
        isNegotiable: negotiable,
        deliveryOptions: [if (allowDelivery) 'delivery', if (allowMeetup) 'meetup'],
        warranty: warranty.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iklan berhasil diterbitkan!')));
      Navigator.pop(context, true);
    } catch (e) {
      showMessage('Iklan gagal diterbitkan: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget section(String heading, String subtitle, IconData icon, List<Widget> children) => Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE8ECF3))),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: blue.withOpacity(.09), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: blue)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ])),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    ),
  );

  InputDecoration decoration(String label, {String? hint, String? prefix}) => InputDecoration(
    labelText: label, hintText: hint, prefixText: prefix, filled: true, fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8ECF3))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: blue, width: 1.4)),
  );

  @override
  void dispose() {
    title.dispose(); description.dispose(); price.dispose(); stock.dispose(); brand.dispose(); warranty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: surface,
    appBar: AppBar(title: const Text('Pasang Iklan', style: TextStyle(fontWeight: FontWeight.w700))),
    body: Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 110), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1769E8), Color(0xFF4B91F5)]), borderRadius: BorderRadius.circular(18)),
          child: const Row(children: [
            Icon(Icons.storefront_rounded, color: Colors.white, size: 34), SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Jual lebih mudah di Flowa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: 4),
              Text('Buat iklan yang jelas agar calon pembeli lebih percaya.', style: TextStyle(color: Colors.white, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 14),
        section('Foto produk', 'Tambahkan hingga 10 foto. Foto pertama menjadi sampul.', Icons.photo_library_outlined, [
          InkWell(
            onTap: loading ? null : pick,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF5F8FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFB8D0FA))),
              child: const Column(children: [
                Icon(Icons.add_photo_alternate_outlined, color: blue, size: 34), SizedBox(height: 7),
                Text('Tambah foto produk', style: TextStyle(color: blue, fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Gunakan foto terang dan tampilkan kondisi sebenarnya', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(height: 112, child: ListView.separated(
              scrollDirection: Axis.horizontal, itemCount: images.length, separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) => Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(images[index], width: 104, height: 104, fit: BoxFit.cover)),
                if (index == 0) Positioned(left: 5, bottom: 5, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Sampul', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                )),
                Positioned(right: 3, top: 3, child: InkWell(
                  onTap: loading ? null : () => setState(() => images.removeAt(index)),
                  child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 15)),
                )),
              ]),
            )),
          ],
          Align(alignment: Alignment.centerRight, child: Text('${images.length}/10 foto', style: const TextStyle(fontSize: 11, color: Colors.black54))),
        ]),
        section('Informasi produk', 'Tulis detail yang mudah dipahami pembeli.', Icons.inventory_2_outlined, [
          TextFormField(controller: title, textCapitalization: TextCapitalization.sentences, decoration: decoration('Nama produk *', hint: 'Contoh: Sepeda lipat 20 inci'),
            validator: (v) => v == null || v.trim().length < 3 ? 'Nama produk minimal 3 karakter.' : null),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('categories').where('active', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              final options = (snapshot.data?.docs ?? []).map((doc) => (doc.data()['name'] ?? '').toString()).where((v) => v.isNotEmpty).toSet().toList();
              if (!options.contains('Lainnya')) options.add('Lainnya');
              final selected = options.contains(category) ? category : options.first;
              return DropdownButtonFormField<String>(
                value: selected, decoration: decoration('Kategori *'),
                items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: loading ? null : (v) { if (v != null) setState(() => category = v); },
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(controller: brand, textCapitalization: TextCapitalization.words, decoration: decoration('Merek / brand', hint: 'Contoh: Samsung, Polygon, atau tanpa merek')),
          const SizedBox(height: 12),
          const Text('Kondisi barang', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: ['Baru', 'Bekas - seperti baru', 'Bekas - kondisi baik', 'Perlu perbaikan'].map((v) => ChoiceChip(
            label: Text(v), selected: condition == v, onSelected: loading ? null : (_) => setState(() => condition = v), selectedColor: const Color(0xFFDCE9FF),
          )).toList()),
          const SizedBox(height: 12),
          TextFormField(controller: description, minLines: 4, maxLines: 7, maxLength: 2000, textCapitalization: TextCapitalization.sentences,
            decoration: decoration('Deskripsi produk', hint: 'Jelaskan spesifikasi, ukuran, kelengkapan, kekurangan, dan alasan dijual.')),
        ]),
        section('Harga & stok', 'Atur harga yang jelas dan jumlah barang tersedia.', Icons.sell_outlined, [
          TextFormField(controller: price, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: decoration('Harga jual *', prefix: 'Rp '),
            validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n <= 0 ? 'Masukkan harga lebih dari Rp0.' : null; }),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero,
            title: const Text('Harga masih bisa dinegosiasikan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Pembeli dapat mengajukan penawaran harga.', style: TextStyle(fontSize: 11)),
            value: negotiable, onChanged: loading ? null : (v) => setState(() => negotiable = v)),
          const Divider(height: 12),
          TextFormField(controller: stock, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: decoration('Jumlah stok *', hint: '1'),
            validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 1 ? 'Stok minimal 1.' : null; }),
          const SizedBox(height: 10),
          TextFormField(controller: warranty, decoration: decoration('Garansi (opsional)', hint: 'Contoh: Garansi toko 7 hari / tidak ada')),
        ]),
        section('Pengiriman & lokasi', 'Tentukan cara pembeli menerima barang.', Icons.local_shipping_outlined, [
          CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Bisa dikirim', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Atur ongkir dan kurir melalui kesepakatan dengan pembeli.', style: TextStyle(fontSize: 11)),
            value: allowDelivery, onChanged: loading ? null : (v) => setState(() => allowDelivery = v ?? false), controlAffinity: ListTileControlAffinity.leading),
          CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Bisa ambil / COD langsung', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Pembeli dan penjual menentukan titik temu bersama.', style: TextStyle(fontSize: 11)),
            value: allowMeetup, onChanged: loading ? null : (v) => setState(() => allowMeetup = v ?? false), controlAffinity: ListTileControlAffinity.leading),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_outlined, color: blue), const SizedBox(width: 9),
              Expanded(child: Text('$locationStatus Koordinat awal iklan disimpan sebagai perkiraan lokasi penjual dan tidak berubah saat pembeli berpindah tempat.', style: const TextStyle(fontSize: 12))),
            ])),
        ]),
        Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(13)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.verified_user_outlined, color: Color(0xFFB7791F), size: 20), SizedBox(width: 9),
            Expanded(child: Text('Pastikan foto, harga, dan kondisi barang sesuai kenyataan. Jangan cantumkan nomor pribadi atau informasi sensitif di deskripsi.', style: TextStyle(fontSize: 12))),
          ])),
      ]),
    ),
    bottomNavigationBar: SafeArea(minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12), child: FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: blue, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      onPressed: loading ? null : save,
      icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.publish_rounded),
      label: Text(loading ? 'Mengunggah iklan...' : 'Terbitkan iklan', style: const TextStyle(fontWeight: FontWeight.w700)),
    )),
  );
}
