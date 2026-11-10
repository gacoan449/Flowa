import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatisticsAdminPage extends StatefulWidget {
  const StatisticsAdminPage({super.key});

  @override
  State<StatisticsAdminPage> createState() => _StatisticsAdminPageState();
}

class _StatisticsAdminPageState extends State<StatisticsAdminPage> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _load();
  }

  Future<int> _count(String collection, {String? field, Object? equals}) async {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(collection);
    if (field != null) query = query.where(field, isEqualTo: equals);
    final result = await query.count().get();
    return result.count ?? 0;
  }

  Future<Map<String, int>> _load() async {
    final values = await Future.wait([
      _count('users'),
      _count('products'),
      _count('products', field: 'status', equals: 'active'),
      _count('reports'),
      _count('reports', field: 'status', equals: 'open'),
      _count('support_threads'),
      _count('banners', field: 'active', equals: true),
      _count('announcements', field: 'active', equals: true),
      _count('categories', field: 'active', equals: true),
    ]);
    return {
      'Pengguna': values[0],
      'Total iklan': values[1],
      'Iklan aktif': values[2],
      'Total laporan': values[3],
      'Laporan terbuka': values[4],
      'Percakapan bantuan': values[5],
      'Banner tayang': values[6],
      'Pengumuman aktif': values[7],
      'Kategori aktif': values[8],
    };
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _statsFuture = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Statistik Flowa'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 10),
                  Text('Statistik gagal dimuat: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!.entries.toList();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.45,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.value.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(entry.key),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
