import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../orders/order_service.dart';

class OrdersAdminPage extends StatelessWidget {
  const OrdersAdminPage({super.key});

  String _label(String status) => {
    'awaiting_confirmation':'Menunggu konfirmasi',
    'paid':'Sudah dibayar',
    'confirmed':'Dikonfirmasi',
    'processing':'Diproses',
    'shipped':'Dikirim',
    'completed':'Selesai',
    'cancelled':'Dibatalkan',
    'return_requested':'Pengajuan retur',
    'returned':'Dikembalikan',
    'disputed':'Sengketa',
  }[status] ?? status;

  Future<void> _change(BuildContext context, String id, String status) async {
    try {
      await OrderService().updateStatus(orderId: id, status: status, reason: 'Diperbarui oleh admin Flowa');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status pesanan menjadi ${_label(status)}.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manajemen Pesanan')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Pesanan tidak dapat dimuat: ${snapshot.error}')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada pesanan. Pesanan baru akan muncul di sini.'));
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final d = doc.data();
            final status = (d['status'] ?? 'unknown').toString();
            final total = (d['total'] as num?)?.toInt() ?? 0;
            final history = d['statusHistory'] is List ? List.from(d['statusHistory'] as List) : const [];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text((d['productTitle'] ?? 'Pesanan').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Chip(label: Text(_label(status))),
                  ]),
                  Text('ID: ${doc.id}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 7),
                  Text('Jumlah: ${d['quantity'] ?? 1} • Total: Rp${total.toString()}'),
                  Text('Pembeli: ${d['buyerId'] ?? '-'}'),
                  Text('Penjual: ${d['sellerId'] ?? '-'}'),
                  Text('Pembayaran: ${d['paymentMethod'] ?? '-'} • ${d['deliveryMethod'] ?? '-'}'),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Riwayat: ${history.map((e) => (e is Map ? e['status'] : '')).join(' → ')}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (status == 'awaiting_confirmation') OutlinedButton(onPressed: () => _change(context, doc.id, 'confirmed'), child: const Text('Konfirmasi')),
                    if (status == 'confirmed') OutlinedButton(onPressed: () => _change(context, doc.id, 'processing'), child: const Text('Proses')),
                    if (status == 'processing') OutlinedButton(onPressed: () => _change(context, doc.id, 'shipped'), child: const Text('Kirim')),
                    if (status == 'shipped') OutlinedButton(onPressed: () => _change(context, doc.id, 'completed'), child: const Text('Selesaikan')),
                    if (status == 'return_requested') OutlinedButton(onPressed: () => _change(context, doc.id, 'returned'), child: const Text('Setujui retur')),
                    if (status == 'disputed') OutlinedButton(onPressed: () => _change(context, doc.id, 'completed'), child: const Text('Tutup sengketa')),
                    if (!['completed','cancelled','returned'].contains(status)) TextButton(
                      onPressed: () => _change(context, doc.id, 'cancelled'),
                      child: const Text('Batalkan', style: TextStyle(color: Colors.red))),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    ),
  );
}
