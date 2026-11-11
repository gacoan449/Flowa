import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    final stream = FirebaseFirestore.instance.collection('notifications')
        .where('recipientId', isEqualTo: uid).limit(100).snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitas')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Aktivitas belum dapat dimuat.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = [...snapshot.data!.docs]..sort((a,b) {
            final av=a.data()['createdAt']; final bv=b.data()['createdAt'];
            final at=av is Timestamp ? av.toDate() : DateTime(2000);
            final bt=bv is Timestamp ? bv.toDate() : DateTime(2000);
            return bt.compareTo(at);
          });
          if (docs.isEmpty) return const Center(child: Text('Belum ada aktivitas. Interaksi baru akan muncul di sini.'));
          return ListView.separated(
            itemCount: docs.length, padding: const EdgeInsets.all(12),
            separatorBuilder: (_,__)=>const Divider(height: 1),
            itemBuilder: (context,index) {
              final doc=docs[index]; final data=doc.data();
              final read=data['read']==true;
              final actor=(data['actorName']??'Pengguna Flowa').toString();
              final type=(data['type']??'activity').toString();
              final message=type=='like'?'menyukai postinganmu':type=='comment'?'mengomentari postinganmu':type=='reply'?'membalas komentarmu':type=='follow'?'mulai mengikutimu':'berinteraksi denganmu';
              return ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFEAF0FF), child: Icon(
                  type=='like'?Icons.favorite:type=='follow'?Icons.person_add_alt_1:Icons.mode_comment_outlined,
                  color: type=='like'?Colors.pink:const Color(0xFF3267E9))),
                title: Text('$actor $message',style: TextStyle(fontWeight: read?FontWeight.normal:FontWeight.w800)),
                subtitle: Text((data['text']??'Buka Flowa untuk melihat aktivitas ini.').toString(),maxLines:2,overflow:TextOverflow.ellipsis),
                trailing: read?null:const Icon(Icons.circle,size:9,color:Color(0xFF3267E9)),
                onTap: () => doc.reference.update({'read':true}),
              );
            },
          );
        },
      ),
    );
  }
}
