import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../chat/chat_profile_service.dart';
import '../chat/chat_screen.dart';
import 'product_service.dart';
import 'seller_store_screen.dart';
import '../orders/order_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  static const _blue = Color(0xFF1769E8);
  static const _ink = Color(0xFF17243A);

  String _rupiah(dynamic value) {
    final amount = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    final digits = amount.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return 'Rp $out';
  }

  Future<void> _placeOrder(BuildContext context, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login dahulu untuk membuat pesanan.')));
      return;
    }
    final rawOptions = product['deliveryOptions'];
    final options = rawOptions is List
        ? rawOptions.map((e) => e.toString()).where((e) => ['delivery','meetup'].contains(e)).toList()
        : <String>['delivery','meetup'];
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penjual belum mengatur metode serah terima.')));
      return;
    }
    final quantityController = TextEditingController(text: '1');
    final addressController = TextEditingController();
    final noteController = TextEditingController();
    String delivery = options.first;
    String payment = 'cod';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Buat Pesanan'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Stok tersedia: ${product['stock'] ?? 1}'),
          const SizedBox(height: 12),
          TextField(controller: quantityController, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Jumlah barang')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: delivery,
            decoration: const InputDecoration(labelText: 'Metode serah terima'),
            items: [
              if (options.contains('delivery')) const DropdownMenuItem(value: 'delivery', child: Text('Pengiriman')),
              if (options.contains('meetup')) const DropdownMenuItem(value: 'meetup', child: Text('Temu langsung')),
            ],
            onChanged: (v) => setDialogState(() => delivery = v ?? delivery),
          ),
          if (delivery == 'delivery') ...[
            const SizedBox(height: 10),
            TextField(controller: addressController, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Alamat lengkap penerima')),
          ],
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: payment,
            decoration: const InputDecoration(labelText: 'Metode pembayaran'),
            items: const [
              DropdownMenuItem(value: 'cod', child: Text('COD / Bayar saat serah terima')),
              DropdownMenuItem(value: 'wallet', child: Text('Saldo Flowa')),
            ],
            onChanged: (v) => setDialogState(() => payment = v ?? 'cod'),
          ),
          const SizedBox(height: 10),
          TextField(controller: noteController, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Catatan untuk penjual (opsional)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Konfirmasi')),
        ],
      )),
    );
    if (confirmed != true) {
      quantityController.dispose(); addressController.dispose(); noteController.dispose();
      return;
    }
    try {
      final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
      final result = await OrderService().createOrder(
        productId: productId,
        quantity: quantity,
        paymentMethod: payment,
        deliveryMethod: delivery,
        deliveryAddress: addressController.text.trim(),
        note: noteController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dibuat • ID ${result['orderId']}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan gagal dibuat: $e')));
      }
    } finally {
      quantityController.dispose(); addressController.dispose(); noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').doc(productId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Produk gagal dimuat. Periksa koneksi internet.')));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final product = snapshot.data!.data();
        if (product == null || product['status'] == 'deleted') {
          return const Scaffold(body: Center(child: Text('Iklan tidak ditemukan atau sudah dihapus.')));
        }

        final title = (product['title'] ?? 'Produk Flowa').toString();
        final sellerId = (product['sellerId'] ?? '').toString();
        final sellerName = (product['sellerName'] ?? 'Penjual Flowa').toString();
        final rawImages = product['imageUrls'];
        final images = <String>[];
        if (rawImages is List) {
          images.addAll(rawImages.whereType<String>().where((e) => e.trim().isNotEmpty));
        }
        final mainImage = (product['imageUrl'] ?? '').toString();
        if (images.isEmpty && mainImage.isNotEmpty) images.add(mainImage);
        final location = (product['locationName'] ?? '').toString().trim();
        final category = (product['category'] ?? 'Produk').toString();
        final price = _rupiah(product['price']);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Detail Iklan', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            iconTheme: const IconThemeData(color: _ink),
            actions: [
              if (user != null)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid)
                      .collection('favorites').doc(productId).snapshots(),
                  builder: (context, favorite) {
                    final saved = favorite.data?.exists == true;
                    return IconButton(
                      tooltip: saved ? 'Hapus dari favorit' : 'Simpan ke favorit',
                      icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: saved ? Colors.red : _ink, size: 27),
                      onPressed: () async {
                        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid)
                            .collection('favorites').doc(productId);
                        try {
                          if (saved) {
                            await ref.delete();
                          } else {
                            await ref.set({
                              'productId': productId,
                              'title': title,
                              'price': product['price'],
                              'imageUrl': mainImage,
                              'sellerId': sellerId,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Favorit gagal diperbarui. Coba lagi.')),
                            );
                          }
                        }
                      },
                    );
                  },
                )
              else
                IconButton(
                  tooltip: 'Login untuk menyimpan',
                  icon: const Icon(Icons.favorite_border_rounded, color: _ink),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Silakan login untuk menyimpan produk favorit.')),
                  ),
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              _Gallery(images: images),
              const SizedBox(height: 17),
              Text(title, style: const TextStyle(fontSize: 23, height: 1.2, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 5),
              Text(price, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _blue)),
              const SizedBox(height: 15),
              _InfoCard(
                icon: Icons.location_on_rounded,
                title: 'Lokasi',
                value: location.isEmpty ? 'Lokasi belum dicantumkan' : location,
                trailingIcon: Icons.category_outlined,
                trailingTitle: 'Kategori',
                trailingValue: category,
              ),
              const SizedBox(height: 13),
              _SellerCard(
                sellerId: sellerId,
                sellerName: sellerName,
                onVisit: sellerId.isEmpty ? null : () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SellerStoreScreen(sellerId: sellerId, fallbackName: sellerName),
                  ));
                },
              ),
              const SizedBox(height: 20),
              const Text('Deskripsi Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 8),
              Text(
                (product['description'] ?? 'Penjual belum menambahkan deskripsi.').toString(),
                style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF344256)),
              ),
              if (images.length > 1) ...[
                const SizedBox(height: 22),
                const Text('Foto Produk', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 105,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(images[index], width: 120, height: 105, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 120, color: Colors.white,
                          child: const Icon(Icons.broken_image_outlined))),
                    ),
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(color: Color(0x140D1B32), blurRadius: 15, offset: Offset(0, -4)),
              ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF596579),
                      side: const BorderSide(color: Color(0xFFDCE2EA)),
                      backgroundColor: const Color(0xFFF2F4F7),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Silakan login untuk melaporkan iklan.')),
                        );
                        return;
                      }
                      final reason = await showDialog<String>(
                        context: context,
                        builder: (dialogContext) {
                          String selected = 'Informasi produk menyesatkan';
                          return AlertDialog(
                            title: const Text('Laporkan Iklan'),
                            content: StatefulBuilder(builder: (context, setDialogState) => DropdownButtonFormField<String>(
                              value: selected,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Informasi produk menyesatkan', child: Text('Informasi menyesatkan')),
                                DropdownMenuItem(value: 'Produk dilarang', child: Text('Produk dilarang')),
                                DropdownMenuItem(value: 'Penipuan atau spam', child: Text('Penipuan atau spam')),
                                DropdownMenuItem(value: 'Foto atau deskripsi tidak sesuai', child: Text('Foto/deskripsi tidak sesuai')),
                              ],
                              onChanged: (value) { if (value != null) setDialogState(() => selected = value); },
                            )),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                              FilledButton(onPressed: () => Navigator.pop(dialogContext, selected), child: const Text('Kirim')),
                            ],
                          );
                        },
                      );
                      if (reason == null) return;
                      try {
                        await ProductService().report(productId, reason);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Terima kasih. Laporan sudah dikirim ke admin Flowa.')),
                        );
                      } catch (_) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Laporan gagal dikirim. Coba lagi.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.flag_rounded, size: 18),
                    label: const FittedBox(child: Text('Laporkan Iklan')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Silakan login untuk chat penjual.')),
                        );
                      } else if (sellerId.isEmpty || sellerId == user.uid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kamu tidak dapat menghubungi diri sendiri melalui iklan ini.')),
                        );
                      } else {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            sellerId: sellerId,
                            sellerName: sellerName,
                            productId: productId,
                            productTitle: title,
                          ),
                        ));
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: const FittedBox(child: Text('Chat Penjual')),
                  ),
                ),
              ]),
              const SizedBox(height: 9),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: user == null || sellerId == user.uid ? null : () => _placeOrder(context, product),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Beli / Buat Pesanan'),
              )),
            ]),
            ),
          ),
        );
      },
    );
  }
}

class _Gallery extends StatefulWidget {
  final List<String> images;
  const _Gallery({required this.images});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant _Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) _index = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: AspectRatio(
        aspectRatio: 1.12,
        child: Stack(children: [
          Positioned.fill(
            child: images.isEmpty
                ? Container(color: const Color(0xFFEAF0F8), child: const Icon(Icons.image_outlined, size: 60, color: Color(0xFF9AA8BA)))
                : PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (_, index) => Image.network(
                      images[index], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF0F8),
                        child: const Icon(Icons.broken_image_outlined, size: 50, color: Color(0xFF9AA8BA))),
                    ),
                  ),
          ),
          if (images.length > 1)
            Positioned(bottom: 12, left: 0, right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _index == index ? 19 : 6, height: 6,
                  decoration: BoxDecoration(color: _index == index ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(10)),
                )),
              ),
            ),
          if (images.isNotEmpty)
            Positioned(top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(.48), borderRadius: BorderRadius.circular(20)),
                child: Text('${_index + 1}/${images.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final IconData trailingIcon;
  final String trailingTitle;
  final String trailingValue;
  const _InfoCard({required this.icon, required this.title, required this.value,
    required this.trailingIcon, required this.trailingTitle, required this.trailingValue});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE8EDF4))),
    child: Row(children: [
      _info(icon, title, value),
      const SizedBox(width: 8),
      Container(width: 1, height: 42, color: const Color(0xFFE9EEF5)),
      const SizedBox(width: 8),
      _info(trailingIcon, trailingTitle, trailingValue),
    ]),
  );

  Widget _info(IconData icon, String title, String value) => Expanded(child: Row(children: [
    CircleAvatar(radius: 17, backgroundColor: const Color(0xFFEAF1FF),
      child: Icon(icon, size: 17, color: const Color(0xFF315FBA))),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF8995A5))),
      Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF26354B))),
    ])),
  ]));
}

class _SellerCard extends StatelessWidget {
  final String sellerId;
  final String sellerName;
  final VoidCallback? onVisit;
  const _SellerCard({required this.sellerId, required this.sellerName, required this.onVisit});

  @override
  Widget build(BuildContext context) {
    if (sellerId.isEmpty) return _card(sellerName, '', 'Profil toko belum tersedia', false);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ChatProfileService.watch(sellerId),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data() ?? {};
        final name = (profile['displayName'] ?? sellerName).toString();
        final photo = (profile['photoUrl'] ?? '').toString();
        final rating = profile['rating'] ?? profile['averageRating'];
        final ratingText = rating is num ? '${rating.toStringAsFixed(1)}/5' : 'Belum ada ulasan';
        final verified = profile['verified'] == true || profile['isVerified'] == true;
        return _card(name, photo, ratingText, verified);
      },
    );
  }

  Widget _card(String name, String photo, String ratingText, bool verified) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8EDF4)),
      boxShadow: const [BoxShadow(color: Color(0x080D1B32), blurRadius: 12, offset: Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Profil Penjual', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1D2A3D))),
      const SizedBox(height: 11),
      Row(children: [
        CircleAvatar(radius: 25, backgroundColor: const Color(0xFFE8F1FF),
          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
          child: photo.isEmpty ? const Icon(Icons.person_rounded, color: Color(0xFF477CF4), size: 27) : null),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
            if (verified) const Padding(padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified_rounded, color: Color(0xFF2475E8), size: 16)),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB323)),
            const SizedBox(width: 3),
            Text(ratingText, style: const TextStyle(fontSize: 11, color: Color(0xFF526176))),
          ]),
        ])),
        if (onVisit != null)
          OutlinedButton(
            onPressed: onVisit,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF344256),
              side: const BorderSide(color: Color(0xFFCAD3E0)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Kunjungi Toko', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
      ]),
    ]),
  );
}
