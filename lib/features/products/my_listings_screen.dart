import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_listing_screen.dart';
import 'product_service.dart';
import '../../core/app_appearance.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).extension<FlowaDesignTokens>()?.backgroundFor('marketplace', Theme.of(context).scaffoldBackgroundColor),
      appBar: AppBar(title: const Text('Iklan Saya')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Iklan gagal dimuat: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Kamu belum memiliki iklan. Produk yang diterbitkan akan tampil di sini.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return Card(
                child: ListTile(
                  leading: data['imageUrl'] == null || data['imageUrl'] == ''
                      ? const CircleAvatar(child: Icon(Icons.image_outlined))
                      : Image.network(
                          data['imageUrl'],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                  title: Text((data['title'] ?? 'Tanpa judul').toString()),
                  subtitle: Text(
                    'Rp ${data['price'] ?? 0} • ${data['status'] ?? 'active'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditListingScreen(id: doc.id, data: data),
                          ),
                        );
                      } else if (value == 'delete') {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Hapus iklan?'),
                            content: const Text('Iklan ini akan dihapus permanen.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (yes == true) {
                          try {
                            await ProductService().deleteProduct(
                              doc.id,
                              List<dynamic>.from(data['imageUrls'] ?? []),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal menghapus: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
