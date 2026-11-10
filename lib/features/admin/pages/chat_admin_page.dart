import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../chat/support_chat_screen.dart';

class ChatAdminPage extends StatefulWidget {
  const ChatAdminPage({super.key});

  @override
  State<ChatAdminPage> createState() => _ChatAdminPageState();
}

class _ChatAdminPageState extends State<ChatAdminPage> {
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    String status,
  ) async {
    try {
      await ref.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'closed' ? 'Tiket ditutup.' : 'Tiket dibuka kembali.')),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah tiket (${e.code}): ${e.message ?? ''}')),
        );
      }
    }
  }

  String _timeLabel(dynamic value) {
    if (value is! Timestamp) return 'Waktu belum tersedia';
    final date = value.toDate().toLocal();
    final now = DateTime.now();
    final sameDay = date.year == now.year && date.month == now.month && date.day == now.day;
    final two = (int n) => n.toString().padLeft(2, '0');
    return sameDay
        ? '${two(date.hour)}:${two(date.minute)}'
        : '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Customer Service'),
      actions: [
        IconButton(
          tooltip: 'Bersihkan pencarian',
          onPressed: _search.text.isEmpty
              ? null
              : () => setState(() => _search.clear()),
          icon: const Icon(Icons.search_off),
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('support_threads')
          .orderBy('lastMessageAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Gagal memuat percakapan: ${snapshot.error}'),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data?.docs ?? [];
        final unreadCount = all.where((d) => d.data()['unreadForAdmin'] == true).length;
        final openCount = all.where((d) => (d.data()['status'] ?? 'open') != 'closed').length;
        final query = _search.text.trim().toLowerCase();
        final docs = all.where((doc) {
          final data = doc.data();
          final status = (data['status'] ?? 'open').toString();
          final unread = data['unreadForAdmin'] == true;
          final matchesFilter = _filter == 'all' ||
              (_filter == 'unread' && unread) ||
              (_filter == 'open' && status != 'closed') ||
              (_filter == 'closed' && status == 'closed');
          final searchable = [
            data['userName'], data['userEmail'], data['userId'],
            data['lastMessage'], doc.id,
          ].join(' ').toLowerCase();
          return matchesFilter && (query.isEmpty || searchable.contains(query));
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(child: _metric('Semua tiket', all.length, Icons.inbox_outlined)),
                  const SizedBox(width: 8),
                  Expanded(child: _metric('Belum dibaca', unreadCount, Icons.mark_chat_unread_outlined)),
                  const SizedBox(width: 8),
                  Expanded(child: _metric('Tiket aktif', openCount, Icons.support_agent)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nama, email, pesan, atau UID',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty ? null : IconButton(
                    onPressed: () => setState(() => _search.clear()),
                    icon: const Icon(Icons.close),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('all', 'Semua'),
                  _filterChip('unread', 'Belum dibaca'),
                  _filterChip('open', 'Aktif'),
                  _filterChip('closed', 'Selesai'),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(child: Text(all.isEmpty
                      ? 'Belum ada percakapan bantuan.'
                      : 'Tidak ada tiket yang cocok dengan pencarian.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final status = (data['status'] ?? 'open').toString();
                        final unread = data['unreadForAdmin'] == true;
                        final name = (data['userName'] ?? data['userEmail'] ?? 'Pengguna').toString();
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            leading: Badge(
                              isLabelVisible: unread,
                              label: const Text('BARU'),
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: const Icon(Icons.person_outline),
                              ),
                            ),
                            title: Row(children: [
                              Expanded(child: Text(name,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.w600))),
                              Text(_timeLabel(data['lastMessageAt']),
                                style: Theme.of(context).textTheme.labelSmall),
                            ]),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((data['lastMessage'] ?? 'Belum ada pesan').toString(),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(status == 'closed' ? 'Selesai' : 'Aktif'),
                                      backgroundColor: status == 'closed'
                                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                                          : Theme.of(context).colorScheme.primaryContainer,
                                    ),
                                    if (unread) const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Text('Perlu dibalas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _setStatus(context, doc.reference, value),
                              itemBuilder: (_) => [
                                if (status != 'open')
                                  const PopupMenuItem(value: 'open', child: Text('Buka tiket')),
                                if (status != 'closed')
                                  const PopupMenuItem(value: 'closed', child: Text('Tutup tiket')),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => SupportChatScreen(admin: true, threadId: doc.id),
                              ));
                              if (mounted) setState(() {});
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );

  Widget _metric(String label, int value, IconData icon) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      child: Column(children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 5),
        Text(value.toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall),
      ]),
    ),
  );

  Widget _filterChip(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    ),
  );
}
