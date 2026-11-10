import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'features/chat/chat_profile_service.dart';
import 'core/app_appearance.dart';
import 'core/brand_splash_screen.dart';
import 'core/notification_service.dart';

Future<void> _recordClientFailure(Object error, StackTrace stack, String source) async {
  try {
    await FirebaseFirestore.instance.collection('client_error_logs').add({
      'message': error.toString().length > 3000 ? error.toString().substring(0, 3000) : error.toString(),
      'stack': stack.toString().length > 6000 ? stack.toString().substring(0, 6000) : stack.toString(),
      'source': source,
      'uid': FirebaseAuth.instance.currentUser?.uid ?? '',
      'platform': defaultTargetPlatform.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Failure logging must never crash the app or mask the original error.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _recordClientFailure(details.exception, details.stack ?? StackTrace.current, 'flutter');
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    _recordClientFailure(error, stack, 'platform');
    return false;
  };
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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AppAppearance.watch(),
      builder: (context, snapshot) {
        final appearance = <String, dynamic>{...AppAppearance.defaults}
          ..addAll(snapshot.data?.data() ?? <String, dynamic>{});
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flowa',
          theme: AppAppearance.theme(appearance),
          darkTheme: AppAppearance.theme(appearance, dark: true),
          themeMode: ThemeMode.system,
          home: const FlowaBrandSplash(),
        );
      },
    );
  }
}
