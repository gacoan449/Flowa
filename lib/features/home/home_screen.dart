import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../products/product_upload_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../profile/profile_screen.dart';
import 'home_config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: HomeConfigService().watch(),
      builder: (context, configSnapshot) {
        final config = <String, dynamic>{...HomeConfigService.defaults}
          ..addAll(configSnapshot.data?.data() ?? {});
        final categories = (config['categories'] as List<dynamic>? ??
                HomeConfigService.defaults['categories'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0758D9), Color(0xFF00A8FF)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (config['title'] ?? 'Flowa').toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        (config['subtitle'] ?? '').toString(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Cari barang di sekitar Anda...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (config['showBanner'] == true)
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('banners')
                        .where('active', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final banners = snapshot.data?.docs ?? [];
                      if (banners.isEmpty) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (config['bannerTitle'] ?? '').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text((config['bannerSubtitle'] ?? '').toString()),
                            ],
                          ),
                        );
                      }
                      return SizedBox(
                        height: 116,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          itemCount: banners.length,
                          itemBuilder: (context, index) {
                            final data = banners[index].data();
                            final image = (data['imageUrl'] ?? '').toString();
                            return Container(
                              width: MediaQuery.of(context).size.width * .84,
                              margin: const EdgeInsets.only(right: 10),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (image.isNotEmpty)
                                    Image.network(
                                      image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  if (image.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          (data['title'] ?? 'Promo Flowa').toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                if (config['showCategories'] == true)
                  SizedBox(
                    height: 54,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      children: [
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected: selectedCategory == null,
                          onSelected: (_) => setState(() => selectedCategory = null),
                        ),
                        const SizedBox(width: 6),
                        ...categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: selectedCategory == category,
                              onSelected: (_) => setState(
                                () => selectedCategory = category,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: MarketplaceScreen(selectedCategory: selectedCategory),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ChatInboxScreen(),
                ));
              }
              if (index == 2) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ProductUploadScreen(),
                ));
              }
              if (index == 3) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ));
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline), label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline), label: 'Pasang Iklan',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}
