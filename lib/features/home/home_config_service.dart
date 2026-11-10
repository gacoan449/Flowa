import 'package:cloud_firestore/cloud_firestore.dart';

class HomeConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watch() =>
      _db.collection('app_config').doc('home').snapshots();

  Future<void> save(Map<String, dynamic> data) =>
      _db.collection('app_config').doc('home').set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  static const List<String> availableSections = [
    'header', 'search', 'banner', 'announcement', 'categories', 'products'
  ];

  static const Map<String, dynamic> defaults = {
    'title': 'Flowa',
    'subtitle': 'Jual beli lokal, lebih dekat',
    'searchHint': 'Cari barang di sekitar Anda...',
    'bannerTitle': 'Temukan barang terbaik di sekitarmu',
    'bannerSubtitle': 'Jual, beli, dan chat langsung dengan penjual',
    'showHeader': true,
    'showSearch': true,
    'showCategories': true,
    'showBanner': true,
    'primaryColor': 0xFF0758D9,
    'accentColor': 0xFF00A8FF,
    'backgroundColor': 0xFFF7F9FC,
    'themeMode': 'light',
    'bannerHeight': 132.0,
    'productColumns': 2,
    'productSpacing': 10.0,
    'sectionOrder': ['header', 'search', 'banner', 'announcement', 'categories', 'products'],
    'sectionVisibility': {
      'header': true, 'search': true, 'banner': true,
      'announcement': true, 'categories': true, 'products': true
    },
    'promoStartAt': null,
    'promoEndAt': null,
  };
}
