import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'public_user_profile_screen.dart';

class DiscoverUsersScreen extends StatefulWidget {
  const DiscoverUsersScreen({super.key});
  @override State<DiscoverUsersScreen> createState() => _DiscoverUsersScreenState();
}
class _DiscoverUsersScreenState extends State<DiscoverUsersScreen> {
  final _search = TextEditingController();
  String _query = '';
  @override void dispose() { _search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('Temukan Pengguna'), backgroundColor: const Color(0xFFF5F7FB)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,8,16,14), child: TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase().replaceFirst('@','')),
          decoration: InputDecoration(hintText: 'Cari nama atau @username', prefixIcon: const Icon(Icons.search),
            filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => _query=''); }, icon: const Icon(Icons.close))),
        )),
        const Padding(padding: EdgeInsets.fromLTRB(18,0,18,10), child: Row(children: [
          Icon(Icons.public, color: Color(0xFF477CF4), size: 18), SizedBox(width: 7),
          Text('Komunitas Flowa', style: TextStyle(fontWeight: FontWeight.w800)), Spacer(),
          Text('Pengguna', style: TextStyle(color: Color(0xFF8793A5), fontSize: 11)),
        ])),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream: FirebaseFirestore.instance.collection('public_profiles').limit(150).snapshots(),
          builder: (context,snap) {
            if (snap.hasError) return const Center(child: Padding(padding: EdgeInsets.all(24),
              child: Text('Daftar pengguna belum dapat dimuat. Periksa Firestore Rules public_profiles.')));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = (snap.data!.docs.where((d) {
              if (d.id == uid) return false;
              final dta=d.data(); final name=(dta['displayName']??'').toString().toLowerCase();
              final username=(dta['username']??'').toString().toLowerCase();
              return _query.isEmpty || name.contains(_query) || username.contains(_query);
            }).toList()..sort((a,b)=>(a.data()['displayName']??'').toString().toLowerCase().compareTo((b.data()['displayName']??'').toString().toLowerCase())));
            if (docs.isEmpty) return Center(child: Text(_query.isEmpty ? 'Belum ada pengguna lain' : 'Pengguna tidak ditemukan'));
            return ListView.separated(padding: const EdgeInsets.fromLTRB(12,0,12,24), itemCount: docs.length,
              separatorBuilder: (_,__)=>const SizedBox(height:7),
              itemBuilder: (context,index) {
                final doc=docs[index]; final data=doc.data();
                final name=(data['displayName']??'Pengguna Flowa').toString();
                final username=(data['username']??'pengguna').toString();
                final photo=(data['photoUrl']??'').toString();
                final online=data['isOnline']==true;
                return Material(color: Colors.white, borderRadius: BorderRadius.circular(16), child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal:13,vertical:6),
                  leading: Stack(children: [
                    CircleAvatar(radius:25, backgroundColor: const Color(0xFFEAF0FF),
                      backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                      child: photo.isEmpty ? const Icon(Icons.person,color: Color(0xFF477CF4)) : null),
                    if(online) Positioned(right:0,bottom:0,child:Container(width:12,height:12,decoration:BoxDecoration(
                      color:const Color(0xFF22B573),shape:BoxShape.circle,border:Border.all(color:Colors.white,width:2)))),
                  ]),
                  title: Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
                  subtitle: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('@$username',style:const TextStyle(color:Color(0xFF477CF4),fontSize:11,fontWeight:FontWeight.w700)),
                    Text(online?'Aktif sekarang':'Pengguna Flowa',style:TextStyle(fontSize:10,color:online?const Color(0xFF22A06B):const Color(0xFF9AA5B5))),
                  ]),
                  trailing: const Icon(Icons.storefront_outlined,color:Color(0xFF477CF4)),
                  onTap: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PublicUserProfileScreen(userId:doc.id,displayName:name))),
                  onLongPress: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(
                    sellerId:doc.id,sellerName:name,productId:'',productTitle:''))),
                ));
              });
          },
        )),
      ]),
    );
  }
}
