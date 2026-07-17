import 'package:flutter/material.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy simulasi (Nanti bisa diganti dengan stream dari Firestore)
    final List<Map<String, dynamic>> notifications = [
      {"title": "Siti_Indah menyukai videomu", "sub": "1 jam yang lalu", "icon": Icons.favorite_rounded, "color": Colors.redAccent},
      {"title": "Budi_Tani mengomentari kirimanmu", "sub": "2 jam yang lalu", "icon": Icons.chat_bubble_rounded, "color": Colors.blueAccent},
      {"title": "Sistem DesaPay", "sub": "Pencairan saldo sukses! ✔", "icon": Icons.account_balance_wallet_rounded, "color": Colors.amber},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Kotak Masuk", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 10),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return _buildPremiumListTile(
            title: item['title'],
            sub: item['sub'],
            icon: item['icon'],
            color: item['color'],
          );
        },
      ),
    );
  }

  // [UPGRADE CTO] Komponen Tile Premium dengan Padding & Elemen Visual Modern
  Widget _buildPremiumListTile({
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
      onTap: () {
        // TODO: Arahkan ke detail notifikasi
      },
    );
  }
}
