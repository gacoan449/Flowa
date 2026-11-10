import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SystemLogsAdminPage extends StatelessWidget {
  const SystemLogsAdminPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(title: const Text('System Logs'), bottom: const TabBar(tabs: [
        Tab(text: 'Kegagalan Aplikasi'), Tab(text: 'Audit Admin'),
      ])),
      body: TabBarView(children: [
        _LogList(collection: 'client_error_logs', titleKey: 'message', subtitleKeys: ['source','uid']),
        _LogList(collection: 'admin_audit_logs', titleKey: 'action', subtitleKeys: ['actorUid','targetUid']),
      ]),
    ),
  );
}

class _LogList extends StatelessWidget {
  const _LogList({required this.collection, required this.titleKey, required this.subtitleKeys});
  final String collection;
  final String titleKey;
  final List<String> subtitleKeys;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection(collection).orderBy('createdAt', descending: true).limit(100).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Log tidak dapat dibaca: ${snapshot.error}')));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return const Center(child: Text('Belum ada catatan.'));
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final data = docs[index].data();
          final title = (data[titleKey] ?? 'Log').toString();
          final detail = subtitleKeys.map((key) => data[key] == null ? '' : '$key: ${data[key]}').where((v) => v.isNotEmpty).join(' • ');
          final timestamp = data['createdAt'];
          final time = timestamp is Timestamp ? timestamp.toDate().toLocal().toString() : 'Waktu tidak tersedia';
          return Card(child: ExpansionTile(
            leading: Icon(collection == 'client_error_logs' ? Icons.error_outline : Icons.history, color: collection == 'client_error_logs' ? Colors.red : null),
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('$detail\n$time'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if ((data['stack'] ?? '').toString().isNotEmpty) SelectableText((data['stack']).toString()),
              if (data['changedKeys'] is List) Text('Field: ${(data['changedKeys'] as List).join(', ')}'),
              if (data['role'] != null) Text('Role: ${data['role']}'),
            ],
          ));
        },
      );
    },
  );
}
