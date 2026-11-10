import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Profil minimum yang aman ditampilkan kepada pengguna lain di dalam chat.
/// Email dan data privat tetap berada di koleksi users.
class ChatProfileService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> ref(String uid) =>
      _db.collection('public_profiles').doc(uid);

  static Future<void> syncCurrentUser({String? displayName}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Map<String, dynamic> privateProfile = {};
    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      privateProfile = snapshot.data() ?? {};
    } catch (_) {}
    var name = 'Pengguna Flowa';
    for (final candidate in [privateProfile['name'], displayName, user.displayName]) {
      final value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) { name = value; break; }
    }
    final usernameValue = (privateProfile['username'] ?? '').toString().trim();
    final username = usernameValue.isNotEmpty ? usernameValue :
      'flowa_${user.uid.substring(0, user.uid.length < 6 ? user.uid.length : 6)}';
    await ref(user.uid).set({
      'uid': user.uid,
      'displayName': name,
      'username': username,
      'bio': (privateProfile['bio'] ?? '').toString(),
      'photoUrl': (privateProfile['photoUrl'] ?? user.photoURL ?? '').toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String uid) =>
      ref(uid).snapshots();

  static Future<void> setPresence(String uid, bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    final existing = await ref(uid).get();
    final current = existing.data() ?? <String, dynamic>{};
    final fallbackName = (current['displayName'] ?? user?.displayName ?? 'Pengguna Flowa').toString();
    final username = (current['username'] ?? 'flowa_${uid.substring(0, uid.length < 6 ? uid.length : 6)}').toString();
    await ref(uid).set({
      'uid': uid,
      'displayName': fallbackName,
      'username': username,
      'photoUrl': current['photoUrl'] ?? user?.photoURL ?? '',
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
