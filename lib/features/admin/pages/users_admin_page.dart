import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key});

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setActive(
      DocumentReference<Map<String, dynamic>> ref, bool active) async {
    try {
      await ref.update({
        'active': active,
        'moderatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status akun: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kelola Pengguna')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Cari nama, email, atau UID',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Gagal memuat pengguna: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final query = _search.text.trim().toLowerCase();
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final searchable = [
                  data['name'], data['email'], doc.id,
                ].join(' ').toLowerCase();
                return query.isEmpty || searchable.contains(query);
              }).toList();
              if (docs.isEmpty) {
                return const Center(child: Text('Pengguna tidak ditemukan.'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final active = data['active'] != false;
                  final name = (data['name'] ?? data['email'] ?? 'Pengguna').toString();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        '${data['email'] ?? doc.id}\n'
                        'Role: ${data['role'] ?? 'user'} • ${active ? 'Aktif' : 'Dinonaktifkan'}',
                      ),
                      isThreeLine: true,
                      trailing: Switch(
                        value: active,
                        onChanged: (value) => _setActive(doc.reference, value),
                      ),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: Text(name),
                          content: SelectableText(
                            'UID: ${doc.id}\n'
                            'Email: ${data['email'] ?? '-'}\n'
                            'Telepon: ${data['phone'] ?? '-'}\n'
                            'Role: ${data['role'] ?? 'user'}\n'
                            'Status: ${active ? 'Aktif' : 'Dinonaktifkan'}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(d),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
