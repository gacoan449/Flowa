import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../home/home_config_service.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});
  @override State<HomeAdminPage> createState() => _HomeAdminPageState();
}
class _HomeAdminPageState extends State<HomeAdminPage> {
  final _service=HomeConfigService();
  final _title=TextEditingController(),_subtitle=TextEditingController(),_bannerTitle=TextEditingController(),_bannerSubtitle=TextEditingController();
  int _primary=0xFF0758D9,_accent=0xFF00A8FF,_background=0xFFF7F9FC,_columns=2;
  double _bannerHeight=132,_spacing=10;
  String _theme='light';
  List<String> _order=['banner','announcement','categories','products'];
  Map<String,bool> _visible={'banner':true,'announcement':true,'categories':true,'products':true};
  DateTime? _start,_end;
  bool _loaded=false,_saving=false;
  static const _palettes=<String,List<int>>{'Biru Flowa':[0xFF0758D9,0xFF00A8FF],'Oranye':[0xFFEA580C,0xFFF59E0B],'Hijau':[0xFF15803D,0xFF4ADE80],'Ungu':[0xFF6D28D9,0xFFA78BFA],'Merah muda':[0xFFBE123C,0xFFFB7185],'Monokrom':[0xFF202124,0xFF6B7280]};
  @override void dispose(){_title.dispose();_subtitle.dispose();_bannerTitle.dispose();_bannerSubtitle.dispose();super.dispose();}
  DateTime? _toDate(dynamic v)=>v is Timestamp?v.toDate():v is DateTime?v:null;
  void _load(Map<String,dynamic> d){
    if(_loaded)return;final m={...HomeConfigService.defaults,...d};
    _title.text=(m['title']??'Flowa').toString();_subtitle.text=(m['subtitle']??'').toString();_bannerTitle.text=(m['bannerTitle']??'').toString();_bannerSubtitle.text=(m['bannerSubtitle']??'').toString();
    _primary=(m['primaryColor'] as num?)?.toInt()??0xFF0758D9;_accent=(m['accentColor'] as num?)?.toInt()??0xFF00A8FF;_background=(m['backgroundColor'] as num?)?.toInt()??0xFFF7F9FC;_theme=(m['themeMode']??'light').toString();
    _bannerHeight=(m['bannerHeight'] as num?)?.toDouble()??132;_spacing=(m['productSpacing'] as num?)?.toDouble()??10;_columns=(m['productColumns'] as num?)?.toInt()??2;
    if(m['sectionOrder'] is List){_order=(m['sectionOrder'] as List).map((e)=>e.toString()).where(HomeConfigService.availableSections.contains).toList();for(final s in HomeConfigService.availableSections){if(!_order.contains(s))_order.add(s);}}
    if(m['sectionVisibility'] is Map){final v=m['sectionVisibility'] as Map;_visible={for(final s in HomeConfigService.availableSections)s:v[s]!=false};}
    _start=_toDate(m['promoStartAt']);_end=_toDate(m['promoEndAt']);_loaded=true;
  }
  Future<void> _pick(bool start) async{final initial=(start?_start:_end)??DateTime.now();final d=await showDatePicker(context:context,initialDate:initial,firstDate:DateTime(2024),lastDate:DateTime(2035));if(d!=null)setState((){if(start){_start=d;}else{_end=d;}});}
  Future<void> _save() async{
    if(_title.text.trim().isEmpty)return;
    if(_start!=null&&_end!=null&&_end!.isBefore(_start!)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tanggal akhir harus setelah tanggal mulai.')));return;}
    setState(()=>_saving=true);
    try{await _service.save({'title':_title.text.trim(),'subtitle':_subtitle.text.trim(),'bannerTitle':_bannerTitle.text.trim(),'bannerSubtitle':_bannerSubtitle.text.trim(),'primaryColor':_primary,'accentColor':_accent,'backgroundColor':_background,'themeMode':_theme,'bannerHeight':_bannerHeight,'productColumns':_columns,'productSpacing':_spacing,'sectionOrder':_order,'sectionVisibility':_visible,'showBanner':_visible['banner'],'showCategories':_visible['categories'],'promoStartAt':_start==null?null:Timestamp.fromDate(_start!),'promoEndAt':_end==null?null:Timestamp.fromDate(_end!),'builderVersion':2});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Desain Home berhasil dipublikasikan!')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan: '+e.toString())));}finally{if(mounted)setState(()=>_saving=false);}
  }
  String _name(String s)=>{'banner':'Banner promosi','announcement':'Pengumuman','categories':'Kategori','products':'Daftar produk'}[s]??s;
  String _dateLabel(DateTime? d)=>d==null?'Belum diatur':d.day.toString()+'/'+d.month.toString()+'/'+d.year.toString();
  Widget _panel(String title,Widget child)=>Card(margin:const EdgeInsets.only(bottom:14),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:12),child])));
  Widget _field(String label,TextEditingController c)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,onChanged:(_)=>setState((){}),decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  Widget _swatches(String label,int current,ValueChanged<int> change,int ix)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label),const SizedBox(height:8),Wrap(spacing:10,children:[for(final p in _palettes.entries)InkWell(onTap:()=>change(p.value[ix]),child:Container(width:34,height:34,decoration:BoxDecoration(color:Color(p.value[ix]),shape:BoxShape.circle,border:Border.all(color:current==p.value[ix]?Colors.black:Colors.white,width:current==p.value[ix]?3:1))))])]);
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Flowa Visual Home Builder'),actions:[IconButton(onPressed:_saving?null:_save,icon:const Icon(Icons.publish))]),body:StreamBuilder(stream:_service.watch(),builder:(context,s){
    if(s.hasError)return Center(child:Text('Gagal memuat: '+s.error.toString()));if(!s.hasData)return const Center(child:CircularProgressIndicator());_load(s.data?.data()??{});
    return ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(_primary),Color(_accent)]),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('PRATINJAU DESAIN HOME',style:TextStyle(color:Colors.white70)),Text(_title.text,style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.bold)),Text(_subtitle.text,style:const TextStyle(color:Colors.white)),const SizedBox(height:12),Container(height:_bannerHeight,width:double.infinity,alignment:Alignment.center,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.2),borderRadius:BorderRadius.circular(12)),child:Text(_bannerTitle.text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))),Text('Grid produk: '+_columns.toString()+' kolom • Jarak: '+_spacing.round().toString()+' px',style:const TextStyle(color:Colors.white70)),
        const SizedBox(height:10),
        Container(width:double.infinity,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Color(_background),borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Urutan Home: '+_order.map(_name).join('  →  '),style:TextStyle(color:_theme=='dark'?Colors.white:Colors.black87,fontSize:11)),
          const SizedBox(height:8),
          Row(children:List.generate(_columns,(i)=>Expanded(child:Container(margin:EdgeInsets.only(right:i==_columns-1?0:_spacing),padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:_theme=='dark'?const Color(0xFF263244):Colors.white,borderRadius:BorderRadius.circular(8)),child:Column(children:[Container(height:34,width:double.infinity,decoration:BoxDecoration(color:Color(_accent).withValues(alpha:.18),borderRadius:BorderRadius.circular(6)),child:Icon(Icons.image_outlined,color:Color(_primary),size:18)),const SizedBox(height:5),Container(height:6,width:double.infinity,color:Color(_primary).withValues(alpha:.2)),const SizedBox(height:4),Container(height:6,width:32,color:Color(_primary).withValues(alpha:.45))]))))),
        ]))])),
      const SizedBox(height:14),
      _panel('1. Identitas Home',Column(children:[_field('Nama Home',_title),_field('Deskripsi',_subtitle),_field('Judul banner',_bannerTitle),_field('Subjudul banner',_bannerSubtitle)])),
      _panel('2. Tema dan warna',Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(spacing:8,children:['light','dark','system'].map((v)=>ChoiceChip(label:Text(v=='light'?'Terang':v=='dark'?'Gelap':'Sistem'),selected:_theme==v,onSelected:(_)=>setState(()=>_theme=v))).toList()),const SizedBox(height:12),_swatches('Warna utama',_primary,(v)=>setState(()=>_primary=v),0),const SizedBox(height:12),_swatches('Warna aksen',_accent,(v)=>setState(()=>_accent=v),1),const SizedBox(height:12),const Text('Latar belakang'),Wrap(spacing:8,children:[0xFFF7F9FC,0xFFFFFFFF,0xFFF1F5F9,0xFF111827].map((v)=>InkWell(onTap:()=>setState(()=>_background=v),child:Container(width:34,height:34,decoration:BoxDecoration(color:Color(v),shape:BoxShape.circle,border:Border.all(color:_background==v?Colors.blue:Colors.grey))))).toList())])),
      _panel('3. Layout dan ukuran',Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Tinggi banner'),Text(_bannerHeight.round().toString()+' px')]),Slider(value:_bannerHeight,min:80,max:220,divisions:14,onChanged:(v)=>setState(()=>_bannerHeight=v)),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Kolom produk'),Text(_columns.toString()+' kolom')]),Slider(value:_columns.toDouble(),min:1,max:3,divisions:2,onChanged:(v)=>setState(()=>_columns=v.round())),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Jarak antarproduk'),Text(_spacing.round().toString()+' px')]),Slider(value:_spacing,min:2,max:24,divisions:11,onChanged:(v)=>setState(()=>_spacing=v))])),
      _panel('4. Susunan bagian Home',const Text('Tahan ikon geser untuk mengubah urutan. Gunakan sakelar untuk menampilkan atau menyembunyikan bagian.')),
      ReorderableListView(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),onReorder:(oldIndex,newIndex)=>setState((){if(newIndex>oldIndex)newIndex--;final item=_order.removeAt(oldIndex);_order.insert(newIndex,item);}),children:[for(final section in _order)Card(key:ValueKey(section),child:SwitchListTile(secondary:const Icon(Icons.drag_handle),title:Text(_name(section)),value:_visible[section]??true,onChanged:(v)=>setState(()=>_visible[section]=v)))]),
      _panel('5. Jadwal promosi',Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Periode ini menjadi jadwal global promo Home. Kosongkan tanggal untuk tanpa batas jadwal.'),OutlinedButton.icon(onPressed:()=>_pick(true),icon:const Icon(Icons.calendar_today),label:Text('Mulai: '+_dateLabel(_start))),OutlinedButton.icon(onPressed:()=>_pick(false),icon:const Icon(Icons.event),label:Text('Akhir: '+_dateLabel(_end))),TextButton(onPressed:()=>setState((){_start=null;_end=null;}),child:const Text('Hapus jadwal'))])),
      FilledButton.icon(onPressed:_saving?null:_save,icon:_saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.publish),label:Text(_saving?'Menerbitkan...':'Publikasikan perubahan Home')),const SizedBox(height:30)
    ]);
  }));
}