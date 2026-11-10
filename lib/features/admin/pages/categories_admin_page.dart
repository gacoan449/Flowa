import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoriesAdminPage extends StatelessWidget {
  const CategoriesAdminPage({super.key});

  Future<void> _edit(BuildContext context, {
    DocumentReference<Map<String, dynamic>>? ref,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ref == null ? 'Kategori baru' : 'Edit kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama kategori'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan')),
        ],
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      final data = {
        'name': controller.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (ref == null) {
        await FirebaseFirestore.instance.collection('categories').add({
          ...data,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update(data);
      }
    }
    controller.dispose();
  }

  Future<void> _delete(BuildContext context,
      DocumentReference<Map<String, dynamic>> ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: const Text('Produk yang sudah memakai kategori ini tidak ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yes == true) await ref.delete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kategori Marketplace')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _edit(context),
      child: const Icon(Icons.add),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('categories')
          .orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Gagal memuat kategori: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada kategori khusus.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.category_outlined)),
              title: Text((data['name'] ?? '').toString()),
              subtitle: Text(data['active'] == true ? 'Aktif' : 'Nonaktif'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _edit(context, ref: doc.reference,
                    initial: (data['name'] ?? '').toString());
                  if (value == 'delete') _delete(context, doc.reference);
                  if (value == 'toggle') doc.reference.update({
                    'active': data['active'] != true,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit nama')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(data['active'] == true ? 'Nonaktifkan' : 'Aktifkan'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
