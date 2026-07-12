import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  // Wajib dipanggil sebelum menginisialisasi Firebase di Flutter
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi Otomatis Firebase menggunakan file google-services.json Anda
    await Firebase.initializeApp();
  } catch (e) {
    print("LOG_INITIALIZATION_ERROR: Firebase gagal dimuat. Pastikan file google-services.json sudah berada di folder android/app/. Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowa',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug merah di pojok HP
      
      // Tema Aplikasi Gabungan Modern Gelap & Emas Khas DesaPay
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.purple,
          secondary: Colors.amber, // Aksen emas DesaPay
          background: Colors.black,
        ),
      ),
      
      // Halaman Pertama yang Muncul Saat Aplikasi Flowa Dibuka Warga
      home: const LoginScreen(),
    );
  }
}
