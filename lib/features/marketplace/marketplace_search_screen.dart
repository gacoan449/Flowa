import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../products/product_detail_screen.dart';

class MarketplaceSearchScreen extends StatefulWidget {
  const MarketplaceSearchScreen({super.key});
  @override
  State<MarketplaceSearchScreen> createState() => _MarketplaceSearchScreenState();
}
class _MarketplaceSearchScreenState extends State<MarketplaceSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cari di Flowa')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: TextField(
        controller: _controller, autofocus: true,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Cari nama produk, kategori, atau lokasi',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty ? null : IconButton(
            onPressed: () { _controller.clear(); setState(() => _query = ''); },
            icon: const Icon(Icons.close)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      )),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products')
          .where('status', isEqualTo: 'active').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _SearchMessage(
            icon: Icons.wifi_off_rounded,
            message: 'Produk belum bisa dimuat. Periksa koneksi lalu coba lagi.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((doc) {
            final d = doc.data();
            if (_query.isEmpty) return true;
            return [d['title'], d['category'], d['locationName'], d['sellerName'], d['description']]
              .join(' ').toLowerCase().contains(_query);
          }).toList();
          if (docs.isEmpty) return _SearchMessage(
            icon: Icons.search_off_rounded,
            message: _query.isEmpty ? 'Belum ada produk aktif.' : 'Tidak ada hasil untuk "$_query".');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 9),
            itemBuilder: (context, i) {
              final doc = docs[i], d = doc.data();
              final image = (d['imageUrl'] ?? '').toString();
              return Card(clipBehavior: Clip.antiAlias, child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: SizedBox(width: 68, height: 68, child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: image.isEmpty
                    ? const ColoredBox(color: Color(0xFFEAF0F8), child: Icon(Icons.shopping_bag_outlined))
                    : Image.network(image, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEAF0F8), child: Icon(Icons.broken_image_outlined))),
                )),
                title: Text((d['title'] ?? 'Produk Flowa').toString(),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Rp ${d['price'] ?? 0}\n${(d['locationName'] ?? d['category'] ?? '').toString()}'),
                isThreeLine: true, trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(productId: doc.id))),
              ));
            },
          );
        },
      )),
    ]),
  );
}
class _SearchMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const _SearchMessage({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 42, color: Colors.grey), const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center)])));
}
