import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/bildirim_service.dart';

part 'kalite_kontrol_panel_widgets.dart';


class KaliteKontrolPanel extends StatefulWidget {
  const KaliteKontrolPanel({Key? key}) : super(key: key);

  @override
  State<KaliteKontrolPanel> createState() => _KaliteKontrolPanelState();
}

class _KaliteKontrolPanelState extends State<KaliteKontrolPanel>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> bekleyenler = [];
  List<Map<String, dynamic>> kontrolEdiliyor = [];
  List<Map<String, dynamic>> tamamlananlar = [];

  bool yukleniyor = true;
  String? currentUserRole;

  // Filtreleme
  String aramaMetni = '';
  String? seciliAsama;
  List<String> asamalar = ['Dokuma', 'Konfeksiyon', 'Yıkama', 'Ütü', 'İlik Düğme', 'Paketleme'];
  final TextEditingController _aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _kullaniciBilgisiYukle();
    _verileriYukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _kullaniciBilgisiYukle() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Önce firma_kullanicilari tablosunu dene
        final response1 = await supabase
            .from(DbTables.firmaKullanicilari)
            .select('rol')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (response1 != null) {
          setState(() => currentUserRole = response1['rol']);
        } else {
          // Yoksa kullanicilar tablosunu dene
          final response2 = await supabase
              .from(DbTables.kullanicilar)
              .select('rol')
              .eq('id', user.id)
              .maybeSingle();
          
          if (response2 != null) {
            setState(() => currentUserRole = response2['rol']);
          }
        }
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgisi alınamadı: $e');
    }
  }

  Future<void> _verileriYukle() async {
    setState(() => yukleniyor = true);
    
    try {
      // Önce tüm kalite kontrol kayıtlarını al
      final response = await supabase
          .from(DbTables.kaliteKontrolAtamalari)
          .select('*')
          .order('created_at', ascending: false);

      debugPrint('📋 Kalite kontrol sorgu sonucu: ${response.length} kayıt');
      
      final tumKontroller = List<Map<String, dynamic>>.from(response);
      
      // Her kayıt için model bilgisini ayrı çek
      final List<Map<String, dynamic>> zenginKontroller = [];
      for (var kontrol in tumKontroller) {
        try {
          final modelId = kontrol['model_id'];
          if (modelId != null) {
            final modelResponse = await supabase
                .from(DbTables.trikoTakip)
                .select('id, marka, item_no, renk, adet, termin_tarihi')
                .eq('id', modelId)
                .maybeSingle();
            
            if (modelResponse != null) {
              kontrol[DbTables.trikoTakip] = modelResponse;
              zenginKontroller.add(kontrol);
            } else {
              debugPrint('⚠️ Model bulunamadı: $modelId');
              // Model bulunamasa bile notlardan bilgi al
              kontrol[DbTables.trikoTakip] = {
                'id': modelId,
                'marka': 'Bilinmiyor',
                'item_no': kontrol['notlar']?.toString().split('-').elementAtOrNull(1)?.trim() ?? 'N/A',
                'renk': null,
                'adet': kontrol['kontrol_edilecek_adet'],
                'termin_tarihi': null,
              };
              zenginKontroller.add(kontrol);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Model bilgisi alınamadı: $e');
        }
      }
      
      debugPrint('📋 Zenginleştirilmiş kontroller: ${zenginKontroller.length} kayıt');

      setState(() {
        // Bekleyenler: atandi durumu (yeni atamalar)
        bekleyenler = zenginKontroller.where((k) => 
          k['durum'] == 'atandi' || 
          k['durum'] == 'beklemede' || 
          k['durum'] == 'kontrol_bekliyor'
        ).toList();
        
        // Kontrol ediliyor: baslandi durumu
        kontrolEdiliyor = zenginKontroller.where((k) => 
          k['durum'] == 'baslandi' ||
          k['durum'] == 'kontrolde'
        ).toList();
        
        // Tamamlananlar: tamamlandi, iptal
        tamamlananlar = zenginKontroller.where((k) => 
          k['durum'] == 'tamamlandi' ||
          k['durum'] == 'onaylandi' || 
          k['durum'] == 'kalite_onay' || 
          k['durum'] == 'reddedildi' || 
          k['durum'] == 'kalite_red' ||
          k['durum'] == 'iptal'
        ).toList();
        
        yukleniyor = false;
      });

      debugPrint('✅ Kalite kontrol verileri yüklendi: ${bekleyenler.length} bekleyen, ${kontrolEdiliyor.length} kontrolde, ${tamamlananlar.length} tamamlanan');

    } catch (e) {
      debugPrint('❌ Kalite kontrol verileri yüklenemedi: $e');
      setState(() => yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Veri yükleme hatası: $e');
      }
    }
  }

  Future<int> _getModelToplamAdet(String? modelId) async {
    if (modelId == null) return 0;
    
    try {
      // Beden dağılımından toplam adedi hesapla
      final response = await supabase
          .from(DbTables.modelBedenDagilimi)
          .select('siparis_adedi')
          .eq('model_id', modelId);
      
      if (response.isNotEmpty) {
        int toplam = 0;
        for (var item in response) {
          toplam += (item['siparis_adedi'] as int?) ?? 0;
        }
        return toplam;
      }
      
      // Eğer beden dağılımı yoksa, model'den al
      final modelResponse = await supabase
          .from(DbTables.trikoTakip)
          .select('adet')
          .eq('id', modelId)
          .maybeSingle();
      
      return (modelResponse?['adet'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Model toplam adet alınamadı: $e');
      return 0;
    }
  }

  List<Map<String, dynamic>> _filtreleListe(List<Map<String, dynamic>> liste) {
    return liste.where((kontrol) {
      final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>?;
      if (model == null) return false;

      // Arama filtresi
      if (aramaMetni.isNotEmpty) {
        final marka = (model['marka'] ?? '').toString().toLowerCase();
        final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
        final renk = (model['renk'] ?? '').toString().toLowerCase();
        final arama = aramaMetni.toLowerCase();
        if (!marka.contains(arama) && !itemNo.contains(arama) && !renk.contains(arama)) {
          return false;
        }
      }

      // Aşama filtresi
      if (seciliAsama != null && seciliAsama!.isNotEmpty) {
        if (kontrol['onceki_asama'] != seciliAsama) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtreliBekleyenler = _filtreleListe(bekleyenler);
    final filtreliKontrolEdiliyor = _filtreleListe(kontrolEdiliyor);
    final filtreliTamamlananlar = _filtreleListe(tamamlananlar);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalite Kontrol Paneli'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showAramaDialog,
            tooltip: 'Ara',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltreDialog,
            tooltip: 'Filtrele',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!context.mounted) return;
              if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            tooltip: 'Çıkış',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${filtreliBekleyenler.length}'),
                backgroundColor: Colors.orange,
                child: const Icon(Icons.pending_actions),
              ),
              text: 'Bekleyen',
            ),
            Tab(
              icon: Badge(
                label: Text('${filtreliKontrolEdiliyor.length}'),
                backgroundColor: Colors.blue,
                child: const Icon(Icons.search),
              ),
              text: 'Kontrol Ediliyor',
            ),
            Tab(
              icon: Badge(
                label: Text('${filtreliTamamlananlar.length}'),
                backgroundColor: Colors.green,
                child: const Icon(Icons.check_circle),
              ),
              text: 'Tamamlanan',
            ),
          ],
        ),
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildKontrolListesi(filtreliBekleyenler, 'bekleyen'),
                _buildKontrolListesi(filtreliKontrolEdiliyor, 'kontrolde'),
                _buildKontrolListesi(filtreliTamamlananlar, 'tamamlanan'),
              ],
            ),
    );
  }

}