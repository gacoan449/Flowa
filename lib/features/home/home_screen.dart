import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../products/product_upload_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../profile/profile_screen.dart';
import 'home_config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen>{
  String? selectedCategory;
  @override Widget build(BuildContext context)=>StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
    stream:HomeConfigService().watch(),
    builder:(context,configSnapshot){
      final config=<String,dynamic>{...HomeConfigService.defaults}..addAll(configSnapshot.data?.data()??{});
      final primary=Color((config['primaryColor'] as num?)?.toInt()??0xFF0758D9);
      final accent=Color((config['accentColor'] as num?)?.toInt()??0xFF00A8FF);
      final background=Color((config['backgroundColor'] as num?)?.toInt()??0xFFF7F9FC);
      final dark=config['themeMode']=='dark';
      final visibility=config['sectionVisibility'] is Map?Map<String,dynamic>.from(config['sectionVisibility'] as Map):<String,dynamic>{};
      final start=config['promoStartAt'] is Timestamp?(config['promoStartAt'] as Timestamp).toDate():null;
      final end=config['promoEndAt'] is Timestamp?(config['promoEndAt'] as Timestamp).toDate():null;
      final now=DateTime.now();
      final promoWindow=(start==null||!now.isBefore(start))&&(end==null||!now.isAfter(DateTime(end.year,end.month,end.day,23,59,59)));
      final bannerHeight=((config['bannerHeight'] as num?)?.toDouble()??132).clamp(80.0,220.0);
      final columns=(config['productColumns'] as num?)?.toInt()??2;
      final spacing=(config['productSpacing'] as num?)?.toDouble()??10;
      final sections=<String,Widget>{
        'banner':if(config['showBanner']==true&&visibility['banner']!=false&&promoWindow)
          StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
            stream:FirebaseFirestore.instance.collection('banners').where('active',isEqualTo:true).snapshots(),
            builder:(context,s){
              final docs=s.data?.docs??[];
              if(docs.isEmpty)return Container(width:double.infinity,margin:const EdgeInsets.fromLTRB(14,12,14,4),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((config['bannerTitle']??'').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),Text((config['bannerSubtitle']??'').toString())]));
              return SizedBox(height:bannerHeight,child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),itemCount:docs.length,itemBuilder:(context,i){
                final d=docs[i].data(),image=(d['imageUrl']??'').toString();
                return Container(width:MediaQuery.of(context).size.width*.84,margin:const EdgeInsets.only(right:10),clipBehavior:Clip.antiAlias,decoration:BoxDecoration(borderRadius:BorderRadius.circular(14)),child:Stack(fit:StackFit.expand,children:[
                  if(image.isNotEmpty)Image.network(image,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink()),
                  const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[Color(0x99000000),Colors.transparent]))),
                  Align(alignment:Alignment.bottomLeft,child:Padding(padding:const EdgeInsets.all(12),child:Text((d['title']??'Promo Flowa').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:17)))),
                ]));
              }));
            }),
        'announcement':if(visibility['announcement']!=false)
          StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
            stream:FirebaseFirestore.instance.collection('announcements').where('active',isEqualTo:true).snapshots(),
            builder:(context,s){final docs=s.data?.docs??[];if(docs.isEmpty)return const SizedBox.shrink();final d=docs.first.data();return Container(width:double.infinity,margin:const EdgeInsets.fromLTRB(14,6,14,4),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFFFF4D8),borderRadius:BorderRadius.circular(12)),child:Row(children:[const Icon(Icons.campaign_outlined,color:Color(0xFF9A6500)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((d['title']??'Info Flowa').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),Text((d['body']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis)]))]));}),
        'categories':if(config['showCategories']==true&&visibility['categories']!=false)
          StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
            stream:FirebaseFirestore.instance.collection('categories').where('active',isEqualTo:true).snapshots(),
            builder:(context,s){final docs=s.data?.docs??[];if(docs.isEmpty)return const SizedBox(height:8);return SizedBox(height:54,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),children:[
              ChoiceChip(label:const Text('Semua'),selected:selectedCategory==null,onSelected:(_)=>setState(()=>selectedCategory=null)),
              const SizedBox(width:6),
              ...docs.map((doc){final name=(doc.data()['name']??'').toString();return Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(name),selected:selectedCategory==name,onSelected:(_)=>setState(()=>selectedCategory=name)));}),
            ]));}),
        'products':if(visibility['products']!=false)
          MarketplaceScreen(selectedCategory:selectedCategory,productColumns:columns,productSpacing:spacing,embedded:true),
      };
      final rawOrder=config['sectionOrder'];
      final order=<String>[];
      if(rawOrder is List){for(final v in rawOrder){final key=v.toString();if(sections.containsKey(key)&&!order.contains(key))order.add(key);}}
      for(final key in sections.keys){if(!order.contains(key))order.add(key);}
      final brightness=dark?Brightness.dark:Brightness.light;
      return Theme(
        data:Theme.of(context).copyWith(brightness:brightness,colorScheme:ColorScheme.fromSeed(seedColor:primary,brightness:brightness)),
        child:Scaffold(
          backgroundColor:dark&&background.value==0xFFF7F9FC?const Color(0xFF101827):background,
          body:SafeArea(child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Container(width:double.infinity,padding:const EdgeInsets.fromLTRB(20,18,20,18),decoration:BoxDecoration(gradient:LinearGradient(colors:[primary,accent]),borderRadius:const BorderRadius.vertical(bottom:Radius.circular(24))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text((config['title']??'Flowa').toString(),style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),
              Text((config['subtitle']??'').toString(),style:const TextStyle(color:Colors.white70)),
              const SizedBox(height:14),
              TextField(readOnly:true,decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Cari barang di sekitar Anda...',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none))),
            ])),
            for(final key in order)if(sections[key]!=null)sections[key]!,
          ]))),
          bottomNavigationBar:NavigationBar(onDestinationSelected:(index){
            if(index==1)Navigator.push(context,MaterialPageRoute(builder:(_)=>const ChatInboxScreen()));
            if(index==2)Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProductUploadScreen()));
            if(index==3)Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProfileScreen()));
          },destinations:const[
            NavigationDestination(icon:Icon(Icons.home_outlined),label:'Beranda'),
            NavigationDestination(icon:Icon(Icons.chat_bubble_outline),label:'Chat'),
            NavigationDestination(icon:Icon(Icons.add_circle_outline),label:'Pasang Iklan'),
            NavigationDestination(icon:Icon(Icons.person_outline),label:'Profil'),
          ]),
        ),
      );
    },
  );
}
