import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  State<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen> {
  final _composer = TextEditingController();
  bool _publishing = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _name {
    final user = FirebaseAuth.instance.currentUser!;
    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    return (user.email ?? 'Pengguna Flowa').split('@').first;
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _publishing) return;
    setState(() => _publishing = true);
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'ownerId': _uid,
        'ownerName': _name,
        'ownerPhoto': FirebaseAuth.instance.currentUser?.photoURL ?? '',
        'text': text,
        'likes': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      _composer.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil dibagikan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Postingan gagal dikirim: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showComposer() {
    _composer.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) => Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Buat postingan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              controller: _composer,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'Apa yang sedang kamu pikirkan?',
                filled: true,
                fillColor: const Color(0xFFF3F6FB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _publishing ? null : () async {
                refresh(() {});
                await _createPost();
                if (mounted) refresh(() {});
              },
              icon: _publishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(_publishing ? 'Membagikan...' : 'Bagikan postingan'),
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggleLike(DocumentReference<Map<String, dynamic>> ref, bool liked) async {
    try {
      await ref.update({
        'likes': liked ? FieldValue.arrayRemove([_uid]) : FieldValue.arrayUnion([_uid]),
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Like gagal disimpan: $e')),
      );
    }
  }

  Future<void> _sharePost(Map<String, dynamic> data) async {
    final author = (data['ownerName'] ?? 'Pengguna Flowa').toString();
    final body = (data['text'] ?? '').toString();
    final text = "$author di Flowa:\n\n$body\n\nLihat di Flowa";
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Isi postingan disalin. Kamu bisa tempel untuk membagikannya.')),
    );
  }

  void _showComments(String postId) {
    final input = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .72,
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('Komentar', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            ),
            Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('posts').doc(postId)
                  .collection('comments').orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Komentar belum dapat dimuat.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Belum ada komentar. Jadilah yang pertama!'));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEAF0FF),
                        child: Text((data['name'] ?? 'P').toString().characters.first.toUpperCase()),
                      ),
                      title: Text((data['name'] ?? 'Pengguna').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text((data['text'] ?? '').toString()),
                    );
                  },
                );
              },
            )),
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    filled: true,
                    fillColor: const Color(0xFFF2F5FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                )),
                IconButton.filled(
                  onPressed: () async {
                    final text = input.text.trim();
                    if (text.isEmpty) return;
                    try {
                      await FirebaseFirestore.instance.collection('posts').doc(postId)
                          .collection('comments').add({
                        'uid': _uid,
                        'name': _name,
                        'text': text,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      input.clear();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Komentar gagal dikirim: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                ),
              ]),
            )),
          ]),
        ),
      ),
    ).whenComplete(input.dispose);
  }

  String _dateLabel(dynamic value) {
    if (value is! Timestamp) return 'Baru saja';
    final date = value.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Postingan', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFFF5F7FB),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showComposer,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Buat postingan'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _showComposer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEAF0FF),
                    backgroundImage: (FirebaseAuth.instance.currentUser?.photoURL ?? '').isNotEmpty
                        ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!) : null,
                    child: (FirebaseAuth.instance.currentUser?.photoURL ?? '').isEmpty
                        ? const Icon(Icons.person_rounded, color: Color(0xFF477CF4)) : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Bagikan cerita atau kabar terbaru...',
                    style: TextStyle(color: Color(0xFF8995A7)))),
                  const Icon(Icons.add_circle_rounded, color: Color(0xFF3267E9), size: 27),
                ]),
              ),
            ),
          ),
        ),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('posts')
              .orderBy('createdAt', descending: true).limit(60).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(
              child: Padding(padding: EdgeInsets.all(28),
                child: Text('Postingan belum dapat dimuat. Periksa Firestore Rules untuk koleksi posts.')),
            );
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return Center(child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.dynamic_feed_rounded, size: 58, color: Color(0xFF9BAAC2)),
                const SizedBox(height: 12),
                const Text('Belum ada postingan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Mulai ramaikan komunitas Flowa dengan postingan pertamamu.',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8793A5))),
                const SizedBox(height: 14),
                FilledButton.icon(onPressed: _showComposer,
                  icon: const Icon(Icons.edit_rounded), label: const Text('Buat postingan')),
              ]),
            ));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final likes = List<String>.from(data['likes'] ?? const []);
                final liked = likes.contains(_uid);
                final photo = (data['ownerPhoto'] ?? '').toString();
                final name = (data['ownerName'] ?? 'Pengguna Flowa').toString();
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFEAF0FF),
                          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty ? const Icon(Icons.person_rounded, color: Color(0xFF477CF4)) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(_dateLabel(data['createdAt']), style: const TextStyle(fontSize: 11, color: Color(0xFF8995A7))),
                        ])),
                        if (data['ownerId'] == _uid)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus postingan?'),
                                  content: const Text('Postingan ini akan dihapus.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                                  ],
                                ));
                                if (yes == true) await doc.reference.delete();
                              }
                            },
                            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Hapus postingan'))],
                          ),
                      ]),
                      const SizedBox(height: 13),
                      SelectableText((data['text'] ?? '').toString(),
                        style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF26344A))),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      Row(children: [
                        Expanded(child: TextButton.icon(
                          onPressed: () => _toggleLike(doc.reference, liked),
                          icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: liked ? const Color(0xFFE34E72) : const Color(0xFF75839A)),
                          label: Text('Suka ${likes.length}',
                            style: TextStyle(color: liked ? const Color(0xFFE34E72) : const Color(0xFF75839A))),
                        )),
                        Expanded(child: TextButton.icon(
                          onPressed: () => _showComments(doc.id),
                          icon: const Icon(Icons.mode_comment_outlined),
                          label: const Text('Komentar'),
                        )),
                        Expanded(child: TextButton.icon(
                          onPressed: () => _sharePost(data),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Bagikan'),
                        )),
                      ]),
                    ]),
                  ),
                );
              },
            );
          },
        )),
      ]),
    );
  }
}
