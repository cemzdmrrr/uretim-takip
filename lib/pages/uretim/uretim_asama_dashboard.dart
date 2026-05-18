import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'dart:async';
import 'dart:convert';
import 'package:uretim_takip/services/dashboard_event_bus.dart';
import 'package:uretim_takip/services/atama_birlestirme_service.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/beden_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/models/beden_models.dart';
import 'package:uretim_takip/services/user_role_service.dart';
import 'package:uretim_takip/utils/role_utils.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/services/workflow_transition_service.dart';

part 'uretim_asama_dashboard_dialog.dart';
part 'uretim_asama_rapor.dart';
part 'uretim_asama_aksiyonlar.dart';

class UretimAsamaDashboard extends StatefulWidget {
  final String asamaAdi; // 'konfeksiyon', 'yikama', 'utu', vb.
  final String asamaDisplayName; // 'Konfeksiyon', 'Yıkama', 'Ütü', vb.
  final String
      atamaTablosu; // DbTables.konfeksiyonAtamalari, DbTables.yikamaAtamalari, vb.
  final String modelDurumKolonu; // 'konfeksiyon_durumu', 'yikama_durumu', vb.
  final Color asamaRengi;
  final IconData asamaIconu;
  final Widget? detayPage; // Özel detay sayfası varsa
  final int initialTabIndex;
  final String? initialSearchQuery;

  const UretimAsamaDashboard({
    Key? key,
    required this.asamaAdi,
    required this.asamaDisplayName,
    required this.atamaTablosu,
    required this.modelDurumKolonu,
    required this.asamaRengi,
    required this.asamaIconu,
    this.detayPage,
    this.initialTabIndex = 0,
    this.initialSearchQuery,
  }) : super(key: key);

  @override
  State<UretimAsamaDashboard> createState() => _UretimAsamaDashboardState();
}

class _UretimAsamaDashboardState extends State<UretimAsamaDashboard>
    with SingleTickerProviderStateMixin {
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
  final WorkflowTransitionService _workflowTransitionService =
      WorkflowTransitionService();
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  final TextEditingController _aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    final initialSearch = widget.initialSearchQuery?.trim();
    if (initialSearch != null && initialSearch.isNotEmpty) {
      aramaMetni = initialSearch;
      _aramaController.text = initialSearch;
    }
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
        if (!marka.contains(arama) &&
            !itemNo.contains(arama) &&
            !renk.contains(arama)) {
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
            if (baslangicTarihi != null &&
                atamaTarihi.isBefore(baslangicTarihi!)) {
              return false;
            }
            if (bitisTarihi != null &&
                atamaTarihi
                    .isAfter(bitisTarihi!.add(const Duration(days: 1)))) {
              return false;
            }
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
    final tumModeller = [
      ...bekleyenModeller,
      ...onaylanmisModeller,
      ...uretimdeOlanModeller,
      ...tamamlananModeller
    ];
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

  bool _rolAsamayaErisir(String? rol) {
    if (rol == null) return false;
    final normalized = RoleUtils.normalizeUserRole(rol) ?? rol;
    final asamaRolu = RoleUtils.normalizeUserRole(widget.asamaAdi);
    if (normalized == 'admin' ||
        normalized == 'firma_admin' ||
        normalized == 'firma_sahibi') {
      return true;
    }
    return {
      widget.asamaAdi,
      asamaRolu,
      '${widget.asamaAdi}_firma',
      '${widget.asamaAdi}_firmasi',
      'tedarikci_${widget.asamaAdi}',
    }.contains(normalized);
  }

  bool get _eskiAtamaSemasi => {
        DbTables.nakisAtamalari,
      }.contains(widget.atamaTablosu);

  bool get _eskiAtamaAciklamaKolonuVar =>
      widget.atamaTablosu == DbTables.nakisAtamalari;

  String get _siralamayaEsasTarihKolonu =>
      _eskiAtamaSemasi ? 'created_at' : 'atama_tarihi';

  List<String> get _atamaSelectColumns {
    if (_eskiAtamaSemasi) {
      return [
        'id',
        'model_id',
        'created_at',
        'durum',
        if (_eskiAtamaAciklamaKolonuVar) 'aciklama',
        'adet',
        'talep_edilen_adet',
        'tamamlanan_adet',
        'beden_detaylari',
        'beden_dagilimi',
        'kabul_tarihi',
        'teslim_tarihi',
        'son_guncelleme_tarihi',
        'tedarikci_id',
        'atanan_kullanici_id',
      ];
    }

    final tabloTedarikciIdVar = ![
      DbTables.paketlemeAtamalari,
      DbTables.kaliteKontrolAtamalari
    ].contains(widget.atamaTablosu);

    final tabloEkstraAlanlarVar = ![
      DbTables.paketlemeAtamalari,
      DbTables.kaliteKontrolAtamalari
    ].contains(widget.atamaTablosu);

    return [
      'id',
      'model_id',
      'atama_tarihi',
      'durum',
      'onay_tarihi',
      'red_sebebi',
      'tamamlama_tarihi',
      'notlar',
      'adet',
      'talep_edilen_adet',
      if (tabloEkstraAlanlarVar) 'kabul_edilen_adet',
      'tamamlanan_adet',
      'beden_detaylari',
      'beden_dagilimi',
      if (tabloEkstraAlanlarVar) 'uretim_baslangic_tarihi',
      if (tabloTedarikciIdVar) 'tedarikci_id',
      'atanan_kullanici_id',
    ];
  }

  String _atamaSelectFields({Set<String> excludedColumns = const {}}) {
    final columns = _atamaSelectColumns
        .where((column) => !excludedColumns.contains(column))
        .toList();
    return columns.join(',');
  }

  String? _missingColumnName(Object error) {
    if (error is! PostgrestException) return null;
    final message =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();

    final withTable = RegExp(
      r'column\s+[a-z0-9_]+\.([a-z0-9_]+)\s+does\s+not\s+exist',
    ).firstMatch(message);
    if (withTable != null) return withTable.group(1);

    final plain = RegExp(
      r'column\s+"?([a-z0-9_]+)"?\s+does\s+not\s+exist',
    ).firstMatch(message);
    return plain?.group(1);
  }

  Future<List<dynamic>> _atamaKayitlariniGetir({
    required bool tabloTedarikciIdVar,
  }) async {
    final excludedColumns = <String>{};
    var useTedarikciIdFilter = tabloTedarikciIdVar;

    for (var attempt = 0; attempt < 8; attempt++) {
      final selectFields = _atamaSelectFields(excludedColumns: excludedColumns);

      try {
        if (currentUserRole == 'admin') {
          return await supabase
              .from(widget.atamaTablosu)
              .select(selectFields)
              .order(_siralamayaEsasTarihKolonu, ascending: false);
        }

        int? kullaniciTedarikciId;
        if (useTedarikciIdFilter) {
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

        if (useTedarikciIdFilter && kullaniciTedarikciId != null) {
          return await supabase
              .from(widget.atamaTablosu)
              .select(selectFields)
              .or('atanan_kullanici_id.eq.$currentUserId,tedarikci_id.eq.$kullaniciTedarikciId')
              .order(_siralamayaEsasTarihKolonu, ascending: false);
        }

        return await supabase
            .from(widget.atamaTablosu)
            .select(selectFields)
            .eq('atanan_kullanici_id', currentUserId!)
            .order(_siralamayaEsasTarihKolonu, ascending: false);
      } catch (e) {
        final missingColumn = _missingColumnName(e);
        if (missingColumn == null) rethrow;

        if (missingColumn == 'tedarikci_id' && useTedarikciIdFilter) {
          useTedarikciIdFilter = false;
          continue;
        }

        if (_atamaSelectColumns.contains(missingColumn) &&
            !excludedColumns.contains(missingColumn)) {
          excludedColumns.add(missingColumn);
          continue;
        }

        rethrow;
      }
    }

    return const [];
  }

  Future<void> _kullaniciKontrolEt() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    try {
      // Önce user_roles tablosundan rol kontrol et
      final roller = await UserRoleService.kullaniciTumRolleriniGetir(
        userId: currentUser.id,
        firmaId: TenantManager.instance.firmaId,
      );

      String? userRole;
      if (roller.contains('admin') ||
          roller.contains('firma_admin') ||
          roller.contains('firma_sahibi')) {
        userRole = 'admin';
      } else {
        userRole = roller.firstWhere(
          _rolAsamayaErisir,
          orElse: () => '',
        );
        if (userRole.isEmpty) {
          userRole = null;
        }
      }

      // Admin veya ilgili aşama rolü değilse, tedarikçi olabilir - email ile kontrol et
      if (!_rolAsamayaErisir(userRole)) {
        final tedarikciCheck = await supabase
            .from(DbTables.tedarikciler)
            .select('id, faaliyet')
            .eq('email', currentUser.email ?? '')
            .maybeSingle();

        if (tedarikciCheck != null) {
          // Tedarikçi - ilgili aşama rolü olarak işaretle
          userRole = 'tedarikci_${widget.asamaAdi}';
          debugPrint(
              '🏢 Tedarikçi ${widget.asamaDisplayName} paneline erişiyor: ${currentUser.email}');
        }
      }

      // Hâlâ ilgili rolü yoksa, sayfa yetkisi ile erişim kontrol et
      if (!_rolAsamayaErisir(userRole)) {
        final sayfaYetkileri =
            await SayfaYetkiService.efektifSayfaYetkileriniGetir(
                currentUser.id);
        if (sayfaYetkileri
            .contains(SayfaYetkiService.normalizeSayfaKodu(widget.asamaAdi))) {
          userRole = 'admin';
          debugPrint(
              '✅ Sayfa yetkisi ile erişim sağlandı: ${currentUser.email} → ${widget.asamaAdi}');
        }
      }

      setState(() {
        currentUserRole = userRole;
        currentUserId = currentUser.id;
      });

      // Admin, ilgili aşama rolü veya tedarikçi ise modelleri getir
      if (_rolAsamayaErisir(currentUserRole)) {
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
      // Bazı tablolarda tedarikci_id yok (paketleme, kalite_kontrol vb.)
      final tabloTedarikciIdVar = !_eskiAtamaSemasi &&
          ![DbTables.paketlemeAtamalari, DbTables.kaliteKontrolAtamalari]
              .contains(widget.atamaTablosu);

      final response = await _atamaKayitlariniGetir(
        tabloTedarikciIdVar: tabloTedarikciIdVar,
      );

      // Durumlara göre ayır
      final tumModeller = List<Map<String, dynamic>>.from(response);
      await _modelBilgileriniEkle(tumModeller);

      setState(() {
        // Bekleyen: bekleyen, beklemede, atandı veya firma onay bekliyor
        bekleyenModeller = tumModeller
            .where((m) =>
                m['durum'] == 'bekleyen' ||
                m['durum'] == 'beklemede' ||
                m['durum'] == 'atandi' ||
                m['durum'] == 'firma_onay_bekliyor' ||
                m['durum'] == null)
            .toList();

        // Onaylanan: kabul edildi ama üretime başlamadı
        onaylanmisModeller = tumModeller
            .where((m) =>
                m['durum'] == 'onaylandi' || m['durum'] == 'kabul_edildi')
            .toList();

        // Üretimde: aktif olarak üretiliyor
        uretimdeOlanModeller = tumModeller
            .where((m) =>
                m['durum'] == 'uretimde' ||
                m['durum'] == 'devam_ediyor' ||
                m['durum'] == 'baslatildi' ||
                m['durum'] == 'kismi_tamamlandi')
            .toList();

        // Tamamlanan: işlem bitti
        tamamlananModeller =
            tumModeller.where((m) => m['durum'] == 'tamamlandi').toList();

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

  Future<void> _modelBilgileriniEkle(
      List<Map<String, dynamic>> atamalar) async {
    final modelIds = atamalar
        .map((atama) => atama['model_id'])
        .where((id) => id != null)
        .toSet()
        .toList();

    if (modelIds.isEmpty) return;

    try {
      final response = await supabase
          .from(DbTables.trikoTakip)
          .select(
              'id, marka, item_no, adet, bedenler, renk, termin_tarihi, created_at')
          .inFilter('id', modelIds);

      final modeller = {
        for (final model in List<Map<String, dynamic>>.from(response))
          model['id']: model,
      };

      for (final atama in atamalar) {
        atama[DbTables.trikoTakip] = modeller[atama['model_id']];
      }
    } catch (e) {
      debugPrint('Model bilgileri ayrıca yüklenemedi: $e');
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
    if (!_rolAsamayaErisir(currentUserRole)) {
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
    final tumFiltrelenmisler = [
      ...filtreliBekleyenler,
      ...filtreliOnaylananlar,
      ...filtreliUretimdekiler,
      ...filtreliTamamlananlar
    ];

    // Aktif filtre var mı?
    final aktifFiltreVar = aramaMetni.isNotEmpty ||
        seciliMarka != null ||
        baslangicTarihi != null ||
        bitisTarihi != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.asamaDisplayName} Paneli'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  _buildErpHeader(
                    bekleyen: filtreliBekleyenler.length,
                    onaylanan: filtreliOnaylananlar.length,
                    islemde: filtreliUretimdekiler.length,
                    tamamlanan: filtreliTamamlananlar.length,
                    toplam: tumFiltrelenmisler.length,
                    aktifFiltreVar: aktifFiltreVar,
                  ),
                  if (aktifFiltreVar) _buildAktifFiltreSeridi(),
                  _buildErpTabSeridi(
                    bekleyen: filtreliBekleyenler.length,
                    onaylanan: filtreliOnaylananlar.length,
                    islemde: filtreliUretimdekiler.length,
                    toplam: tumFiltrelenmisler.length,
                  ),
                  SizedBox(
                    height: constraints.maxHeight,
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
            ),
          );
        },
      ),
    );
  }
}
