import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductsAdminPage extends StatefulWidget {
  const ProductsAdminPage({super.key});

  @override
  State<ProductsAdminPage> createState() => _ProductsAdminPageState();
}

class _ProductsAdminPageState extends State<ProductsAdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _setProductStatus(
      DocumentReference<Map<String, dynamic>> ref, String status) async {
    try {
      await ref.update({
        'status': status,
        'moderatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status iklan diubah menjadi $status.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
        );
      }
    }
  }

  Future<void> _updateReport(
      DocumentReference<Map<String, dynamic>> ref, String status) async {
    try {
      await ref.update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui laporan: $e')),
        );
      }
    }
  }

  Widget _products() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _db.collection('products').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Gagal memuat iklan: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return const Center(child: Text('Belum ada iklan.'));
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data();
          final status = (data['status'] ?? 'active').toString();
          final image = (data['imageUrl'] ?? '').toString();
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: image.isEmpty
                  ? const CircleAvatar(child: Icon(Icons.inventory_2))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(image, width: 52, height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                    ),
              title: Text((data['title'] ?? 'Produk').toString()),
              subtitle: Text(
                'Rp ${data['price'] ?? 0} • ${data['sellerName'] ?? data['sellerId'] ?? '-'}\n'
                'Status: $status • Laporan: ${data['reportCount'] ?? 0}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'active' || value == 'inactive') {
                    _setProductStatus(doc.reference, value);
                  }
                },
                itemBuilder: (_) => [
                  if (status != 'active')
                    const PopupMenuItem(value: 'active', child: Text('Pulihkan / tayangkan')),
                  if (status == 'active')
                    const PopupMenuItem(value: 'inactive', child: Text('Nonaktifkan iklan')),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Widget _reports() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _db.collection('reports').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Gagal memuat laporan: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return const Center(child: Text('Belum ada laporan pengguna.'));
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data();
          final status = (data['status'] ?? 'open').toString();
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.flag_outlined)),
              title: Text((data['reason'] ?? 'Laporan').toString()),
              subtitle: Text(
                'Produk: ${data['productId'] ?? '-'}\n'
                'Pelapor: ${data['reporterId'] ?? '-'} • Status: $status',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _updateReport(doc.reference, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'reviewing', child: Text('Sedang diperiksa')),
                  PopupMenuItem(value: 'resolved', child: Text('Selesaikan')),
                  PopupMenuItem(value: 'rejected', child: Text('Tolak laporan')),
                  PopupMenuItem(value: 'open', child: Text('Buka kembali')),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Iklan & Moderasi'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'Semua iklan'),
          Tab(text: 'Laporan'),
        ],
      ),
    ),
    body: TabBarView(controller: _tabs, children: [_products(), _reports()]),
  );
}
