import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../wallet/topup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('PasarKomunitas'),
        actions: [
          IconButton(
            tooltip: 'Top up Koin',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopUpScreen())),
          ),
          IconButton(onPressed: () => AuthService().logout(), icon: const Icon(Icons.logout)),
        ],
        bottom: const TabBar(tabs: [
          Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
          Tab(icon: Icon(Icons.storefront_outlined), text: 'Pasar'),
        ]),
      ),
      body: const TabBarView(children: [
        Center(child: Text('Inbox percakapan akan tampil di sini')),
        Center(child: Text('Produk lokal berdasarkan radius akan tampil di sini')),
      ]),
    ),
  );
}
