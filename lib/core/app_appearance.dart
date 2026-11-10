import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FlowaDesignTokens extends ThemeExtension<FlowaDesignTokens> {
  const FlowaDesignTokens({required this.screenBackgrounds, required this.navigation});
  final Map<String, Color> screenBackgrounds;
  final Map<String, String> navigation;

  Color backgroundFor(String screen, Color fallback) => screenBackgrounds[screen] ?? fallback;

  @override
  FlowaDesignTokens copyWith({Map<String, Color>? screenBackgrounds, Map<String, String>? navigation}) =>
      FlowaDesignTokens(screenBackgrounds: screenBackgrounds ?? this.screenBackgrounds,
        navigation: navigation ?? this.navigation);

  @override
  FlowaDesignTokens lerp(ThemeExtension<FlowaDesignTokens>? other, double t) {
    if (other is! FlowaDesignTokens) return this;
    return t < .5 ? this : other;
  }
}

class AppAppearance {
  static const defaults = <String, dynamic>{
    'primaryColor': 0xFF0866FF,
    'accentColor': 0xFF00A8FF,
    'scaffoldColor': 0xFFF6F8FC,
    'surfaceColor': 0xFFFFFFFF,
    'textColor': 0xFF172033,
    'cornerRadius': 18.0,
    'buttonRadius': 14.0,
    'iconSize': 22.0,
    'buttonHeight': 48.0,
    'screenBackgrounds': <String, int>{
      'home': 0xFFF6F8FC,
      'marketplace': 0xFFF6F8FC,
      'chat': 0xFFF5F7FB,
      'chatDetail': 0xFFFFFFFF,
      'upload': 0xFFF5F7FB,
      'profile': 0xFFF6F8FC,
      'settings': 0xFFF6F8FC,
    },
    'navigation': <String, dynamic>{
      'homeLabel': 'Beranda', 'homeIcon': 'home',
      'chatLabel': 'Chat', 'chatIcon': 'chat',
      'uploadLabel': 'Pasang Iklan', 'uploadIcon': 'add',
      'profileLabel': 'Profil', 'profileIcon': 'person',
    },
    'buttonStyle': 'filled',
    'cardElevation': 0.0,
    'compactDensity': false,
    'updatedAt': null,
  };

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch() =>
      FirebaseFirestore.instance.collection('app_config').doc('appearance').snapshots();

  static Color color(dynamic value, int fallback) =>
      Color((value as num?)?.toInt() ?? fallback);

  static double number(dynamic value, double fallback) =>
      (value as num?)?.toDouble() ?? fallback;

  static IconData icon(String name) {
    const icons = <String, IconData>{
      'home': Icons.home_rounded, 'home_outline': Icons.home_outlined,
      'chat': Icons.chat_bubble_rounded, 'chat_outline': Icons.chat_bubble_outline_rounded,
      'message': Icons.forum_rounded, 'add': Icons.add_circle_rounded,
      'add_outline': Icons.add_circle_outline_rounded, 'store': Icons.storefront_rounded,
      'search': Icons.search_rounded, 'person': Icons.person_rounded,
      'person_outline': Icons.person_outline_rounded, 'favorite': Icons.favorite_rounded,
      'grid': Icons.grid_view_rounded, 'category': Icons.category_rounded,
      'shopping': Icons.shopping_bag_rounded, 'wallet': Icons.account_balance_wallet_rounded,
      'settings': Icons.settings_rounded, 'notifications': Icons.notifications_rounded,
      'support': Icons.support_agent_rounded, 'location': Icons.location_on_rounded,
      'sell': Icons.sell_rounded, 'local_offer': Icons.local_offer_rounded,
    };
    return icons[name] ?? Icons.widgets_rounded;
  }

  static ThemeData theme(Map<String, dynamic> raw, {bool dark = false}) {
    final config = <String, dynamic>{...defaults, ...raw};
    final brightness = dark ? Brightness.dark : Brightness.light;
    final primary = color(config['primaryColor'], 0xFF0866FF);
    final accent = color(config['accentColor'], 0xFF00A8FF);
    final surface = color(config['surfaceColor'], dark ? 0xFF1B2638 : 0xFFFFFFFF);
    final scaffold = color(config['scaffoldColor'], dark ? 0xFF101827 : 0xFFF6F8FC);
    final text = color(config['textColor'], dark ? 0xFFF4F7FC : 0xFF172033);
    final radius = number(config['cornerRadius'], 18).clamp(0.0, 36.0);
    final buttonRadius = number(config['buttonRadius'], 14).clamp(0.0, 36.0);
    final iconSize = number(config['iconSize'], 22).clamp(14.0, 36.0);
    final buttonHeight = number(config['buttonHeight'], 48).clamp(36.0, 72.0);
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness,
      surface: surface, primary: primary, secondary: accent);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius));
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      iconTheme: IconThemeData(size: iconSize, color: scheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(backgroundColor: scaffold, foregroundColor: text,
        elevation: 0, centerTitle: false, iconTheme: IconThemeData(size: iconSize, color: text)),
      cardTheme: CardThemeData(
        elevation: number(config['cardElevation'], 0),
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: const EdgeInsets.all(4),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: Size(0, buttonHeight), shape: buttonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        minimumSize: Size(0, buttonHeight), shape: buttonShape)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        minimumSize: Size(0, buttonHeight), shape: buttonShape)),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: buttonShape)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: primary, width: 1.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface, indicatorColor: primary.withValues(alpha: .13),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          fontSize: 11, color: text))),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
    );
  }
}
