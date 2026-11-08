import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ProductService {
 final _db=FirebaseFirestore.instance; final _auth=FirebaseAuth.instance;
 Future<void> createProduct({required String title,required String description,required int price,required String imageUrl,required double latitude,required double longitude}) async {
  final uid=_auth.currentUser!.uid, wallet=_db.collection('wallets').doc(uid), product=_db.collection('products').doc(), log=_db.collection('coin_transactions').doc();
  await _db.runTransaction((tx) async { final snap=await tx.get(wallet); final balance=(snap.data()?['balance']??0) as int;
   if(balance<1) throw StateError('Koin habis. Silakan top up sebelum mengunggah produk.');
   tx.set(product,{'sellerId':uid,'title':title.trim(),'description':description.trim(),'price':price,'imageUrl':imageUrl,'latitude':latitude,'longitude':longitude,'status':'active','createdAt':FieldValue.serverTimestamp()});
   tx.set(wallet,{'balance':balance-1,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
   tx.set(log,{'userId':uid,'type':'PRODUCT_UPLOAD','amount':-1,'productId':product.id,'createdAt':FieldValue.serverTimestamp()});
  });
 }
}