import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../chat/chat_profile_service.dart';
import 'product_detail_screen.dart';

class SellerStoreScreen extends StatelessWidget {
  final String sellerId;
  final String fallbackName;
  const SellerStoreScreen({super.key, required this.sellerId, required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Toko Penjual', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: ChatProfileService.watch(sellerId),
            builder: (context, snapshot) {
              final profile = snapshot.data?.data() ?? {};
              final name = (profile['displayName'] ?? fallbackName).toString();
              final photo = (profile['photoUrl'] ?? '').toString();
              final verified = profile['verified'] == true || profile['isVerified'] == true;
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8EDF4))),
                child: Row(children: [
                  CircleAvatar(radius: 31, backgroundColor: const Color(0xFFEAF1FF),
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.storefront_rounded, color: Color(0xFF477CF4), size: 30) : null),
                  const SizedBox(width: 13),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (verified) const Icon(Icons.verified_rounded, color: Color(0xFF2475E8), size: 15),
                      if (verified) const SizedBox(width: 4),
                      Text(verified ? 'Penjual terverifikasi' : 'Toko Flowa',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                    ]),
                  ])),
                ]),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('products')
                .where('sellerId', isEqualTo: sellerId)
                .where('status', isEqualTo: 'active')
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Padding(
                  padding: EdgeInsets.all(24), child: Text('Produk toko belum dapat dimuat.'),
                );
                if (!snapshot.hasData) return const Padding(
                  padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()),
                );
                final products = snapshot.data!.docs;
                if (products.isEmpty) return const Padding(
                  padding: EdgeInsets.all(24), child: Center(child: Text('Penjual belum memiliki iklan aktif.')),
                );
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Produk Toko (${products.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1D2A3D))),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .72,
                    ),
                    itemBuilder: (context, index) {
                      final doc = products[index];
                      final data = doc.data();
                      final image = (data['imageUrl'] ?? '').toString();
                      final price = data['price'] is num ? (data['price'] as num).toInt() : int.tryParse('${data['price']}') ?? 0;
                      final digits = price.toString();
                      final formatted = StringBuffer();
                      for (var i = 0; i < digits.length; i++) {
                        if (i > 0 && (digits.length - i) % 3 == 0) formatted.write('.');
                        formatted.write(digits[i]);
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productId: doc.id),
                        )),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8EDF4))),
                          clipBehavior: Clip.antiAlias,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: SizedBox(width: double.infinity,
                              child: image.isEmpty ? const ColoredBox(color: Color(0xFFEAF1FA),
                                child: Icon(Icons.image_outlined, size: 38, color: Color(0xFF9AA8BA)))
                                : Image.network(image, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEAF1FA),
                                    child: Icon(Icons.broken_image_outlined))))),
                            Padding(padding: const EdgeInsets.fromLTRB(10, 9, 10, 11), child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text((data['title'] ?? 'Produk').toString(), maxLines: 2,
                                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 5),
                                Text('Rp $formatted', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                                  color: Color(0xFF1769E8))),
                              ],
                            )),
                          ]),
                        ),
                      );
                    },
                  ),
                ]);
              },
            ),
          ),
        ),
      ]),
    );
  }
}
