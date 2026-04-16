import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/dal_form_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uretim_takip/services/model_maliyet_hesaplama_servisi.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'model_detay_utils.dart' as utils;

part 'model_detay_fiyatlandirma.dart';
part 'model_detay_aksesuar.dart';
part 'model_detay_yukleme.dart';
part 'model_detay_admin.dart';
part 'model_detay_durum.dart';
part 'model_detay_bilgiler.dart';
part 'model_detay_uretim.dart';

class ModelDetay extends StatefulWidget {
  final String modelId;
  final Map<String, dynamic>? modelData;

  const ModelDetay({
    Key? key,
    required this.modelId,
    this.modelData,
  }) : super(key: key);

  @override
  State<ModelDetay> createState() => _ModelDetayState();
}

class _ModelDetayState extends State<ModelDetay> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? currentModelData;
  final supabase = Supabase.instance.client;
  TabController? _tabController;

  /// Modelin üretim dalını modelData'dan okur, yoksa firmanın birincil dalını kullanır
  String get _modelUretimDali =>
      currentModelData?['uretim_dali'] as String? ?? DalFormConfig.birincilDal;
  
  // Üretim kayıtları
  List<dynamic> orguUretimKayitlari = [];
  List<dynamic> konfeksiyonUretimKayitlari = [];
  List<dynamic> nakisUretimKayitlari = [];
  List<dynamic> yikamaUretimKayitlari = [];
  List<dynamic> ilikDugmeUretimKayitlari = [];
  List<dynamic> utuUretimKayitlari = [];

  // Atama kayıtları
  List<dynamic> dokumaAtamalari = [];
  List<dynamic> konfeksiyonAtamalari = [];
  List<dynamic> nakisAtamalari = [];
  List<dynamic> yikamaAtamalari = [];
  List<dynamic> ilikDugmeAtamalari = [];
  List<dynamic> utuAtamalari = [];
  List<dynamic> kaliteKontrolAtamalari = [];
  List<dynamic> paketlemeAtamalari = [];

  // Aksesuar ve Yükleme verileri
  List<dynamic> modelAksesuarlari = [];
  List<dynamic> teknikDosyalar = [];
  List<dynamic> yuklemeKayitlari = [];
  
  // Düzenleme modları
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Form controller'ları (Model Bilgileri için)
  final _formKey = GlobalKey<FormState>();
  
  String? kullaniciRolu;
  String? kullaniciEmail;
  bool _isLoading = true;
  bool _hasAccess = false; // Erişim kontrolü

  @override
  void initState() {
    super.initState();
    currentModelData = widget.modelData;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _kullaniciRolunuAl();
    await _erisimKontrolYap();
    if (_hasAccess) {
      await verileriGetir();
      await _aksesuarlariGetir();
      await _teknikDosyalariGetir();
      await _yuklemeKayitlariniGetir();
      _initializeTabController();
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  // Aksesuar verilerini getir
  Future<void> _aksesuarlariGetir() async {
    try {
      // Önce model_aksesuar kayıtlarını al (join yerine ayrı sorgular)
      final modelAksesuarResponse = await supabase
          .from(DbTables.modelAksesuar)
          .select('*')
          .eq('model_id', widget.modelId);
      
      debugPrint('📦 model_aksesuar sorgusu: ${modelAksesuarResponse.length} kayıt');
      debugPrint('📦 model_aksesuar verisi: $modelAksesuarResponse');
      
      if (modelAksesuarResponse.isEmpty) {
        setState(() { modelAksesuarlari = []; });
        return;
      }
      
      // Her aksesuar için detay bilgilerini al
      final List<Map<String, dynamic>> aksesuarlarWithDetails = [];
      for (var ma in modelAksesuarResponse) {
        try {
          final aksesuarId = ma['aksesuar_id'];
          debugPrint('🔍 Aksesuar ID: $aksesuarId');
          
          if (aksesuarId != null) {
            // Aksesuar detayını al
            final aksesuarDetay = await supabase
                .from(DbTables.aksesuarlar)
                .select('*')
                .eq('id', aksesuarId)
                .maybeSingle();
            
            // Aksesuar bedenlerinden toplam stok hesapla
            int toplamStok = 0;
            List<Map<String, dynamic>> aksesuarBedenler = [];
            try {
              final bedenler = await supabase
                  .from(DbTables.aksesuarBedenler)
                  .select('beden, stok_miktari')
                  .eq('aksesuar_id', aksesuarId)
                  .eq('durum', 'aktif');
              
              if (bedenler.isNotEmpty) {
                for (var beden in bedenler) {
                  toplamStok += (beden['stok_miktari'] as int? ?? 0);
                  aksesuarBedenler.add(Map<String, dynamic>.from(beden));
                }
              }
            } catch (e) {
              debugPrint('⚠️ Beden stok hesaplama hatası: $e');
            }
            
            // Eğer beden stoku 0 ise, aksesuarlar tablosundaki miktar alanını kullan
            if (toplamStok == 0 && aksesuarDetay != null) {
              toplamStok = (aksesuarDetay['miktar'] as num?)?.toInt() ?? 0;
            }
            
            debugPrint('✅ Aksesuar detay: $aksesuarDetay');
            debugPrint('   - ad: ${aksesuarDetay?['ad']}');
            debugPrint('   - miktar (tablodan): ${aksesuarDetay?['miktar']}');
            debugPrint('   - toplam_stok (hesaplanan): $toplamStok');
            debugPrint('   - birim_fiyat: ${aksesuarDetay?['birim_fiyat']}');
            
            // Aksesuar detayına hesaplanan stoğu ve bedenleri ekle
            final Map<String, dynamic> enrichedAksesuarDetay = aksesuarDetay != null 
                ? {...Map<String, dynamic>.from(aksesuarDetay), 'toplam_stok': toplamStok, 'aksesuar_bedenler': aksesuarBedenler}
                : {'toplam_stok': toplamStok, 'aksesuar_bedenler': aksesuarBedenler};
            
            aksesuarlarWithDetails.add({
              ...Map<String, dynamic>.from(ma),
              DbTables.aksesuarlar: enrichedAksesuarDetay,
            });
          }
        } catch (e) {
          debugPrint('❌ Aksesuar detay hatası: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          modelAksesuarlari = aksesuarlarWithDetails;
        });
        debugPrint('📊 Toplam aksesuar sayısı: ${modelAksesuarlari.length}');
      }
    } catch (e) {
      debugPrint('❌ Aksesuar getirme hatası: $e');
      if (mounted) {
        setState(() {
          modelAksesuarlari = [];
        });
      }
    }
  }

  // Teknik dosyaları getir
  Future<void> _teknikDosyalariGetir() async {
    try {
      final response = await supabase
          .from(DbTables.teknikDosyalar)
          .select('*')
          .eq('model_id', widget.modelId)
          .order('created_at', ascending: false);
      
      setState(() {
        teknikDosyalar = response;
      });
    } catch (e) {
      // Teknik dosyalar getirme hatası
    }
  }

  // Yükleme kayıtlarını getir
  Future<void> _yuklemeKayitlariniGetir() async {
    try {
      final response = await supabase
          .from(DbTables.yuklemeKayitlari)
          .select('*')
          .eq('model_id', widget.modelId)
          .order('tarih', ascending: false);
      
      setState(() {
        yuklemeKayitlari = response;
      });
    } catch (e) {
      // Yükleme kayıtları getirme hatası
    }
  }

  // Erişim kontrolü - kullanıcı sadece kendine atanan modelleri görebilir
  Future<void> _erisimKontrolYap() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _hasAccess = false;
        return;
      }

      kullaniciEmail = user.email;
      
      // Admin tüm modellere erişebilir
      if (kullaniciRolu == 'admin') {
        _hasAccess = true;
        return;
      }

      // Üretim zinciri kullanıcıları sadece kendilerine atanan modellere erişebilir
      final Set<String> atanmisModelIdleri = {};
      
      // Tüm atama tablolarından bu kullanıcıya atanan model ID'lerini çek
      final fId = TenantManager.instance.requireFirmaId;
      final futures = [
        supabase.from(DbTables.dokumaAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
        supabase.from(DbTables.konfeksiyonAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
        supabase.from(DbTables.nakisAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
        supabase.from(DbTables.yikamaAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
        supabase.from(DbTables.ilikDugmeAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
        supabase.from(DbTables.utuAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
      ];
      
      final atamaResults = await Future.wait(futures.map((future) async {
        try {
          return await future;
        } catch (e) {
          return [];
        }
      }));
      
      // Tüm atanmış model ID'lerini topla
      for (var atamaList in atamaResults) {
        for (var atama in atamaList) {
          atanmisModelIdleri.add(atama['model_id']);
        }
      }
      
      // Bu model bu kullanıcıya atanmış mı?
      _hasAccess = atanmisModelIdleri.contains(widget.modelId);
      
    } catch (e) {
      _hasAccess = false;
    }
  }

  Future<void> verileriGetir() async {
    try {
      // Model verilerini getir
      final modelResponse = await supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('id', widget.modelId)
          .single();
      
      setState(() {
        currentModelData = modelResponse;
      });
      
      // Üretim kayıtlarını getir
      await _uretimKayitlariniGetir();
      
      // Atama kayıtlarını getir - sadece bu kullanıcıya ait olanları
      await _atamaKayitlariniGetir();
      
    } catch (e) {
      // Veri getirme hatası
    }
  }

  Future<void> _uretimKayitlariniGetir() async {
    try {
      final response = await supabase
          .from(DbTables.uretimKayitlari)
          .select('*')
          .eq('model_id', widget.modelId)
          .order('created_at', ascending: false);

      setState(() {
        orguUretimKayitlari = response.where((r) => r['asama'] == 'orgu' || r['asama'] == 'dokuma').toList();
        konfeksiyonUretimKayitlari = response.where((r) => r['asama'] == 'konfeksiyon').toList();
        nakisUretimKayitlari = response.where((r) => r['asama'] == 'nakis').toList();
        yikamaUretimKayitlari = response.where((r) => r['asama'] == 'yikama').toList();
        ilikDugmeUretimKayitlari = response.where((r) => r['asama'] == 'ilik_dugme').toList();
        utuUretimKayitlari = response.where((r) => r['asama'] == 'utu').toList();
      });
    } catch (e) {
      // Üretim kayıtları getirme hatası
    }
  }

  Future<void> _atamaKayitlariniGetir() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      // Admin tüm atamaları görebilir, diğerleri sadece kendilerininkileri
      final String userFilter = kullaniciRolu == 'admin' ? '' : user.id;
      
      final futures = [
        _getAtamalarForStage(DbTables.dokumaAtamalari, userFilter),
        _getAtamalarForStage(DbTables.konfeksiyonAtamalari, userFilter),
        _getAtamalarForStage(DbTables.nakisAtamalari, userFilter),
        _getAtamalarForStage(DbTables.yikamaAtamalari, userFilter),
        _getAtamalarForStage(DbTables.ilikDugmeAtamalari, userFilter),
        _getAtamalarForStage(DbTables.utuAtamalari, userFilter),
        _getAtamalarForStage(DbTables.kaliteKontrolAtamalari, userFilter),
        _getAtamalarForStage(DbTables.paketlemeAtamalari, userFilter),
      ];

      final results = await Future.wait(futures);
      
      setState(() {
        dokumaAtamalari = results[0];
        konfeksiyonAtamalari = results[1];
        nakisAtamalari = results[2];
        yikamaAtamalari = results[3];
        ilikDugmeAtamalari = results[4];
        utuAtamalari = results[5];
        kaliteKontrolAtamalari = results[6];
        paketlemeAtamalari = results[7];
      });
      
    } catch (e) {
      // Atama kayıtları getirme hatası
    }
  }

  Future<List<dynamic>> _getAtamalarForStage(String tableName, String userFilter) async {
    try {
      var query = supabase.from(tableName)
          .select('*')
          .eq('model_id', widget.modelId);
          
      // Admin değilse sadece kendi atamalarını getir
      if (userFilter.isNotEmpty && kullaniciRolu != 'admin') {
        query = query.eq('atanan_kullanici_id', userFilter);
      }
      
      return await query.order('created_at', ascending: false);
    } catch (e) {
      return [];
    }
  }

  Future<void> _kullaniciRolunuAl() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final response = await supabase
          .from(DbTables.userRoles)
          .select('role, atolye_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          kullaniciRolu = response['role'];
        });
      }
    } catch (e) {
      // Kullanıcı rolü alma hatası
    }
  }



  void _initializeTabController() {
    _tabController?.dispose();
    
    // 6 sekme: Model Bilgileri, Model Durumu, Üretim Durumu, Fiyatlandırma (admin), Aksesuarlar, Yükleme
    int tabCount = 4; // Varsayılan: Model Bilgileri, Model Durumu, Üretim Durumu, Aksesuarlar
    if (kullaniciRolu == 'admin') {
      tabCount = 6; // Admin için tüm sekmeler
    }
    
    if (mounted) {
      _tabController = TabController(length: tabCount, vsync: this);
    }
  }



  @override
  Widget build(BuildContext context) {
    final marka = currentModelData?['marka'] ?? 'Bilinmeyen Marka';
    final itemNo = currentModelData?['item_no'] ?? 'Bilinmeyen Item No';
    
    // Veriler yüklenirken loading göster
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Model Detay'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Erişim yoksa hata sayfası göster
    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erişim Engellendi'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Bu modele erişim yetkiniz yok',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Kullanıcı: ${kullaniciEmail ?? "Bilinmiyor"}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                'Rol: ${kullaniciRolu ?? "Tanımlanmamış"}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$marka - $itemNo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
              tooltip: 'İptal',
            ),
          if (kullaniciRolu == 'admin' && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Düzenle',
            ),
        ],
        bottom: _tabController == null ? null : TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(icon: Icon(Icons.info), text: 'Model Bilgileri'),
            const Tab(icon: Icon(Icons.flag), text: 'Model Durumu'),
            const Tab(icon: Icon(Icons.production_quantity_limits), text: 'Üretim Durumu'),
            if (kullaniciRolu == 'admin')
              const Tab(icon: Icon(Icons.attach_money), text: 'Fiyatlandırma'),
            const Tab(icon: Icon(Icons.category), text: 'Aksesuarlar'),
            if (kullaniciRolu == 'admin')
              const Tab(icon: Icon(Icons.upload_file), text: 'Yükleme'),
          ],
        ),
      ),
      body: _tabController == null 
        ? const LoadingWidget()
        : TabBarView(
            controller: _tabController,
            children: [
              _buildModelBilgileriTab(),
              _buildModelDurumuTab(),
              _buildUretimDurumuTab(),
              if (kullaniciRolu == 'admin')
                _buildFiyatlandirmaTab(),
              _buildAksesuarlarTab(),
              if (kullaniciRolu == 'admin')
                _buildYuklemeTab(),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
