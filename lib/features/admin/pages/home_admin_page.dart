import 'package:flutter/material.dart';

import '../../home/home_config_service.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  final _service = HomeConfigService();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _bannerTitle = TextEditingController();
  final _bannerSubtitle = TextEditingController();
  final _categories = TextEditingController();
  bool _showBanner = true;
  bool _showCategories = true;
  bool _showPopular = true;
  bool _loading = false;
  bool _loaded = false;

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _bannerTitle.dispose();
    _bannerSubtitle.dispose();
    _categories.dispose();
    super.dispose();
  }

  void _load(Map<String, dynamic> data) {
    if (_loaded) return;
    final merged = <String, dynamic>{...HomeConfigService.defaults}..addAll(data);
    _title.text = (merged['title'] ?? '').toString();
    _subtitle.text = (merged['subtitle'] ?? '').toString();
    _bannerTitle.text = (merged['bannerTitle'] ?? '').toString();
    _bannerSubtitle.text = (merged['bannerSubtitle'] ?? '').toString();
    _categories.text = (merged['categories'] as List<dynamic>).join(', ');
    _showBanner = merged['showBanner'] == true;
    _showCategories = merged['showCategories'] == true;
    _showPopular = merged['showPopular'] == true;
    _loaded = true;
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama aplikasi/beranda tidak boleh kosong.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final categories = _categories.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      await _service.save({
        'title': _title.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'bannerTitle': _bannerTitle.text.trim(),
        'bannerSubtitle': _bannerSubtitle.text.trim(),
        'categories': categories,
        'showBanner': _showBanner,
        'showCategories': _showCategories,
        'showPopular': _showPopular,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tampilan beranda berhasil diperbarui.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan beranda: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(String label, TextEditingController controller,
      {int lines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Builder')),
      body: StreamBuilder(
        stream: _service.watch(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat pengaturan: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _load(snapshot.data?.data() ?? {});
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Atur beranda Flowa tanpa mengubah kode aplikasi. Perubahan tersimpan ke Firebase dan tampil otomatis pada aplikasi pengguna.',
              ),
              const SizedBox(height: 18),
              _field('Nama / judul beranda', _title),
              _field('Deskripsi singkat', _subtitle),
              const Divider(height: 28),
              Text('Konten banner bawaan', style: Theme.of(context).textTheme.titleMedium),
              _field('Judul banner', _bannerTitle),
              _field('Subjudul banner', _bannerSubtitle, lines: 2),
              const Divider(height: 28),
              Text('Kategori marketplace', style: Theme.of(context).textTheme.titleMedium),
              _field(
                'Daftar kategori (pisahkan dengan koma)',
                _categories,
                lines: 3,
                hint: 'Mobil, Motor, Elektronik, Fashion',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tampilkan banner'),
                value: _showBanner,
                onChanged: (value) => setState(() => _showBanner = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tampilkan kategori'),
                value: _showCategories,
                onChanged: (value) => setState(() => _showCategories = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktifkan bagian populer (pengaturan siap untuk modul berikutnya)'),
                value: _showPopular,
                onChanged: (value) => setState(() => _showPopular = value),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_loading ? 'Menyimpan...' : 'Simpan & terbitkan perubahan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
