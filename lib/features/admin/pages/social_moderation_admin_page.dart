import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SocialModerationAdminPage extends StatelessWidget {
  const SocialModerationAdminPage({super.key});
  @override Widget build(BuildContext context){
    final db=FirebaseFirestore.instance;
    return Scaffold(appBar:AppBar(title:const Text('Moderasi Sosial')),
      body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream:db.collection('reports').where('status',isEqualTo:'pending').snapshots(),
        builder:(context,snap){
          if(snap.hasError)return const Center(child:Text('Laporan belum dapat dimuat. Periksa permission reports.'));
          if(!snap.hasData)return const Center(child:CircularProgressIndicator());
          final docs=snap.data!.docs;
          if(docs.isEmpty)return const Center(child:Text('Tidak ada laporan tertunda.'));
          return ListView.separated(padding:const EdgeInsets.all(12),itemCount:docs.length,
            separatorBuilder:(_,__)=>const SizedBox(height:8),
            itemBuilder:(context,index){
              final doc=docs[index];final d=doc.data();
              final type=(d['targetType']??(d['productId']!=null?'product':'user')).toString();
              final target=(d['targetId']??d['productId']??'').toString();
              return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[const Icon(Icons.flag_outlined,color:Colors.red),const SizedBox(width:8),
                  Expanded(child:Text('Laporan $type',style:const TextStyle(fontWeight:FontWeight.w800))),
                  Text((d['status']??'pending').toString(),style:const TextStyle(color:Colors.orange))]),
                const SizedBox(height:8),
                Text('Alasan: ${d['reason']??'-'}'),
                Text('Target: ${target.isEmpty?'Tidak tersedia':target}',maxLines:1,overflow:TextOverflow.ellipsis),
                const SizedBox(height:10),
                Wrap(spacing:8,children:[
                  OutlinedButton(onPressed:()=>doc.reference.update({'status':'reviewed','reviewedAt':FieldValue.serverTimestamp()}),child:const Text('Tandai ditinjau')),
                  if(type=='post'&&target.isNotEmpty)FilledButton.tonal(onPressed:()async{
                    await db.collection('posts').doc(target).delete();
                    await doc.reference.update({'status':'action_taken','reviewedAt':FieldValue.serverTimestamp()});
                  },child:const Text('Hapus postingan')),
                  TextButton(onPressed:()=>doc.reference.update({'status':'dismissed','reviewedAt':FieldValue.serverTimestamp()}),child:const Text('Abaikan')),
                ]),
              ])));
            });
        }));
  }
}
