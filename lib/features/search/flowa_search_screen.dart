import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../chat/public_user_profile_screen.dart';

class FlowaSearchScreen extends StatefulWidget {
  const FlowaSearchScreen({super.key});
  @override State<FlowaSearchScreen> createState()=>_FlowaSearchScreenState();
}
class _FlowaSearchScreenState extends State<FlowaSearchScreen> {
  final _controller=TextEditingController();
  String _query='';
  String _tab='Semua';
  @override void dispose(){_controller.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    final q=_query.toLowerCase().replaceFirst('@','');
    return Scaffold(
      appBar: AppBar(title: const Text('Cari di Flowa')),
      body: Column(children:[
        Padding(padding:const EdgeInsets.all(14),child:TextField(
          controller:_controller, autofocus:true,
          onChanged:(v)=>setState(()=>_query=v.trim()),
          decoration:InputDecoration(hintText:'Cari orang, username, atau postingan',prefixIcon:const Icon(Icons.search),
            suffixIcon:_query.isEmpty?null:IconButton(onPressed:(){_controller.clear();setState(()=>_query='');},icon:const Icon(Icons.close)),
            filled:true,fillColor:const Color(0xFFF2F5FA),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none)),
        )),
        Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:SegmentedButton<String>(
          segments:const [ButtonSegment(value:'Semua',label:Text('Semua')),ButtonSegment(value:'Orang',label:Text('Orang')),ButtonSegment(value:'Postingan',label:Text('Postingan'))],
          selected:{_tab},onSelectionChanged:(v)=>setState(()=>_tab=v.first),showSelectedIcon:false,
        )),
        Expanded(child:_query.length<2?const Center(child:Text('Ketik minimal 2 karakter untuk mulai mencari.')):ListView(
          padding:const EdgeInsets.all(12),children:[
            if(_tab!='Postingan') ...[
              const Text('PENGGUNA',style:TextStyle(fontWeight:FontWeight.w800,color:Color(0xFF718096))),
              const SizedBox(height:6),
              StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                stream:FirebaseFirestore.instance.collection('public_profiles').limit(200).snapshots(),
                builder:(context,snap){
                  if(!snap.hasData)return const Padding(padding:EdgeInsets.all(12),child:LinearProgressIndicator());
                  final docs=snap.data!.docs.where((d){
                    if(d.id==uid)return false; final x=d.data();
                    return ('${x['displayName']??''} ${x['username']??''}').toString().toLowerCase().contains(q);
                  }).take(30).toList();
                  if(docs.isEmpty)return const ListTile(title:Text('Pengguna tidak ditemukan'));
                  return Column(children:docs.map((d){
                    final x=d.data();final name=(x['displayName']??'Pengguna Flowa').toString();final photo=(x['photoUrl']??'').toString();
                    return ListTile(leading:CircleAvatar(backgroundImage:photo.isEmpty?null:NetworkImage(photo),child:photo.isEmpty?const Icon(Icons.person):null),
                      title:Text(name),subtitle:Text('@${x['username']??''}'),
                      onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PublicUserProfileScreen(userId:d.id,displayName:name))));
                  }).toList());
                },
              ),
            ],
            if(_tab!='Orang') ...[
              const SizedBox(height:14),const Text('POSTINGAN',style:TextStyle(fontWeight:FontWeight.w800,color:Color(0xFF718096))),
              const SizedBox(height:6),
              StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                stream:FirebaseFirestore.instance.collection('posts').orderBy('createdAt',descending:true).limit(100).snapshots(),
                builder:(context,snap){
                  if(snap.hasError)return const ListTile(title:Text('Pencarian postingan belum tersedia.'));
                  if(!snap.hasData)return const Padding(padding:EdgeInsets.all(12),child:LinearProgressIndicator());
                  final docs=snap.data!.docs.where((d){
                    final x=d.data();return ('${x['text']??''} ${x['ownerName']??''}').toString().toLowerCase().contains(q);
                  }).take(40).toList();
                  if(docs.isEmpty)return const ListTile(title:Text('Postingan tidak ditemukan'));
                  return Column(children:docs.map((d){final x=d.data();return Card(child:ListTile(
                    leading:const Icon(Icons.article_outlined,color:Color(0xFF3267E9)),
                    title:Text((x['text']??'Album foto').toString(),maxLines:2,overflow:TextOverflow.ellipsis),
                    subtitle:Text((x['ownerName']??'Pengguna').toString()),
                    onTap:()=>showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(ctx)=>Padding(
                      padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Text((x['ownerName']??'Pengguna').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
                        const SizedBox(height:8),Text((x['text']??'Album foto').toString()),
                        const SizedBox(height:12),Text('${(x['imageUrls'] as List?)?.length??0} foto',style:const TextStyle(color:Color(0xFF3267E9))),
                      ]),
                    )),
                  ));}).toList());
                },
              ),
            ],
          ],
        )),
      ]),
    );
  }
}
