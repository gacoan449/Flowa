import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Data simulasi konten yang dilaporkan (Dalam produksi, ini akan di-stream dari Firestore)
  final List<Map<String, dynamic>> _reportedContents = [
    {
      "id": "rep_1",
      "creator": "Kreator_Nakal",
      "reason": "Konten mengandung unsur kekerasan",
      "videoTitle": "Video_Tawuran_01.mp4",
      "reportsCount": 14
    },
    {
      "id": "rep_2",
      "creator": "Akun_Spam",
      "reason": "Judi Online/Penipuan",
      "videoTitle": "Jackpot_Gede_09.mp4",
      "reportsCount": 42
    },
  ];

  // [UPGRADE CTO] Fungsi Eksekusi Terpusat (Admin Audit Log)
  void _executeAdminAction(String id, String action, String creatorName) {
    // TODO: Tambahkan fungsi Cloud Function untuk menghapus dari Firebase di sini
    setState(() {
      _reportedContents.removeWhere((item) => item['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tindakan $action terhadap $creatorName BERHASIL dilakukan.'),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Command Center Admin", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistik Mewah
            Row(
              children: [
                _buildStatBox("Total Laporan", "${_reportedContents.length}", Colors.blueGrey),
                const SizedBox(width: 16),
                _buildStatBox("Status Sistem", "Aman", Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Antrean Moderasi Konten:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),

            Expanded(
              child: _reportedContents.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                        const SizedBox(height: 10),
                        Text("Semua konten telah dibersihkan.", style: TextStyle(color: Colors.grey[600])),
                      ]),
                    )
                  : ListView.builder(
                      itemCount: _reportedContents.length,
                      itemBuilder: (context, index) {
                        final report = _reportedContents[index];
                        return _buildReportCard(report);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("@${report['creator']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                Chip(
                  backgroundColor: Colors.red.shade50,
                  label: Text("${report['reportsCount']} Laporan", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text("Konten: ${report['videoTitle']}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
            const SizedBox(height: 6),
            Text("Alasan: ${report['reason']}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _executeAdminAction(report['id'], "Abaikan", report['creator']),
                  child: const Text("Abaikan", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  onPressed: () => _executeAdminAction(report['id'], "Hapus Video", report['creator']),
                  child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _executeAdminAction(report['id'], "Blokir Permanen", report['creator']),
                  child: const Text("Blokir User", style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
