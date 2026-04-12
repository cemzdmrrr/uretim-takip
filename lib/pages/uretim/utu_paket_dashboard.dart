import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/dashboard_event_bus.dart';
import 'package:uretim_takip/utils/app_exceptions.dart';

part 'utu_paket_ceki.dart';
part 'utu_paket_aksiyonlar.dart';
part 'utu_paket_paketleme.dart';
part 'utu_paket_ceki_islemleri.dart';
part 'utu_paket_dialoglar.dart';

class UtuPaketDashboard extends StatefulWidget {
  const UtuPaketDashboard({Key? key}) : super(key: key);

  @override
  State<UtuPaketDashboard> createState() => _UtuPaketDashboardState();
}

class _UtuPaketDashboardState extends State<UtuPaketDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Ütü atamaları
  List<Map<String, dynamic>> utuBekleyenler = [];
  List<Map<String, dynamic>> utuOnaylananlar = [];
  List<Map<String, dynamic>> utuUretimde = [];
  List<Map<String, dynamic>> utuTamamlananlar = [];

  // Paketleme atamaları
  List<Map<String, dynamic>> paketBekleyenler = [];
  List<Map<String, dynamic>> paketOnaylananlar = [];
  List<Map<String, dynamic>> paketUretimde = [];
  List<Map<String, dynamic>> paketTamamlananlar = [];

  // Çeki listesi
  List<Map<String, dynamic>> cekiListesi = [];

  bool yukleniyor = true;
  String? currentUserRole;
  String? currentUserId;

  // Alt tab seçimi (0: Ütü, 1: Paketleme, 2: Çeki)
  int secilenAnaTab = 0;

  // Her bölüm için durum tab seçimi
  int utuDurumTab = 0;
  int paketDurumTab = 0;

  // Filtreleme
  String aramaMetni = '';
  String? seciliMarka;
  List<String> markalar = [];

  final supabase = Supabase.instance.client;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  // Supabase Realtime Subscriptions
  RealtimeChannel? _utuChannel;
  RealtimeChannel? _paketChannel;
  RealtimeChannel? _cekiChannel;

  final TextEditingController _aramaController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => secilenAnaTab = _tabController.index);
      }
    });
    _setupEventListener();
    // Veri yüklemeyi başlat
    _baslat();
  }

  // Başlangıç fonksiyonu - tüm async işlemleri yönetir
  Future<void> _baslat() async {
    try {
      await _kullaniciKontrolEt();
    } catch (e) {
      debugPrint('❌ Başlatma hatası: $e');
    }
  }

  // Gelişmiş raporlar için model hesaplamalarını güncelle
  Future<void> _guncelleGelismisRaporlar(String modelId) async {
    try {
      // Yükleme kayıtlarını topla
      final yukleme = await supabase
          .from(DbTables.yuklemeKayitlari)
          .select('adet')
          .eq('model_id', modelId);
      
      int toplamYuklenen = 0;
      for (var kayit in yukleme) {
        toplamYuklenen += (kayit['adet'] as num?)?.toInt() ?? 0;
      }

      // Model verilerini getir
      final modelData = await supabase
          .from(DbTables.trikoTakip)
          .select('toplam_adet, adet')
          .eq('id', modelId)
          .single();
      
      final modelAdet = (modelData['toplam_adet'] ?? modelData['adet'] ?? 0) as num;
      final kalanAdet = modelAdet.toInt() - toplamYuklenen;
      
      // triko_takip tablosunu güncelle
      await supabase.from(DbTables.trikoTakip).update({
        'yuklenen_adet': toplamYuklenen,
        'kalan_adet': kalanAdet > 0 ? kalanAdet : 0,
      }).eq('id', modelId);
      
      debugPrint('📊 Model raporları güncellendi - Yüklenen: $toplamYuklenen, Kalan: $kalanAdet');
    } catch (e) {
      debugPrint('⚠️ Rapor güncelleme hatası: $e');
      // Hata olsa da devam et
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventSubscription?.cancel();
    _aramaController.dispose();
    // Realtime subscriptions'ı kapat
    _utuChannel?.unsubscribe();
    _paketChannel?.unsubscribe();
    _cekiChannel?.unsubscribe();
    super.dispose();
  }

  void _setupEventListener() {
    _eventSubscription = DashboardEventBus().stream.listen((event) {
      if (event['type'] == 'refresh' ||
          event['asama'] == 'utu' ||
          event['asama'] == 'paketleme') {
        _verileriYukle();
      }
    });
  }

  // ===== SUPABASE REALTIME SUBSCRIPTION =====
  void _setupRealtimeSubscription() {
    try {
      // Önce mevcut channel'ları kapat
      _utuChannel?.unsubscribe();
      _paketChannel?.unsubscribe();
      _cekiChannel?.unsubscribe();

      // Benzersiz channel isimleri kullan
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Ütü atamaları realtime
      _utuChannel = supabase
          .channel('utu_channel_$timestamp')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: DbTables.utuAtamalari,
            callback: (payload) {
              debugPrint('🔄 Ütü ataması değişikliği: ${payload.eventType}');
              if (mounted) _verileriYukle();
            },
          )
          .subscribe();
      debugPrint('✅ Ütü atamaları realtime subscription başlatıldı');

      // Paketleme atamaları realtime
      _paketChannel = supabase
          .channel('paket_channel_$timestamp')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: DbTables.paketlemeAtamalari,
            callback: (payload) {
              debugPrint(
                  '🔄 Paketleme ataması değişikliği: ${payload.eventType}');
              if (mounted) _verileriYukle();
            },
          )
          .subscribe();
      debugPrint('✅ Paketleme atamaları realtime subscription başlatıldı');

      // Çeki listesi realtime
      _cekiChannel = supabase
          .channel('ceki_channel_$timestamp')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: DbTables.cekiListesi,
            callback: (payload) {
              debugPrint('🔄 Çeki listesi değişikliği: ${payload.eventType}');
              if (mounted) _verileriYukle();
            },
          )
          .subscribe();
      debugPrint('✅ Çeki listesi realtime subscription başlatıldı');
    } catch (e) {
      debugPrint('❌ Realtime subscription hatası: $e');
    }
  }

  Future<void> _kullaniciKontrolEt() async {
    if (!mounted) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }

      currentUserId = user.id;

      // Kullanıcı rolünü firma_kullanicilari tablosundan al
      try {
        final response = await supabase
            .from(DbTables.firmaKullanicilari)
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          currentUserRole = response['role'];
        }
      } catch (e) {
        debugPrint('⚠️ Rol bilgisi alınamadı: $e');
        // Rol bilgisi alınamazsa devam et
      }

      // Verileri yükle
      await _verileriYukle();

      // Veriler yüklendikten sonra realtime'ı başlat
      if (mounted) {
        _setupRealtimeSubscription();
      }
    } catch (e) {
      debugPrint('❌ Kullanıcı kontrolü hatası: $e');
      if (mounted) {
        setState(() => yukleniyor = false);
      }
    }
  }

  Future<void> _verileriYukle() async {
    if (!mounted) return;

    setState(() => yukleniyor = true);

    try {
      debugPrint('🔄 Veriler yükleniyor...');

      // Tüm verileri paralel yükle
      await Future.wait([
        _utuAtamalariniYukle(),
        _paketlemeAtamalariniYukle(),
        _cekiListesiniYukle(),
      ]);

      // Markaları topla
      _markalariTopla();

      debugPrint('✅ Tüm veriler yüklendi');

      // UI'ı güncelle
      if (mounted) {
        setState(() {
          yukleniyor = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Veriler yüklenirken hata: $e');
      if (mounted) {
        setState(() => yukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Veriler yüklenirken hata: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _utuAtamalariniYukle() async {
    try {
      debugPrint('🔄 Ütü atamaları yükleniyor...');

      final response = await supabase.from(DbTables.utuAtamalari).select('''
        id, model_id, atama_tarihi, durum, notlar, adet, onay_tarihi, red_sebebi,
        talep_edilen_adet, kabul_edilen_adet, tamamlanan_adet, tamamlama_tarihi,
        tedarikci_id, atanan_kullanici_id,
        triko_takip(id, marka, item_no, adet, bedenler, renk, termin_tarihi, created_at)
      ''').eq('firma_id', TenantManager.instance.requireFirmaId).order('atama_tarihi', ascending: false);

      final liste = List<Map<String, dynamic>>.from(response);

      // Bekleyen: bekleyen, atandi, beklemede, null
      utuBekleyenler = liste
          .where((a) =>
              a['durum'] == 'bekleyen' ||
              a['durum'] == 'atandi' ||
              a['durum'] == 'beklemede' ||
              a['durum'] == null)
          .toList();

      utuOnaylananlar = liste
          .where(
              (a) => a['durum'] == 'onaylandi' || a['durum'] == 'kabul_edildi')
          .toList();

      utuUretimde = liste
          .where((a) =>
              a['durum'] == 'devam_ediyor' ||
              a['durum'] == 'uretimde' ||
              a['durum'] == 'baslatildi' ||
              a['durum'] == 'kismi_tamamlandi')
          .toList();

      utuTamamlananlar =
          liste.where((a) => a['durum'] == 'tamamlandi').toList();

      debugPrint(
          '✅ Ütü yüklendi - Bekleyen: ${utuBekleyenler.length}, Onaylanan: ${utuOnaylananlar.length}, Üretimde: ${utuUretimde.length}, Tamamlanan: ${utuTamamlananlar.length}');
    } catch (e) {
      debugPrint('❌ Ütü atamaları yüklenirken hata: $e');
      rethrow; // Hatayı üst fonksiyona ilet
    }
  }

  Future<void> _paketlemeAtamalariniYukle() async {
    try {
      debugPrint('🔄 Paketleme atamaları yükleniyor...');

      final response = await supabase.from(DbTables.paketlemeAtamalari).select('''
        id, model_id, atama_tarihi, durum, notlar, adet, onay_tarihi, red_sebebi,
        talep_edilen_adet, tamamlanan_adet, tamamlama_tarihi,
        atanan_kullanici_id,
        triko_takip(id, marka, item_no, adet, bedenler, renk, termin_tarihi, created_at)
      ''').eq('firma_id', TenantManager.instance.requireFirmaId).order('atama_tarihi', ascending: false);

      final liste = List<Map<String, dynamic>>.from(response);

      // Bekleyen: bekleyen, atandi, beklemede, null
      paketBekleyenler = liste
          .where((a) =>
              a['durum'] == 'bekleyen' ||
              a['durum'] == 'atandi' ||
              a['durum'] == 'beklemede' ||
              a['durum'] == null)
          .toList();

      paketOnaylananlar = liste
          .where(
              (a) => a['durum'] == 'onaylandi' || a['durum'] == 'kabul_edildi')
          .toList();

      paketUretimde = liste
          .where((a) =>
              a['durum'] == 'devam_ediyor' ||
              a['durum'] == 'uretimde' ||
              a['durum'] == 'baslatildi' ||
              a['durum'] == 'kismi_tamamlandi')
          .toList();

      paketTamamlananlar =
          liste.where((a) => a['durum'] == 'tamamlandi').toList();

      debugPrint(
          '✅ Paketleme yüklendi - Bekleyen: ${paketBekleyenler.length}, Onaylanan: ${paketOnaylananlar.length}, Üretimde: ${paketUretimde.length}, Tamamlanan: ${paketTamamlananlar.length}');
    } catch (e) {
      debugPrint('❌ Paketleme atamaları yüklenirken hata: $e');
      rethrow; // Hatayı üst fonksiyona ilet
    }
  }

  Future<void> _cekiListesiniYukle() async {
    try {
      debugPrint('🔄 Çeki listesi yükleniyor...');

      try {
        final response = await supabase.from(DbTables.cekiListesi).select('''
          id, model_id, koli_no, koli_adedi, adet, paketleme_tarihi, 
          gonderim_durumu, gonderim_tarihi, alici_bilgisi, kargo_firmasi, takip_no, notlar, created_at,
          beden_kodu, adet_per_koli, is_mix_koli, mix_beden_detay,
          triko_takip(id, marka, item_no, adet, bedenler, renk)
        ''').eq('firma_id', TenantManager.instance.requireFirmaId).order('created_at', ascending: false);
        cekiListesi = List<Map<String, dynamic>>.from(response);
        debugPrint('✅ Çeki listesi yüklendi: ${cekiListesi.length} kayıt');
      } catch (e) {
        debugPrint('⚠️ Çeki tablosu hatası: $e');
        // Tablo yoksa veya hata varsa boş liste
        cekiListesi = [];
      }
    } catch (e) {
      debugPrint('❌ Çeki listesi yüklenirken hata: $e');
      cekiListesi = [];
      rethrow; // Hatayı üst fonksiyona ilet
    }
  }

  void _markalariTopla() {
    final tumAtamalar = [
      ...utuBekleyenler,
      ...utuOnaylananlar,
      ...utuUretimde,
      ...utuTamamlananlar,
      ...paketBekleyenler,
      ...paketOnaylananlar,
      ...paketUretimde,
      ...paketTamamlananlar
    ];
    final markaSet = <String>{};
    for (var atama in tumAtamalar) {
      final model = atama[DbTables.trikoTakip];
      if (model != null && model['marka'] != null) {
        markaSet.add(model['marka'].toString());
      }
    }
    markalar = markaSet.toList()..sort();
  }

  List<Map<String, dynamic>> _filtreleListe(List<Map<String, dynamic>> liste) {
    return liste.where((atama) {
      final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
      if (model == null) return false;

      if (aramaMetni.isNotEmpty) {
        final marka = (model['marka'] ?? '').toString().toLowerCase();
        final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
        final renk = (model['renk'] ?? '').toString().toLowerCase();
        final arama = aramaMetni.toLowerCase();
        if (!marka.contains(arama) &&
            !itemNo.contains(arama) &&
            !renk.contains(arama)) {
          return false;
        }
      }

      if (seciliMarka != null && seciliMarka!.isNotEmpty) {
        if (model['marka'] != seciliMarka) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ütü Paket Paneli'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(
              icon: Icon(Icons.all_inbox),
              text: 'Ütü Paket',
            ),
            Tab(
              icon: const Icon(Icons.list_alt),
              text: 'Çeki Listesi (${cekiListesi.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Ara',
            onPressed: _aramaDialoguGoster,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrele',
            onPressed: _filtreDialoguGoster,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Rapor',
            onPressed: _raporDialoguGoster,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _verileriYukle,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUtuPaketPanel(),
                _buildCekiListesiPanel(),
              ],
            ),
      floatingActionButton:
          secilenAnaTab == 1 // Çeki listesi sekmesindeyse butonu göster
              ? FloatingActionButton.extended(
                  onPressed: _yeniCekiEkle,
                  backgroundColor: Colors.amber[700],
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Çeki'),
                )
              : null,
    );
  }

  Widget _buildUtuPaketPanel() {
    // Alt tab: Bekleyen, Onaylanan, İşlemde, Tamamlanan
    final int durumTab = utuDurumTab; // eski değişkeni kullanıyoruz
    return Column(
      children: [
        Container(
          color: Colors.amber[50],
          child: Row(
            children: [
              _buildDurumTab(
                  'Bekleyen',
                  utuBekleyenler.length + paketBekleyenler.length,
                  0,
                  durumTab,
                  (i) => setState(() => utuDurumTab = i),
                  Icons.hourglass_empty,
                  Colors.orange),
              _buildDurumTab(
                  'Onaylanan',
                  utuOnaylananlar.length + paketOnaylananlar.length,
                  1,
                  durumTab,
                  (i) => setState(() => utuDurumTab = i),
                  Icons.check_circle,
                  Colors.green),
              _buildDurumTab(
                  'İşlemde',
                  utuUretimde.length + paketUretimde.length,
                  2,
                  durumTab,
                  (i) => setState(() => utuDurumTab = i),
                  Icons.play_circle,
                  Colors.blue),
              _buildDurumTab(
                  'Tamamlanan',
                  utuTamamlananlar.length + paketTamamlananlar.length,
                  3,
                  durumTab,
                  (i) => setState(() => utuDurumTab = i),
                  Icons.done_all,
                  Colors.grey),
            ],
          ),
        ),
        Expanded(
          child: _buildUtuPaketTabContent(durumTab),
        ),
      ],
    );
  }

  Widget _buildUtuPaketTabContent(int tabIndex) {
    // Tüm ütü ve paketleme atamalarını birleştir
    List<Map<String, dynamic>> list = [];
    if (tabIndex == 0) {
      list = [
        ..._filtreleListe(utuBekleyenler),
        ..._filtreleListe(paketBekleyenler)
      ];
    } else if (tabIndex == 1) {
      list = [
        ..._filtreleListe(utuOnaylananlar),
        ..._filtreleListe(paketOnaylananlar)
      ];
    } else if (tabIndex == 2) {
      list = [..._filtreleListe(utuUretimde), ..._filtreleListe(paketUretimde)];
    } else if (tabIndex == 3) {
      list = [
        ..._filtreleListe(utuTamamlananlar),
        ..._filtreleListe(paketTamamlananlar)
      ];
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Kayıt yok', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Text(
              'Ütü: ${utuBekleyenler.length + utuOnaylananlar.length + utuUretimde.length + utuTamamlananlar.length} | '
              'Paket: ${paketBekleyenler.length + paketOnaylananlar.length + paketUretimde.length + paketTamamlananlar.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final atama = list[i];
        final tip = atama.containsKey('tedarikci_id') ? 'utu' : 'paketleme';
        return _buildAtamaKarti(atama, tip);
      },
    );
  }



  Widget _buildDurumTab(String baslik, int sayi, int index, int secilenIndex,
      Function(int) onTap, IconData icon, Color renk) {
    final secili = index == secilenIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: secili ? renk : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: secili ? renk : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(
                '$baslik ($sayi)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: secili ? FontWeight.bold : FontWeight.normal,
                  color: secili ? renk : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }




}
