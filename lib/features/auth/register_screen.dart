import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    if (password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter.')));
      return;
    }
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak sama.')));
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService().register(email: email.text, password: password.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrasi gagal: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); confirm.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daftar Akun')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        TextField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true,
          decoration: const InputDecoration(labelText: 'Password minimal 6 karakter')),
        const SizedBox(height: 12),
        TextField(controller: confirm, obscureText: true,
          decoration: const InputDecoration(labelText: 'Ulangi password')),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: loading ? null : submit,
          child: Text(loading ? 'Membuat akun...' : 'Daftar'),
        )),
      ]),
    ),
  );
}
