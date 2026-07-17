import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _identifierController = TextEditingController(); 
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    // [UPGRADE CTO] WAJIB: Membersihkan memori HP dari controller saat halaman pendaftaran ditutup
    _usernameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    String username = _usernameController.text.trim();
    String account = _identifierController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || account.isEmpty || password.isEmpty) {
      _showPremiumSnackBar('Semua kolom pendaftaran wajib diisi!', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // [PERINGATAN CTO]: Logika dipertahankan sesuai SOP.
      // Namun untuk standar industri ke depannya, password TIDAK BOLEH disimpan dalam bentuk teks biasa (plain text).
      // Wajib menggunakan Firebase Authentication atau enkripsi (Hashing) demi keamanan ekosistem.
      await FirebaseFirestore.instance.collection('users').add({
        'username': username,
        'account': account,
        'password': password, 
        'role': 'user',       
        'isVerified': false,  
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showPremiumSnackBar('Pendaftaran Berhasil! Silakan masuk di halaman utama.');
      
      // Menggunakan mounted check sebelum melakukan navigasi asinkron
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showPremiumSnackBar('Gagal mendaftar ke server: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi Notifikasi (SnackBar) Premium
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
      extendBodyBehindAppBar: true, // Membuat gradien meluas hingga ke bawah AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A002B), // Ungu sangat gelap (Konsisten dengan LoginScreen)
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
                strokeWidth: 3,
              )
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ikon Premium dengan Glow Effect
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
                        child: const Icon(Icons.person_add_alt_1, size: 70, color: Colors.purpleAccent),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Buat Akun Baru",
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Daftar untuk mulai kumpul & ngonten di Flowa",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Input Username Premium
                      _buildPremiumTextField(
                        controller: _usernameController,
                        hintText: "Nama Pengguna (Contoh: Budi_Tani)",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),

                      // Input Akun Premium
                      _buildPremiumTextField(
                        controller: _identifierController,
                        hintText: "Nomor HP atau Email",
                        icon: Icons.phone_android_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Input Kata Sandi Premium
                      _buildPremiumTextField(
                        controller: _passwordController,
                        hintText: "Buat Kata Sandi",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 40),

                      // Tombol Daftar Mewah dengan Gradien
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
                          onPressed: _handleRegister,
                          child: const Text(
                            "Daftar Sekarang", 
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  // Widget builder terpisah untuk konsistensi UI & Clean Code
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
        fillColor: Colors.white.withOpacity(0.05), // Efek Glassmorphism
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
