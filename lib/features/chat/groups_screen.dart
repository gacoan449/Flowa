import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _creating = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _name.text.trim();
    final description = _description.text.trim();
    if (name.length < 3 || _creating) return;
    setState(() => _creating = true);
    try {
      final ref = await FirebaseFirestore.instance.collection('groups').add({
        'name': name,
        'description': description,
        'ownerId': _uid,
        'members': [_uid],
        'memberCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: ref.id, groupName: name)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grup gagal dibuat: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showCreateDialog() {
    _name.clear();
    _description.clear();
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, refresh) => Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Buat grup baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(controller: _name, maxLength: 50, decoration: const InputDecoration(labelText: 'Nama grup', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _description, maxLength: 240, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi grup', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _creating ? null : () async { refresh(() {}); await _createGroup(); if (mounted) refresh(() {}); },
            icon: _creating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.group_add_rounded),
            label: Text(_creating ? 'Membuat...' : 'Buat grup'),
          )),
        ]),
      )),
    );
  }

  Future<void> _joinGroup(DocumentReference<Map<String, dynamic>> ref, List<String> members) async {
    try {
      await ref.update({'members': FieldValue.arrayUnion([_uid]), 'memberCount': members.length + 1});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak bisa bergabung: $e')));
    }
  }

  Future<void> _leaveGroup(DocumentReference<Map<String, dynamic>> ref, List<String> members) async {
    if (members.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pemilik grup tidak bisa keluar sebelum menghapus atau memindahkan kepemilikan grup.')));
      return;
    }
    try {
      await ref.update({'members': FieldValue.arrayRemove([_uid]), 'memberCount': members.length - 1});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal keluar dari grup: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return const Scaffold(body: Center(child: Text('Silakan login.')));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('Grup Flowa', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: const Color(0xFFF5F7FB)),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showCreateDialog, icon: const Icon(Icons.add), label: const Text('Buat grup')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('groups').orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Grup belum bisa dimuat. Periksa Firestore Rules koleksi groups.')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.groups_rounded, size: 60, color: Color(0xFF8DA4CB)),
            const SizedBox(height: 12), const Text('Belum ada grup', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const Text('Buat komunitas pertama Flowa atau mulai dengan grup sesuai minatmu.', textAlign: TextAlign.center),
            const SizedBox(height: 14), FilledButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add), label: const Text('Buat grup')),
          ])));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 100), itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index]; final data = doc.data();
              final members = List<String>.from(data['members'] ?? const <String>[]);
              final joined = members.contains(_uid);
              final name = (data['name'] ?? 'Grup Flowa').toString();
              return Card(
                elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const CircleAvatar(radius: 24, backgroundColor: Color(0xFFEAF0FF), child: Icon(Icons.groups_rounded, color: Color(0xFF3267E9))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${members.length} anggota', style: const TextStyle(color: Color(0xFF7C899D), fontSize: 12)),
                    ])),
                    if (joined) const Chip(label: Text('Anggota'), visualDensity: VisualDensity.compact),
                  ]),
                  if ((data['description'] ?? '').toString().isNotEmpty) Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(data['description'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => joined
                        ? Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: doc.id, groupName: name)))
                        : _joinGroup(doc.reference, members),
                      child: Text(joined ? 'Buka grup' : 'Gabung grup'),
                    )),
                    if (joined && data['ownerId'] != _uid) ...[
                      const SizedBox(width: 8),
                      IconButton(tooltip: 'Keluar grup', onPressed: () => _leaveGroup(doc.reference, members), icon: const Icon(Icons.logout_rounded)),
                    ],
                  ]),
                ])),
              );
            },
          );
        },
      ),
    );
  }
}
