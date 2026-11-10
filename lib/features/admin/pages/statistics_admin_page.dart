import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatisticsAdminPage extends StatelessWidget {
  const StatisticsAdminPage({super.key});

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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Statistik Flowa'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: () => (context as Element).markNeedsBuild(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, int>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Statistik gagal dimuat: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!.entries.toList();
        return RefreshIndicator(
          onRefresh: () async {
            // Rebuild the page so aggregate counts are requested again.
            (context as Element).markNeedsBuild();
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
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
