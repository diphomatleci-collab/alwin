import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DB.instance.database;
  runApp(const SmartSchoolApp());
}

class SmartSchoolApp extends StatelessWidget {
  const SmartSchoolApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart School',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457C5)),
      scaffoldBackgroundColor: const Color(0xFFF4F7FC)),
    home: const HomePage(),
  );
}

class DB {
  DB._();
  static final DB instance = DB._();
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = await getDatabasesPath();
    _db = await openDatabase(p.join(path, 'smart_school.db'), version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT UNIQUE, password TEXT)');
        await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT)');
        await db.execute('CREATE TABLE articles(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, category TEXT, content TEXT, created_at TEXT)');
        await db.insert('users', {'username':'admin', 'password':'admin123'});
        const subjects = [
          'Pendidikan Agama dan Budi Pekerti','Pendidikan Pancasila','Bahasa Indonesia',
          'PJOK','Sejarah','Seni Budaya','Matematika','Bahasa Inggris','Informatika',
          'IPAS','PPLG / Pemrograman Web','Koding dan Kecerdasan Artifisial','Bahasa Daerah'
        ];
        for (final subject in subjects) {
          await db.insert('categories', {'name': subject});
        }
        await db.insert('articles', {
          'title':'Selamat Datang di Smart School',
          'category':'Informatika',
          'content':'Smart School adalah portal edukasi sekolah. Admin dapat menambah, mengedit, dan menghapus materi pembelajaran.',
          'created_at':DateTime.now().toIso8601String()
        });
      });
    return _db!;
  }
  Future<bool> login(String user, String pass) async {
    final rows = await (await database).query('users',
      where:'username = ? AND password = ?', whereArgs:[user, pass]);
    return rows.isNotEmpty;
  }
  Future<List<String>> categories() async {
    final rows = await (await database).query('categories', orderBy:'name');
    return rows.map((e) => e['name'] as String).toList();
  }
  Future<List<Map<String,Object?>>> articles({String? category, String search = ''}) async {
    final db = await database;
    if (category != null) {
      return db.query('articles', where:'category = ? AND title LIKE ?',
        whereArgs:[category, '%$search%'], orderBy:'id DESC');
    }
    return db.query('articles', where:'title LIKE ? OR content LIKE ?',
      whereArgs:['%$search%', '%$search%'], orderBy:'id DESC');
  }
  Future<void> save({int? id, required String title, required String category, required String content}) async {
    final db = await database;
    final data = {'title':title.trim(),'category':category,'content':content.trim(),
      'created_at':DateTime.now().toIso8601String()};
    if (id == null) { await db.insert('articles', data); }
    else { await db.update('articles', data, where:'id = ?', whereArgs:[id]); }
  }
  Future<void> delete(int id) async =>
    (await database).delete('articles', where:'id = ?', whereArgs:[id]);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  bool admin = false;
  int tab = 0;
  @override void initState() {
    super.initState();
    SharedPreferences.getInstance().then((v) {
      if (mounted) setState(() => admin = v.getBool('admin') ?? false);
    });
  }
  Future<void> openLogin() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    if (result == true) setState(() => admin = true);
  }
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin', false);
    setState(() => admin = false);
  }
  @override Widget build(BuildContext context) {
    final pages = [
      DashboardPage(admin:admin, onLogin:openLogin),
      const ArticlePage(),
      CategoryPage(onSelect:(c) => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticlePage(category:c))))
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Smart School', style:TextStyle(fontWeight:FontWeight.bold)),
        backgroundColor:const Color(0xFF2457C5), foregroundColor:Colors.white,
        actions:[admin
          ? TextButton.icon(onPressed:logout, icon:const Icon(Icons.logout,color:Colors.white), label:const Text('Keluar',style:TextStyle(color:Colors.white)))
          : TextButton.icon(onPressed:openLogin, icon:const Icon(Icons.login,color:Colors.white), label:const Text('Login Admin',style:TextStyle(color:Colors.white)))]),
      body:pages[tab],
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),
          NavigationDestination(icon:Icon(Icons.article_outlined),label:'Artikel'),
          NavigationDestination(icon:Icon(Icons.category_outlined),label:'Kategori')
        ]),
    );
  }
}

class CategoryPage extends StatelessWidget {
  final void Function(String) onSelect;

  const CategoryPage({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: DB.instance.categories(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: items.map((category) {
            return ListTile(
              leading: const Icon(Icons.category),
              title: Text(category),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelect(category),
            );
          }).toList(),
        );
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  final bool admin;
  final VoidCallback onLogin;
  const DashboardPage({super.key,required this.admin,required this.onLogin});
  @override Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future:DB.instance.categories(),
    builder:(context,snapshot) {
      final list=snapshot.data ?? [];
      return LayoutBuilder(builder:(context,size) {
        final columns=size.maxWidth>700?4:2;
        return ListView(padding:const EdgeInsets.all(18),children:[
          Container(padding:const EdgeInsets.all(22),
            decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),
              gradient:const LinearGradient(colors:[Color(0xFF2457C5),Color(0xFF5487E8)])),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Belajar Lebih Mudah!',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),
              const SizedBox(height:8),
              const Text('Portal informasi dan materi pembelajaran sekolah.',style:TextStyle(color:Colors.white)),
              const SizedBox(height:14),
              if(!admin) FilledButton.tonalIcon(onPressed:onLogin,icon:const Icon(Icons.admin_panel_settings),label:const Text('Login Admin')),
              if(admin) const Chip(label:Text('Mode Admin Aktif'))
            ])),
          const SizedBox(height:22),
          const Text('Mata Pelajaran',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          if(snapshot.connectionState==ConnectionState.waiting) const Center(child:CircularProgressIndicator())
          else GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
            itemCount:list.length,
            gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.4),
            itemBuilder:(context,i)=>InkWell(borderRadius:BorderRadius.circular(16),
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ArticlePage(category:list[i]))),
              child:Container(padding:const EdgeInsets.all(14),
                decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),
                child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
                  const Icon(Icons.menu_book,color:Color(0xFF2457C5),size:27),const SizedBox(height:8),
                  Text(list[i],maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w600))
                ]))))
        ]);
      });
    });
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user=TextEditingController(), pass=TextEditingController();
  String? error;
  bool loading=false;
  Future<void> submit() async {
    if(user.text.trim().isEmpty || pass.text.isEmpty) {
      setState(()=>error='Username dan password wajib diisi.'); return;
    }
    setState(()=>loading=true);
    final ok=await DB.instance.login(user.text.trim(),pass.text);
    if(!mounted)return;
    setState(()=>loading=false);
    if(ok) {
      final prefs=await SharedPreferences.getInstance();
      await prefs.setBool('admin',true);
      if(mounted)Navigator.pop(context,true);
    } else { setState(()=>error='Username atau password salah.'); }
  }
  @override void dispose(){user.dispose();pass.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Login Admin')),
    body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),
      child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),
        child:Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Icon(Icons.school,size:58,color:Color(0xFF2457C5)),
          const SizedBox(height:12),
          const Text('Masuk ke Smart School',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
          const SizedBox(height:22),
          TextField(controller:user,decoration:const InputDecoration(labelText:'Username',prefixIcon:Icon(Icons.person))),
          const SizedBox(height:14),
          TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'Password',prefixIcon:Icon(Icons.lock))),
          if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.red))),
          const SizedBox(height:18),
          SizedBox(width:double.infinity,child:FilledButton(onPressed:loading?null:submit,
            child:loading?const CircularProgressIndicator():const Text('Login'))),
          const SizedBox(height:12),
          const Text('Akun demo: admin / admin123',style:TextStyle(color:Colors.grey))
        ])))))));
}

class ArticlePage extends StatefulWidget {
  final String? category;
  const ArticlePage({super.key,this.category});
  @override State<ArticlePage> createState()=>_ArticlePageState();
}
class _ArticlePageState extends State<ArticlePage> {
  final search=TextEditingController();
  bool admin=false;
  @override void initState(){
    super.initState();
    SharedPreferences.getInstance().then((v){if(mounted)setState(()=>admin=v.getBool('admin')??false);});
  }
  @override void dispose(){search.dispose();super.dispose();}
  Future<void> refresh() async {if(mounted)setState((){});}
  Future<void> add() async {
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>ArticleFormPage(initialCategory:widget.category)));
    refresh();
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.category??'Daftar Artikel')),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(16),child:TextField(controller:search,onChanged:(_)=>setState((){}),
        decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari artikel atau materi...'))),
      Expanded(child:FutureBuilder<List<Map<String,Object?>>>(
        future:DB.instance.articles(category:widget.category,search:search.text),
        builder:(context,snapshot){
          final rows=snapshot.data??[];
          if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
          if(rows.isEmpty)return const Center(child:Text('Belum ada artikel pada kategori ini.'));
          return ListView.builder(padding:const EdgeInsets.all(14),itemCount:rows.length,
            itemBuilder:(context,i){
              final item=rows[i]; final id=item['id'] as int;
              return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.article)),
                title:Text(item['title'] as String,style:const TextStyle(fontWeight:FontWeight.bold)),
                subtitle:Text(item['category'] as String),
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ArticleDetailPage(article:item))),
                trailing:admin?PopupMenuButton<String>(
                  onSelected:(v)async{
                    if(v=='edit')await Navigator.push(context,MaterialPageRoute(builder:(_)=>ArticleFormPage(article:item)));
                    if(v=='delete'){
                      final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
                        title:const Text('Hapus artikel?'),content:const Text('Data yang dihapus tidak dapat dikembalikan.'),
                        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
                          FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Hapus'))]));
                      if(yes==true)await DB.instance.delete(id);
                    }
                    refresh();
                  },
                  itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Hapus'))])
                  :const Icon(Icons.chevron_right)));
            });
        }))
    ]),
    floatingActionButton:admin?FloatingActionButton(onPressed:add,child:const Icon(Icons.add)):null
  );
}

class ArticleDetailPage extends StatelessWidget {
  final Map<String,Object?> article;
  const ArticleDetailPage({super.key,required this.article});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Detail Materi')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      Text(article['category'] as String,style:const TextStyle(color:Color(0xFF2457C5),fontWeight:FontWeight.bold)),
      const SizedBox(height:10),
      Text(article['title'] as String,style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),
      const Divider(height:30),
      Text(article['content'] as String,style:const TextStyle(fontSize:16,height:1.6))
    ]));
}

class ArticleFormPage extends StatefulWidget {
  final Map<String,Object?>? article;
  final String? initialCategory;
  const ArticleFormPage({super.key,this.article,this.initialCategory});
  @override State<ArticleFormPage> createState()=>_ArticleFormPageState();
}
class _ArticleFormPageState extends State<ArticleFormPage>{
  final keyForm=GlobalKey<FormState>();
  final title=TextEditingController(), content=TextEditingController();
  List<String> categories=[];
  String? category;
  @override void initState(){
    super.initState();
    title.text=widget.article?['title'] as String? ?? '';
    content.text=widget.article?['content'] as String? ?? '';
    category=widget.article?['category'] as String? ?? widget.initialCategory;
    DB.instance.categories().then((v){if(mounted)setState(()=>{categories=v,category??=v.isNotEmpty?v.first:null});});
  }
  @override void dispose(){title.dispose();content.dispose();super.dispose();}
  Future<void> save()async{
    if(!keyForm.currentState!.validate()||category==null)return;
    await DB.instance.save(id:widget.article?['id'] as int?,title:title.text,category:category!,content:content.text);
    if(mounted)Navigator.pop(context);
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article == null ? 'Tambah Artikel' : 'Edit Artikel'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: keyForm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: title,
                        maxLength: 80,
                        decoration: const InputDecoration(labelText: 'Judul artikel'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Judul wajib diisi.';
                          if (v.trim().length < 3) return 'Judul minimal 3 karakter.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: 'Kategori mata pelajaran'),
                        items: categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => category = v),
                        validator: (v) => v == null ? 'Pilih kategori.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: content,
                        minLines: 5,
                        maxLines: 9,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Isi materi / artikel',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Isi artikel wajib diisi.';
                          if (v.trim().length < 10) return 'Isi minimal 10 karakter.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: save,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Data'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
