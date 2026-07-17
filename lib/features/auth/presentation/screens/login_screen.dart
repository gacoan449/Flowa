import 'package:flutter/material.dart';
import '../../../../app_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); 
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // KUNCI RAHASIA ADMIN
  // [PERINGATAN CTO]: Untuk saat ini logika dipertahankan sesuai SOP. 
  // Namun wajib dijadwalkan untuk migrasi ke server (Firebase) agar tidak bocor dari APK.
  final String _emailAdminRahasia = "hilwaowner@flowa.com"; 
  final String _sandiAdminRahasia = "taniowner77";          

  @override
  void dispose() {
    // WAJIB: Membersihkan controller dari memori saat layar ditutup untuk mencegah Memory Leak
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    String account = _identifierController.text.trim();
    String password = _passwordController.text.trim();

    if (account.isEmpty || password.isEmpty) {
      _showPremiumSnackBar('Nomor HP/Email dan Kata Sandi tidak boleh kosong!', isError: true);
      return;
    }

    // Deteksi otomatis Admin vs Warga
    if (account == _emailAdminRahasia && password == _sandiAdminRahasia) {
      _showPremiumSnackBar('Selamat datang Pemilik Utama! Mengaktifkan Ruang Kontrol Admin...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AppNavigation(overrideRole: 'admin'),
        ),
      );
    } else {
      _showPremiumSnackBar('Masuk sukses sebagai warga: $account');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AppNavigation(overrideRole: 'user'),
        ),
      );
    }
  }

  // Fungsi khusus untuk menampilkan Notifikasi (SnackBar) yang lebih elegan bergaya modern
  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang gradien mewah dari ungu gelap ke hitam pekat
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A002B), // Ungu sangat gelap
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dengan efek cahaya (Glow Effect)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_circle_fill, size: 80, color: Colors.purpleAccent),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Flowa",
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 36, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2.0
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Wadah kumpul & ngonten video warga desa",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // Input Akun Premium
                  _buildPremiumTextField(
                    controller: _identifierController,
                    hintText: "Nomor HP atau Email",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // Input Kata Sandi Premium
                  _buildPremiumTextField(
                    controller: _passwordController,
                    hintText: "Kata Sandi",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 40),

                  // Tombol Masuk Mewah dengan Gradien
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Colors.purpleAccent, Colors.purple],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _handleLogin,
                      child: const Text(
                        "Masuk", 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Teks Daftar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya akun? ", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Daftar Sekarang", 
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget builder terpisah agar kode utama (build) tetap bersih (Clean Code)
  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05), // Efek Glassmorphism transparan
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Icon(icon, color: Colors.white54),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }
}
