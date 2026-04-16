import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'dart:async';
import 'package:uretim_takip/services/dashboard_event_bus.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/beden_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/models/beden_models.dart';


part 'uretim_asama_dashboard_dialog.dart';
part 'uretim_asama_rapor.dart';
part 'uretim_asama_aksiyonlar.dart';

class UretimAsamaDashboard extends StatefulWidget {
  final String asamaAdi; // 'konfeksiyon', 'yikama', 'utu', vb.
  final String asamaDisplayName; // 'Konfeksiyon', 'Yıkama', 'Ütü', vb.
  final String atamaTablosu; // DbTables.konfeksiyonAtamalari, DbTables.yikamaAtamalari, vb.
  final String modelDurumKolonu; // 'konfeksiyon_durumu', 'yikama_durumu', vb.
  final Color asamaRengi;
  final IconData asamaIconu;
  final Widget? detayPage; // Özel detay sayfası varsa

  const UretimAsamaDashboard({
    Key? key,
    required this.asamaAdi,
    required this.asamaDisplayName,
    required this.atamaTablosu,
    required this.modelDurumKolonu,
    required this.asamaRengi,
    required this.asamaIconu,
    this.detayPage,
  }) : super(key: key);

  @override
  State<UretimAsamaDashboard> createState() => _UretimAsamaDashboardState();
}

class _UretimAsamaDashboardState extends State<UretimAsamaDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> atanmisModeller = [];
  List<Map<String, dynamic>> bekleyenModeller = [];
  List<Map<String, dynamic>> onaylanmisModeller = [];
  List<Map<String, dynamic>> uretimdeOlanModeller = [];
  List<Map<String, dynamic>> tamamlananModeller = [];
  bool yukleniyor = true;
  String? currentUserRole;
  String? currentUserId;

  // Filtreleme değişkenleri
  String aramaMetni = '';
  DateTime? baslangicTarihi;
  DateTime? bitisTarihi;
  String? seciliMarka;
  List<String> markalar = [];

  final supabase = Supabase.instance.client;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  final TextEditingController _aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _kullaniciKontrolEt();
    _setupEventListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventSubscription?.cancel();
    _aramaController.dispose();
    super.dispose();
  }

  // Filtreleme fonksiyonları
  List<Map<String, dynamic>> _filtreleListe(List<Map<String, dynamic>> liste) {
    return liste.where((atama) {
      final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
      if (model == null) return false;
      
      // Arama metni filtresi
      if (aramaMetni.isNotEmpty) {
        final marka = (model['marka'] ?? '').toString().toLowerCase();
        final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
        final renk = (model['renk'] ?? '').toString().toLowerCase();
        final arama = aramaMetni.toLowerCase();
        if (!marka.contains(arama) && !itemNo.contains(arama) && !renk.contains(arama)) {
          return false;
        }
      }
      
      // Marka filtresi
      if (seciliMarka != null && seciliMarka!.isNotEmpty) {
        if (model['marka'] != seciliMarka) return false;
      }
      
      // Tarih filtresi
      if (baslangicTarihi != null || bitisTarihi != null) {
        final atamaTarihiStr = atama['atama_tarihi'] ?? atama['created_at'];
        if (atamaTarihiStr != null) {
          final atamaTarihi = DateTime.tryParse(atamaTarihiStr.toString());
          if (atamaTarihi != null) {
            if (baslangicTarihi != null && atamaTarihi.isBefore(baslangicTarihi!)) return false;
            if (bitisTarihi != null && atamaTarihi.isAfter(bitisTarihi!.add(const Duration(days: 1)))) return false;
          }
        }
      }
      
      return true;
    }).toList();
  }

  void _filtreleriTemizle() {
    setState(() {
      aramaMetni = '';
      baslangicTarihi = null;
      bitisTarihi = null;
      seciliMarka = null;
      _aramaController.clear();
    });
  }

  void _markalariTopla() {
    final tumModeller = [...bekleyenModeller, ...onaylanmisModeller, ...uretimdeOlanModeller, ...tamamlananModeller];
    final markaSet = <String>{};
    for (var atama in tumModeller) {
      final model = atama[DbTables.trikoTakip];
      if (model != null && model['marka'] != null) {
        markaSet.add(model['marka'].toString());
      }
    }
    setState(() {
      markalar = markaSet.toList()..sort();
    });
  }

  Future<void> _kullaniciKontrolEt() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    try {
      // Önce user_roles tablosundan rol kontrol et
      final response = await supabase
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id)
          .maybeSingle();
      
      String? userRole = response?['role'];
      
      // Admin veya ilgili aşama rolü değilse, tedarikçi olabilir - email ile kontrol et
      if (userRole != 'admin' && userRole != widget.asamaAdi) {
        final tedarikciCheck = await supabase
            .from(DbTables.tedarikciler)
            .select('id, faaliyet')
            .eq('email', currentUser.email ?? '')
            .maybeSingle();
        
        if (tedarikciCheck != null) {
          // Tedarikçi - ilgili aşama rolü olarak işaretle
          userRole = 'tedarikci_${widget.asamaAdi}';
          debugPrint('🏢 Tedarikçi ${widget.asamaDisplayName} paneline erişiyor: ${currentUser.email}');
        }
      }
      
      setState(() {
        currentUserRole = userRole;
        currentUserId = currentUser.id;
      });

      // Admin, ilgili aşama rolü veya tedarikçi ise modelleri getir
      if (currentUserRole == widget.asamaAdi || 
          currentUserRole == 'admin' || 
          currentUserRole == 'tedarikci_${widget.asamaAdi}') {
        await _modelleriGetir();
      } else {
        // İlgili rol değilse anasayfaya yönlendir
        debugPrint('⚠️ Yetkisiz erişim denemesi: $currentUserRole');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.splash);
      }
    } catch (e) {
      debugPrint('Kullanıcı kontrol hatası: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<void> _modelleriGetir() async {
    if (currentUserId == null) return;

    setState(() => yukleniyor = true);
    try {
      List<dynamic> response;
      
      // Bazı tablolarda tedarikci_id yok (paketleme, kalite_kontrol vb.)
      final tabloTedarikciIdVar = ![DbTables.paketlemeAtamalari, DbTables.kaliteKontrolAtamalari].contains(widget.atamaTablosu);
      
      // Bazı tablolarda bazı sütunlar yok (paketleme, kalite_kontrol vb.)
      final tabloEkstraAlanlarVar = ![DbTables.paketlemeAtamalari, DbTables.kaliteKontrolAtamalari].contains(widget.atamaTablosu);
      
      // Sorgu alanları - opsiyonel alanlar sadece varsa eklenir
      // NOT: fire_adet, baslama_tarihi, planlanan_bitis_tarihi bazı tablolarda olmayabilir
      final selectFields = '''
        id,
        model_id,
        atama_tarihi,
        durum,
        onay_tarihi,
        red_sebebi,
        tamamlama_tarihi,
        notlar,
        adet,
        talep_edilen_adet,
        ${tabloEkstraAlanlarVar ? 'kabul_edilen_adet,' : ''}
        tamamlanan_adet,
        ${tabloEkstraAlanlarVar ? 'uretim_baslangic_tarihi,' : ''}
        ${tabloTedarikciIdVar ? 'tedarikci_id,' : ''}
        atanan_kullanici_id,
        triko_takip(
          id,
          marka,
          item_no,
          adet,
          bedenler,
          renk,
          termin_tarihi,
          created_at
        )
      ''';
      
      if (currentUserRole == 'admin') {
        // Admin için tüm atamalar
        response = await supabase
            .from(widget.atamaTablosu)
            .select(selectFields)
            .order('atama_tarihi', ascending: false);
      } else {
        // Normal kullanıcı için - önce tedarikci_id'sini bul
        int? kullaniciTedarikciId;
        
        if (tabloTedarikciIdVar) {
          try {
            final userEmail = supabase.auth.currentUser?.email;
            if (userEmail != null) {
              final tedarikciResponse = await supabase
                  .from(DbTables.tedarikciler)
                  .select('id')
                  .eq('email', userEmail)
                  .limit(1);
              
              if (tedarikciResponse.isNotEmpty) {
                kullaniciTedarikciId = tedarikciResponse[0]['id'];
              }
            }
          } catch (e) {
            debugPrint('Tedarikci ID bulunamadı: $e');
          }
        }
        
        if (tabloTedarikciIdVar && kullaniciTedarikciId != null) {
          // Tedarikci olarak atananları getir
          response = await supabase
              .from(widget.atamaTablosu)
              .select(selectFields)
              .or('atanan_kullanici_id.eq.$currentUserId,tedarikci_id.eq.$kullaniciTedarikciId')
              .order('atama_tarihi', ascending: false);
        } else {
          // Sadece atanan_kullanici_id ile eşleşenler
          response = await supabase
              .from(widget.atamaTablosu)
              .select(selectFields)
              .eq('atanan_kullanici_id', currentUserId!)
              .order('atama_tarihi', ascending: false);
        }
      }

      // Durumlara göre ayır
      final tumModeller = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        // Bekleyen: bekleyen, beklemede, atandı veya firma onay bekliyor
        bekleyenModeller = tumModeller
            .where((m) => m['durum'] == 'bekleyen' || m['durum'] == 'beklemede' || m['durum'] == 'atandi' || m['durum'] == 'firma_onay_bekliyor' || m['durum'] == null)
            .toList();
        
        // Onaylanan: kabul edildi ama üretime başlamadı
        onaylanmisModeller = tumModeller
            .where((m) => m['durum'] == 'onaylandi' || m['durum'] == 'kabul_edildi')
            .toList();
        
        // Üretimde: aktif olarak üretiliyor
        uretimdeOlanModeller = tumModeller
            .where((m) => m['durum'] == 'uretimde' || m['durum'] == 'devam_ediyor' || m['durum'] == 'baslatildi' || m['durum'] == 'kismi_tamamlandi')
            .toList();
        
        // Tamamlanan: işlem bitti
        tamamlananModeller = tumModeller
            .where((m) => m['durum'] == 'tamamlandi')
            .toList();
        
        atanmisModeller = tumModeller;
        yukleniyor = false;
      });
      
      // Markaları topla
      _markalariTopla();
    } catch (e) {
      debugPrint('${widget.asamaDisplayName} modelleri getirme hatası: $e');
      setState(() => yukleniyor = false);
      if (!mounted) return;
      context.showSnackBar('Veriler yüklenirken hata oluştu: $e');
    }
  }

  void _setupEventListener() {
    _eventSubscription = DashboardEventBus().onAtamaUpdate.listen((eventData) {
      // Atama olayını dinle ve gerekirse yenile
      if (mounted) {
        setState(() {
          // Widget'ların yenilenmesini tetikle
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Yükleme durumu - rol henüz belirlenmemişse de yükleniyor göster
    if (yukleniyor || currentUserRole == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.asamaDisplayName} Paneli'),
          backgroundColor: widget.asamaRengi,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Admin, ilgili aşama rolü veya tedarikçi kontrolü
    if (currentUserRole != widget.asamaAdi && 
        currentUserRole != 'admin' &&
        currentUserRole != 'tedarikci_${widget.asamaAdi}') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erişim Reddedildi'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            'Bu sayfaya sadece ${widget.asamaDisplayName} personeli erişebilir.',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    // Filtrelenmiş listeler
    final filtreliBekleyenler = _filtreleListe(bekleyenModeller);
    final filtreliOnaylananlar = _filtreleListe(onaylanmisModeller);
    final filtreliUretimdekiler = _filtreleListe(uretimdeOlanModeller);
    final filtreliTamamlananlar = _filtreleListe(tamamlananModeller);
    final tumFiltrelenmisler = [...filtreliBekleyenler, ...filtreliOnaylananlar, ...filtreliUretimdekiler, ...filtreliTamamlananlar];

    // Aktif filtre var mı?
    final aktifFiltreVar = aramaMetni.isNotEmpty || seciliMarka != null || baslangicTarihi != null || bitisTarihi != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.asamaDisplayName} Paneli'),
        backgroundColor: widget.asamaRengi,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Arama
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: _AsamaModelAramaDelegate(
                  tumModeller: atanmisModeller,
                  asamaRengi: widget.asamaRengi,
                ),
              );
              if (result != null && result.isNotEmpty) {
                setState(() {
                  aramaMetni = result;
                  _aramaController.text = result;
                });
              }
            },
            tooltip: 'Ara',
          ),
          // Filtreleme
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: _showFilterDialog,
                tooltip: 'Filtrele',
              ),
              if (aktifFiltreVar)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          // Raporlama
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showRaporDialog,
            tooltip: 'Rapor',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _modelleriGetir,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Bekleyen (${filtreliBekleyenler.length})',
              icon: const Icon(Icons.pending),
            ),
            Tab(
              text: 'Onaylanan (${filtreliOnaylananlar.length})',
              icon: const Icon(Icons.check_circle),
            ),
            Tab(
              text: 'İşlemde (${filtreliUretimdekiler.length})',
              icon: Icon(widget.asamaIconu),
            ),
            Tab(
              text: 'Tümü (${tumFiltrelenmisler.length})',
              icon: const Icon(Icons.list),
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Column(
        children: [
          // Aktif filtre göstergesi
          if (aktifFiltreVar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aktif Filtre: ${[
                        if (aramaMetni.isNotEmpty) '"$aramaMetni"',
                        if (seciliMarka != null) 'Marka: $seciliMarka',
                        if (baslangicTarihi != null) 'Başlangıç: ${DateFormat('dd.MM.yyyy').format(baslangicTarihi!)}',
                        if (bitisTarihi != null) 'Bitiş: ${DateFormat('dd.MM.yyyy').format(bitisTarihi!)}',
                      ].join(', ')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _filtreleriTemizle,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Temizle'),
                  ),
                ],
              ),
            ),
          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModelListesi(
                  filtreliBekleyenler,
                  'Onayınızı bekleyen ${widget.asamaDisplayName.toLowerCase()} işi bulunmuyor.',
                ),
                _buildModelListesi(
                  filtreliOnaylananlar,
                  'Onaylanmış ${widget.asamaDisplayName.toLowerCase()} işi bulunmuyor.',
                ),
                _buildModelListesi(
                  filtreliUretimdekiler,
                  'İşlemde olan ${widget.asamaDisplayName.toLowerCase()} işi bulunmuyor.',
                ),
                _buildModelListesi(
                  tumFiltrelenmisler,
                  'Size atanmış ${widget.asamaDisplayName.toLowerCase()} işi bulunmuyor.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
