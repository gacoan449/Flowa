import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../chat/support_chat_screen.dart';

class ChatAdminPage extends StatelessWidget {
  const ChatAdminPage({super.key});

  Future<void> _setStatus(
      DocumentReference<Map<String, dynamic>> ref, String status) async {
    await ref.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customer Service')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('support_threads')
          .orderBy('lastMessageAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat percakapan: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada pesan bantuan.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final status = (data['status'] ?? 'open').toString();
            final unread = data['unreadForAdmin'] == true;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: ListTile(
                leading: Badge(
                  isLabelVisible: unread,
                  label: const Text('Baru'),
                  child: const CircleAvatar(child: Icon(Icons.support_agent)),
                ),
                title: Text((data['userName'] ?? data['userId'] ?? 'Pengguna').toString()),
                subtitle: Text(
                  '${data['lastMessage'] ?? 'Belum ada pesan'}\nStatus: $status',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _setStatus(doc.reference, value),
                  itemBuilder: (_) => [
                    if (status != 'open')
                      const PopupMenuItem(value: 'open', child: Text('Buka tiket')),
                    if (status != 'closed')
                      const PopupMenuItem(value: 'closed', child: Text('Tutup tiket')),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupportChatScreen(admin: true, threadId: doc.id),
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
