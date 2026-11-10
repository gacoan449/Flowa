import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/app_appearance.dart';

class AppDesignStudioPage extends StatefulWidget {
  const AppDesignStudioPage({super.key});
  @override
  State<AppDesignStudioPage> createState() => _AppDesignStudioPageState();
}

class _AppDesignStudioPageState extends State<AppDesignStudioPage> {
  final _db = FirebaseFirestore.instance;
  final _labels = <String, TextEditingController>{};
  final _icons = <String, String>{};
  final _backgrounds = <String, int>{};
  int _primary = 0xFF0866FF;
  int _accent = 0xFF00A8FF;
  int _scaffold = 0xFFF6F8FC;
  int _surface = 0xFFFFFFFF;
  int _textColor = 0xFF172033;
  double _radius = 18;
  double _buttonRadius = 14;
  double _iconSize = 22;
  double _buttonHeight = 48;
  double _elevation = 0;
  String _buttonStyle = 'filled';
  bool _loaded = false;
  bool _saving = false;

  static const _screens = <String, String>{
    'home': 'Beranda',
    'marketplace': 'Marketplace',
    'chat': 'Daftar Chat',
    'chatDetail': 'Ruang Chat',
    'upload': 'Pasang Iklan',
    'profile': 'Profil Pengguna',
    'settings': 'Pengaturan Akun',
    'favorites': 'Favorit',
    'orders': 'Pesanan',
    'myListings': 'Iklan Saya',
    'sellerStore': 'Toko Penjual',
    'discover': 'Temukan Pengguna',
  };
  static const _palettes = <int>[
    0xFF0866FF, 0xFF6750A4, 0xFF00897B, 0xFFEF6C00,
    0xFFD81B60, 0xFF3949AB, 0xFF455A64, 0xFF111827,
    0xFFF6F8FC, 0xFFFFFFFF, 0xFF101827, 0xFF1B2638,
    0xFFFFF4D8, 0xFFEAF3FF, 0xFFFCEEF4, 0xFFEAF8F3,
  ];
  static const _iconOptions = <String>[
    'home','home_outline','chat','chat_outline','message','add','add_outline',
    'store','search','person','person_outline','favorite','grid','category',
    'shopping','wallet','settings','notifications','support','location','sell','local_offer'
  ];

  @override
  void initState() {
    super.initState();
    for (final key in ['home','chat','upload','profile']) {
      _labels[key] = TextEditingController(text: AppAppearance.defaults['navigation'][key + 'Label'] as String);
      _icons[key] = AppAppearance.defaults['navigation'][key + 'Icon'] as String;
    }
    _backgrounds.addAll(Map<String, int>.from(AppAppearance.defaults['screenBackgrounds'] as Map));
  }

  @override
  void dispose() {
    for (final c in _labels.values) { c.dispose(); }
    super.dispose();
  }

  void _load(Map<String, dynamic> data) {
    if (_loaded) return;
    _primary = (data['primaryColor'] as num?)?.toInt() ?? _primary;
    _accent = (data['accentColor'] as num?)?.toInt() ?? _accent;
    _scaffold = (data['scaffoldColor'] as num?)?.toInt() ?? _scaffold;
    _surface = (data['surfaceColor'] as num?)?.toInt() ?? _surface;
    _textColor = (data['textColor'] as num?)?.toInt() ?? _textColor;
    _radius = (data['cornerRadius'] as num?)?.toDouble() ?? _radius;
    _buttonRadius = (data['buttonRadius'] as num?)?.toDouble() ?? _buttonRadius;
    _iconSize = (data['iconSize'] as num?)?.toDouble() ?? _iconSize;
    _buttonHeight = (data['buttonHeight'] as num?)?.toDouble() ?? _buttonHeight;
    _elevation = (data['cardElevation'] as num?)?.toDouble() ?? _elevation;
    _buttonStyle = (data['buttonStyle'] ?? _buttonStyle).toString();
    final nav = Map<String, dynamic>.from(data['navigation'] is Map ? data['navigation'] as Map : {});
    for (final key in _labels.keys) {
      _labels[key]!.text = (nav[key + 'Label'] ?? _labels[key]!.text).toString();
      _icons[key] = (nav[key + 'Icon'] ?? _icons[key]).toString();
    }
    final backgrounds = data['screenBackgrounds'];
    if (backgrounds is Map) {
      for (final entry in backgrounds.entries) {
        if (_backgrounds.containsKey(entry.key) && entry.value is num) {
          _backgrounds[entry.key.toString()] = (entry.value as num).toInt();
        }
      }
    }
    _loaded = true;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final navigation = <String, dynamic>{};
      for (final key in _labels.keys) {
        navigation[key + 'Label'] = _labels[key]!.text.trim();
        navigation[key + 'Icon'] = _icons[key];
      }
      final data = <String, dynamic>{
        'primaryColor': _primary,
        'accentColor': _accent,
        'scaffoldColor': _scaffold,
        'surfaceColor': _surface,
        'textColor': _textColor,
        'cornerRadius': _radius,
        'buttonRadius': _buttonRadius,
        'iconSize': _iconSize,
        'buttonHeight': _buttonHeight,
        'cardElevation': _elevation,
        'buttonStyle': _buttonStyle,
        'navigation': navigation,
        'screenBackgrounds': _backgrounds,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'schemaVersion': 1,
      };
      await _db.collection('app_config').doc('appearance').set(data, SetOptions(merge: true));
      await _db.collection('admin_audit_logs').add({
        'actorUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'action': 'appearance_config_updated',
        'createdAt': FieldValue.serverTimestamp(),
        'changedKeys': data.keys.toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Desain global berhasil diterbitkan ke aplikasi.')));
      }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan desain: $e'))); }
    } finally {
      if (mounted) { setState(() => _saving = false); }
    }
  }

  Widget _colorPicker(String title, int value, ValueChanged<int> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 9),
      Wrap(spacing: 9, runSpacing: 9, children: _palettes.map((color) => InkWell(
        onTap: () => setState(() => onChanged(color)),
        customBorder: const CircleBorder(),
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle,
            border: Border.all(color: value == color ? Theme.of(context).colorScheme.primary : Colors.black12, width: value == color ? 3 : 1)),
          child: value == color ? const Icon(Icons.check, size: 17, color: Colors.white) : null,
        ),
      )).toList()),
      const SizedBox(height: 16),
    ]);
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {String suffix = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label)), Text(value.toStringAsFixed(0) + suffix, style: const TextStyle(fontWeight: FontWeight.bold))]),
      Slider(value: value.clamp(min, max).toDouble(), min: min, max: max, onChanged: (v) => setState(() => onChanged(v))),
    ]);
  }

  Widget _section(String title, String subtitle, List<Widget> children) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 16), ...children,
    ])),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AppAppearance.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_loaded) { _load(snapshot.data!.data() ?? {}); }
        if (snapshot.hasError) return Scaffold(appBar: AppBar(title: const Text('Visual Design Studio')), body: Center(child: Text('Gagal memuat desain: ${snapshot.error}')));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return Scaffold(
          appBar: AppBar(title: const Text('Visual Design Studio')),
          body: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 100), children: [
            _section('Live Preview', 'Contoh komponen mengikuti token desain yang akan diterapkan global.', [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Color(_scaffold), borderRadius: BorderRadius.circular(_radius), border: Border.all(color: Colors.black12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.hub_rounded, color: Color(_primary), size: _iconSize), const SizedBox(width: 8), Text('Flowa • Preview', style: TextStyle(color: Color(_textColor), fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 14),
                  Container(height: 44, decoration: BoxDecoration(color: Color(_surface), borderRadius: BorderRadius.circular(_radius)), child: const Row(children: [SizedBox(width: 12), Icon(Icons.search), SizedBox(width: 8), Text('Cari di Flowa')])),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Container(height: 74, decoration: BoxDecoration(color: Color(_accent).withValues(alpha: .18), borderRadius: BorderRadius.circular(_radius)), child: Center(child: Icon(Icons.photo_outlined, color: Color(_primary), size: 30)))),
                    const SizedBox(width: 9),
                    Expanded(child: Container(height: 74, decoration: BoxDecoration(color: Color(_surface), borderRadius: BorderRadius.circular(_radius)), child: const Center(child: Text('Kartu Produk')))),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(height: _buttonHeight, width: double.infinity, child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Color(_primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius))),
                    onPressed: () {}, child: const Text('Tombol Utama Preview'))),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    for (final entry in _labels.entries) Column(children: [
                      Icon(AppAppearance.icon(_icons[entry.key] ?? 'home'), color: Color(_primary), size: _iconSize),
                      Text(entry.value.text.isEmpty ? entry.key : entry.value.text, style: const TextStyle(fontSize: 10)),
                    ]),
                  ]),
                ]),
              ),
            ]),
            _section('Brand & Warna', 'Atur identitas warna, latar, permukaan kartu, dan teks.', [
              _colorPicker('Warna utama', _primary, (v) => _primary = v),
              _colorPicker('Warna aksen', _accent, (v) => _accent = v),
              _colorPicker('Background aplikasi', _scaffold, (v) => _scaffold = v),
              _colorPicker('Background kartu / surface', _surface, (v) => _surface = v),
              _colorPicker('Warna teks utama', _textColor, (v) => _textColor = v),
            ]),
            _section('Bentuk & Komponen', 'Kontrol radius, ukuran ikon, tinggi tombol, dan elevasi kartu.', [
              _slider('Radius kartu / input', _radius, 0, 36, (v) => _radius = v, suffix: ' px'),
              _slider('Radius tombol', _buttonRadius, 0, 36, (v) => _buttonRadius = v, suffix: ' px'),
              _slider('Ukuran ikon global', _iconSize, 14, 36, (v) => _iconSize = v, suffix: ' px'),
              _slider('Tinggi tombol', _buttonHeight, 36, 72, (v) => _buttonHeight = v, suffix: ' px'),
              _slider('Elevasi kartu', _elevation, 0, 12, (v) => _elevation = v),
              DropdownButtonFormField<String>(
                initialValue: _buttonStyle,
                decoration: const InputDecoration(labelText: 'Gaya tombol default'),
                items: const [
                  DropdownMenuItem(value: 'filled', child: Text('Filled / solid')),
                  DropdownMenuItem(value: 'outlined', child: Text('Outlined')),
                  DropdownMenuItem(value: 'soft', child: Text('Soft / tonal')),
                ],
                onChanged: (v) => setState(() => _buttonStyle = v ?? 'filled'),
              ),
            ]),
            _section('Navigasi & Ikon', 'Ganti label dan bentuk ikon navigasi utama.', [
              for (final key in _labels.keys) Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Expanded(child: TextField(controller: _labels[key], decoration: InputDecoration(labelText: 'Label ${key == 'home' ? 'Beranda' : key == 'chat' ? 'Chat' : key == 'upload' ? 'Pasang Iklan' : 'Profil'}'))),
                  const SizedBox(width: 10),
                  SizedBox(width: 150, child: DropdownButtonFormField<String>(
                    initialValue: _iconOptions.contains(_icons[key]) ? _icons[key] : 'home',
                    decoration: const InputDecoration(labelText: 'Ikon'),
                    items: _iconOptions.map((v) => DropdownMenuItem(value: v, child: Row(children: [Icon(AppAppearance.icon(v), size: 18), const SizedBox(width: 7), Flexible(child: Text(v, overflow: TextOverflow.ellipsis))]))).toList(),
                    onChanged: (v) => setState(() => _icons[key] = v ?? 'home'),
                  )),
                ]),
              ),
            ]),
            _section('Background per Halaman', 'Tentukan warna latar khusus untuk setiap area aplikasi.', [
              for (final entry in _screens.entries) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 7),
                  Wrap(spacing: 8, children: _palettes.take(12).map((color) => InkWell(
                    onTap: () => setState(() => _backgrounds[entry.key] = color),
                    customBorder: const CircleBorder(),
                    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle,
                      border: Border.all(color: _backgrounds[entry.key] == color ? Theme.of(context).colorScheme.primary : Colors.black12, width: _backgrounds[entry.key] == color ? 3 : 1))),
                  )).toList()),
                ]),
              ),
            ]),
          ]),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.publish_rounded),
              label: Text(_saving ? 'Menerbitkan...' : 'Terapkan ke seluruh aplikasi'),
            ),
          ),
        );
      },
    );
  }
}
