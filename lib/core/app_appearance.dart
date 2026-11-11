import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FlowaDesignTokens extends ThemeExtension<FlowaDesignTokens> {
  const FlowaDesignTokens({required this.screenBackgrounds, required this.navigation});
  final Map<String, Color> screenBackgrounds;
  final Map<String, String> navigation;

  Color backgroundFor(String screen, Color fallback) => screenBackgrounds[screen] ?? fallback;

  @override
  FlowaDesignTokens copyWith({Map<String, Color>? screenBackgrounds, Map<String, String>? navigation}) =>
      FlowaDesignTokens(
        screenBackgrounds: screenBackgrounds ?? this.screenBackgrounds,
        navigation: navigation ?? this.navigation,
      );

  @override
  FlowaDesignTokens lerp(ThemeExtension<FlowaDesignTokens>? other, double t) {
    if (other is! FlowaDesignTokens) return this;
    return t < .5 ? this : other;
  }
}

class AppAppearance {
  // Bright, premium blue system. Existing Firestore customization still overrides these values.
  static const defaults = <String, dynamic>{
    'primaryColor': 0xFF0866FF,
    'accentColor': 0xFF18B6FF,
    'scaffoldColor': 0xFFF4F8FF,
    'surfaceColor': 0xFFFFFFFF,
    'textColor': 0xFF13233F,
    'cornerRadius': 22.0,
    'buttonRadius': 18.0,
    'iconSize': 23.0,
    'buttonHeight': 52.0,
    'screenBackgrounds': <String, int>{
      'home': 0xFFF4F8FF,
      'marketplace': 0xFFF4F8FF,
      'chat': 0xFFF3F7FD,
      'chatDetail': 0xFFF8FAFF,
      'upload': 0xFFF4F8FF,
      'profile': 0xFFF4F8FF,
      'settings': 0xFFF4F8FF,
      'favorites': 0xFFF4F8FF,
      'orders': 0xFFF4F8FF,
      'myListings': 0xFFF4F8FF,
      'sellerStore': 0xFFF4F8FF,
      'discover': 0xFFF4F8FF,
    },
    'navigation': <String, dynamic>{
      'homeLabel': 'Beranda', 'homeIcon': 'home',
      'chatLabel': 'Chat', 'chatIcon': 'chat',
      'uploadLabel': 'Pasang Iklan', 'uploadIcon': 'add',
      'profileLabel': 'Profil', 'profileIcon': 'person',
    },
    'buttonStyle': 'filled',
    'cardElevation': 1.0,
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
    final accent = color(config['accentColor'], 0xFF18B6FF);
    final configuredSurface = color(config['surfaceColor'], 0xFFFFFFFF);
    final configuredScaffold = color(config['scaffoldColor'], 0xFFF4F8FF);
    final configuredText = color(config['textColor'], 0xFF13233F);
    final surface = dark && configuredSurface.value == 0xFFFFFFFF
        ? const Color(0xFF172235) : configuredSurface;
    final scaffold = dark && configuredScaffold.value == 0xFFF4F8FF
        ? const Color(0xFF0E1624) : configuredScaffold;
    final text = dark && configuredText.value == 0xFF13233F
        ? const Color(0xFFF5F8FF) : configuredText;
    final radius = number(config['cornerRadius'], 22).clamp(12.0, 36.0).toDouble();
    final buttonRadius = number(config['buttonRadius'], 18).clamp(12.0, 36.0).toDouble();
    final iconSize = number(config['iconSize'], 23).clamp(18.0, 36.0).toDouble();
    final buttonHeight = number(config['buttonHeight'], 52).clamp(44.0, 72.0).toDouble();

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
      primary: primary,
      secondary: accent,
    );
    final rawBackgrounds = config['screenBackgrounds'] is Map
        ? Map<String, dynamic>.from(config['screenBackgrounds'] as Map)
        : <String, dynamic>{};
    final screenBackgrounds = <String, Color>{
      for (final entry in rawBackgrounds.entries)
        entry.key: color(entry.value, scaffold.value),
    };
    final rawNavigation = config['navigation'] is Map
        ? Map<String, dynamic>.from(config['navigation'] as Map)
        : <String, dynamic>{};
    final navigation = <String, String>{
      for (final entry in rawNavigation.entries) entry.key: entry.value.toString(),
    };

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    final buttonBackground = config['buttonStyle'] == 'soft'
        ? scheme.secondaryContainer
        : (config['buttonStyle'] == 'outlined' ? surface : primary);
    final buttonForeground = config['buttonStyle'] == 'soft'
        ? scheme.onSecondaryContainer
        : (config['buttonStyle'] == 'outlined' ? primary : scheme.onPrimary);

    final baseText = ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: text,
      displayColor: text,
    );

    return ThemeData(
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[
        FlowaDesignTokens(
          screenBackgrounds: screenBackgrounds,
          navigation: navigation,
        ),
      ],
      brightness: brightness,
      colorScheme: scheme,
      textTheme: baseText.copyWith(
        titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w750),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.35),
      ),
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      iconTheme: IconThemeData(size: iconSize, color: scheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseText.titleLarge?.copyWith(color: text, fontWeight: FontWeight.w800),
        iconTheme: IconThemeData(size: iconSize, color: text),
      ),
      cardTheme: CardThemeData(
        elevation: number(config['cardElevation'], 1),
        shadowColor: primary.withValues(alpha: .10),
        surfaceTintColor: Colors.transparent,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
        ),
        margin: const EdgeInsets.all(4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .55),
        thickness: .8,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonForeground,
          elevation: 2,
          shadowColor: primary.withValues(alpha: .28),
          minimumSize: Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonForeground,
          elevation: 2,
          shadowColor: primary.withValues(alpha: .25),
          minimumSize: Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: config['buttonStyle'] == 'soft'
              ? scheme.secondaryContainer.withValues(alpha: .55)
              : surface,
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: .35)),
          minimumSize: Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w750),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w750),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
          iconSize: iconSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: .75)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: primary.withValues(alpha: .10),
        indicatorColor: primary.withValues(alpha: .13),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? primary
              : scheme.onSurfaceVariant,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          fontSize: 11,
          color: states.contains(WidgetState.selected)
              ? primary
              : scheme.onSurfaceVariant,
        )),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: .12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w650),
      ),
    );
  }
}
