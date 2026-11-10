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
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('announcements')
                      .where('active', isEqualTo: true).snapshots(),
                  builder: (context, announcementSnapshot) {
                    final announcements = announcementSnapshot.data?.docs ?? [];
                    if (announcements.isEmpty) return const SizedBox.shrink();
                    final announcement = announcements.first.data();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign_outlined, color: Color(0xFF9A6500)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((announcement['title'] ?? 'Info Flowa').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text((announcement['body'] ?? '').toString(),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (config['showCategories'] == true)
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('categories')
                        .where('active', isEqualTo: true).snapshots(),
                    builder: (context, categorySnapshot) {
                      final categories = categorySnapshot.data?.docs ?? [];
                      if (categories.isEmpty) return const SizedBox(height: 8);
                      return SizedBox(
                        height: 54,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          children: [
                            ChoiceChip(
                              label: const Text('Semua'),
                              selected: selectedCategory == null,
                              onSelected: (_) => setState(() => selectedCategory = null),
                            ),
                            const SizedBox(width: 6),
                            ...categories.map((doc) {
                              final category = (doc.data()['name'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: selectedCategory == category,
                                  onSelected: (_) => setState(() => selectedCategory = category),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
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
