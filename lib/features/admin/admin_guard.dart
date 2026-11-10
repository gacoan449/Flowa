import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = (user?.email ?? '').trim().toLowerCase();
    final isAdmin = user != null && email == 'flowa324@gmail.com';

    if (!isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Akses admin ditolak.')),
      );
    }

    return const AdminDashboard();
  }
}
