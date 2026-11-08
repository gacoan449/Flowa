import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../chat/support_chat_screen.dart';
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
          const CircleAvatar(radius: 38, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.displayName ?? user?.email ?? 'Pengguna',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
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
