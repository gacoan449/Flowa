import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await AuthService().login(email: email.text.trim(), password: password.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFF), Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        )),
        Positioned(top: -100, right: -80, child: _Glow(color: primary.withValues(alpha: .13), size: 260)),
        Positioned(bottom: 70, left: -110, child: _Glow(color: const Color(0xFF18B6FF).withValues(alpha: .10), size: 280)),
        SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, const Color(0xFF18B6FF)]),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: primary.withValues(alpha: .28), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 35),
              )),
              const SizedBox(height: 22),
              Text('Selamat datang di Flowa', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Terhubung, berbagi, dan temukan hal menarik dalam satu pengalaman yang lebih dekat.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF62708A), height: 1.45)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .88),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white),
                  boxShadow: [BoxShadow(color: const Color(0xFF12315F).withValues(alpha: .08), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Masuk', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  const Text('Gunakan akun Flowa Anda untuk melanjutkan.', style: TextStyle(color: Color(0xFF7A879A))),
                  const SizedBox(height: 22),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@email.com', prefixIcon: Icon(Icons.alternate_email_rounded))),
                  const SizedBox(height: 14),
                  TextField(controller: password, obscureText: obscure,
                    onSubmitted: (_) => loading ? null : submit(),
                    decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
                  const SizedBox(height: 22),
                  SizedBox(height: 54, child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primary, const Color(0xFF238BFF)]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: primary.withValues(alpha: .26), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      onPressed: loading ? null : submit,
                      child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                        : const Text('Masuk ke Flowa'),
                    ),
                  )),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Belum punya akun? Daftar sekarang'),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              const Text('Dengan melanjutkan, Anda menyetujui pengalaman komunitas Flowa yang aman dan nyaman.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF8793A6), height: 1.4)),
            ]),
          ),
        ))),
      ]),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color; final double size;
  @override Widget build(BuildContext context) => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
