import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../products/product_detail_screen.dart';

class PublicUserProfileScreen extends StatelessWidget {
  const PublicUserProfileScreen({super.key, required this.userId, required this.displayName});
  final String userId;
  final String displayName;

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('public_profiles').doc(userId).snapshots(),
    builder: (context, profileSnap) {
      final profile=profileSnap.data?.data() ?? {};
      final name=(profile['displayName'] ?? displayName).toString();
      final username=(profile['username'] ?? '').toString();
      final photo=(profile['photoUrl'] ?? '').toString();
      final bio=(profile['bio'] ?? '').toString();
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(title: const Text('Profil Pengguna'),backgroundColor:const Color(0xFFF5F7FB)),
        body: Column(children:[
          Container(width:double.infinity,color:Colors.white,padding:const EdgeInsets.fromLTRB(20,18,20,18),
            child:Column(children:[
              CircleAvatar(radius:42,backgroundColor:const Color(0xFFEAF0FF),
                backgroundImage:photo.isNotEmpty?NetworkImage(photo):null,
                child:photo.isEmpty?const Icon(Icons.person,size:42,color:Color(0xFF477CF4)):null),
              const SizedBox(height:10),
              Text(name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
              if(username.isNotEmpty) Text('@$username',style:const TextStyle(color:Color(0xFF477CF4),fontWeight:FontWeight.w700)),
              if(bio.isNotEmpty) Padding(padding:const EdgeInsets.only(top:6),child:Text(bio,textAlign:TextAlign.center)),
              const SizedBox(height:13),
              SizedBox(width:double.infinity,child:FilledButton.icon(
                onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(
                  sellerId:userId,sellerName:name,productId:'',productTitle:''))),
                icon:const Icon(Icons.chat_bubble_outline),label:const Text('Kirim Pesan'))),
            ])),
          const Padding(padding:EdgeInsets.fromLTRB(16,16,16,8),child:Row(children:[
            Icon(Icons.storefront_outlined,color:Color(0xFF477CF4)),SizedBox(width:8),
            Text('Produk pengguna ini',style:TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
          ])),
          Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
            stream:FirebaseFirestore.instance.collection('products')
              .where('sellerId',isEqualTo:userId).where('status',isEqualTo:'active').snapshots(),
            builder:(context,snapshot){
              if(snapshot.hasError)return const Center(child:Text('Produk belum dapat dimuat.'));
              if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
              final products=snapshot.data!.docs;
              if(products.isEmpty)return const Center(child:Text('Pengguna ini belum memiliki produk aktif.'));
              return GridView.builder(
                padding:const EdgeInsets.all(12),
                gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.78),
                itemCount:products.length,
                itemBuilder:(context,index){
                  final doc=products[index];final data=doc.data();
                  final image=(data['imageUrl']??'').toString();
                  return Card(clipBehavior:Clip.antiAlias,child:InkWell(
                    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductDetailScreen(productId:doc.id))),
                    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Expanded(child:image.isEmpty?const Center(child:Icon(Icons.shopping_bag_outlined,size:38)):
                        Image.network(image,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined)))),
                      Padding(padding:const EdgeInsets.all(9),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Text((data['title']??'Produk').toString(),maxLines:2,overflow:TextOverflow.ellipsis,
                          style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),
                        const SizedBox(height:4),
                        Text('Rp ${data['price']??0}',style:const TextStyle(color:Color(0xFF3267E9),fontWeight:FontWeight.w900)),
                      ])),
                    ]),
                  ));
                },
              );
            },
          )),
        ]),
      );
    },
  );
}
