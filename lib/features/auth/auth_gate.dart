import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_dashboard.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import '../chat/chat_profile_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AuthMessage(
            title: 'Gagal memeriksa sesi',
            message: snapshot.error.toString(),
            onRetry: () {},
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Memeriksa sesi akun...');
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return _UserProfileGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _UserProfileGate extends StatefulWidget {
  const _UserProfileGate({super.key, required this.user});
  final User user;

  @override
  State<_UserProfileGate> createState() => _UserProfileGateState();
}

class _UserProfileGateState extends State<_UserProfileGate> with WidgetsBindingObserver {
  late Future<String> _roleFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _roleFuture = _loadRole();
    _updatePresence(true);
  }

  Future<String> _loadRole() async {
    // Refresh profil Auth agar status verifikasi tidak memakai cache lama.
    await widget.user.reload().timeout(const Duration(seconds: 15));
    final currentUser = FirebaseAuth.instance.currentUser ?? widget.user;
    final adminEmail = (currentUser.email ?? '').trim().toLowerCase();

    // Kembali ke model akses admin semula: email admin khusus langsung
    // diarahkan ke dashboard, tanpa syarat emailVerified.
    if (adminEmail == 'flowa324@gmail.com') {
      try {
        await ChatProfileService.syncCurrentUser(displayName: currentUser.displayName);
      } catch (_) {
        // Sinkronisasi profil chat tidak boleh menghalangi akses admin.
      }
      return 'admin';
    }

    // Staff roles are issued only by the trusted setStaffRole Cloud Function.
    // Force-refresh the signed custom claims before selecting an admin workspace.
    final tokenResult = await currentUser.getIdTokenResult(true).timeout(const Duration(seconds: 15));
    final claimRole = (tokenResult.claims?['role'] ?? '').toString().toLowerCase();
    if (['admin', 'moderator', 'support'].contains(claimRole)) {
      try {
        await ChatProfileService.syncCurrentUser(displayName: currentUser.displayName);
      } catch (_) {}
      return claimRole;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
    final snapshot = await ref.get().timeout(const Duration(seconds: 15));
    try {
      await ChatProfileService.syncCurrentUser(displayName: widget.user.displayName);
    } catch (_) {
      // Public chat profile sync is best-effort and must not block sign-in.
    }

    if (!snapshot.exists) {
      await ref.set({
        'uid': widget.user.uid,
        'email': widget.user.email ?? '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
      return 'user';
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    if (data['active'] == false) return 'suspended';
    final role = (data['role'] ?? 'user').toString().toLowerCase().trim();
    if (data['role'] == null || role.isEmpty) {
      await ref.set({'role': 'user'}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
      return 'user';
    }
    return role;
  }

  Future<void> _updatePresence(bool online) async {
    try { await ChatProfileService.setPresence(widget.user.uid, online); } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updatePresence(true);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) _updatePresence(false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updatePresence(false);
    super.dispose();
  }

  void _retry() => setState(() => _roleFuture = _loadRole());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Memuat profil akun...');
        }
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          final message = error.contains('permission-denied')
              ? 'Akses profil ditolak oleh aturan Firestore. Periksa Firestore Rules untuk users/{uid}.'
              : (error.contains('unavailable') || error.contains('deadline-exceeded'))
                  ? 'Server Firebase tidak merespons. Periksa koneksi internet lalu coba lagi.'
                  : error;
          return _AuthMessage(
            title: 'Profil belum dapat dimuat',
            message: message,
            onRetry: _retry,
          );
        }
        switch (snapshot.data) {
          case 'admin':
          case 'moderator':
          case 'support':
            return const AdminDashboard();
          case 'suspended':
            return _AuthMessage(
              title: 'Akun dinonaktifkan',
              message: 'Akun ini sedang dinonaktifkan oleh admin Flowa. Hubungi Customer Service jika merasa ini keliru.',
              onRetry: _retry,
            );
          case 'user':
          case 'buyer':
          case 'customer':
          case null:
            return const _MaintenanceAwareHome();
          default:
            return _AuthMessage(
              title: 'Role akun belum didukung',
              message: 'Role "' + (snapshot.data ?? '') +
                  '" belum memiliki halaman tujuan. Hubungi admin.',
              onRetry: _retry,
            );
        }
      },
    );
  }
}


class _MaintenanceAwareHome extends StatelessWidget {
  const _MaintenanceAwareHome();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('app_config').doc('platform').snapshots(),
      builder: (context, snapshot) {
        final config = snapshot.data?.data() ?? <String, dynamic>{};
        if (config['maintenanceMode'] == true) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.construction_rounded, size: 58),
                  const SizedBox(height: 16),
                  const Text('Flowa sedang pemeliharaan', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text((config['maintenanceMessage'] ?? 'Silakan coba kembali nanti.').toString(), textAlign: TextAlign.center),

                ]),
              ),
            ),
          );
        }
        return const HomeScreen();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      );
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Keluar dari akun'),
                ),
              ],
            ),
          ),
        ),
      );
}
