import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../chat/support_chat_screen.dart';
import '../chat/chat_profile_service.dart';
import '../favorites/favorites_screen.dart';
import '../products/my_listings_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: user == null ? null : ChatProfileService.watch(user.uid),
            builder: (context, snapshot) {
              final profile = snapshot.data?.data() ?? {};
              final name = (profile['displayName'] ?? user?.displayName ?? 'Pengguna Flowa').toString();
              final username = (profile['username'] ?? '').toString();
              final photo = (profile['photoUrl'] ?? '').toString();
              return Column(children: [
                CircleAvatar(radius: 38, backgroundColor: const Color(0xFFEAF0FF),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person, size: 40) : null),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                if (username.isNotEmpty) Text('@$username', style: const TextStyle(color: Color(0xFF477CF4))),
                TextButton.icon(
                  onPressed: user == null ? null : () => _editDisplayName(context, user.uid, name),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Ubah nama tampilan'),
                ),
              ]);
            },
          ),
          const SizedBox(height: 24),
          _menu(context, Icons.inventory_2_outlined, 'Iklan Saya',
              'Lihat dan kelola produk yang kamu pasang',
              const MyListingsScreen()),
          _menu(context, Icons.favorite_border, 'Favorit',
              'Produk yang kamu simpan', const FavoritesScreen()),
          _menu(context, Icons.support_agent, 'Bantuan & Chat',
              'Hubungi Customer Service', const SupportChatScreen()),
          _menu(context, Icons.settings_outlined, 'Pengaturan Akun',
              'Kelola informasi akun dan keamanan', const SettingsScreen()),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Keluar dari Flowa?'),
                  content: const Text('Kamu perlu login kembali untuk masuk.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await AuthService().logout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editDisplayName(BuildContext context, String uid, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nama tampilan'),
        content: TextField(controller: controller, autofocus: true, maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nama yang terlihat oleh pengguna lain')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan')),
        ],
      ),
    );
    if (value == null || value.isEmpty) { controller.dispose(); return; }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await ChatProfileService.syncCurrentUser(displayName: value);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tampilan berhasil diperbarui.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama gagal diperbarui: $e')));
    } finally { controller.dispose(); }
  }

  Widget _menu(BuildContext context, IconData icon, String title,
      String subtitle, Widget page) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}
