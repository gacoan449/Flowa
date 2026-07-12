import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Simulasi laporan pelanggaran masuk dari para pengguna Flowa
  final List<Map<String, dynamic>> _reportedContents = [
    {
      "id": "rep_1",
      "creator": "Kreator_Nakal",
      "reason": "Konten mengandung unsur kekerasan/perkelahian",
      "videoTitle": "Video tawuran di jalan raya.mp4",
      "reportsCount": 14
    },
    {
      "id": "rep_2",
      "creator": "Akun_Spam",
      "reason": "Mengunggah video judi online berkedok game",
      "videoTitle": "Cara menang mudah jackpot gede.mp4",
      "reportsCount": 42
    },
  ];

  void _actionTake(String id, String action) {
    setState(() {
      _reportedContents.removeWhere((item) => item['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tindakan Berhasil: $action dilakukan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pusat Pengawasan Admin Flowa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[800], // Warna merah tegas khusus penanda ruang admin
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringkasan Statistik Laporan
            Row(
              children: [
                _buildStatBox("Total Laporan", "${_reportedContents.length}", Colors.orange),
                const SizedBox(width: 16),
                _buildStatBox("Kreator Dipantau", "2", Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Daftar Pelanggaran Kreator (Butuh Tindakan):", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),

            // List konten bermasalah
            Expanded(
              child: _reportedContents.isEmpty
                  ? const Center(child: Text("Aplikasi Aman! Tidak ada pelanggaran kreator saat ini.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _reportedContents.length,
                      itemBuilder: (context, index) {
                        final report = _reportedContents[index];
                        return Card(
                          margin: const EdgeInsets.bottomAt(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.between,
                                  children: [
                                    Text("@${report['creator']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
                                      child: Text("${report['reportsCount']} Laporan", style: TextStyle(color: Colors.red[800], fontSize: 12, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("File: ${report['videoTitle']}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text("Alasan: ${report['reason']}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 16),
                                
                                // Tombol Eksekusi Ketat Admin
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _actionTake(report['id'], "Abaikan Laporan"),
                                      child: const Text("Abaikan", style: TextStyle(color: Colors.grey)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                      onPressed: () => _actionTake(report['id'], "Hapus Video"),
                                      child: const Text("Hapus Video", style: TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                                      onPressed: () => _actionTake(report['id'], "Blokir Permanen Akun Kreator"),
                                      child: const Text("Blokir Kreator", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
