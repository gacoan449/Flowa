import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/cloudinary_service.dart';
import 'chat_profile_service.dart';

class ChatScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String productId;
  final String productTitle;
  const ChatScreen({super.key, required this.sellerId, required this.sellerName, required this.productId, required this.productTitle});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  bool _uploading = false;
  bool _recording = false;
  String? _playingUrl;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final Future<void> _chatReady;
  Timer? _typingTimer;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _chatId { final ids = [_uid, widget.sellerId]..sort(); return ids.join('_'); }
  DocumentReference<Map<String, dynamic>> get _chat =>
      FirebaseFirestore.instance.collection('chats').doc(_chatId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatReady = _ensureChat();
    _text.addListener(_onTextChanged);
  }

  Future<void> _ensureChat() async {
    if (widget.sellerId.isEmpty || widget.sellerId == _uid) throw StateError('ID penjual tidak valid.');
    await _chat.set({
      'participants': ([_uid, widget.sellerId]..sort()),
      'productId': widget.productId,
      'productTitle': widget.productTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await ChatProfileService.setPresence(_uid, true);
  }

  void _onTextChanged() {
    _typingTimer?.cancel();
    if (_text.text.trim().isEmpty) {
      _setTyping(false);
      return;
    }
    _setTyping(true);
    _typingTimer = Timer(const Duration(milliseconds: 900), () => _setTyping(false));
  }

  Future<void> _setTyping(bool value) async {
    try {
      await _chatReady;
      await _chat.update({'typing.$_uid': value});
    } catch (_) {}
  }

  Future<void> _markIncomingRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    var changed = false;
    for (final doc in docs) {
      final data = doc.data();
      if (data['senderId'] == _uid) continue;
      final delivered = List<String>.from(data['deliveredTo'] ?? const []);
      final read = List<String>.from(data['readBy'] ?? const []);
      if (!delivered.contains(_uid) || !read.contains(_uid)) {
        batch.update(doc.reference, {
          'deliveredTo': FieldValue.arrayUnion([_uid]),
          'readBy': FieldValue.arrayUnion([_uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        changed = true;
      }
    }
    if (changed) {
      try { await batch.commit(); } catch (_) {}
    }
  }

  String _clock(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending) return;
    await _sendPayload({'text': value, 'type': 'text'}, value);
  }

  Future<void> _sendPayload(Map<String, dynamic> payload, String preview) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await _chatReady;
      final batch = FirebaseFirestore.instance.batch();
      batch.set(_chat, {
        'lastMessage': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'typing.$_uid': false,
      }, SetOptions(merge: true));
      batch.set(_chat.collection('messages').doc(), {
        ...payload,
        'senderId': _uid,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': [_uid],
        'readBy': [_uid],
      });
      await batch.commit();
      _text.clear();
      _focus.requestFocus();
    } on FirebaseException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan gagal dikirim (${e.code}): ${e.message ?? ''}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan gagal dikirim: $e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _pickImage() async {
    if (_uploading || _sending) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800);
      if (picked == null || !mounted) return;
      setState(() => _uploading = true);
      final url = await CloudinaryService.uploadImage(File(picked.path), folder: 'flowa/chat/images');
      await _sendPayload({'type': 'image', 'mediaUrl': url, 'text': ''}, '📷 Foto');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto gagal dikirim: $e')));
    } finally { if (mounted) setState(() => _uploading = false); }
  }


  Future<void> _toggleRecording() async {
    if (_recording) {
      try {
        final path = await _recorder.stop();
        if (mounted) setState(() => _recording = false);
        if (path == null) return;
        setState(() => _uploading = true);
        final url = await CloudinaryService.uploadAudio(File(path));
        await _sendPayload({'type': 'audio', 'mediaUrl': url, 'text': ''}, '🎤 Pesan suara');
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan suara gagal dikirim: $e')));
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
      return;
    }
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin mikrofon diperlukan untuk merekam suara.')));
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '\${dir.path}/flowa_voice_\${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100), path: path);
      if (mounted) setState(() => _recording = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mikrofon tidak dapat dimulai: $e')));
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_playingUrl == url) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _playingUrl = null);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        if (mounted) setState(() => _playingUrl = url);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio tidak dapat diputar: $e')));
    }
  }

  Future<void> _react(DocumentReference<Map<String, dynamic>> ref, String emoji) async {
    try {
      await ref.update({'reactions.$_uid': emoji, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reaksi gagal disimpan: $e')));
    }
  }

  Future<void> _showMessageActions(DocumentSnapshot<Map<String, dynamic>> doc, String text) async {
    await showModalBottomSheet<void>(
      context: context, backgroundColor: Colors.white, showDragHandle: true,
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Reaksi pesan', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['❤️','😂','😮','😢','👍','🙏'].map((emoji) =>
            InkWell(onTap: () { Navigator.pop(ctx); _react(doc.reference, emoji); },
              child: Padding(padding: const EdgeInsets.all(7), child: Text(emoji, style: const TextStyle(fontSize: 27))))).toList()),
          if (text.isNotEmpty) ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Salin pesan'),
            onTap: () { Clipboard.setData(ClipboardData(text: text)); Navigator.pop(ctx); }),
        ]),
      )),
    );
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Blokir pengguna?'),
      content: const Text('Kamu dan pengguna ini tidak dapat saling mengirim pesan di percakapan ini.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Blokir')),
      ],
    ));
    if (confirm != true) return;
    try {
      await _chat.set({'blockedBy': FieldValue.arrayUnion([_uid])}, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('user_blocks').doc('${_uid}_${widget.sellerId}').set({
        'blockerId': _uid, 'blockedUserId': widget.sellerId, 'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengguna berhasil diblokir.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memblokir: $e')));
    }
  }

  Future<void> _reportUser() async {
    final reason = TextEditingController();
    final selected = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Laporkan pengguna'),
      content: TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(
        hintText: 'Jelaskan alasan laporan...', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, reason.text.trim()), child: const Text('Kirim laporan')),
      ],
    ));
    reason.dispose();
    if (selected == null || selected.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': _uid, 'targetUserId': widget.sellerId, 'chatId': _chatId,
        'reason': selected, 'type': 'chat_user', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan terkirim ke admin Flowa.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Laporan gagal dikirim: $e')));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ChatProfileService.setPresence(_uid, false);
      _setTyping(false);
    } else if (state == AppLifecycleState.resumed) {
      ChatProfileService.setPresence(_uid, true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    _text.removeListener(_onTextChanged);
    _setTyping(false);
    ChatProfileService.setPresence(_uid, false);
    _recorder.dispose();
    _audioPlayer.dispose();
    _text.dispose(); _focus.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0, titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ChatProfileService.watch(widget.sellerId),
          builder: (context, profileSnap) {
            final profile = profileSnap.data?.data() ?? {};
            final name = (profile['displayName'] ?? '').toString().trim().isEmpty
              ? widget.sellerName : profile['displayName'].toString();
            final photo = (profile['photoUrl'] ?? '').toString();
            return Row(children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0xFFEAF0FF),
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty ? const Icon(Icons.person_rounded, color: Color(0xFF477CF4)) : null),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B2940))),
                const SizedBox(height: 2),
                Text(profile['isOnline'] == true ? '● Aktif sekarang' : _lastSeen(profile['lastSeen']),
                  style: TextStyle(fontSize: 10, color: profile['isOnline'] == true ? const Color(0xFF20A56B) : const Color(0xFF8793A5))),
              ])),
            ]);
          },
        ),
        actions: [PopupMenuButton<String>(
          onSelected: (v) { if (v == 'report') _reportUser(); if (v == 'block') _blockUser(); },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'report', child: ListTile(leading: Icon(Icons.flag_outlined), title: Text('Laporkan'))),
            PopupMenuItem(value: 'block', child: ListTile(leading: Icon(Icons.block_rounded), title: Text('Blokir pengguna'))),
          ],
          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF536176)),
        )],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(13, 10, 13, 4), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE9EEF6))),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF477CF4))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MEMBAHAS PRODUK', style: TextStyle(fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w800, color: Color(0xFF8B97A9))),
              const SizedBox(height: 3),
              Text(widget.productTitle.isEmpty ? 'Percakapan dengan penjual' : widget.productTitle, maxLines: 1,
                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF26354B))),
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
              stream: _chat.collection('messages').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _empty(Icons.cloud_off, 'Pesan tidak dapat dimuat', 'Coba periksa koneksi internet kamu.');
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF477CF4)));
                final messages = snap.data?.docs ?? [];
                _markIncomingRead(messages);
                if (messages.isEmpty) return _empty(Icons.waving_hand_rounded, 'Mulai percakapan!', 'Tanyakan detail produk, harga, stok, atau cara pengiriman kepada penjual.');
                return ListView.builder(
                  reverse: true, padding: const EdgeInsets.fromLTRB(14, 18, 14, 20), itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index]; final data = doc.data();
                    final mine = data['senderId'] == _uid;
                    final value = (data['text'] ?? '').toString();
                    final type = (data['type'] ?? 'text').toString();
                    final media = (data['mediaUrl'] ?? '').toString();
                    final delivered = List<String>.from(data['deliveredTo'] ?? const []);
                    final read = List<String>.from(data['readBy'] ?? const []);
                    final statusColor = read.contains(widget.sellerId) ? const Color(0xFF66D9FF)
                      : delivered.contains(widget.sellerId) ? const Color(0xFFE0E8F5) : const Color(0xFFB7C3D5);
                    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () => _showMessageActions(doc, value),
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                          margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                          decoration: BoxDecoration(
                            color: mine ? const Color(0xFF244FC7) : Colors.white,
                            borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18)),
                            boxShadow: [if (!mine) BoxShadow(color: const Color(0xFF253858).withOpacity(.045), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            if (type == 'image' && media.isNotEmpty)
                              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(media, width: 220, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(12), child: Text('Foto tidak dapat dimuat'))))
                            else if (type == 'audio' && media.isNotEmpty)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(onPressed: () => _playAudio(media),
                                  icon: Icon(_playingUrl == media ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                    color: mine ? Colors.white : const Color(0xFF356DEB), size: 30)),
                                Text('Pesan suara', style: TextStyle(color: mine ? Colors.white : const Color(0xFF26354B), fontSize: 13)),
                              ])
                            else
                              Align(alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(color: mine ? Colors.white : const Color(0xFF26354B), fontSize: 14, height: 1.4))),
                            const SizedBox(height: 5),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_clock(data['createdAt']), style: TextStyle(fontSize: 9, color: mine ? Colors.white.withOpacity(.78) : const Color(0xFF9AA5B5))),
                              if (mine) ...[const SizedBox(width: 5), Icon(isDelivered ? Icons.done_all_rounded : Icons.done_rounded, size: 15, color: statusColor)],
                            ]),
                            if (reactions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5),
                              child: Wrap(spacing: 4, children: reactions.values.toSet().map((e) => Text(e.toString(), style: const TextStyle(fontSize: 17))).toList())),
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
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _chat.snapshots(),
          builder: (context, snapshot) {
            final typing = snapshot.data?.data()?['typing'];
            final otherTyping = typing is Map && typing[widget.sellerId] == true;
            return AnimatedContainer(duration: const Duration(milliseconds: 180), height: otherTyping ? 25 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.centerLeft,
              child: otherTyping ? const Text('Sedang mengetik…', style: TextStyle(fontSize: 11, color: Color(0xFF477CF4), fontStyle: FontStyle.italic)) : null);
          },
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(9, 9, 12, 9),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: const Color(0xFF253858).withOpacity(.05), blurRadius: 14, offset: const Offset(0, -4))]),
          child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(onPressed: _uploading || _sending ? null : _pickImage,
              icon: _uploading ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF477CF4))),
            IconButton(onPressed: _uploading ? null : _toggleRecording,
              icon: Icon(_recording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                color: _recording ? Colors.red : const Color(0xFF477CF4))),
            Expanded(child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF2F4F8), borderRadius: BorderRadius.circular(23)),
              child: TextField(controller: _text, focusNode: _focus, minLines: 1, maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Tulis pesan...', hintStyle: TextStyle(color: Color(0xFF9AA5B5), fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 12), border: InputBorder.none)),
            )),
            const SizedBox(width: 8),
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

  String _lastSeen(dynamic value) {
    if (value is! Timestamp) return 'Percakapan Flowa';
    final diff = DateTime.now().difference(value.toDate());
    if (diff.inMinutes < 1) return 'Terakhir aktif baru saja';
    if (diff.inHours < 1) return 'Terakhir aktif ${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return 'Terakhir aktif ${diff.inHours} jam lalu';
    return 'Terakhir aktif ${diff.inDays} hari lalu';
  }

  Widget _empty(IconData icon, String title, String subtitle) => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 38),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 74, height: 74, decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFEAF0FF), Color(0xFFF0ECFF)])),
        child: Icon(icon, color: const Color(0xFF5278E8), size: 32)),
      const SizedBox(height: 17), Text(title, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1C2940))),
      const SizedBox(height: 7), Text(subtitle, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF8995A7))),
    ]),
  ));
}
