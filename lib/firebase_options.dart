// Jalankan: flutterfire configure
// File ini adalah placeholder agar struktur proyek jelas.
// Ganti dengan firebase_options.dart hasil konfigurasi Firebase resmi.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'ISI_DARI_FIREBASE',
          appId: 'ISI_DARI_FIREBASE',
          messagingSenderId: 'ISI_DARI_FIREBASE',
          projectId: 'ISI_DARI_FIREBASE',
        );
      default:
        throw UnsupportedError('Platform belum dikonfigurasi Firebase.');
    }
  }
}
