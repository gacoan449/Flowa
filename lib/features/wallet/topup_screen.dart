import 'package:flutter/material.dart';

class TopUpScreen extends StatelessWidget {
  const TopUpScreen({super.key});
  static const packages = [
    ('coin_10', '10 Koin', 'Rp10.000'),
    ('coin_50', '50 Koin', 'Rp45.000'),
    ('coin_120', '120 Koin', 'Rp100.000'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Top Up Koin')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Pilih paket koin. Pembayaran top up diproses melalui TriPay.'),
        const SizedBox(height: 12),
        ...packages.map((p) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.monetization_on_outlined)),
          title: Text(p.$2),
          subtitle: Text(p.$3),
          trailing: FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gateway TriPay perlu dihubungkan ke backend terlebih dahulu.')),
            ),
            child: const Text('Beli'),
          ),
        ))),
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            'Catatan: transaksi jual-beli antara pembeli dan penjual dilakukan langsung oleh pengguna (transfer, COD, atau metode lain yang mereka sepakati). Aplikasi hanya menyediakan sistem pembelian Koin untuk fitur internal.',
          ),
        ),
      ],
    ),
  );
}
