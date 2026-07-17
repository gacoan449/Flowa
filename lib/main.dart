import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // [UPGRADE CTO] Paket font premium

import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  // Wajib dipanggil sebelum menginisialisasi Firebase di Flutter
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi Otomatis Firebase menggunakan file google-services.json Anda
    await Firebase.initializeApp();
  } catch (e) {
    // [UPGRADE CTO] Menggunakan debugPrint standar industri
    debugPrint("LOG_INITIALIZATION_ERROR: Firebase gagal dimuat. Pastikan file google-services.json sudah berada di folder android/app/. Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowa',
      debugShowCheckedModeBanner: false, 
      
      // Tema Aplikasi Gabungan Modern Gelap & Emas Khas DesaPay
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.purple,
          secondary: Colors.amber, // Aksen emas
          surface: Colors.black, // [UPGRADE CTO] Memperbaiki 'background' yang deprecated
        ),
        
        // [UPGRADE CTO] Injeksi Tipografi Premium secara Global
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      
      // Halaman Pertama yang Muncul Saat Aplikasi Flowa Dibuka Warga
      home: const LoginScreen(),
    );
  }
}
