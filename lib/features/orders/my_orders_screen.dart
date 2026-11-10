import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pesanan Saya'), bottom: const TabBar(tabs: [
          Tab(text: 'Pembelian'), Tab(text: 'Penjualan'),
        ])),
        body: TabBarView(children: [
          _OrdersList(uid: uid, field: 'buyerId', buyerView: true),
          _OrdersList(uid: uid, field: 'sellerId', buyerView: false),
        ]),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.uid, required this.field, required this.buyerView});
  final String uid;
  final String field;
  final bool buyerView;

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
    'disputed':'Dalam sengketa',
  }[status] ?? status;

  Future<void> _update(BuildContext context, String id, String status) async {
    try {
      await OrderService().updateStatus(orderId: id, status: status);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status pesanan: ${_label(status)}')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak dapat memperbarui pesanan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('orders').where(field, isEqualTo: uid).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Pesanan gagal dimuat: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = [...snapshot.data!.docs];
      docs.sort((a, b) {
        final at = a.data()['createdAt'];
        final bt = b.data()['createdAt'];
        final ad = at is Timestamp ? at.toDate() : DateTime(2000);
        final bd = bt is Timestamp ? bt.toDate() : DateTime(2000);
        return bd.compareTo(ad);
      });
      if (docs.isEmpty) return Center(child: Text(buyerView ? 'Belum ada pembelian.' : 'Belum ada pesanan dari pembeli.'));
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data();
          final status = (data['status'] ?? '').toString();
          final total = (data['total'] as num?)?.toInt() ?? 0;
          return Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text((data['productTitle'] ?? 'Produk').toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                Chip(label: Text(_label(status))),
              ]),
              Text('Jumlah: ${data['quantity'] ?? 1} • Total: Rp$total'),
              Text('Metode: ${data['paymentMethod'] ?? 'COD'} • ${data['deliveryMethod'] ?? '-'}'),
              if ((data['deliveryAddress'] ?? '').toString().isNotEmpty)
                Text('Alamat: ${data['deliveryAddress']}'),
              if ((data['note'] ?? '').toString().isNotEmpty)
                Text('Catatan: ${data['note']}'),
              const SizedBox(height: 10),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('app_config').doc('platform').snapshots(),
                builder: (context, settings) {
                  final config = settings.data?.data() ?? <String, dynamic>{};
                  final actions = <Widget>[];
                  if (!buyerView) {
                    if (status == 'awaiting_confirmation' || status == 'paid') {
                      actions.add(OutlinedButton(onPressed: () => _update(context, doc.id, 'confirmed'), child: const Text('Konfirmasi')));
                    }
                    if (status == 'confirmed') actions.add(OutlinedButton(onPressed: () => _update(context, doc.id, 'processing'), child: const Text('Proses')));
                    if (status == 'processing') actions.add(OutlinedButton(onPressed: () => _update(context, doc.id, 'shipped'), child: const Text('Kirim')));
                    if (status == 'shipped') actions.add(OutlinedButton(onPressed: () => _update(context, doc.id, 'completed'), child: const Text('Tandai selesai')));
                  } else {
                    if (['awaiting_confirmation','paid','confirmed'].contains(status) && config['allowBuyerCancellation'] != false) {
                      actions.add(TextButton(onPressed: () => _update(context, doc.id, 'cancelled'), child: const Text('Batalkan')));
                    }
                    if (status == 'completed' && config['returnsEnabled'] == true) {
                      actions.add(OutlinedButton(onPressed: () => _update(context, doc.id, 'return_requested'), child: const Text('Ajukan retur')));
                    }
                    if (!['cancelled','returned'].contains(status) && config['disputesEnabled'] == true) {
                      actions.add(OutlinedButton(onPressed: () => _update(context, doc.id, 'disputed'), child: const Text('Ajukan sengketa')));
                    }
                  }
                  return Wrap(spacing: 8, runSpacing: 6, children: actions);
                },
              ),
            ]),
          ));
        },
      );
    },
  );
}
