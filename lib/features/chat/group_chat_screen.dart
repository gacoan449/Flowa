import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupChatScreen({super.key, required this.groupId, required this.groupName});
  @override State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _message = TextEditingController();
  bool _sending = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _name {
    final user = FirebaseAuth.instance.currentUser!;
    return (user.displayName ?? user.email?.split('@').first ?? 'Pengguna').trim();
  }
  CollectionReference<Map<String, dynamic>> get _messages =>
    FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('messages');

  @override
  void dispose() { _message.dispose(); super.dispose(); }

  Future<void> _send() async {
    final value = _message.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(_messages.doc(), {
        'senderId': _uid, 'senderName': _name, 'text': value,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(FirebaseFirestore.instance.collection('groups').doc(widget.groupId), {
        'lastMessage': value, 'lastMessageAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _message.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan grup gagal dikirim: $e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  String _time(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: const Color(0xFFF5F7FB)),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _messages.orderBy('createdAt', descending: true).limit(100).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Pesan grup tidak dapat dimuat.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('Mulai percakapan di grup ini 👋'));
            return ListView.builder(
              reverse: true, padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index]; final data = doc.data();
                final mine = data['senderId'] == _uid;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFFDCE8FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (!mine) Text((data['senderName'] ?? 'Anggota').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF3267E9))),
                      Text((data['text'] ?? '').toString()),
                      Align(alignment: Alignment.bottomRight, child: Text(_time(data['createdAt']), style: const TextStyle(fontSize: 10, color: Color(0xFF8793A5)))),
                    ]),
                  ),
                );
              },
            );
          },
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _message, minLines: 1, maxLines: 4, textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'Tulis pesan grup...', filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _sending ? null : _send,
              icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded)),
          ]),
        )),
      ]),
    );
  }
}
