import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../chat/chat_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState()=>_SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen>{
  final _name=TextEditingController();
  bool _saving=false;
  bool _notifications=true, _showOnline=true, _showActivity=true;
  @override void initState(){super.initState();final u=FirebaseAuth.instance.currentUser;_name.text=u?.displayName??'';_loadPreferences();}
  @override void dispose(){_name.dispose();super.dispose();}
  Future<void> _loadPreferences()async{
    final u=FirebaseAuth.instance.currentUser;if(u==null)return;
    try{final d=await FirebaseFirestore.instance.collection('users').doc(u.uid).get();final x=d.data()??{};
      if(!mounted)return;setState((){_notifications=x['prefNotifications']!=false;_showOnline=x['prefShowOnline']!=false;_showActivity=x['prefShowActivity']!=false;});
    }catch(_){}
  }
  Future<void> _pref(String key,bool value)async{
    final u=FirebaseAuth.instance.currentUser;if(u==null)return;
    setState(()=>{if(key=='prefNotifications')_notifications=value else if(key=='prefShowOnline')_showOnline=value else _showActivity=value});
    try{await FirebaseFirestore.instance.collection('users').doc(u.uid).set({key:value,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));}
    catch(_){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pengaturan gagal disimpan. Coba lagi.')));_loadPreferences();}
  }
  Future<void> _saveName()async{
    final u=FirebaseAuth.instance.currentUser;if(u==null)return;final n=_name.text.trim();
    if(n.isEmpty){_msg('Nama tidak boleh kosong.');return;}
    setState(()=>_saving=true);
    try{await u.updateDisplayName(n);await FirebaseFirestore.instance.collection('users').doc(u.uid).set({'name':n,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));await ChatProfileService.syncCurrentUser(displayName:n);_msg('Nama berhasil diperbarui.');}
    catch(_){_msg('Nama gagal disimpan. Periksa koneksi lalu coba lagi.');}
    finally{if(mounted)setState(()=>_saving=false);}
  }
  void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  Future<void> _changePassword()async{
    final u=FirebaseAuth.instance.currentUser;if(u==null||u.email==null){_msg('Fitur ubah kata sandi tidak tersedia untuk metode masuk ini.');return;}
    final current=TextEditingController(),next=TextEditingController(),confirm=TextEditingController();
    final values=await showDialog<List<String>>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Ubah kata sandi'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:current,obscureText:true,decoration:const InputDecoration(labelText:'Kata sandi saat ini')),
        TextField(controller:next,obscureText:true,decoration:const InputDecoration(labelText:'Kata sandi baru (min. 6 karakter)')),
        TextField(controller:confirm,obscureText:true,decoration:const InputDecoration(labelText:'Ulangi kata sandi baru')),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,[current.text,next.text,confirm.text]),child:const Text('Perbarui'))]));
    if(values==null)return;
    if(values[1].length<6||values[1]!=values[2]){_msg('Kata sandi baru minimal 6 karakter dan harus sama.');return;}
    try{
      final credential=EmailAuthProvider.credential(email:u.email!,password:values[0]);
      await u.reauthenticateWithCredential(credential);
      await u.updatePassword(values[1]);_msg('Kata sandi berhasil diperbarui.');
    }on FirebaseAuthException catch(e){_msg(e.code=='wrong-password'||e.code=='invalid-credential'?'Kata sandi saat ini tidak sesuai.':e.code=='requires-recent-login'?'Silakan masuk ulang sebelum mengubah kata sandi.':'Kata sandi gagal diperbarui. Coba lagi.');}
    catch(_){_msg('Kata sandi gagal diperbarui. Coba lagi.');}
  }
  Future<void> _resetPassword()async{
    final email=FirebaseAuth.instance.currentUser?.email;if(email==null){_msg('Email akun tidak tersedia.');return;}
    try{await FirebaseAuth.instance.sendPasswordResetEmail(email:email);_msg('Tautan reset kata sandi dikirim ke email akun.');}
    catch(_){_msg('Email reset belum bisa dikirim. Coba lagi nanti.');}
  }
  Widget _section(String title,List<Widget> children)=>Padding(padding:const EdgeInsets.only(bottom:18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Padding(padding:const EdgeInsets.only(left:4,bottom:8),child:Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16))),
    Card(child:Column(children:children)),
  ]));
  @override Widget build(BuildContext context){
    final u=FirebaseAuth.instance.currentUser;
    return Scaffold(appBar:AppBar(title:const Text('Pengaturan Akun')),body:ListView(padding:const EdgeInsets.all(16),children:[
      _section('INFORMASI AKUN',[
        Padding(padding:const EdgeInsets.fromLTRB(16,14,16,4),child:TextField(controller:_name,textCapitalization:TextCapitalization.words,decoration:const InputDecoration(labelText:'Nama tampilan',prefixIcon:Icon(Icons.person_outline)))),
        ListTile(leading:const Icon(Icons.email_outlined),title:const Text('Email'),subtitle:Text(u?.email??'Email tidak tersedia')),
        Padding(padding:const EdgeInsets.fromLTRB(16,0,16,14),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:_saving?null:_saveName,child:Text(_saving?'Menyimpan...':'Simpan perubahan')))),
      ]),
      _section('KEAMANAN',[
        ListTile(leading:const Icon(Icons.lock_outline),title:const Text('Ubah kata sandi'),subtitle:const Text('Perbarui kata sandi akun'),trailing:const Icon(Icons.chevron_right),onTap:_changePassword),
        const Divider(height:1),
        ListTile(leading:const Icon(Icons.mark_email_read_outlined),title:const Text('Lupa kata sandi?'),subtitle:const Text('Kirim tautan pemulihan ke email'),trailing:const Icon(Icons.chevron_right),onTap:_resetPassword),
      ]),
      _section('NOTIFIKASI',[
        SwitchListTile(value:_notifications,onChanged:(v)=>_pref('prefNotifications',v),secondary:const Icon(Icons.notifications_outlined),title:const Text('Notifikasi aplikasi'),subtitle:const Text('Info pesanan, pesan, dan aktivitas')),
      ]),
      _section('PRIVASI',[
        SwitchListTile(value:_showOnline,onChanged:(v)=>_pref('prefShowOnline',v),secondary:const Icon(Icons.circle_outlined),title:const Text('Tampilkan status online'),subtitle:const Text('Izinkan pengguna melihat saat kamu aktif')),
        const Divider(height:1),
        SwitchListTile(value:_showActivity,onChanged:(v)=>_pref('prefShowActivity',v),secondary:const Icon(Icons.visibility_outlined),title:const Text('Tampilkan aktivitas profil'),subtitle:const Text('Buat aktivitas profil terlihat oleh pengguna lain')),
      ]),
      _section('TENTANG FLOWA',[
        const ListTile(leading:Icon(Icons.info_outline),title:Text('Tentang Flowa'),subtitle:Text('Marketplace lokal untuk terhubung dan bertumbuh')),
        const ListTile(leading:Icon(Icons.privacy_tip_outlined),title:Text('Privasi & keamanan'),subtitle:Text('Jaga informasi akun dan kata sandi kamu')),
      ]),
    ]));
  }
}
