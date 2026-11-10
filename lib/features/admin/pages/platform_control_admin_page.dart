import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PlatformControlAdminPage extends StatefulWidget {
  const PlatformControlAdminPage({super.key});
  @override
  State<PlatformControlAdminPage> createState() => _PlatformControlAdminPageState();
}

class _PlatformControlAdminPageState extends State<PlatformControlAdminPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  late final TabController _tabs;
  final Map<String, TextEditingController> _inputs = {};
  final Map<String, bool> _toggles = {};
  bool _loaded = false;
  bool _saving = false;

  static const Map<String, List<Map<String, dynamic>>> _groups = {
    'App Experience': [
      {'k':'navigationEnabled','l':'Navigasi utama aktif','t':'b','d':true},
      {'k':'searchEnabled','l':'Pencarian aktif','t':'b','d':true},
      {'k':'chatEnabled','l':'Chat aktif','t':'b','d':true},
      {'k':'favoritesEnabled','l':'Favorit aktif','t':'b','d':true},
      {'k':'uploadEnabled','l':'Pasang iklan aktif','t':'b','d':true},
      {'k':'navigationLabelHome','l':'Teks menu Beranda','t':'s','d':'Beranda'},
      {'k':'navigationLabelSearch','l':'Teks menu Jelajah','t':'s','d':'Jelajah'},
      {'k':'navigationLabelChat','l':'Teks menu Chat','t':'s','d':'Chat'},
      {'k':'navigationLabelProfile','l':'Teks menu Profil','t':'s','d':'Profil'},
      {'k':'appAnnouncement','l':'Pesan global aplikasi','t':'s','d':''},
    ],
    'Marketplace': [
      {'k':'serviceFeePercent','l':'Biaya layanan (%)','t':'n','d':'0'},
      {'k':'minimumServiceFee','l':'Biaya layanan minimum (Rp)','t':'n','d':'0'},
      {'k':'adsEnabled','l':'Iklan/listing diizinkan','t':'b','d':true},
      {'k':'paidPromotionEnabled','l':'Promosi berbayar diizinkan','t':'b','d':false},
      {'k':'stockValidationEnabled','l':'Validasi stok diwajibkan','t':'b','d':true},
      {'k':'codEnabled','l':'Pembayaran COD diizinkan','t':'b','d':true},
      {'k':'walletEnabled','l':'Saldo Flowa diizinkan','t':'b','d':false},
      {'k':'maxActiveListings','l':'Maksimum iklan aktif per penjual','t':'n','d':'50'},
      {'k':'promotionDisclaimer','l':'Catatan aturan promosi','t':'s','d':''},
    ],
    'Order Management': [
      {'k':'ordersEnabled','l':'Penerimaan pesanan aktif','t':'b','d':true},
      {'k':'allowBuyerCancellation','l':'Pembeli boleh mengajukan pembatalan','t':'b','d':true},
      {'k':'cancellationWindowMinutes','l':'Batas pembatalan (menit)','t':'n','d':'30'},
      {'k':'returnsEnabled','l':'Pengajuan pengembalian aktif','t':'b','d':false},
      {'k':'disputesEnabled','l':'Pusat sengketa aktif','t':'b','d':false},
      {'k':'orderStatusLabels','l':'Label status pesanan (pisahkan koma)','t':'s','d':'Menunggu, Diproses, Dikirim, Selesai, Dibatalkan'},
      {'k':'returnPolicy','l':'Ringkasan kebijakan pengembalian','t':'s','d':''},
    ],
    'User & Security': [
      {'k':'adminAuditEnabled','l':'Catat aktivitas admin','t':'b','d':true},
      {'k':'requireAdminReauth','l':'Autentikasi ulang untuk aksi sensitif','t':'b','d':true},
      {'k':'loginAlertEnabled','l':'Peringatan aktivitas login','t':'b','d':true},
      {'k':'rolePolicy','l':'Template peran (owner, admin, moderator, support)','t':'s','d':'owner,admin,moderator,support'},
      {'k':'permissionPolicy','l':'Template izin (pisahkan koma)','t':'s','d':'dashboard,content,marketplace,orders,users,security,system'},
    ],
    'System Control': [
      {'k':'maintenanceMode','l':'Mode pemeliharaan','t':'b','d':false},
      {'k':'maintenanceMessage','l':'Pesan pemeliharaan','t':'s','d':'Flowa sedang menjalani pemeliharaan. Silakan coba lagi nanti.'},
      {'k':'pushNotificationsEnabled','l':'Notifikasi push aktif','t':'b','d':true},
      {'k':'emailNotificationsEnabled','l':'Notifikasi email aktif','t':'b','d':true},
      {'k':'featureFlagNewHome','l':'Feature flag: Home baru','t':'b','d':true},
      {'k':'featureFlagNewChat','l':'Feature flag: Chat baru','t':'b','d':true},
      {'k':'featureFlagPaidPromo','l':'Feature flag: Promosi berbayar','t':'b','d':false},
      {'k':'failureLogRetentionDays','l':'Retensi log kegagalan (hari)','t':'n','d':'30'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _groups.length, vsync: this);
    for (final fields in _groups.values) {
      for (final f in fields) {
        final key = f['k'] as String;
        if (f['t'] == 'b') {
          _toggles[key] = f['d'] as bool;
        } else {
          _inputs[key] = TextEditingController(text: f['d'].toString());
        }
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _inputs.values) { c.dispose(); }
    super.dispose();
  }

  void _load(Map<String, dynamic> data) {
    if (_loaded) return;
    for (final fields in _groups.values) {
      for (final f in fields) {
        final key = f['k'] as String;
        final value = data[key] ?? f['d'];
        if (f['t'] == 'b') {
          _toggles[key] = value == true;
        } else {
          _inputs[key]!.text = value.toString();
        }
      }
    }
    _loaded = true;
  }

  Map<String, dynamic> _buildPayload() {
    final values = <String, dynamic>{};
    for (final fields in _groups.values) {
      for (final f in fields) {
        final key = f['k'] as String;
        if (f['t'] == 'b') {
          values[key] = _toggles[key] ?? false;
        } else if (f['t'] == 'n') {
          final n = num.tryParse(_inputs[key]!.text.trim());
          if (n == null || n < 0) { throw FormatException('Nilai angka tidak valid: ' + (f['l'] as String)); }
          if (key == 'serviceFeePercent' && n > 100) { throw const FormatException('Biaya layanan maksimal 100%.'); }
          values[key] = n;
        } else {
          values[key] = _inputs[key]!.text.trim();
        }
      }
    }
    values['updatedAt'] = FieldValue.serverTimestamp();
    values['updatedBy'] = FirebaseAuth.instance.currentUser?.uid ?? '';
    values['schemaVersion'] = 1;
    return values;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final values = _buildPayload();
      await _db.collection('app_config').doc('platform').set(values, SetOptions(merge: true));
      if (_toggles['adminAuditEnabled'] == true) {
        await _db.collection('admin_audit_logs').add({
          'actorUid': FirebaseAuth.instance.currentUser?.uid ?? '',
          'actorEmail': FirebaseAuth.instance.currentUser?.email ?? '',
          'action': 'platform_config_updated',
          'changedKeys': values.keys.where((k) => k != 'updatedAt').toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfigurasi tersimpan di Firestore.'))); }
    } on FormatException catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'))); }
    } finally {
      if (mounted) { setState(() => _saving = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('app_config').doc('platform').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_loaded) { _load(snapshot.data!.data() ?? {}); }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Platform Control Center'),
            bottom: TabBar(controller: _tabs, isScrollable: true,
              tabs: _groups.keys.map((name) => Tab(text: name)).toList()),
          ),
          body: snapshot.hasError
              ? Center(child: Text('Gagal membaca konfigurasi: ${snapshot.error}'))
              : !snapshot.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(controller: _tabs, children: _groups.entries.map((entry) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          Text(entry.key, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_description(entry.key)),
                          const SizedBox(height: 16),
                          for (final f in entry.value) _field(f),
                          if (entry.key == 'Marketplace') _notice('Biaya dan aturan promosi disimpan sebagai kebijakan. Perhitungan checkout, pemotongan saldo, dan penagihan promosi belum terhubung ke backend transaksi.'),
                          if (entry.key == 'Order Management') _notice('Repo saat ini belum memiliki skema dan alur koleksi pesanan. Pengaturan ini belum mengubah pesanan nyata, pembatalan, retur, atau sengketa.'),
                          if (entry.key == 'User & Security') _notice('Template role/izin belum memberi hak akses. Hak admin tetap ditentukan Firebase Security Rules/backend tepercaya; jangan gunakan konfigurasi klien sebagai pengaman.'),
                          if (entry.key == 'System Control') _notice('Sakelar maintenance, notifikasi, dan feature flag tersimpan. Efek globalnya memerlukan pembacaan konfigurasi di masing-masing alur aplikasi/backend.'),
                        ],
                      );
                    }).toList()),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _saving || !snapshot.hasData ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan semua pengaturan'),
            ),
          ),
        );
      },
    );
  }

  Widget _field(Map<String, dynamic> f) {
    final key = f['k'] as String;
    if (f['t'] == 'b') {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(f['l'] as String),
        value: _toggles[key] ?? false,
        onChanged: (v) => setState(() => _toggles[key] = v),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: _inputs[key],
        keyboardType: f['t'] == 'n' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        maxLines: key == 'maintenanceMessage' || key == 'returnPolicy' || key == 'appAnnouncement' ? 3 : 1,
        decoration: InputDecoration(labelText: f['l'] as String, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _notice(String message) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
  );

  String _description(String section) {
    switch (section) {
      case 'App Experience': return 'Kontrol label navigasi, pesan global, dan sakelar fitur.';
      case 'Marketplace': return 'Parameter biaya layanan, stok, iklan, promosi, dan metode transaksi.';
      case 'Order Management': return 'Kebijakan status dan penanganan pesanan.';
      case 'User & Security': return 'Audit aktivitas serta kebijakan akses admin.';
      default: return 'Mode operasional, notifikasi, feature flags, dan retensi log.';
    }
  }
}
