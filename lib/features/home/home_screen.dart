import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../wallet/topup_screen.dart';
import '../products/product_upload_screen.dart';
import '../admin/admin_guard.dart';
class HomeScreen extends StatelessWidget { const HomeScreen({super.key});
 @override Widget build(BuildContext c)=>DefaultTabController(length:2,child:Scaffold(appBar:AppBar(title:const Text('PasarKomunitas'),actions:[
 IconButton(tooltip:'Tambah Produk',icon:const Icon(Icons.add_business),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ProductUploadScreen()))),
 IconButton(tooltip:'Top up Koin',icon:const Icon(Icons.account_balance_wallet_outlined),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const TopUpScreen()))),
 PopupMenuButton<String>(onSelected:(v){if(v=='admin')Navigator.push(c,MaterialPageRoute(builder:(_)=>const AdminGuard()));if(v=='logout')AuthService().logout();},itemBuilder:(_)=>const [PopupMenuItem(value:'admin',child:Text('Admin Dashboard')),PopupMenuItem(value:'logout',child:Text('Keluar'))])],bottom:const TabBar(tabs:[Tab(icon:Icon(Icons.chat_bubble_outline),text:'Chat'),Tab(icon:Icon(Icons.storefront_outlined),text:'Pasar')])),body:const TabBarView(children:[Center(child:Text('Inbox percakapan akan tampil di sini')),Center(child:Text('Produk lokal berdasarkan radius akan tampil di sini'))])));}