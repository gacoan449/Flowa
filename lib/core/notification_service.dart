import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> flowaFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Android/iOS displays notification payloads in the system tray while backgrounded.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(settings);
    const channel = AndroidNotificationChannel(
      'flowa_messages', 'Pesan Flowa',
      description: 'Notifikasi pesan dan percakapan Flowa',
      importance: Importance.high,
    );
    await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onBackgroundMessage(flowaFirebaseMessagingBackgroundHandler);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _registerDevice(user.uid);
    });
  }

  Future<void> _registerDevice(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid)
            .collection('devices').doc(token).set({
          'token': token,
          'platform': 'android',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _messaging.onTokenRefresh.listen((token) {
        FirebaseFirestore.instance.collection('users').doc(uid)
            .collection('devices').doc(token).set({
          'token': token,
          'platform': 'android',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {
      // Notification registration must not block sign-in or app startup.
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Pesan baru';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? 'Kamu menerima pesan baru di Flowa.';
    await _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flowa_messages', 'Pesan Flowa',
          channelDescription: 'Notifikasi pesan dan percakapan Flowa',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
