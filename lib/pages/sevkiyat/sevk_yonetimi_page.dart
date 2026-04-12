import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'sevk_yonetimi_admin.dart';
part 'sevk_yonetimi_tabs.dart';

class SevkYonetimiPage extends StatefulWidget {
  const SevkYonetimiPage({super.key});

  @override
  State<SevkYonetimiPage> createState() => _SevkYonetimiPageState();
}

class _SevkYonetimiPageState extends State<SevkYonetimiPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final supabase = Supabase.instance.client;
  
  // Admin client for user management
  final adminClient = SupabaseConfig.adminClient;
  
  String kullaniciRolu = '';
  String kullaniciId = '';
  List<Map<String, dynamic>> atanmisModeller = [];
  List<Map<String, dynamic>> sevkTalepleri = [];
  List<Map<String, dynamic>> bildirimler = [];
  List<Map<String, dynamic>> tumKullanicilar = []; // Admin için kullanıcı listesi
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    // TabController'ı initialize data'dan sonra oluşturacağız
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getKullaniciBilgileri();
    
    // TabController'ı rol belirlendikten sonra oluştur
    if (!mounted) return;
    setState(() {
      final tabCount = _getTabCountForRole();
      _tabController?.dispose(); // Eski controller'ı temizle
      _tabController = TabController(length: tabCount, vsync: this);
    });
    
    await _loadData();
  }

  int _getTabCountForRole() {
    switch (kullaniciRolu) {
      case 'admin':
        return 3;
      case 'orgu_firmasi':
      case 'kalite_personeli':
      case 'sevkiyat_soforu':
      case 'atolye_personeli':
        return 3;
      default:
        return 1;
    }
  }

  Future<void> _getKullaniciBilgileri() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      kullaniciId = user.id;
      
      try {
        final roleResponse = await supabase
            .from(DbTables.userRoles)
            .select('role, atolye_id, yetki_seviyesi')
            .eq('user_id', user.id)
            .single();
        
        kullaniciRolu = roleResponse['role'] ?? '';
      } catch (e) {
        debugPrint('Kullanıcı rolü bulunamadı: $e');
        // Admin rolü varsayılan olarak ata
        kullaniciRolu = 'admin';
        
        // Kullanıcı kaydını oluştur
        try {
          await supabase.from(DbTables.userRoles).insert({
            'user_id': user.id,
            'role': 'admin',
            'yetki_seviyesi': 'admin',
          });
          debugPrint('Admin kullanıcı rolü oluşturuldu');
        } catch (insertError) {
          debugPrint('Kullanıcı rolü oluşturulamadı: $insertError');
        }
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => yukleniyor = true);
    
    try {
      switch (kullaniciRolu) {
        case 'admin':
          await _loadAdminData();
          break;
        case 'orgu_firmasi':
          await _loadOrguFirmasiData();
          break;
        case 'kalite_personeli':
          await _loadKalitePersoneliData();
          break;
        case 'sevkiyat_soforu':
          await _loadSevkiyatSoforuData();
          break;
        case 'atolye_personeli':
          await _loadAtolyePersoneliData();
          break;
      }
      
      await _loadBildirimler();
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
    }
    
    if (!mounted) return;
    setState(() => yukleniyor = false);
  }

  Future<void> _loadAdminData() async {
    try {
      // Admin tüm verileri görür - tüm tabloları oku
      final modelResponse = await supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .limit(20);
      
      final sevkResponse = await supabase
          .from(DbTables.sevkTalepleri)
          .select('*')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .limit(20);
      
      atanmisModeller = List<Map<String, dynamic>>.from(modelResponse);
      sevkTalepleri = List<Map<String, dynamic>>.from(sevkResponse);
      
      // Kullanıcıları yükle
      await _loadAllUsers();
      
      // Demo admin verileri
      if (atanmisModeller.isEmpty) {
        atanmisModeller = [
          {
            'id': '1',
            'marka': 'Admin Test Marka 1',
            'item_no': 'ADM001',
            'model_adi': 'Admin Test Model 1',
            'toplam_adet': 500,
            'yuklenen_adet': 300,
            'orgu_firma': 'Tüm Firmalar',
            'durum': 'uretimde'
          },
          {
            'id': '2',
            'marka': 'Admin Test Marka 2',
            'item_no': 'ADM002',
            'model_adi': 'Admin Test Model 2',
            'toplam_adet': 750,
            'yuklenen_adet': 600,
            'orgu_firma': 'Tüm Firmalar',
            'durum': 'tamamlandi'
          },
        ];
      }
      
      if (sevkTalepleri.isEmpty) {
        sevkTalepleri = [
          {
            'id': '1',
            'model_id': '1',
            'sevk_edilen_adet': 100,
            'durum': 'kalite_onay',
            'asama': 'orgu',
            DbTables.trikoTakip: {
              'marka': 'Admin Test Marka',
              'item_no': 'ADM001',
              'model_adi': 'Admin Test Model'
            }
          },
          {
            'id': '2',
            'model_id': '2',
            'sevk_edilen_adet': 150,
            'durum': 'sevk_hazir',
            'asama': 'konfeksiyon',
            DbTables.trikoTakip: {
              'marka': 'Admin Test Marka 2',
              'item_no': 'ADM002',
              'model_adi': 'Admin Test Model 2'
            }
          }
        ];
      }
    } catch (e) {
      debugPrint('Admin verileri yüklenirken hata: $e');
      // Admin için demo veriler
      atanmisModeller = [
        {
          'id': '1',
          'marka': 'Demo Admin Marka',
          'item_no': 'DEMO001',
          'model_adi': 'Demo Admin Model',
          'toplam_adet': 1000,
          'yuklenen_adet': 750,
          'orgu_firma': 'Sistem Admin',
          'durum': 'uretimde'
        }
      ];
      
      sevkTalepleri = [
        {
          'id': '1',
          'model_id': '1',
          'sevk_edilen_adet': 200,
          'durum': 'admin_onay',
          'asama': 'tumu',
          DbTables.trikoTakip: {
            'marka': 'Demo Admin Marka',
            'item_no': 'DEMO001',
            'model_adi': 'Demo Admin Model'
          }
        }
      ];
    }
  }

  Future<void> _loadOrguFirmasiData() async {
    try {
      // Örgü firmasına atanmış modelleri getir
      final response = await supabase
          .from(DbTables.trikoTakip)
          .select('''
            id, marka, item_no, model_adi, toplam_adet, yuklenen_adet,
            orgu_firma, durum
          ''')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .limit(10); // Test için limit ekle
      
      atanmisModeller = List<Map<String, dynamic>>.from(response);
      
      // Eğer veri yoksa demo veri ekle
      if (atanmisModeller.isEmpty) {
        atanmisModeller = [
          {
            'id': '1',
            'marka': 'Test Marka',
            'item_no': 'TM001',
            'model_adi': 'Test Model 1',
            'toplam_adet': 100,
            'yuklenen_adet': 60,
            'orgu_firma': 'Test Örgü Firması',
            'durum': 'uretimde'
          },
          {
            'id': '2',
            'marka': 'Test Marka',
            'item_no': 'TM002',
            'model_adi': 'Test Model 2',
            'toplam_adet': 200,
            'yuklenen_adet': 120,
            'orgu_firma': 'Test Örgü Firması',
            'durum': 'uretimde'
          }
        ];
      }
    } catch (e) {
      debugPrint('Örgü firması verileri yüklenirken hata: $e');
      // Hata durumunda demo veri göster
      atanmisModeller = [
        {
          'id': '1',
          'marka': 'Demo Marka',
          'item_no': 'DM001',
          'model_adi': 'Demo Model',
          'toplam_adet': 50,
          'yuklenen_adet': 30,
          'orgu_firma': 'Demo Örgü Firması',
          'durum': 'uretimde'
        }
      ];
    }
  }

  Future<void> _loadKalitePersoneliData() async {
    try {
      // Kalite onayı bekleyen sevk taleplerini getir
      final response = await supabase
          .from(DbTables.sevkTalepleri)
          .select('''
            id, model_id, sevk_adeti, durum,
            kaynak_atolye_id, hedef_atolye_id,
            created_at
          ''')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('durum', 'kalite_onay')
          .limit(10);
      
      sevkTalepleri = List<Map<String, dynamic>>.from(response);
      
      // Demo veri ekle
      if (sevkTalepleri.isEmpty) {
        sevkTalepleri = [
          {
            'id': '1',
            'model_id': '1',
            'sevk_edilen_adet': 25,
            'durum': 'kalite_onay',
            'asama': 'orgu',
            DbTables.trikoTakip: {
              'marka': 'Test Marka',
              'item_no': 'TM001',
              'model_adi': 'Test Model 1'
            }
          }
        ];
      }
    } catch (e) {
      debugPrint('Kalite personeli verileri yüklenirken hata: $e');
      sevkTalepleri = [];
    }
  }

  Future<void> _loadSevkiyatSoforuData() async {
    try {
      // Sevkiyat onayı verilmiş talepleri getir
      final response = await supabase
          .from(DbTables.sevkTalepleri)
          .select('''
            id, model_id, sevk_edilen_adet, durum, asama, hedef_atolye_id,
            triko_takip!inner(marka, item_no, model_adi),
            atolyeler!inner(atolye_adi, atolye_tipi, adres)
          ''')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('durum', 'sevk_hazir')
          .limit(10);
      
      sevkTalepleri = List<Map<String, dynamic>>.from(response);
      
      // Demo veri ekle
      if (sevkTalepleri.isEmpty) {
        sevkTalepleri = [
          {
            'id': '1',
            'model_id': '1',
            'sevk_edilen_adet': 25,
            'durum': 'sevk_hazir',
            'asama': 'orgu',
            DbTables.trikoTakip: {
              'marka': 'Test Marka',
              'item_no': 'TM001',
              'model_adi': 'Test Model 1'
            },
            'atolyeler': {
              'atolye_adi': 'Konfeksiyon Atölyesi',
              'atolye_tipi': 'konfeksiyon',
              'adres': 'Test Adres, İstanbul'
            }
          }
        ];
      }
    } catch (e) {
      debugPrint('Sevkiyat şoförü verileri yüklenirken hata: $e');
      sevkTalepleri = [];
    }
  }

  Future<void> _loadAtolyePersoneliData() async {
    try {
      // Atölyeye gelen ürünleri getir
      final atolyeResponse = await supabase
          .from(DbTables.userRoles)
          .select('atolye_id')
          .eq('user_id', kullaniciId)
          .single();
      
      if (atolyeResponse['atolye_id'] != null) {
        final response = await supabase
            .from(DbTables.sevkTalepleri)
            .select('''
              id, model_id, sevk_edilen_adet, durum, asama,
              triko_takip!inner(marka, item_no, model_adi)
            ''')
            .eq('hedef_atolye_id', atolyeResponse['atolye_id'])
            .inFilter('durum', ['teslim_edildi', 'kabul_edildi']);
        
        sevkTalepleri = List<Map<String, dynamic>>.from(response);
      }
      
      // Demo veri ekle
      if (sevkTalepleri.isEmpty) {
        sevkTalepleri = [
          {
            'id': '1',
            'model_id': '1',
            'sevk_edilen_adet': 25,
            'durum': 'teslim_edildi',
            'asama': 'orgu',
            DbTables.trikoTakip: {
              'marka': 'Test Marka',
              'item_no': 'TM001',
              'model_adi': 'Test Model 1'
            }
          }
        ];
      }
    } catch (e) {
      debugPrint('Atölye personeli verileri yüklenirken hata: $e');
      sevkTalepleri = [
        {
          'id': '1',
          'model_id': '1',
          'sevk_edilen_adet': 25,
          'durum': 'teslim_edildi',
          'asama': 'orgu',
          DbTables.trikoTakip: {
            'marka': 'Demo Marka',
            'item_no': 'DM001',
            'model_adi': 'Demo Model'
          }
        }
      ];
    }
  }

  Future<void> _loadBildirimler() async {
    try {
      final response = await supabase
          .from(DbTables.bildirimler)
          .select('*')
          .eq('user_id', kullaniciId) // kullanici_id yerine user_id
          .eq('okundu', false)
          .order('created_at', ascending: false)
          .limit(10);
      
      bildirimler = List<Map<String, dynamic>>.from(response);
      
      // Demo bildirim ekle
      if (bildirimler.isEmpty) {
        bildirimler = [
          {
            'id': '1',
            'baslik': 'Hoş Geldiniz',
            'mesaj': 'Sevkiyat yönetimi sistemine hoş geldiniz.',
            'tip': 'bilgi',
            'created_at': DateTime.now().toIso8601String(),
            'okundu': false
          }
        ];
      }
    } catch (e) {
      debugPrint('Bildirimler yüklenirken hata: $e');
      // Demo bildirimler
      bildirimler = [
        {
          'id': '1',
          'baslik': kullaniciRolu == 'admin' ? 'Admin Panel Hoş Geldiniz' : 'Hoş Geldiniz',
          'mesaj': kullaniciRolu == 'admin' 
              ? 'Admin paneline hoş geldiniz. Tüm sistem yetkileriniz aktif.'
              : 'Sevkiyat yönetimi sistemine hoş geldiniz.',
          'tip': 'bilgi',
          'created_at': DateTime.now().toIso8601String(),
          'okundu': false
        }
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sevkiyat Yönetimi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _getTabsForRole(),
        ) : null,
        actions: [
          // Geliştirici test menüsü
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                kullaniciRolu = value;
                // TabController'ı yeniden oluştur
                final tabCount = _getTabCountForRole();
                _tabController?.dispose();
                _tabController = TabController(length: tabCount, vsync: this);
              });
              _loadData();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'admin',
                child: Text('Test: Admin'),
              ),
              const PopupMenuItem<String>(
                value: 'orgu_firmasi',
                child: Text('Test: Örgü Firması'),
              ),
              const PopupMenuItem<String>(
                value: 'kalite_personeli',
                child: Text('Test: Kalite Personeli'),
              ),
              const PopupMenuItem<String>(
                value: 'sevkiyat_soforu',
                child: Text('Test: Sevkiyat Şoförü'),
              ),
              const PopupMenuItem<String>(
                value: 'atolye_personeli',
                child: Text('Test: Atölye Personeli'),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => _showBildirimler(),
              ),
              if (bildirimler.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      bildirimler.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : _tabController != null 
              ? TabBarView(
                  controller: _tabController,
                  children: _getTabViewsForRole(),
                )
              : const Center(child: Text('Yükleniyor...')),
    );
  }

  List<Widget> _getTabsForRole() {
    switch (kullaniciRolu) {
      case 'admin':
        return [
          const Tab(text: 'Genel Bakış'),
          const Tab(text: 'Kullanıcı Yönetimi'),
          const Tab(text: 'Sistem Ayarları'),
        ];
      case 'orgu_firmasi':
        return [
          const Tab(text: 'Atanmış Modeller'),
          const Tab(text: 'Sevk Talepleri'),
          const Tab(text: 'Geçmiş'),
        ];
      case 'kalite_personeli':
        return [
          const Tab(text: 'Bekleyen Onaylar'),
          const Tab(text: 'Onaylananlar'),
          const Tab(text: 'Reddedilenler'),
        ];
      case 'sevkiyat_soforu':
        return [
          const Tab(text: 'Hazır Sevkiyatlar'),
          const Tab(text: 'Devam Eden'),
          const Tab(text: 'Tamamlanan'),
        ];
      case 'atolye_personeli':
        return [
          const Tab(text: 'Gelen Ürünler'),
          const Tab(text: 'Üretimde'),
          const Tab(text: 'Tamamlanan'),
        ];
      default:
        return [const Tab(text: 'Genel')];
    }
  }

  List<Widget> _getTabViewsForRole() {
    switch (kullaniciRolu) {
      case 'admin':
        return [
          _buildAdminGenelBakisTab(),
          _buildAdminKullaniciYonetimiTab(),
          _buildAdminSistemAyarlariTab(),
        ];
      case 'orgu_firmasi':
        return [
          _buildAtanmisModellerTab(),
          _buildSevkTalepleriTab(),
          _buildGecmisTab(),
        ];
      case 'kalite_personeli':
        return [
          _buildKaliteBekleyenTab(),
          _buildKaliteOnaylananTab(),
          _buildKaliteReddedilenTab(),
        ];
      case 'sevkiyat_soforu':
        return [
          _buildSevkiyatHazirTab(),
          _buildSevkiyatDevamTab(),
          _buildSevkiyatTamamTab(),
        ];
      case 'atolye_personeli':
        return [
          _buildAtolyeGelenTab(),
          _buildAtolyeUretimTab(),
          _buildAtolyeTamamTab(),
        ];
      default:
        return [const Center(child: Text('Yetkisiz erişim'))];
    }
  }


  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
