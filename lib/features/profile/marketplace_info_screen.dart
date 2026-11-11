import 'package:flutter/material.dart';
import '../../core/app_appearance.dart';

class MarketplaceInfoScreen extends StatelessWidget {
  const MarketplaceInfoScreen({
    super.key,
    required this.showPrivacy,
  });

  final bool showPrivacy;

  @override
  Widget build(BuildContext context) {
    final sections = showPrivacy ? _privacySections : _aboutSections;
    return Scaffold(
      backgroundColor: Theme.of(context).extension<FlowaDesignTokens>()?.backgroundFor(
            'settings', Theme.of(context).scaffoldBackgroundColor),
      appBar: AppBar(
        title: Text(showPrivacy ? 'Privasi & Keamanan' : 'Tentang Flowa'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!showPrivacy) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.storefront_rounded,
                      size: 34, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(height: 10),
                  Text('Flowa', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
                  const SizedBox(height: 6),
                  Text(
                    'Marketplace untuk menemukan produk, bertransaksi, dan terhubung dengan penjual di sekitar.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...sections.map((section) => Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: Icon(section.icon),
                  title: Text(section.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.body, style: const TextStyle(height: 1.5)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Text(
            'Informasi ini merupakan panduan penggunaan di dalam aplikasi. Ketentuan operasional dapat berubah melalui pembaruan aplikasi dan pengumuman resmi Flowa.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static const _aboutSections = <_InfoSection>[
    _InfoSection(Icons.shopping_bag_outlined, 'Aturan pembeli',
        'Periksa foto, deskripsi, kondisi, harga, lokasi, dan informasi penjual sebelum memesan. Tanyakan detail yang belum jelas melalui chat. Pastikan alamat dan catatan pesanan benar. Jangan membuat pesanan palsu, menyalahgunakan promo, atau meminta transaksi di luar kesepakatan yang ditampilkan di aplikasi.'),
    _InfoSection(Icons.storefront_outlined, 'Aturan penjual',
        'Pasang produk yang benar-benar tersedia dan berhak kamu jual. Gunakan foto serta deskripsi yang sesuai kondisi sebenarnya, cantumkan harga dan stok yang akurat, dan perbarui iklan ketika barang habis. Tanggapi pesanan dan chat dengan wajar. Dilarang menaikkan harga secara menyesatkan, memasang iklan palsu, atau mengirim barang yang berbeda dari kesepakatan.'),
    _InfoSection(Icons.handshake_outlined, 'Pesanan dan pembayaran',
        'Ikuti metode pembayaran yang tersedia pada halaman checkout. Untuk pesanan COD, pembeli membayar sesuai total yang tertera ketika barang diterima. Periksa kembali total, jumlah barang, metode pengiriman atau temu langsung, serta alamat sebelum mengonfirmasi pesanan. Jangan menganggap pembayaran berhasil hanya berdasarkan tangkapan layar.'),
    _InfoSection(Icons.local_shipping_outlined, 'Pengiriman dan serah terima',
        'Pembeli dan penjual perlu menyepakati detail serah terima melalui fitur pesanan atau chat. Simpan bukti komunikasi dan bukti serah terima. Jangan membagikan kode verifikasi, kata sandi, atau data sensitif kepada pihak yang mengaku sebagai kurir maupun staf Flowa.'),
    _InfoSection(Icons.assignment_return_outlined, 'Pembatalan, retur, dan sengketa',
        'Ajukan pembatalan, retur, atau sengketa melalui detail pesanan jika opsi tersedia. Jelaskan alasan secara jujur dan sertakan bukti yang relevan jika diminta. Penjual dan pembeli diminta merespons dengan kooperatif. Pengajuan akan ditinjau sesuai status pesanan dan kebijakan yang berlaku; pengajuan tidak otomatis berarti pengembalian dana disetujui. Untuk COD, pengembalian uang atau barang perlu dikonfirmasi secara terpisah dan tidak dianggap otomatis selesai.'),
    _InfoSection(Icons.block_outlined, 'Barang dan aktivitas terlarang',
        'Jangan memasang atau memperdagangkan barang ilegal, barang curian, barang palsu yang melanggar hak pihak lain, senjata atau bahan berbahaya yang dilarang, obat terlarang, maupun produk lain yang dilarang hukum. Dilarang melakukan penipuan, spam, pemerasan, pelecehan, manipulasi ulasan, atau menyalahgunakan akun pengguna lain.'),
    _InfoSection(Icons.flag_outlined, 'Pelaporan dan moderasi',
        'Gunakan fitur laporan untuk memberi tahu Flowa tentang iklan, akun, atau perilaku yang mencurigakan. Sertakan alasan dan informasi yang relevan. Flowa dapat meninjau laporan dan membatasi konten atau akun sesuai hasil pemeriksaan dan ketentuan yang berlaku. Jangan gunakan laporan untuk mengganggu pengguna lain.'),
    _InfoSection(Icons.info_outline, 'Batas tanggung jawab transaksi',
        'Flowa menyediakan sarana untuk mempertemukan pembeli dan penjual. Selalu periksa identitas, barang, dan kesepakatan sebelum menyelesaikan transaksi. Jangan menyerahkan barang atau uang berdasarkan klaim yang belum diverifikasi. Jika menemukan dugaan penipuan atau keadaan darurat, hentikan transaksi dan gunakan kanal bantuan yang tersedia.'),
  ];

  static const _privacySections = <_InfoSection>[
    _InfoSection(Icons.dataset_outlined, 'Informasi yang digunakan',
        'Aplikasi dapat memproses informasi akun seperti nama, email, foto profil, bio, serta informasi yang kamu masukkan ketika menggunakan fitur marketplace seperti iklan, pesanan, chat, dan laporan. Informasi teknis tertentu juga dapat tercatat untuk membantu menjaga kestabilan dan keamanan aplikasi. Jangan memasukkan data pribadi yang tidak diperlukan ke deskripsi iklan atau chat publik.'),
    _InfoSection(Icons.tune_outlined, 'Penggunaan informasi',
        'Informasi digunakan untuk menjalankan fitur akun, menampilkan profil dan iklan, menghubungkan pembeli dengan penjual, memproses pesanan, menyediakan bantuan, menangani laporan, serta menjaga keamanan dan mencegah penyalahgunaan. Data tidak boleh digunakan untuk tujuan yang tidak berkaitan dengan layanan tanpa dasar dan pemberitahuan yang sesuai.'),
    _InfoSection(Icons.visibility_outlined, 'Informasi yang terlihat oleh pengguna lain',
        'Nama tampilan, foto profil, bio, iklan, dan informasi yang kamu kirim dalam chat atau transaksi dapat terlihat oleh pihak yang berinteraksi denganmu sesuai fitur aplikasi. Email akun dan data autentikasi tidak ditampilkan sebagai informasi profil publik. Hindari menulis alamat rumah lengkap atau nomor identitas pada bio dan iklan.'),
    _InfoSection(Icons.circle_outlined, 'Status online dan aktivitas',
        'Jika pengaturan tersedia, kamu dapat mengatur apakah status online dan aktivitas profil ditampilkan. Perubahan preferensi disimpan pada akun. Pengaturan ini tidak menghapus riwayat pesanan, chat, atau informasi yang memang diperlukan untuk menjalankan transaksi.'),
    _InfoSection(Icons.lock_outline, 'Keamanan akun',
        'Gunakan kata sandi yang kuat dan unik, jangan membagikan kode OTP atau tautan pemulihan, dan keluar dari perangkat yang bukan milikmu. Ubah kata sandi jika merasa akun diakses orang lain. Flowa tidak akan meminta kata sandi atau kode OTP melalui chat. Aktifkan perlindungan perangkat dan jaga email pemulihan tetap aman.'),
    _InfoSection(Icons.storage_outlined, 'Penyimpanan dan akses data',
        'Data akun dan aktivitas layanan disimpan pada layanan backend yang digunakan aplikasi agar fitur dapat berjalan. Akses terhadap data dibatasi berdasarkan kebutuhan fitur dan hak akses. Jangan menganggap penghapusan aplikasi dari perangkat otomatis menghapus data akun di server.'),
    _InfoSection(Icons.manage_accounts_outlined, 'Kontrol dan permintaan pengguna',
        'Kamu dapat memperbarui informasi profil dan preferensi yang disediakan di Pengaturan. Untuk permintaan koreksi atau penghapusan data yang tidak tersedia langsung di aplikasi, hubungi Bantuan & Chat dan jelaskan permintaanmu. Sebagian catatan transaksi atau keamanan mungkin perlu dipertahankan sesuai kewajiban dan kebutuhan penyelesaian masalah.'),
    _InfoSection(Icons.phonelink_lock_outlined, 'Perangkat dan sesi',
        'Jangan gunakan akun bersama pada perangkat umum. Pastikan perangkat terkunci dan perbarui sistem operasi. Jika perangkat hilang, amankan akun email yang terhubung dan lakukan pemulihan kata sandi sesegera mungkin.'),
  ];
}

class _InfoSection {
  const _InfoSection(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}
