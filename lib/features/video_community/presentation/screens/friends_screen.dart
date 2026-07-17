import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulasi data teman (Di masa depan, ini akan di-fetch dari Firestore 'followers')
    final List<Map<String, String>> friends = [
      {"name": "Siti_Indah", "status": "Baru saja mengunggah video"},
      {"name": "Budi_Tani", "status": "Sedang live di sawah"},
      {"name": "Pak_Kades", "status": "Aktif 5 menit yang lalu"},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Aktivitas Teman", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: friends.isEmpty 
        ? _buildEmptyState() 
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _buildFriendCard(friend['name']!, friend['status']!);
            },
          ),
    );
  }

  // [UPGRADE CTO] Tampilan elegan saat tidak ada aktivitas teman
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("Belum ada aktivitas", style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  // [UPGRADE CTO] Card Teman Premium dengan Efek Glassmorphism
  Widget _buildFriendCard(String name, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.purple.withOpacity(0.3),
            child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill, color: Colors.amber.withOpacity(0.8), size: 30),
        ],
      ),
    );
  }
}
