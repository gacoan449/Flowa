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
    final name = (displayName ?? user.displayName ?? '').trim();
    await ref(user.uid).set({
      'uid': user.uid,
      'displayName': name.isNotEmpty
          ? name
          : (user.email?.split('@').first ?? 'Pengguna Flowa'),
      'photoUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String uid) =>
      ref(uid).snapshots();

  static Future<void> setPresence(String uid, bool online) async {
    await ref(uid).set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
