import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String productId;
  final String productTitle;
  const ChatScreen({super.key, required this.sellerId, required this.sellerName, required this.productId, required this.productTitle});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  late final Future<void> _chatReady;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _chatId { final ids = [_uid, widget.sellerId]..sort(); return ids.join('_'); }

  @override
  void initState() { super.initState(); _chatReady = _ensureChat(); }

  Future<void> _ensureChat() async {
    if (widget.sellerId.isEmpty || widget.sellerId == _uid) throw StateError('ID penjual tidak valid.');
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
      'participants': ([_uid, widget.sellerId]..sort()),
      'productId': widget.productId,
      'productTitle': widget.productTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _clock(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _chatReady;
      final chat = FirebaseFirestore.instance.collection('chats').doc(_chatId);
      final batch = FirebaseFirestore.instance.batch();
      batch.set(chat, {'lastMessage': value, 'lastMessageAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      batch.set(chat.collection('messages').doc(), {'senderId': _uid, 'text': value, 'createdAt': FieldValue.serverTimestamp()});
      await batch.commit();
      _text.clear();
      _focus.requestFocus();
    } on FirebaseException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan gagal dikirim (${e.code}): ${e.message ?? ''}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan gagal dikirim: $e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  void dispose() { _text.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0, titleSpacing: 0,
        title: Row(children: [
          Container(width: 39, height: 39, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF477CF4), Color(0xFF7559D9)])), child: const Icon(Icons.person_rounded, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.sellerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B2940))),
            const SizedBox(height: 2),
            const Text('Percakapan Flowa', style: TextStyle(fontSize: 10, color: Color(0xFF8793A5))),
          ])),
        ]),
        actions: [IconButton(onPressed: () => showModalBottomSheet<void>(context: context, builder: (ctx) => SafeArea(child: ListTile(leading: const Icon(Icons.info_outline), title: const Text('Tentang percakapan'), subtitle: const Text('Chat ini dibuat untuk diskusi produk di Flowa.'), onTap: () => Navigator.pop(ctx)))), icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF536176)))],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(13, 10, 13, 4), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE9EEF6))),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF477CF4))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MEMBAHAS PRODUK', style: TextStyle(fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w800, color: Color(0xFF8B97A9))),
              const SizedBox(height: 3),
              Text(widget.productTitle.isEmpty ? 'Percakapan dengan penjual' : widget.productTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF26354B))),
            ])),
            const Icon(Icons.verified_outlined, color: Color(0xFF37A77A), size: 18),
          ]),
        ),
        Expanded(child: FutureBuilder<void>(
          future: _chatReady,
          builder: (context, ready) {
            if (ready.hasError) return _empty(Icons.lock_outline, 'Percakapan belum siap', 'Periksa akun dan koneksi internet, lalu coba kembali.');
            if (ready.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: Color(0xFF477CF4)));
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _empty(Icons.cloud_off, 'Pesan tidak dapat dimuat', 'Coba periksa koneksi internet kamu.');
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF477CF4)));
                final messages = snap.data?.docs ?? [];
                if (messages.isEmpty) return _empty(Icons.waving_hand_rounded, 'Mulai percakapan!', 'Tanyakan detail produk, harga, stok, atau cara pengiriman kepada penjual.');
                return ListView.builder(
                  reverse: true, padding: const EdgeInsets.fromLTRB(14, 18, 14, 20), itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final mine = data['senderId'] == _uid;
                    final value = (data['text'] ?? '').toString();
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesan disalin')));
                        },
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                          margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                          decoration: BoxDecoration(
                            color: mine ? const Color(0xFF356DEB) : Colors.white,
                            borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18)),
                            boxShadow: [if (!mine) BoxShadow(color: const Color(0xFF253858).withOpacity(.045), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Align(alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(color: mine ? Colors.white : const Color(0xFF26354B), fontSize: 14, height: 1.4))),
                            const SizedBox(height: 5),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_clock(data['createdAt']), style: TextStyle(fontSize: 9, color: mine ? Colors.white.withOpacity(.75) : const Color(0xFF9AA5B5))),
                              if (mine) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, size: 13, color: Colors.white.withOpacity(.8))],
                            ]),
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
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: const Color(0xFF253858).withOpacity(.05), blurRadius: 14, offset: const Offset(0, -4))]),
          child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF2F4F8), borderRadius: BorderRadius.circular(23)),
              child: TextField(controller: _text, focusNode: _focus, minLines: 1, maxLines: 5, textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Tulis pesan...', hintStyle: TextStyle(color: Color(0xFF9AA5B5), fontSize: 13), contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 12), border: InputBorder.none)),
            )),
            const SizedBox(width: 9),
            Material(color: const Color(0xFF356DEB), borderRadius: BorderRadius.circular(18),
              child: InkWell(onTap: _sending ? null : _send, borderRadius: BorderRadius.circular(18),
                child: SizedBox(width: 47, height: 47, child: Center(child: _sending
                  ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 21))))),
          ])),
        ),
      ]),
    );
  }

  Widget _empty(IconData icon, String title, String subtitle) => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 38),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 74, height: 74, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFEAF0FF), Color(0xFFF0ECFF)])), child: Icon(icon, color: const Color(0xFF5278E8), size: 32)),
      const SizedBox(height: 17),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1C2940))),
      const SizedBox(height: 7),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF8995A7))),
    ]),
  ));
}
