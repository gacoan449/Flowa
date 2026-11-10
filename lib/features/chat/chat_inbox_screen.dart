import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_profile_service.dart';
import 'chat_screen.dart';
import 'discover_users_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});
  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  String _timeLabel(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (now.difference(date).inDays < 7) {
      const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    final stream = FirebaseFirestore.instance.collection('chats')
        .where('participants', arrayContains: user.uid).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB), surfaceTintColor: Colors.transparent,
        elevation: 0, titleSpacing: 22,
        title: const Text('Pesan', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
        actions: [
          IconButton(tooltip: 'Temukan pengguna', onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DiscoverUsersScreen())),
            icon: const Icon(Icons.person_search_rounded, color: Color(0xFF3267E9))),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17),
              boxShadow: [BoxShadow(color: const Color(0xFF15294B).withOpacity(.045), blurRadius: 18, offset: const Offset(0, 6))]),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama pengguna atau percakapan',
                hintStyle: const TextStyle(color: Color(0xFF9AA5B5), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8491A5)),
                suffixIcon: _query.isEmpty ? null : IconButton(
                  onPressed: () { _search.clear(); setState(() => _query = ''); },
                  icon: const Icon(Icons.close_rounded)),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
          )),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 21), child: Row(children: [
          Text('Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF17243A))),
          Spacer(), Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF8C98AA)),
          SizedBox(width: 5), Text('Percakapan pribadi', style: TextStyle(fontSize: 11, color: Color(0xFF8C98AA))),
        ])),
        const SizedBox(height: 9),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _state(Icons.cloud_off_rounded, 'Pesan belum dapat dimuat', 'Periksa koneksi internet lalu coba lagi.');
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF3267E9)));
            final docs = [...?snapshot.data?.docs];
            docs.sort((a, b) {
              final at = a.data()['lastMessageAt']; final bt = b.data()['lastMessageAt'];
              final ad = at is Timestamp ? at.toDate() : DateTime(2000);
              final bd = bt is Timestamp ? bt.toDate() : DateTime(2000);
              return bd.compareTo(ad);
            });
            final filtered = docs.where((doc) {
              final d = doc.data();
              return (d['productTitle'] ?? '').toString().toLowerCase().contains(_query) ||
                (d['lastMessage'] ?? '').toString().toLowerCase().contains(_query);
            }).toList();
            if (docs.isEmpty) return _state(Icons.forum_rounded, 'Belum ada percakapan', 'Temukan produk menarik, lalu hubungi penjual dari halaman produk.');
            if (filtered.isEmpty) return _state(Icons.search_off_rounded, 'Tidak ada hasil', 'Coba kata kunci lain.');

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 24), itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final doc = filtered[index]; final data = doc.data();
                final participants = List<String>.from(data['participants'] ?? const []);
                final otherId = participants.firstWhere((id) => id != user.uid, orElse: () => '');
                final productTitle = (data['productTitle'] ?? 'Percakapan Flowa').toString();
                final preview = (data['lastMessage'] ?? 'Mulai percakapan').toString();
                final time = _timeLabel(data['lastMessageAt']);
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: otherId.isEmpty ? null : ChatProfileService.watch(otherId),
                  builder: (context, profileSnapshot) {
                    final profile = profileSnapshot.data?.data() ?? {};
                    final name = (profile['displayName'] ?? '').toString().trim().isNotEmpty
                      ? profile['displayName'].toString() : 'Pengguna Flowa';
                    final photo = (profile['photoUrl'] ?? '').toString();
                    final online = profile['isOnline'] == true;
                    final username = (profile['username'] ?? '').toString();
                    final searchable = '$name @$username $productTitle $preview'.toLowerCase();
                    if (_query.isNotEmpty && !searchable.contains(_query)) return const SizedBox.shrink();
                    return Material(
                      color: Colors.white, borderRadius: BorderRadius.circular(19),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(19),
                        onTap: otherId.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatScreen(sellerId: otherId, sellerName: name,
                            productId: (data['productId'] ?? '').toString(), productTitle: productTitle))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
                          child: Row(children: [
                            Stack(children: [
                              CircleAvatar(radius: 27, backgroundColor: const Color(0xFFEAF0FF),
                                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                                child: photo.isEmpty ? const Icon(Icons.person_rounded, color: Color(0xFF477CF4), size: 29) : null),
                              if (online) Positioned(right: 0, bottom: 0, child: Container(
                                width: 13, height: 13, decoration: BoxDecoration(color: const Color(0xFF22B573),
                                  shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                            ]),
                            const SizedBox(width: 13),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B2940)))),
                                const SizedBox(width: 7), Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF9AA5B5))),
                              ]),
                              const SizedBox(height: 3),
                              Text(productTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF477CF4), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF7E8A9D))),
                            ])),
                            const SizedBox(width: 4), const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFB0BAC8)),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        )),
      ]),
    );
  }

  Widget _state(IconData icon, String title, String subtitle) => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 36),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 82, height: 82, decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFEAF0FF), Color(0xFFF0ECFF)])),
        child: Icon(icon, size: 36, color: const Color(0xFF5278E8))),
      const SizedBox(height: 19), Text(title, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1C2940))),
      const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF8995A7))),
    ]),
  ));
}
