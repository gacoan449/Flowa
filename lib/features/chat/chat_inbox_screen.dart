import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';

class ChatInboxScreen extends StatelessWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    }
    final stream = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              'Chat tidak dapat dimuat',
              snapshot.error.toString(),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = [...?snapshot.data?.docs];
          docs.sort((a, b) {
            final at = a.data()['lastMessageAt'];
            final bt = b.data()['lastMessageAt'];
            final ad = at is Timestamp ? at.toDate() : DateTime(2000);
            final bd = bt is Timestamp ? bt.toDate() : DateTime(2000);
            return bd.compareTo(ad);
          });
          if (docs.isEmpty) {
            return _message('Belum ada percakapan',
                'Chat penjual dari halaman detail produk untuk memulai percakapan.');
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final participants =
                  List<String>.from(data['participants'] ?? const []);
              final otherId = participants.firstWhere(
                (id) => id != user.uid,
                orElse: () => '',
              );
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text((data['productTitle'] ?? 'Percakapan').toString()),
                subtitle: Text((data['lastMessage'] ?? 'Mulai percakapan').toString(),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: otherId.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              sellerId: otherId,
                              sellerName: 'Pengguna Flowa',
                              productId: (data['productId'] ?? '').toString(),
                              productTitle:
                                  (data['productTitle'] ?? 'Produk').toString(),
                            ),
                          ),
                        ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(String title, String detail) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 42),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(detail, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
