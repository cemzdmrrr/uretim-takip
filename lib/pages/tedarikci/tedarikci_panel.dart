import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/app_routes.dart';

part 'tedarikci_panel_aksiyonlar.dart';


class TedarikciPanel extends StatefulWidget {
  const TedarikciPanel({Key? key}) : super(key: key);

  @override
  State<TedarikciPanel> createState() => _TedarikciPanelState();
}

class _TedarikciPanelState extends State<TedarikciPanel> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> bekleyenAtamalar = [];
  List<Map<String, dynamic>> aktifAtamalar = [];
  List<Map<String, dynamic>> tamamlananAtamalar = [];
  Map<String, dynamic>? tedarikciInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTedarikciData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTedarikciData() async {
    try {
      setState(() => _isLoading = true);
      
      // Önce mevcut kullanıcının tedarikci bilgilerini al
      final currentUser = supabase.auth.currentUser;
      if (currentUser?.email == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      // Tedarikciler tablosundan kullanıcı bilgisini bul
      final tedarikciResponse = await supabase
          .from(DbTables.tedarikciler)
          .select('*')
          .eq('email', currentUser!.email!)
          .single();
      
      setState(() {
        tedarikciInfo = tedarikciResponse;
      });

      // Bu tedarikci için tüm atamaları al
      debugPrint('🔍 ${tedarikciInfo!['sirket']} tedarikci ID: ${tedarikciInfo!['id']} için atamalar aranıyor...');
      await _loadAtamalar();
      
    } catch (e) {
      debugPrint('❌ Tedarikci veri yükleme hatası: $e');
      if (!mounted) return;
      context.showErrorSnackBar('Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAtamalar() async {
    if (tedarikciInfo == null) return;

    try {
      final tedarikciId = tedarikciInfo!['id'];
      
      // Tüm atama tablolarından bu tedarikci için atamaları al
      final List<String> atamaTablolari = [
        DbTables.dokumaAtamalari,
        DbTables.konfeksiyonAtamalari, 
        DbTables.nakisAtamalari,
        DbTables.yikamaAtamalari,
        DbTables.ilikDugmeAtamalari,
        DbTables.utuAtamalari
      ];

      final List<Map<String, dynamic>> tumAtamalar = [];

      for (String tabloAdi in atamaTablolari) {
        try {
          debugPrint('🔍 $tabloAdi tablosunda tedarikci_id=$tedarikciId arıyor...');
          final response = await supabase
              .from(tabloAdi)
              .select('''
                id, model_id, adet, talep_edilen_adet, tamamlanan_adet, 
                durum, created_at, atama_tarihi, tamamlama_tarihi, kabul_edilen_adet, tedarikci_id,
                triko_takip!inner(marka, item_no, renk, adet)
              ''')
              .eq('tedarikci_id', tedarikciId);

          debugPrint('📊 $tabloAdi tablosunda ${response.length} atama bulundu');
          for (var atama in response) {
            debugPrint('   - Model: ${atama[DbTables.trikoTakip]['marka']} - ${atama[DbTables.trikoTakip]['item_no']}, Adet: ${atama['adet']}, Durum: ${atama['durum']}');
            atama['atama_tipi'] = _getAtamaTipiFromTable(tabloAdi);
            tumAtamalar.add(atama);
          }
        } catch (e) {
          debugPrint('⚠️ $tabloAdi tablosu sorgulanamadı: $e');
          // Bu tablo yoksa devam et
        }
      }

      // Atamaları durumlarına göre ayır
      setState(() {
        bekleyenAtamalar = tumAtamalar.where((a) => 
          a['durum'] == 'atandi' || a['durum'] == 'beklemede').toList();
        aktifAtamalar = tumAtamalar.where((a) => 
          a['durum'] == 'onaylandi' || a['durum'] == 'uretimde' || a['durum'] == 'baslatildi').toList();
        tamamlananAtamalar = tumAtamalar.where((a) => 
          a['durum'] == 'tamamlandi' || a['durum'] == 'kismi_tamamlandi').toList();
      });

      debugPrint('✅ Atamalar yüklendi: ${bekleyenAtamalar.length} bekleyen, ${aktifAtamalar.length} aktif, ${tamamlananAtamalar.length} tamamlanan');
      
      // Test için atamaların durumlarını detaylı logla
      for (var atama in tumAtamalar) {
        debugPrint('   📝 Atama ID: ${atama['id']}, Durum: ${atama['durum']}, Model: ${atama[DbTables.trikoTakip]['marka']}-${atama[DbTables.trikoTakip]['item_no']}');
      }

    } catch (e) {
      debugPrint('❌ Atamalar yükleme hatası: $e');
    }
  }

  String _getAtamaTipiFromTable(String tabloAdi) {
    switch (tabloAdi) {
      case DbTables.dokumaAtamalari: return 'Dokuma';
      case DbTables.konfeksiyonAtamalari: return 'Konfeksiyon';
      case DbTables.nakisAtamalari: return 'Nakış';
      case DbTables.yikamaAtamalari: return 'Yıkama';
      case DbTables.ilikDugmeAtamalari: return 'İlik Düğme';
      case DbTables.utuAtamalari: return 'Ütü';
      default: return tabloAdi;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tedarikci Paneli'),
          backgroundColor: Colors.indigo,
        ),
        body: const LoadingWidget(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tedarikciInfo?['sirket'] ?? 'Tedarikci Paneli'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTedarikciData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!context.mounted) return;
              if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Bekleyen',
              icon: Badge(
                label: Text('${bekleyenAtamalar.length}'),
                child: const Icon(Icons.pending_actions),
              ),
            ),
            Tab(
              text: 'Aktif',
              icon: Badge(
                label: Text('${aktifAtamalar.length}'),
                child: const Icon(Icons.work),
              ),
            ),
            Tab(
              text: 'Tamamlanan',
              icon: Badge(
                label: Text('${tamamlananAtamalar.length}'),
                child: const Icon(Icons.done_all),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tedarikci bilgi kartı
          if (tedarikciInfo != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.business, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tedarikciInfo!['sirket'] ?? 'Şirket Adı',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${tedarikciInfo!['ad']} ${tedarikciInfo!['soyad']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'Faaliyet: ${tedarikciInfo!['faaliyet']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Toplam: ${bekleyenAtamalar.length + aktifAtamalar.length + tamamlananAtamalar.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('atama', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAtamaListesi(bekleyenAtamalar, 'bekleyen'),
                _buildAtamaListesi(aktifAtamalar, 'aktif'),
                _buildAtamaListesi(tamamlananAtamalar, 'tamamlanan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtamaListesi(List<Map<String, dynamic>> atamalar, String tip) {
    if (atamalar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tip == 'bekleyen' ? Icons.pending_actions :
              tip == 'aktif' ? Icons.work : Icons.done_all,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              tip == 'bekleyen' ? 'Bekleyen atama yok' :
              tip == 'aktif' ? 'Aktif atama yok' : 'Tamamlanan atama yok',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: atamalar.length,
      itemBuilder: (context, index) {
        final atama = atamalar[index];
        final modelData = atama[DbTables.trikoTakip];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAtamaColor(atama['atama_tipi']),
              child: Text(
                atama['atama_tipi'][0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${modelData['marka']} - ${modelData['item_no']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${atama['atama_tipi']} • ${atama['durum']}'),
                if (tip == 'bekleyen') 
                  Text('Talep: ${atama['talep_edilen_adet'] ?? atama['adet'] ?? 0} adet')
                else if (tip == 'aktif') ...[
                  Text('Kabul Edilen: ${atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0} adet'),
                  if (atama['tamamlanan_adet'] != null && atama['tamamlanan_adet'] > 0) ...[
                    Text('Tamamlanan: ${atama['tamamlanan_adet']} adet', 
                         style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _buildProgressBar(atama),
                  ],
                ] else if (tip == 'tamamlanan') ...[
                  Text('Kabul Edilen: ${atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0} adet'),
                  Text('✅ Tamamlanan: ${atama['tamamlanan_adet'] ?? 0} adet',
                       style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  if (atama['tamamlama_tarihi'] != null)
                    Text('📅 Tamamlama: ${_formatDate(atama['tamamlama_tarihi'])}',
                         style: const TextStyle(color: Colors.blue, fontSize: 12)),
                  // Progress bar göster
                  const SizedBox(height: 4),
                  _buildProgressBar(atama),
                ],
              ],
            ),
            trailing: tip == 'bekleyen' ? 
              PopupMenuButton<String>(
                onSelected: (value) => _handleAtamaAction(value, atama),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'kabul',
                    child: ListTile(
                      leading: Icon(Icons.check, color: Colors.green),
                      title: Text('Kabul Et'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reddet',
                    child: ListTile(
                      leading: Icon(Icons.close, color: Colors.red),
                      title: Text('Reddet'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ) : tip == 'aktif' ?
              ElevatedButton.icon(
                onPressed: () => _showTamamlamaDialog(atama),
                icon: const Icon(Icons.done),
                label: const Text('Tamamla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ) : 
              PopupMenuButton<String>(
                onSelected: (value) => _handleTamamlananAction(value, atama),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'revize',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.orange),
                      title: Text('Revize Et'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'detay',
                    child: ListTile(
                      leading: Icon(Icons.info, color: Colors.blue),
                      title: Text('Detay Görüntüle'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            onTap: () => _showAtamaDetay(atama),
          ),
        );
      },
    );
  }

  Color _getAtamaColor(String atamaUpi) {
    switch (atamaUpi) {
      case 'Dokuma': return Colors.brown;
      case 'Konfeksiyon': return Colors.purple;
      case 'Nakış': return Colors.pink;
      case 'Yıkama': return Colors.cyan;
      case 'İlik Düğme': return Colors.indigo;
      case 'Ütü': return Colors.red;
      default: return Colors.grey;
    }
  }

}
