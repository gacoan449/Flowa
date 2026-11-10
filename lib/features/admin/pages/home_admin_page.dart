import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _searchHint = TextEditingController();
  final _bannerTitle = TextEditingController();
  final _bannerSubtitle = TextEditingController();

  int _primary = 0xFF0758D9, _accent = 0xFF00A8FF, _background = 0xFFF7F9FC, _columns = 2;
  double _bannerHeight = 132, _spacing = 10;
  String _theme = 'light', _selected = 'header';
  List<String> _order = [...HomeConfigService.defaults['sectionOrder'] as List<String>];
  Map<String, bool> _visible = {for (final s in HomeConfigService.availableSections) s: true};
  DateTime? _start, _end;
  bool _loaded = false, _saving = false;
  static const _palettes = <String, List<int>>{
    'Biru Flowa': [0xFF0758D9, 0xFF00A8FF],
    'Oranye': [0xFFEA580C, 0xFFF59E0B],
    'Hijau': [0xFF15803D, 0xFF4ADE80],
    'Ungu': [0xFF6D28D9, 0xFFA78BFA],
    'Merah muda': [0xFFBE123C, 0xFFFB7185],
    'Monokrom': [0xFF202124, 0xFF6B7280],
  };

  @override
  void dispose() {
    _title.dispose(); _subtitle.dispose(); _searchHint.dispose();
    _bannerTitle.dispose(); _bannerSubtitle.dispose();
    super.dispose();
  }

  DateTime? _toDate(dynamic value) => value is Timestamp ? value.toDate() : value is DateTime ? value : null;

  void _load(Map<String, dynamic> data) {
    if (_loaded) return;
    final map = {...HomeConfigService.defaults, ...data};
    _title.text = (map['title'] ?? 'Flowa').toString();
    _subtitle.text = (map['subtitle'] ?? '').toString();
    _searchHint.text = (map['searchHint'] ?? 'Cari barang di sekitar Anda...').toString();
    _bannerTitle.text = (map['bannerTitle'] ?? '').toString();
    _bannerSubtitle.text = (map['bannerSubtitle'] ?? '').toString();
    _primary = (map['primaryColor'] as num?)?.toInt() ?? 0xFF0758D9;
    _accent = (map['accentColor'] as num?)?.toInt() ?? 0xFF00A8FF;
    _background = (map['backgroundColor'] as num?)?.toInt() ?? 0xFFF7F9FC;
    _theme = (map['themeMode'] ?? 'light').toString();
    _bannerHeight = (map['bannerHeight'] as num?)?.toDouble() ?? 132;
    _spacing = (map['productSpacing'] as num?)?.toDouble() ?? 10;
    _columns = (map['productColumns'] as num?)?.toInt() ?? 2;
    if (map['sectionOrder'] is List) {
      _order = (map['sectionOrder'] as List).map((e) => e.toString())
          .where(HomeConfigService.availableSections.contains).toList();
      for (final section in HomeConfigService.availableSections) {
        if (!_order.contains(section)) _order.add(section);
      }
    }
    if (map['sectionVisibility'] is Map) {
      final value = map['sectionVisibility'] as Map;
      _visible = {for (final section in HomeConfigService.availableSections) section: value[section] != false};
    }
    _start = _toDate(map['promoStartAt']);
    _end = _toDate(map['promoEndAt']);
    _loaded = true;
  }

  String _name(String key) => {
    'header': 'Header / identitas toko',
    'search': 'Kolom pencarian',
    'banner': 'Banner promosi',
    'announcement': 'Pengumuman',
    'categories': 'Kategori produk',
    'products': 'Daftar produk',
  }[key] ?? key;

  IconData _icon(String key) => {
    'header': Icons.storefront_outlined,
    'search': Icons.search,
    'banner': Icons.view_carousel_outlined,
    'announcement': Icons.campaign_outlined,
    'categories': Icons.category_outlined,
    'products': Icons.grid_view_rounded,
  }[key] ?? Icons.widgets_outlined;

  String _dateLabel(DateTime? date) => date == null ? 'Tidak dijadwalkan' : '${date.day}/${date.month}/${date.year}';

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _start : _end) ?? DateTime.now();
    final date = await showDatePicker(context: context, initialDate: initial,
      firstDate: DateTime(2024), lastDate: DateTime(2035));
    if (date != null) setState(() { if (isStart) { _start = date; } else { _end = date; } });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama Home tidak boleh kosong.')));
      return;
    }
    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal akhir harus setelah tanggal mulai.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.save({
        'title': _title.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'searchHint': _searchHint.text.trim(),
        'bannerTitle': _bannerTitle.text.trim(),
        'bannerSubtitle': _bannerSubtitle.text.trim(),
        'primaryColor': _primary,
        'accentColor': _accent,
        'backgroundColor': _background,
        'themeMode': _theme,
        'bannerHeight': _bannerHeight,
        'productColumns': _columns,
        'productSpacing': _spacing,
        'sectionOrder': _order,
        'sectionVisibility': _visible,
        'showHeader': _visible['header'],
        'showSearch': _visible['search'],
        'showBanner': _visible['banner'],
        'showCategories': _visible['categories'],
        'promoStartAt': _start == null ? null : Timestamp.fromDate(_start!),
        'promoEndAt': _end == null ? null : Timestamp.fromDate(_end!),
        'builderVersion': 3,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tampilan Home berhasil dipublikasikan.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _panel(String title, String description, Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE7ECF3))),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 14),
        child,
      ]),
    ),
  );

  Widget _field(String label, TextEditingController controller, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: controller, onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder())),
  );

  Widget _swatches(String label, int current, ValueChanged<int> change, int index) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(spacing: 10, runSpacing: 8, children: [
        for (final palette in _palettes.entries)
          Tooltip(message: palette.key, child: InkWell(
            onTap: () => change(palette.value[index]),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: Color(palette.value[index]), shape: BoxShape.circle,
                border: Border.all(color: current == palette.value[index] ? Colors.black : Colors.white, width: current == palette.value[index] ? 3 : 1)),
            ),
          )),
      ]),
    ],
  );

  Widget _previewBlock(String key) {
    final selected = key == _selected;
    final color = Color(_primary);
    Widget child;
    switch (key) {
      case 'header':
        child = Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(_primary), Color(_accent)]), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_title.text.isEmpty ? 'Nama Home' : _title.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            Text(_subtitle.text, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ]),
        );
        break;
      case 'search':
        child = Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.black12)),
          child: Row(children: [const Icon(Icons.search, size: 17), const SizedBox(width: 7), Expanded(child: Text(_searchHint.text, style: const TextStyle(fontSize: 10, color: Colors.black54)))]));
        break;
      case 'banner':
        child = Container(height: _bannerHeight.clamp(60, 120), alignment: Alignment.center, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(_accent).withOpacity(.35), Color(_primary).withOpacity(.18)]), borderRadius: BorderRadius.circular(9)),
          child: Text(_bannerTitle.text.isEmpty ? 'Banner promosi' : _bannerTitle.text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold)));
        break;
      case 'announcement':
        child = Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF2D6), borderRadius: BorderRadius.circular(9)),
          child: const Row(children: [Icon(Icons.campaign_outlined, size: 16), SizedBox(width: 7), Text('Pengumuman terbaru', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]));
        break;
      case 'categories':
        child = Wrap(spacing: 5, children: ['Semua', 'Elektronik', 'Fashion'].map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 9)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)).toList());
        break;
      default:
        child = Row(children: List.generate(_columns, (index) => Expanded(child: Container(
          margin: EdgeInsets.only(right: index == _columns - 1 ? 0 : _spacing / 2),
          padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7)),
          child: Column(children: [
            Container(height: 34, decoration: BoxDecoration(color: Color(_accent).withOpacity(.2), borderRadius: BorderRadius.circular(5)), child: const Center(child: Icon(Icons.image_outlined, size: 16))),
            const SizedBox(height: 5), Container(height: 5, width: double.infinity, color: Colors.black12),
            const SizedBox(height: 4), Container(height: 5, width: 30, color: color.withOpacity(.4)),
          ]),
        ))));
    }
    return InkWell(
      onTap: () => setState(() => _selected = key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? color : Colors.transparent, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: selected ? color.withOpacity(.06) : Colors.transparent,
        ),
        child: Row(children: [
          Icon(Icons.drag_indicator, size: 17, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Expanded(child: child),
          const SizedBox(width: 5),
          Icon(selected ? Icons.tune : Icons.touch_app_outlined, size: 16, color: selected ? color : Colors.grey),
        ]),
      ),
    );
  }

  Widget _editorForSelected() {
    switch (_selected) {
      case 'header':
        return Column(children: [_field('Nama / judul Home', _title), _field('Deskripsi singkat', _subtitle)]);
      case 'search':
        return _field('Placeholder pencarian', _searchHint, hint: 'Cari barang di sekitar Anda...');
      case 'banner':
        return Column(children: [
          _field('Judul banner fallback', _bannerTitle),
          _field('Subjudul banner fallback', _bannerSubtitle),
          _slider('Tinggi banner', _bannerHeight, 80, 220, (v) => setState(() => _bannerHeight = v), 'px'),
        ]);
      case 'products':
        return Column(children: [
          _slider('Jumlah kolom produk', _columns.toDouble(), 1, 3, (v) => setState(() => _columns = v.round()), 'kolom', divisions: 2),
          _slider('Jarak antarproduk', _spacing, 2, 24, (v) => setState(() => _spacing = v), 'px'),
        ]);
      default:
        return const Text('Bagian ini mengambil konten dari menu Banner, Pengumuman, atau Kategori. Atur isi kontennya pada modul terkait.');
    }
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> change, String unit, {int? divisions}) => Column(
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label), Text('${value.round()} $unit', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: change),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Visual Home Studio'),
      actions: [
        IconButton(tooltip: 'Reset preview', onPressed: () => setState(() { _selected = 'header'; }), icon: const Icon(Icons.center_focus_strong)),
        TextButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.publish), label: const Text('Publikasikan')),
      ],
    ),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Gagal memuat konfigurasi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        _load(snapshot.data?.data() ?? {});
        final selectedName = _name(_selected);
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF10233F), borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.design_services_outlined, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HOME PAGE COMPOSER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  SizedBox(height: 3),
                  Text('Pilih komponen, susun posisi, atur tampilannya, lalu publikasikan.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 12),
            _panel('Kanvas halaman Home', 'Ketuk komponen untuk memilihnya. Tahan ikon geser untuk mengubah urutan.', Column(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Color(_background), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.black12)),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.phone_android, size: 14),
                    const SizedBox(width: 5),
                    const Text('Pratinjau mobile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${_order.where((s) => _visible[s] == true).length} komponen aktif', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  ]),
                  const SizedBox(height: 9),
                  for (final key in _order)
                    if (_visible[key] == true) _previewBlock(key),
                  Container(height: 28, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      Icon(Icons.home_outlined, size: 15), Icon(Icons.chat_bubble_outline, size: 15),
                      Icon(Icons.add_circle_outline, size: 15), Icon(Icons.person_outline, size: 15),
                    ])),
                ]),
              ),
              const SizedBox(height: 10),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) => setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _order.removeAt(oldIndex);
                  _order.insert(newIndex, item);
                }),
                children: [
                  for (var index = 0; index < _order.length; index++)
                    Card(
                      key: ValueKey(_order[index]),
                      margin: const EdgeInsets.only(bottom: 5),
                      child: ListTile(
                        dense: true,
                        selected: _selected == _order[index],
                        leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
                        title: Text(_name(_order[index]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        onTap: () => setState(() => _selected = _order[index]),
                        trailing: Switch(
                          value: _visible[_order[index]] ?? true,
                          onChanged: (value) => setState(() => _visible[_order[index]] = value),
                        ),
                      ),
                    ),
                ],
              ),
            ])),
            _panel('Pengaturan komponen: $selectedName', 'Kontrol hanya untuk komponen yang sedang dipilih.', _editorForSelected()),
            _panel('Tema dan identitas visual', 'Atur gaya global yang digunakan seluruh halaman.', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 7, children: [
                ChoiceChip(label: const Text('Terang'), selected: _theme == 'light', onSelected: (_) => setState(() => _theme = 'light')),
                ChoiceChip(label: const Text('Gelap'), selected: _theme == 'dark', onSelected: (_) => setState(() => _theme = 'dark')),
                ChoiceChip(label: const Text('Ikuti sistem'), selected: _theme == 'system', onSelected: (_) => setState(() => _theme = 'system')),
              ]),
              const SizedBox(height: 14),
              _swatches('Warna utama', _primary, (v) => setState(() => _primary = v), 0),
              const SizedBox(height: 12),
              _swatches('Warna aksen', _accent, (v) => setState(() => _accent = v), 1),
              const SizedBox(height: 12),
              const Text('Latar belakang', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 10, children: [0xFFF7F9FC, 0xFFFFFFFF, 0xFFF1F5F9, 0xFF111827].map((value) => InkWell(
                onTap: () => setState(() => _background = value),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(
                  color: Color(value), shape: BoxShape.circle,
                  border: Border.all(color: _background == value ? Colors.blue : Colors.grey),
                )),
              )).toList()),
            ])),
            _panel('Jadwal promosi Home', 'Jadwal global untuk menampilkan area promosi.', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OutlinedButton.icon(onPressed: () => _pickDate(true), icon: const Icon(Icons.calendar_today), label: Text('Mulai: ${_dateLabel(_start)}')),
              OutlinedButton.icon(onPressed: () => _pickDate(false), icon: const Icon(Icons.event), label: Text('Akhir: ${_dateLabel(_end)}')),
              TextButton(onPressed: () => setState(() { _start = null; _end = null; }), child: const Text('Hapus jadwal')),
            ])),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_outlined),
              label: Text(_saving ? 'Menerbitkan...' : 'Publikasikan perubahan Home'),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    ),
  );
}
