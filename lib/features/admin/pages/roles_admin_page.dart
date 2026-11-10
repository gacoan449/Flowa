import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../orders/order_service.dart';

class RolesAdminPage extends StatelessWidget {
  const RolesAdminPage({super.key});

  Future<void> _assign(BuildContext context, String uid, String role) async {
    try {
      await OrderService().setStaffRole(uid: uid, role: role);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role dan izin backend berhasil diperbarui. Akun target perlu login ulang untuk memuat token baru.')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah role: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerEmail = (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase();
    if (ownerEmail != 'flowa324@gmail.com') {
      return Scaffold(appBar: AppBar(title: const Text('Role & Izin')), body: const Center(child: Text('Hanya pemilik utama yang dapat mengatur role staf.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Role & Permission')),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.all(14),
          child: Card(child: Padding(
            padding: EdgeInsets.all(14),
            child: Text('Role diberikan melalui Cloud Functions dan Firebase Custom Claims. Perubahan izin tidak bergantung pada teks konfigurasi yang dapat diubah dari aplikasi.'),
          )),
        ),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').limit(200).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Gagal memuat pengguna: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.where((d) => (d.data()['email'] ?? '').toString().toLowerCase() != 'flowa324@gmail.com').toList();
            if (docs.isEmpty) return const Center(child: Text('Belum ada pengguna yang dapat diberi role.'));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();
                final current = (data['role'] ?? 'user').toString();
                final role = ['admin','moderator','support'].contains(current) ? current : 'customer';
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Text(((data['name'] ?? data['email'] ?? '?').toString().isNotEmpty ? (data['name'] ?? data['email']).toString()[0] : '?').toUpperCase())),
                  title: Text((data['name'] ?? 'Pengguna Flowa').toString()),
                  subtitle: Text((data['email'] ?? doc.id).toString() + '\nRole saat ini: $current'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Ubah role',
                    onSelected: (value) => _assign(context, doc.id, value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'admin', child: Text('Admin')),
                      PopupMenuItem(value: 'moderator', child: Text('Moderator')),
                      PopupMenuItem(value: 'support', child: Text('Customer Support')),
                    ],
                    child: Chip(label: Text(role == 'customer' ? 'User' : role.toUpperCase())),
                  ),
                ));
              },
            );
          },
        )),
      ]),
    );
  }
}
