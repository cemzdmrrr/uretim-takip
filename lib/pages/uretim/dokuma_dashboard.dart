import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/dashboard_event_bus.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/beden_service.dart';
import 'package:uretim_takip/models/beden_models.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'dokuma_dashboard_dialog.dart';
part 'dokuma_dashboard_rapor.dart';
part 'dokuma_dashboard_widgets.dart';
part 'dokuma_dashboard_detay.dart';
part 'dokuma_dashboard_aksiyonlar.dart';

class DokumaDashboard extends StatefulWidget {
  const DokumaDashboard({Key? key}) : super(key: key);

  @override
  State<DokumaDashboard> createState() => _DokumaDashboardState();
}

class _DokumaDashboardState extends State<DokumaDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> bekleyenModeller = [];      // Atandı - tedarikci onayı bekliyor
  List<Map<String, dynamic>> onaylanmisModeller = [];    // Onaylandı - üretim başlayabilir
  List<Map<String, dynamic>> uretimdeOlanModeller = [];  // Üretimde/Kısmi tamamlandı
  List<Map<String, dynamic>> tamamlananModeller = [];    // Tamamen tamamlandı - kalıcı kayıt
  bool yukleniyor = true;
  String? currentUserRole;
  String? currentUserId;

  // Filtreleme değişkenleri
  String aramaMetni = '';
  DateTime? baslangicTarihi;
  DateTime? bitisTarihi;
  String? seciliMarka;
  List<String> markalar = [];
  
  // Filtrelenmiş listeler
  List<Map<String, dynamic>> filtrelenmisListe = [];

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
      
      // Admin veya dokuma rolü değilse, tedarikçi olabilir - email ile kontrol et
      if (userRole != 'admin' && userRole != 'dokuma') {
        final tedarikciCheck = await supabase
            .from(DbTables.tedarikciler)
            .select('id, faaliyet')
            .eq('email', currentUser.email ?? '')
            .maybeSingle();
        
        if (tedarikciCheck != null) {
          // Tedarikçi - dokuma rolü olarak işaretle
          userRole = 'tedarikci_dokuma';
        }
      }
      
      setState(() {
        currentUserRole = userRole;
        currentUserId = currentUser.id;
      });

      // Dokuma, admin veya tedarikçi ise modelleri getir
      if (currentUserRole == 'dokuma' || currentUserRole == 'admin' || currentUserRole == 'tedarikci_dokuma') {
        await _modelleriGetir();
      } else {
        // Yetkisiz kullanıcı - anasayfaya yönlendir
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.splash);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<void> _modelleriGetir() async {
    if (currentUserId == null) return;

    setState(() => yukleniyor = true);
    try {
      // Dokuma atamalarını getir (admin kullanıcı için tüm atamalar, dokuma/tedarikçi kullanıcı için kendi atamaları)
      if (currentUserRole == 'admin') {
        // Admin için tüm dokuma atamaları
        final response = await supabase
            .from(DbTables.dokumaAtamalari)
            .select('''
              id,
              model_id,
              atama_tarihi,
              durum,
              notlar,
              tamamlanan_adet,
              kabul_edilen_adet,
              talep_edilen_adet,
              adet,
              fire_adet,
              tamamlama_tarihi,
              baslama_tarihi,
              planlanan_bitis_tarihi,
              tedarikci_id,
              triko_takip(
                id,
                marka,
                item_no,
                renk,
                adet,
                bedenler,
                termin_tarihi,
                created_at
              )
            ''')
            .eq('firma_id', TenantManager.instance.requireFirmaId)
            .order('atama_tarihi', ascending: false);
        
        final tumModeller = response;
        
        setState(() {
          // Durumlara göre ayır - mantıksal sıralama
          // 1. Bekleyen: Atandı, henüz tedarikci onayı bekleniyor
          bekleyenModeller = tumModeller
              .where((m) => m['durum'] == 'atandi' || m['durum'] == 'beklemede')
              .toList();
          
          // 2. Onaylanan: Tedarikci onayladı, üretim başlayabilir
          onaylanmisModeller = tumModeller
              .where((m) => m['durum'] == 'onaylandi')
              .toList();
          
          // 3. Üretimde: Üretim başladı veya kısmi tamamlandı
          uretimdeOlanModeller = tumModeller
              .where((m) => m['durum'] == 'uretimde' || m['durum'] == 'baslatildi' || m['durum'] == 'kismi_tamamlandi')
              .toList();
          
          // 4. Tamamlanan: Tamamen bitti
          tamamlananModeller = tumModeller
              .where((m) => m['durum'] == 'tamamlandi')
              .toList();
          
          yukleniyor = false;
        });
      } else {
        // Dokuma kullanıcısı için - önce kendi atamaları, sonra tedarikci_id bazlı
        // Önce kullanıcının tedarikci_id'sini bul (user_roles veya tedarikciler tablosundan)
        int? kullaniciTedarikciId;
        
        try {
          // Kullanıcının email'ini al
          final userEmail = supabase.auth.currentUser?.email;
          if (userEmail != null) {
            // Tedarikci tablosunda bu email var mı?
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
          // Tedarikci ID bulunamadı
        }
        
        // Sorgu oluştur - atanan_kullanici_id VEYA tedarikci_id ile eşleşen kayıtlar
        List<dynamic> response;
        
        if (kullaniciTedarikciId != null) {
          // Tedarikci olarak atananları getir
          response = await supabase
              .from(DbTables.dokumaAtamalari)
              .select('''
                id,
                model_id,
                atama_tarihi,
                durum,
                notlar,
                tamamlanan_adet,
                kabul_edilen_adet,
                talep_edilen_adet,
                adet,
                fire_adet,
                tamamlama_tarihi,
                baslama_tarihi,
                planlanan_bitis_tarihi,
                tedarikci_id,
                atanan_kullanici_id,
                triko_takip(
                  id,
                  marka,
                  item_no,
                  renk,
                  adet,
                  bedenler,
                  termin_tarihi,
                  created_at
                )
              ''')
              .or('atanan_kullanici_id.eq.$currentUserId,tedarikci_id.eq.$kullaniciTedarikciId')
              .order('atama_tarihi', ascending: false);
        } else {
          // Sadece atanan_kullanici_id ile eşleşenler
          response = await supabase
              .from(DbTables.dokumaAtamalari)
              .select('''
                id,
                model_id,
                atama_tarihi,
                durum,
                notlar,
                tamamlanan_adet,
                kabul_edilen_adet,
                talep_edilen_adet,
                adet,
                fire_adet,
                tamamlama_tarihi,
                baslama_tarihi,
                planlanan_bitis_tarihi,
                tedarikci_id,
                atanan_kullanici_id,
                triko_takip(
                  id,
                  marka,
                  item_no,
                  renk,
                  adet,
                  bedenler,
                  termin_tarihi,
                  created_at
                )
              ''')
              .eq('atanan_kullanici_id', currentUserId!)
              .order('atama_tarihi', ascending: false);
        }
        
        final tumModeller = response as List<Map<String, dynamic>>;
        
        setState(() {
          // Durumlara göre ayır - mantıksal sıralama
          // 1. Bekleyen: Atandı, henüz tedarikci onayı bekleniyor
          bekleyenModeller = tumModeller
              .where((m) => m['durum'] == 'atandi' || m['durum'] == 'beklemede')
              .toList();
          
          // 2. Onaylanan: Tedarikci onayladı, üretim başlayabilir
          onaylanmisModeller = tumModeller
              .where((m) => m['durum'] == 'onaylandi')
              .toList();
          
          // 3. Üretimde: Üretim başladı veya kısmi tamamlandı
          uretimdeOlanModeller = tumModeller
              .where((m) => m['durum'] == 'uretimde' || m['durum'] == 'baslatildi' || m['durum'] == 'kismi_tamamlandi')
              .toList();
          
          // 4. Tamamlanan: Tamamen bitti
          tamamlananModeller = tumModeller
              .where((m) => m['durum'] == 'tamamlandi')
              .toList();
          
          yukleniyor = false;
        });
        
        // Markaları topla
        _markalariTopla();
      }
    } catch (e) {
      setState(() => yukleniyor = false);
      if (!mounted) return;
      context.showSnackBar('Veriler yüklenirken hata oluştu: $e');
    }
  }

  // Markaları topla
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

  // Liste filtreleme
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

  // Filtreleri temizle
  void _filtreleriTemizle() {
    setState(() {
      aramaMetni = '';
      baslangicTarihi = null;
      bitisTarihi = null;
      seciliMarka = null;
      _aramaController.clear();
    });
  }

  // Rapor dialog
  @override
  Widget build(BuildContext context) {
    // Yükleme durumu - rol henüz belirlenmemişse de yükleniyor göster
    if (yukleniyor || currentUserRole == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dokuma Paneli'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Tedarikçi, dokuma veya admin değilse erişimi reddet
    if (currentUserRole != 'dokuma' && 
        currentUserRole != 'admin' && 
        currentUserRole != 'tedarikci_dokuma') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erişim Reddedildi'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Bu sayfaya sadece dokuma personeli ve admin kullanıcılar erişebilir.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    // Filtrelenmiş listeleri hesapla
    final filtreliBekleyen = _filtreleListe(bekleyenModeller);
    final filtreliOnaylanan = _filtreleListe(onaylanmisModeller);
    final filtreliUretimde = _filtreleListe(uretimdeOlanModeller);
    final filtreliTamamlanan = _filtreleListe(tamamlananModeller);
    
    // Aktif filtre var mı?
    final aktifFiltre = aramaMetni.isNotEmpty || seciliMarka != null || baslangicTarihi != null || bitisTarihi != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokuma Paneli'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Arama
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _DokumaSearchDelegate(
                  tumModeller: [...bekleyenModeller, ...onaylanmisModeller, ...uretimdeOlanModeller, ...tamamlananModeller],
                  onSelected: (model) {
                    // Model seçildiğinde detay göster
                    _showAtamaDetay(model, model[DbTables.trikoTakip]);
                  },
                ),
              );
            },
            tooltip: 'Ara',
          ),
          // Filtre
          IconButton(
            icon: Badge(
              isLabelVisible: aktifFiltre,
              child: const Icon(Icons.filter_alt),
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrele',
          ),
          // Rapor
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showRaporDialog,
            tooltip: 'Rapor',
          ),
          // Yenile
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _modelleriGetir,
            tooltip: 'Yenile',
          ),
          // Çıkış
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
          isScrollable: true,
          tabs: [
            Tab(
              text: 'Bekleyen (${filtreliBekleyen.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'Onaylanan (${filtreliOnaylanan.length})',
              icon: const Icon(Icons.thumb_up),
            ),
            Tab(
              text: 'Üretimde (${filtreliUretimde.length})',
              icon: const Icon(Icons.precision_manufacturing),
            ),
            Tab(
              text: 'Tamamlanan (${filtreliTamamlanan.length})',
              icon: const Icon(Icons.done_all),
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
          if (aktifFiltre)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtreler: ${[
                        if (aramaMetni.isNotEmpty) '"$aramaMetni"',
                        if (seciliMarka != null) 'Marka: $seciliMarka',
                        if (baslangicTarihi != null) 'Başlangıç: ${DateFormat('dd.MM.yyyy').format(baslangicTarihi!)}',
                        if (bitisTarihi != null) 'Bitiş: ${DateFormat('dd.MM.yyyy').format(bitisTarihi!)}',
                      ].join(', ')}',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _filtreleriTemizle,
                    child: const Text('Temizle'),
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
                  filtreliBekleyen,
                  'Tedarikci onayı bekleyen model bulunmuyor.',
                ),
                _buildModelListesi(
                  filtreliOnaylanan,
                  'Onaylanmış ve üretime hazır model bulunmuyor.',
                ),
                _buildModelListesi(
                  filtreliUretimde,
                  'Üretimde olan model bulunmuyor.',
                ),
                _buildModelListesi(
                  filtreliTamamlanan,
                  'Tamamlanmış model bulunmuyor.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setupEventListener() {
    final eventBus = DashboardEventBus();
    _eventSubscription = eventBus.stream.listen((event) {
      if (event['event_type'] == 'atama_update') {
        final data = event['data'] as Map<String, dynamic>;
        // Sadece dokuma aşaması için güncelleme yap
        if (data['stage'] == 'dokuma') {
          _modelleriGetir();
          
          // Başarı mesajı göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${data['assigned_count']} model dokuma aşamasına atandı'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }

  Color _getDurumColor(String? durum) {
    switch (durum) {
      case 'atandi':
      case 'beklemede':
        return Colors.orange;
      case 'onaylandi':
      case 'uretimde':
      case 'baslatildi':
        return Colors.blue;
      case 'kismi_tamamlandi':
        return Colors.lightBlue;
      case 'tamamlandi':
        return Colors.green;
      case 'reddedildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDurumText(String? durum) {
    switch (durum) {
      case 'atandi':
        return 'Atandı';
      case 'beklemede':
        return 'Beklemede';
      case 'onaylandi':
        return 'Onaylandı';
      case 'uretimde':
        return 'Üretimde';
      case 'baslatildi':
        return 'Başlatıldı';
      case 'kismi_tamamlandi':
        return 'Kısmi Tamamlandı';
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'reddedildi':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

}
