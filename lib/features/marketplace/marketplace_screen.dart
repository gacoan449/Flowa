import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
import '../products/product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  Position? _buyerPosition;
  bool _locationLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _refreshBuyerLocation();
  }

  Future<void> _refreshBuyerLocation() async {
    if (mounted) setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      final position = await LocationService().current();
      if (!mounted) return;
      setState(() {
        _buyerPosition = position;
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buyerPosition = null;
        _locationLoading = false;
        _locationError = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  bool _validCoordinates(dynamic lat, dynamic lng) =>
      lat is num && lng is num &&
      lat >= -90 && lat <= 90 &&
      lng >= -180 && lng <= 180 &&
      !(lat == 0 && lng == 0);

  String _distanceLabel(Map<String, dynamic> product, String? buyerId) {
    if (product['sellerId'] == buyerId) return 'Produk kamu';
    if (_buyerPosition == null) return 'Aktifkan GPS untuk melihat jarak';
    final lat = product['latitude'];
    final lng = product['longitude'];
    if (!_validCoordinates(lat, lng)) return 'Lokasi penjual belum tersedia';
    final meters = Geolocator.distanceBetween(
      _buyerPosition!.latitude,
      _buyerPosition!.longitude,
      (lat as num).toDouble(),
      (lng as num).toDouble(),
    );
    if (meters < 1000) return '${meters.round()} m dari kamu';
    final km = meters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km dari kamu';
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (_locationLoading || _locationError != null)
            Material(
              color: const Color(0xFFEAF3FF),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Icon(_locationLoading ? Icons.gps_not_fixed : Icons.location_off,
                        color: const Color(0xFF1769E8), size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationLoading
                            ? 'Mencari lokasi kamu untuk menghitung jarak...'
                            : 'Jarak belum tersedia. ${_locationError ?? 'Aktifkan GPS dan izinkan lokasi.'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (!_locationLoading)
                      TextButton(onPressed: _refreshBuyerLocation, child: const Text('Coba lagi')),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('products')
                  .where('status', isEqualTo: 'active').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Produk belum dapat dimuat: ${snapshot.error}'),
                  ));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text(
                    'Belum ada produk aktif. Jadilah yang pertama memasang iklan!',
                  ));
                }
                final buyerId = FirebaseAuth.instance.currentUser?.uid;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final distance = _distanceLabel(data, buyerId);
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        leading: data['imageUrl'] == null || data['imageUrl'] == ''
                            ? const CircleAvatar(child: Icon(Icons.shopping_bag_outlined))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['imageUrl'], width: 58, height: 58, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                        title: Text((data['title'] ?? '').toString(),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rp ${data['price'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1769E8),
                                  )),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.near_me_outlined, size: 13,
                                      color: Color(0xFF16834A)),
                                  const SizedBox(width: 3),
                                  Expanded(child: Text(distance, style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF16834A),
                                    fontWeight: FontWeight.w600,
                                  ))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productId: doc.id),
                        )),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
}
