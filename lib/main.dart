import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // [UPGRADE CTO] Paket font premium

import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  // Wajib dipanggil sebelum menginisialisasi Firebase di Flutter
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi Firebase menggunakan opsi data JSON manual untuk Flowa.com
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA",
        appId: "1:242778852239:android:1f29dc10d55376eafe99fa",
        messagingSenderId: "242778852239",
        projectId: "desapay-10614",
        storageBucket: "desapay-10614.firebasestorage.app",
      ),
    );
  } catch (e) {
    // [UPGRADE CTO] Menggunakan debugPrint standar industri
    debugPrint("LOG_INITIALIZATION_ERROR: Firebase gagal dimuat. Error: $e");
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
