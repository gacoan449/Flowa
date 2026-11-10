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

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  bool _uploading = false;
  bool _recording = false;
  String? _recordedAudioPath;
  Duration? _recordedAudioDuration;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;
  String? _playingUrl;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _audioCompleteSub;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  late final Future<void> _chatReady;
  Timer? _typingTimer;
  Timer? _lastSeenRefreshTimer;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _chatId { final ids = [_uid, widget.sellerId]..sort(); return ids.join('_'); }
  DocumentReference<Map<String, dynamic>> get _chat =>
      FirebaseFirestore.instance.collection('chats').doc(_chatId);

  @override
  void initState() {
    super.initState();
    _chatReady = _ensureChat();
    _text.addListener(_onTextChanged);
    _lastSeenRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _audioCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingUrl = null;
        _audioPosition = Duration.zero;
      });
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _audioPosition = position);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _audioDuration = duration);
    });
  }

  Future<void> _ensureChat() async {
    if (widget.sellerId.isEmpty || widget.sellerId == _uid) throw StateError('ID penjual tidak valid.');
    final metadata = <String, dynamic>{
      'participants': ([_uid, widget.sellerId]..sort()),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Direct messages must not erase an existing product context for this pair.
    if (widget.productId.isNotEmpty) {
      metadata['productId'] = widget.productId;
      metadata['productTitle'] = widget.productTitle;
    }
    await _chat.set(metadata, SetOptions(merge: true));
    try { await ChatProfileService.setPresence(_uid, true); } catch (_) {}
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

  Future<bool> _sendPayload(Map<String, dynamic> payload, String preview) async {
    if (_sending) return false;
    setState(() => _sending = true);
    try {
      await _chatReady;
      final batch = FirebaseFirestore.instance.batch();
      batch.set(_chat, {
        'lastMessage': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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
      return true;
    } on FirebaseException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan gagal dikirim (${e.code}): ${e.message ?? ''}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan gagal dikirim: $e')));
    } finally { if (mounted) setState(() => _sending = false); }
    return false;
  }

  Future<void> _pickImage() async {
    if (_uploading || _sending) return;
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 82, maxWidth: 1800);
      if (picked.isEmpty || !mounted) return;
      setState(() => _uploading = true);
      for (final image in picked.take(10)) {
        final url = await CloudinaryService.uploadImage(File(image.path), folder: 'flowa/chat/images');
        await _sendPayload({'type': 'image', 'mediaUrl': url, 'text': ''}, '📷 Foto');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto gagal dikirim: $e')));
    } finally { if (mounted) setState(() => _uploading = false); }
  }



  Future<void> _chooseEmoji() async {
    const emojis = ['😀','😂','🥰','😍','😊','😉','😭','😎','🤔','😮','😡','❤️','🔥','👍','🙏','🎉'];
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(spacing: 14, runSpacing: 14, children: emojis.map((emoji) =>
          InkWell(onTap: () {
            final value = _text.value;
            final selection = value.selection;
            final start = selection.isValid ? selection.start : value.text.length;
            final end = selection.isValid ? selection.end : value.text.length;
            final next = value.text.replaceRange(start, end, emoji);
            _text.value = TextEditingValue(text: next,
              selection: TextSelection.collapsed(offset: start + emoji.length));
            Navigator.pop(ctx);
            _focus.requestFocus();
          }, child: Text(emoji, style: const TextStyle(fontSize: 29)))).toList(),
        ),
      )),
    );
  }

  Future<void> _startRecording() async {
    if (_recording || _uploading || _recordedAudioPath != null) return;
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin mikrofon diperlukan untuk merekam suara.')));
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/flowa_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100), path: path);
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordingElapsed = Duration.zero;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _recording) {
          setState(() => _recordingElapsed += const Duration(seconds: 1));
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mikrofon tidak dapat dimulai: $e')));
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    try {
      final path = await _recorder.stop();
      _recordingTimer?.cancel();
      if (!mounted) return;
      setState(() => _recording = false);
      if (path == null) return;
      Duration? recordedDuration;
      final probe = AudioPlayer();
      try {
        await probe.setSource(DeviceFileSource(path));
        recordedDuration = await probe.getDuration();
      } catch (_) {
        recordedDuration = _recordingElapsed;
      } finally {
        await probe.dispose();
      }
      if (!mounted) return;
      setState(() {
        _recordedAudioPath = path;
        _recordedAudioDuration = (recordedDuration == null || recordedDuration == Duration.zero)
            ? _recordingElapsed
            : recordedDuration;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rekaman gagal dihentikan: $e')));
      }
    }
  }

  Future<void> _sendRecordedAudio() async {
    final path = _recordedAudioPath;
    if (path == null || _uploading || _sending) return;
    setState(() => _uploading = true);
    try {
      final url = await CloudinaryService.uploadAudio(File(path));
      final sent = await _sendPayload({
        'type': 'audio',
        'mediaUrl': url,
        'text': '',
        if (_recordedAudioDuration != null)
          'durationMs': _recordedAudioDuration!.inMilliseconds,
      }, '🎤 Pesan suara');
      if (sent && mounted) {
        setState(() {
          _recordedAudioPath = null;
          _recordedAudioDuration = null;
        });
        try { await File(path).delete(); } catch (_) {}
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan suara gagal dikirim: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _discardRecordedAudio() async {
    final path = _recordedAudioPath;
    setState(() {
      _recordedAudioPath = null;
      _recordedAudioDuration = null;
    });
    if (path != null) {
      try { await File(path).delete(); } catch (_) {}
    }
  }

  String _formatAudioTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _playAudio(String url, {Duration? knownDuration}) async {
    try {
      if (_playingUrl == url) {
        await _audioPlayer.stop();
        if (mounted) {
          setState(() {
            _playingUrl = null;
            _audioPosition = Duration.zero;
          });
        }
        return;
      }
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _playingUrl = url;
          _audioPosition = Duration.zero;
          _audioDuration = knownDuration ?? Duration.zero;
        });
      }
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        setState(() => _playingUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio tidak dapat diputar: $e')),
        );
      }
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

  Future<void> _unblockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buka blokir pengguna?'),
        content: const Text('Pengguna ini dapat kembali mengirim pesan kepadamu setelah blokir dibuka.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buka blokir')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _chat.update({
        'blockedBy': FieldValue.arrayRemove([_uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final blockRef = FirebaseFirestore.instance
          .collection('user_blocks').doc('${_uid}_${widget.sellerId}');
      final block = await blockRef.get();
      if (block.exists) await blockRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blokir berhasil dibuka.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka blokir: $e')),
        );
      }
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
  void dispose() {
    _typingTimer?.cancel();
    _lastSeenRefreshTimer?.cancel();
    _recordingTimer?.cancel();
    _text.removeListener(_onTextChanged);
    _setTyping(false);
    _audioCompleteSub?.cancel();
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
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _chat.snapshots(),
            builder: (context, chatSnapshot) {
              final blockedBy = List<String>.from(
                chatSnapshot.data?.data()?['blockedBy'] ?? const [],
              );
              final blockedByMe = blockedBy.contains(_uid);
              return PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'report') _reportUser();
                  if (v == 'block') _blockUser();
                  if (v == 'unblock') _unblockUser();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Laporkan'),
                    ),
                  ),
                  PopupMenuItem(
                    value: blockedByMe ? 'unblock' : 'block',
                    child: ListTile(
                      leading: Icon(blockedByMe ? Icons.lock_open_rounded : Icons.block_rounded),
                      title: Text(blockedByMe ? 'Buka blokir' : 'Blokir pengguna'),
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF536176)),
              );
            },
          ),
        ],
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
              Text(widget.productTitle.isEmpty ? 'PESAN LANGSUNG' : 'MEMBAHAS PRODUK', style: const TextStyle(fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w800, color: Color(0xFF8B97A9))),
              const SizedBox(height: 3),
              Text(widget.productTitle.isEmpty ? 'Percakapan pribadi di Flowa' : widget.productTitle, maxLines: 1,
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
                    final isRead = read.contains(widget.sellerId);
                    final isDelivered = delivered.contains(widget.sellerId);
                    final statusColor = isRead ? const Color(0xFF45D6FF)
                      : isDelivered ? const Color(0xFFD5DEED) : const Color(0xFFB7C3D5);
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
                              InkWell(
                                onTap: () => _playAudio(
                                  media,
                                  knownDuration: Duration(
                                    milliseconds: (data['durationMs'] as num?)?.toInt() ?? 0,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(
                                      _playingUrl == media
                                          ? Icons.stop_circle_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: mine ? Colors.white : const Color(0xFF356DEB),
                                      size: 34,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Pesan suara', style: TextStyle(
                                          color: mine ? Colors.white : const Color(0xFF26354B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        )),
                                        const SizedBox(height: 2),
                                        Text(
                                          _playingUrl == media
                                              ? '${_formatAudioTime(_audioPosition)} / ${_formatAudioTime(_audioDuration)}'
                                              : _formatAudioTime(Duration(
                                                  milliseconds: (data['durationMs'] as num?)?.toInt() ?? 0,
                                                )),
                                          style: TextStyle(
                                            color: mine ? Colors.white70 : const Color(0xFF8793A5),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]),
                                ),
                              )
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
          child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_recording || _recordedAudioPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _recording ? const Color(0xFFFFF0F0) : const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(
                      _recording ? Icons.fiber_manual_record_rounded : Icons.mic_rounded,
                      color: _recording ? Colors.red : const Color(0xFF356DEB),
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _recording ? 'Sedang merekam suara...' : 'Rekaman siap dikirim',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF26354B)),
                        ),
                        Text(
                          _formatAudioTime(_recording ? _recordingElapsed : (_recordedAudioDuration ?? Duration.zero)),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF68778D)),
                        ),
                      ],
                    )),
                    if (_recording)
                      FilledButton.icon(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('Stop'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD94141), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
                      )
                    else ...[
                      IconButton(
                        tooltip: 'Hapus rekaman',
                        onPressed: _uploading ? null : _discardRecordedAudio,
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD94141)),
                      ),
                      FilledButton.icon(
                        onPressed: _uploading || _sending ? null : _sendRecordedAudio,
                        icon: _uploading
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(_uploading ? 'Mengirim' : 'Kirim'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF356DEB), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
                      ),
                    ],
                  ]),
                ),
              ),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(onPressed: _uploading || _sending ? null : _chooseEmoji,
              icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF477CF4))),
            IconButton(onPressed: _uploading || _sending ? null : _pickImage,
              icon: _uploading ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF477CF4))),
            if (!_recording && _recordedAudioPath == null)
              IconButton(
                tooltip: 'Rekam pesan suara',
                onPressed: _uploading || _sending ? null : _startRecording,
                icon: const Icon(Icons.mic_rounded, color: Color(0xFF477CF4)),
              ),
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
          ]),
          ]),
          ),
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
