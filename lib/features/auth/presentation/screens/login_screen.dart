import 'package:flutter/material.dart';
import '../../../../app_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // Bisa diisi Nomor HP / Email warga
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // 1. KUNCI RAHASIA ADMIN (Tersimpan aman di GitHub, warga tidak akan pernah tahu!)
  final String _emailAdminRahasia = "hilwaowner@flowa.com"; // Silakan ganti dengan email Anda jika mau
  final String _sandiAdminRahasia = "taniowner77";          // Silakan ganti dengan sandi rahasia Anda

  void _handleLogin() {
    String account = _identifierController.text.trim();
    String password = _passwordController.text.trim();

    if (account.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor HP/Email dan Kata Sandi tidak boleh kosong!')),
      );
      return;
    }

    // 2. LOGIKA KECANGGIHAN DESAPAY: Deteksi otomatis apakah yang login adalah sang Pemilik Aplikasi
    if (account == _emailAdminRahasia && password == _sandiAdminRahasia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selamat datang Pemilik Utama! Mengaktifkan Ruang Kontrol Admin...')),
      );

      // LANGSUNG DIKUNCI MASUK SEBAGAI 'admin' TERKENDALIAN PENUH!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AppNavigation(overrideRole: 'admin'),
        ),
      );
    } else {
      // Alur masuk untuk Warga Desa biasa (Role otomatis dikunci sebagai 'user' penonton biasa)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masuk sukses sebagai warga: $account')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AppNavigation(overrideRole: 'user'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, size: 80, color: Colors.purple),
                const SizedBox(height: 12),
                const Text(
                  "Flowa",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const Text(
                  "Wadah kumpul & ngonten video warga desa",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Input Akun
                TextField(
                  controller: _identifierController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Nomor HP atau Email",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.phone_android_outlined, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Kata Sandi dengan Tombol Intip
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Kata Sandi",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // Tombol Masuk Utama
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleLogin,
                    child: const Text("Masuk", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun Flowa? ", style: TextStyle(color: Colors.white54)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text("Daftar Sekarang", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
