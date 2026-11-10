import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'features/auth/auth_gate.dart';
import 'features/chat/chat_profile_service.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(flowaFirebaseMessagingBackgroundHandler);
  runApp(const FlowaApp());
}

class FlowaApp extends StatefulWidget {
  const FlowaApp({super.key});

  @override
  State<FlowaApp> createState() => _FlowaAppState();
}

class _FlowaAppState extends State<FlowaApp> with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.initialize();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        ChatProfileService.setPresence(user.uid, true).catchError((_) {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (state == AppLifecycleState.resumed) {
      ChatProfileService.setPresence(user.uid, true).catchError((_) {});
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ChatProfileService.setPresence(user.uid, false).catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flowa',
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}