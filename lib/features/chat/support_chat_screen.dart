import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupportChatScreen extends StatefulWidget {
  final bool admin;
  final String? threadId;

  const SupportChatScreen({super.key, this.admin = false, this.threadId});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final text = TextEditingController();
  bool sending = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;
  String get id => widget.threadId ?? uid;
  DocumentReference<Map<String, dynamic>> get thread =>
      FirebaseFirestore.instance.collection('support_threads').doc(id);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureThread();
      await _markRead();
    });
  }

  Future<void> _ensureThread() async {
    if (widget.admin) return;
    try {
      await thread.set({
        'userId': uid,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // A visible stream error will explain a Firebase permission or network issue.
    }
  }

  Future<void> _markRead() async {
    try {
      final snapshot = await thread.get();
      if (!snapshot.exists) return;
      await thread.update(widget.admin
          ? {'unreadForAdmin': false}
          : {'unreadForUser': false});
    } catch (_) {
      // Read receipts are best-effort; they must not block opening the chat.
    }
  }

  Future<void> send() async {
    final value = text.text.trim();
    if (value.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      final data = <String, dynamic>{
        'lastMessage': value,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'unreadForAdmin': !widget.admin,
        'unreadForUser': widget.admin,
      };
      if (!widget.admin) data['userId'] = uid;
      await thread.set(data, SetOptions(merge: true));
      await thread.collection('messages').add({
        'senderId': uid,
        'text': value,
        'createdAt': FieldValue.serverTimestamp(),
      });
      text.clear();
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesan bantuan gagal dikirim (${e.code}): ${e.message ?? ''}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesan bantuan gagal dikirim: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.admin ? 'Customer Support' : 'Bantuan Flowa'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: thread.collection('messages')
                  .orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Riwayat bantuan gagal dimuat: ${snapshot.error}'),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Sampaikan pertanyaanmu kepada Customer Service Flowa.'),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final mine = data['senderId'] == uid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text((data['text'] ?? '').toString()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: text,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan ke Customer Service',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: sending ? null : send,
                    icon: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
