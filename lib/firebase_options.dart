import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// Firebase configuration for project flowa-d6d47.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyArsKK5zAgLlE0DfLs_RDOL1qbYutOCWzQ',
          appId: '1:1099448464104:android:4b06ecffad67e6a7920f5d',
          messagingSenderId: '1099448464104',
          projectId: 'flowa-d6d47',
          storageBucket: 'flowa-d6d47.firebasestorage.app',
        );
      default:
        throw UnsupportedError(
          'Firebase baru dikonfigurasi untuk Android.',
        );
    }
  }
}
