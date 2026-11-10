import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnnouncementsAdminPage extends StatefulWidget {
  const AnnouncementsAdminPage({super.key});

  @override
  State<AnnouncementsAdminPage> createState() => _AnnouncementsAdminPageState();
}

class _AnnouncementsAdminPageState extends State<AnnouncementsAdminPage> {
  final _db = FirebaseFirestore.instance;

  Future<void> _edit({DocumentReference<Map<String, dynamic>>? ref,
    Map<String, dynamic>? data}) async {
    final title = TextEditingController(text: (data?['title'] ?? '').toString());
    final body = TextEditingController(text: (data?['body'] ?? '').toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ref == null ? 'Pengumuman baru' : 'Edit pengumuman'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 10),
              TextField(controller: body, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Isi pengumuman')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan')),
        ],
      ),
    );
    if (result == true && title.text.trim().isNotEmpty) {
      final payload = {
        'title': title.text.trim(),
        'body': body.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (ref == null) {
        await _db.collection('announcements').add({
          ...payload,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update(payload);
      }
    }
    title.dispose();
    body.dispose();
  }

  Future<void> _delete(DocumentReference<Map<String, dynamic>> ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus pengumuman?'),
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
    appBar: AppBar(title: const Text('Pengumuman')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('Buat pengumuman'),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Gagal memuat: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada pengumuman.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final active = data['active'] == true;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: ListTile(
                title: Text((data['title'] ?? '').toString()),
                subtitle: Text((data['body'] ?? '').toString(), maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _edit(ref: doc.reference, data: data);
                    if (v == 'delete') _delete(doc.reference);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
                leading: Switch(
                  value: active,
                  onChanged: (v) => doc.reference.update({
                    'active': v,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
