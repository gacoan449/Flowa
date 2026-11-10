import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/auth_gate.dart';

class FlowaBrandSplash extends StatefulWidget {
  const FlowaBrandSplash({super.key});

  @override
  State<FlowaBrandSplash> createState() => _FlowaBrandSplashState();
}

class _FlowaBrandSplashState extends State<FlowaBrandSplash> {
  bool _showApp = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showApp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) return const AuthGate();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/images/flowa_logo.jpg',
                width: 156,
                height: 156,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Flowa',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0xFF263B66),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temukan. Terhubung. Bertumbuh.',
              style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
            ),
          ],
        ),
      ),
    );
  }
}
