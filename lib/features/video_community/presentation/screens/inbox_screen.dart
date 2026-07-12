import 'package:flutter/material.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Kotak Masuk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          final titles = ["Siti_Indah menyukai videomu", "Budi_Tani mengomentari kirimanmu", "Sistem DesaPay"];
          final subs = ["1 jam yang lalu", "2 jam yang lalu", "Pemberitahuan pencairan saldo sukses! ✔"];
          final icons = [Icons.favorite, Icons.comment, Icons.account_balance_wallet];
          final colors = [Colors.red, Colors.blue, Colors.amber];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colors[index].withOpacity(0.2),
              child: Icon(icons[index], color: colors[index]),
            ),
            title: Text(titles[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(subs[index], style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          );
        },
      ),
    );
  }
}
