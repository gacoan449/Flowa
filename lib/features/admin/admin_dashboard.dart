import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'pages/users_admin_page.dart';
import 'pages/products_admin_page.dart';
import 'pages/banners_admin_page.dart';
import 'pages/chat_admin_page.dart';
import 'pages/home_admin_page.dart';
import 'pages/categories_admin_page.dart';
import 'pages/announcements_admin_page.dart';
import 'pages/statistics_admin_page.dart';
import 'pages/platform_control_admin_page.dart';
import 'pages/app_design_studio_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminModule {
  const _AdminModule(this.title,this.subtitle,this.icon,this.page);
  final String title,subtitle;
  final IconData icon;
  final Widget page;
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _search = TextEditingController();
  @override
  void dispose(){_search.dispose();super.dispose();}

  @override
  Widget build(BuildContext context) {
    final groups = <String,List<_AdminModule>>{
      'Konten & Tampilan':[
        _AdminModule('Visual Home Builder','Atur tema, warna, layout, dan konten Home',Icons.dashboard_customize,const HomeAdminPage()),
        _AdminModule('Banner & Promo','Kelola materi promosi beranda',Icons.campaign,const BannersAdminPage()),
        _AdminModule('Pengumuman','Informasi dan pemberitahuan pengguna',Icons.notifications_active,const AnnouncementsAdminPage()),
        _AdminModule('Kategori','Susun kategori marketplace',Icons.category_outlined,const CategoriesAdminPage()),
      ],
      'Operasional Marketplace':[
        _AdminModule('Iklan & Moderasi','Tinjau produk dan laporan pengguna',Icons.inventory_2,const ProductsAdminPage()),
        _AdminModule('Pengguna','Cari dan kelola status akun',Icons.people_alt_outlined,const UsersAdminPage()),
      ],
      'Platform & Sistem':[
        _AdminModule('Visual Design Studio','Atur warna, tombol, ikon, navigasi, dan background semua halaman',Icons.palette_outlined,const AppDesignStudioPage()),
        _AdminModule('Platform Control Center','Navigasi, marketplace, order policy, keamanan, dan sistem',Icons.tune,const PlatformControlAdminPage()),
      ],
      'Layanan & Analitik':[
        _AdminModule('Customer Service','Pantau dan tangani percakapan bantuan',Icons.support_agent,const ChatAdminPage()),
        _AdminModule('Statistik','Ringkasan data operasional Flowa',Icons.analytics_outlined,const StatisticsAdminPage()),
      ],
    };
    final q=_search.text.trim().toLowerCase();
    return Scaffold(
      appBar:AppBar(
        title:const Text('Flowa Control Center'),
        actions:[IconButton(tooltip:'Keluar',onPressed:()=>AuthService().logout(),icon:const Icon(Icons.logout))],
      ),
      body:ListView(
        padding:const EdgeInsets.fromLTRB(16,12,16,28),
        children:[
          Container(
            padding:const EdgeInsets.all(20),
            decoration:BoxDecoration(
              gradient:const LinearGradient(colors:[Color(0xFF0758D9),Color(0xFF00A8FF)]),
              borderRadius:BorderRadius.circular(22),
            ),
            child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[Icon(Icons.hub_outlined,color:Colors.white,size:25),SizedBox(width:9),Text('FLOWA SUPER ADMIN',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w700,letterSpacing:1.1))]),
              SizedBox(height:12),
              Text('Control Center',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.bold)),
              SizedBox(height:4),
              Text('Pusat kendali konten, marketplace, pengguna, dan layanan.',style:TextStyle(color:Colors.white)),
            ]),
          ),
          const SizedBox(height:16),
          TextField(
            controller:_search,
            onChanged:(_)=>setState((){}),
            decoration:InputDecoration(
              hintText:'Cari menu admin...',
              prefixIcon:const Icon(Icons.search),
              suffixIcon:_search.text.isEmpty?null:IconButton(onPressed:()=>setState(_search.clear),icon:const Icon(Icons.close)),
              border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)),
              filled:true,
            ),
          ),
          const SizedBox(height:12),
          for(final group in groups.entries)
            if(group.value.any((m)=>q.isEmpty||m.title.toLowerCase().contains(q)||m.subtitle.toLowerCase().contains(q)))
              ...[
                Padding(
                  padding:const EdgeInsets.fromLTRB(2,14,2,8),
                  child:Text(group.key,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
                ),
                LayoutBuilder(builder:(context,constraints){
                  final columns=constraints.maxWidth>=760?3:(constraints.maxWidth>=480?2:1);
                  final modules=group.value.where((m)=>q.isEmpty||m.title.toLowerCase().contains(q)||m.subtitle.toLowerCase().contains(q)).toList();
                  return GridView.builder(
                    shrinkWrap:true,
                    physics:const NeverScrollableScrollPhysics(),
                    itemCount:modules.length,
                    gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:columns,
                      mainAxisSpacing:10,
                      crossAxisSpacing:10,
                      mainAxisExtent:104,
                    ),
                    itemBuilder:(context,index){
                      final module=modules[index];
                      return Card(
                        clipBehavior:Clip.antiAlias,
                        child:InkWell(
                          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>module.page)),
                          child:Padding(
                            padding:const EdgeInsets.all(13),
                            child:Row(children:[
                              Container(
                                width:44,height:44,
                                decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(13)),
                                child:Icon(module.icon,color:Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width:11),
                              Expanded(child:Column(
                                mainAxisAlignment:MainAxisAlignment.center,
                                crossAxisAlignment:CrossAxisAlignment.start,
                                children:[
                                  Text(module.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold)),
                                  const SizedBox(height:4),
                                  Text(module.subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall),
                                ],
                              )),
                              const Icon(Icons.chevron_right),
                            ]),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
        ],
      ),
    );
  }
}
