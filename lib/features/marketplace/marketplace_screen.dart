import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';
import '../products/product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({
    super.key,
    this.selectedCategory,
    this.productColumns=2,
    this.productSpacing=10,
    this.embedded=false,
  });
  final String? selectedCategory;
  final int productColumns;
  final double productSpacing;
  final bool embedded;
  @override State<MarketplaceScreen> createState()=>_MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  Position? _buyerPosition;
  bool _locationLoading=true;
  String? _locationError;
  @override void initState(){super.initState();_refreshBuyerLocation();}
  Future<void> _refreshBuyerLocation() async {
    if(mounted)setState((){_locationLoading=true;_locationError=null;});
    try{
      final p=await LocationService().current();
      if(!mounted)return;
      setState((){_buyerPosition=p;_locationLoading=false;});
    }catch(e){
      if(!mounted)return;
      setState((){_buyerPosition=null;_locationLoading=false;_locationError='Lokasi tidak tersedia';});
    }
  }
  bool _validCoordinates(dynamic lat,dynamic lng)=>lat is num&&lng is num&&lat>=-90&&lat<=90&&lng>=-180&&lng<=180&&!(lat==0&&lng==0);
  String _distanceLabel(Map<String,dynamic> p,String? buyerId){
    if(p['sellerId']==buyerId)return 'Produk kamu';
    if(_buyerPosition==null)return 'Aktifkan GPS untuk melihat jarak';
    final lat=p['latitude'],lng=p['longitude'];
    if(!_validCoordinates(lat,lng))return 'Lokasi penjual belum tersedia';
    final meters=Geolocator.distanceBetween(_buyerPosition!.latitude,_buyerPosition!.longitude,(lat as num).toDouble(),(lng as num).toDouble());
    if(meters<1000)return '${meters.round()} m dari kamu';
    final km=meters/1000;return '${km.toStringAsFixed(km<10?1:0)} km dari kamu';
  }
  Widget _locationBar()=>Material(
    color:Theme.of(context).colorScheme.surfaceContainerHighest,
    child:Padding(
      padding:const EdgeInsets.symmetric(horizontal:14,vertical:5),
      child:Row(children:[
        Icon(_locationLoading?Icons.gps_not_fixed:(_locationError==null?Icons.my_location:Icons.location_off),size:19),
        const SizedBox(width:8),
        Expanded(child:Text(_locationLoading?'Mencari lokasi GPS kamu...':(_locationError==null?'Jarak dihitung dari lokasi GPS kamu.':'Jarak belum tersedia. Aktifkan GPS atau periksa izin lokasi.'),style:const TextStyle(fontSize:12))),
        IconButton(tooltip:'Perbarui GPS',onPressed:_locationLoading?null:_refreshBuyerLocation,icon:const Icon(Icons.refresh,size:20)),
      ]),
    ),
  );
  Widget _productGrid()=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream:FirebaseFirestore.instance.collection('products').where('status',isEqualTo:'active').snapshots(),
    builder:(context,snapshot){
      if(snapshot.hasError)return const Center(child:Padding(padding:EdgeInsets.all(20),child:Text('Produk belum bisa dimuat. Periksa koneksi lalu coba lagi.')));
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final docs=snapshot.data!.docs.where((doc){
        final selected=widget.selectedCategory;
        return selected==null||(doc.data()['category']??'Lainnya').toString()==selected;
      }).toList();
      if(docs.isEmpty)return const Padding(padding:EdgeInsets.all(28),child:Center(child:Text('Belum ada produk aktif. Jadilah yang pertama memasang iklan!')));
      final buyerId=FirebaseAuth.instance.currentUser?.uid;
      return GridView.builder(
        shrinkWrap:widget.embedded,
        physics:widget.embedded?const NeverScrollableScrollPhysics():const AlwaysScrollableScrollPhysics(),
        padding:EdgeInsets.all(widget.productSpacing),
        gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:widget.productColumns.clamp(1,3),
          crossAxisSpacing:widget.productSpacing,
          mainAxisSpacing:widget.productSpacing,
          childAspectRatio:widget.productColumns<=1?3.2:(widget.productColumns==2?1.05:0.78),
        ),
        itemCount:docs.length,
        itemBuilder:(context,index){
          final doc=docs[index],data=doc.data();
          final distance=_distanceLabel(data,buyerId);
          return Card(
            clipBehavior:Clip.antiAlias,
            child:InkWell(
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductDetailScreen(productId:doc.id))),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(child:data['imageUrl']==null||data['imageUrl']==''?Container(width:double.infinity,color:Theme.of(context).colorScheme.surfaceContainerHighest,child:const Icon(Icons.shopping_bag_outlined,size:34)):Image.network(data['imageUrl'].toString(),width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined)))),
                Padding(padding:const EdgeInsets.all(9),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text((data['title']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w600)),
                  const SizedBox(height:3),
                  Text('Rp ${data['price']??0}',maxLines:1,style:TextStyle(fontWeight:FontWeight.bold,color:Theme.of(context).colorScheme.primary)),
                  const SizedBox(height:3),
                  Row(children:[const Icon(Icons.near_me_outlined,size:12),const SizedBox(width:3),Expanded(child:Text(distance,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10)))]),
                ])),
              ]),
            ),
          );
        },
      );
    },
  );
  @override Widget build(BuildContext context){
    final grid=_productGrid();
    return Column(
      mainAxisSize:widget.embedded?MainAxisSize.min:MainAxisSize.max,
      children:[
        _locationBar(),
        if(widget.embedded)grid else Expanded(child:grid),
      ],
    );
  }
}
