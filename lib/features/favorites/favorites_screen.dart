import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../products/product_detail_screen.dart';
import '../products/seller_store_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(
      body: Center(child: Text('Silakan masuk untuk melihat favorit.')));
    final collection = FirebaseFirestore.instance.collection('users')
      .doc(user.uid).collection('favorites');
    return Scaffold(
      appBar: AppBar(title: const Text('Favorit Saya')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: collection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(
            child: Padding(padding: EdgeInsets.all(24),
              child: Text('Favorit belum bisa dimuat. Periksa koneksi lalu coba lagi.',
                textAlign: TextAlign.center)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.favorite_border, size: 48, color: Colors.grey),
              SizedBox(height: 10), Text('Belum ada produk favorit.'),
            ]));
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index], data = doc.data();
              final productId = (data['productId'] ?? doc.id).toString();
              final sellerId = (data['sellerId'] ?? '').toString();
              final title = (data['title'] ?? 'Produk Flowa').toString();
              final image = (data['imageUrl'] ?? '').toString();
              final price = data['price'] ?? 0;
              return Card(clipBehavior: Clip.antiAlias, child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                leading: SizedBox(width: 58, height: 58, child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: image.isEmpty
                    ? const ColoredBox(color: Color(0xFFEAF0F8), child: Icon(Icons.shopping_bag_outlined))
                    : Image.network(image, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEAF0F8), child: Icon(Icons.broken_image_outlined))),
                )),
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Rp $price'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'remove') {
                      try { await doc.reference.delete(); }
                      catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Favorit gagal dihapus. Coba lagi.'))); }
                    } else if (value == 'product') {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productId: productId)));
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'product', child: Text('Lihat produk')),
                    PopupMenuItem(value: 'remove', child: Text('Hapus favorit')),
                  ],
                ),
                onTap: () {
                  if (sellerId.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SellerStoreScreen(sellerId: sellerId, fallbackName: 'Toko Flowa')));
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: productId)));
                  }
                },
              ));
            },
          );
        },
      ),
    );
  }
}
