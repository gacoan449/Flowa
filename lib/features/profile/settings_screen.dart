import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../chat/chat_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController();
  bool _saving = false;
  @override
  void initState() { super.initState(); _name.text = FirebaseAuth.instance.currentUser?.displayName ?? ''; }
  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tampilan tidak boleh kosong.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await user.updateDisplayName(name);
      await user.reload();
      await ChatProfileService.syncCurrentUser(displayName: name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama profil berhasil diperbarui.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan gagal disimpan. Periksa koneksi dan coba lagi.')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Akun')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(controller: _name, textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama tampilan',
            border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 14),
        TextFormField(initialValue: user?.email ?? 'Email tidak tersedia', readOnly: true,
          decoration: const InputDecoration(labelText: 'Email akun',
            border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : 'Simpan Pengaturan')),
      ]),
    );
  }
}
