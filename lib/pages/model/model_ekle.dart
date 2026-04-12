import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/dal_form_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/theme/app_theme.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'model_ekle_bilgiler.dart';
part 'model_ekle_fiyatlandirma.dart';
part 'model_ekle_aksesuarlar.dart';

class ModelEkle extends StatefulWidget {
  const ModelEkle({Key? key}) : super(key: key);

  @override
  State<ModelEkle> createState() => _ModelEkleState();
}

class _ModelEkleState extends State<ModelEkle> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  late String _aktifDal;
  
  bool _isLoading = false;

  // Seçilen aksesuarlar listesi
  final List<Map<String, dynamic>> _selectedAksesuarlar = [];

  // Form Controllers
  final _markaController = TextEditingController();
  final _itemNoController = TextEditingController();
  final _modelAdiController = TextEditingController();
  final _koleksiyonController = TextEditingController();
  final _iplikKarisimiController = TextEditingController();
  final _iplikMarkasiController = TextEditingController();
  final _iplikRenkKoduController = TextEditingController();
  final _iplikNumarasiController = TextEditingController();
  final _desenDetayiController = TextEditingController();
  final _renkKombinasyonuController = TextEditingController();
  final _gramajController = TextEditingController();
  final _igneNoController = TextEditingController();
  final _gaugeController = TextEditingController();
  final _teknikGramajController = TextEditingController();
  final _ozelTalimatlarController = TextEditingController();
  final _genelNotlarController = TextEditingController();

  // Fiyatlandırma Controller'ları
  final _iplikKgFiyatiController = TextEditingController();
  final _iplikMaliyetiController = TextEditingController();
  final _makinaFiyatController = TextEditingController(); // Çıkış süresi
  final _makinaDkFiyatiController = TextEditingController(); // Dk fiyatı
  final _orguFiyatController = TextEditingController();
  final _dikimFiyatController = TextEditingController();
  final _utuFiyatController = TextEditingController();
  final _yikamaFiyatController = TextEditingController();
  final _ilikDugmeFiyatController = TextEditingController();
  final _fermuarFiyatController = TextEditingController();
  final _aksesuarFiyatController = TextEditingController();
  final _genelAksesuarFiyatController = TextEditingController(); // Yeni - Genel Aksesuar için
  final _genelGiderFiyatController = TextEditingController(); // Genel Gider için
  final _karMarjiController = TextEditingController(); // Başlangıçta boş
  final _pesinFiyatController = TextEditingController();
  
  // Vade seçenekleri
  final _vadeOraniController = TextEditingController(); // Vade oranı manuel giriş
  int _selectedVade = 0; // 0=Peşin, 1-6=Vade ayları

  // Dropdown'lar yerine manuel giriş controller'ları
  final _sezonController = TextEditingController();
  final _urunKategorisiController = TextEditingController();
  final _trikoTipiController = TextEditingController();
  final _cinsiyetController = TextEditingController();
  final _yasGrubuController = TextEditingController();
  final _yakaTipiController = TextEditingController();
  final _kolTipiController = TextEditingController();
  final _anaIplikTuruController = TextEditingController();
  final _makineTipiController = TextEditingController();
  final _orguSikligiController = TextEditingController();
  final _durumController = TextEditingController();
  final _iplikKalinligiController = TextEditingController();
  final _desenTipiController = TextEditingController();

  // Date fields
  DateTime? _siparisTarihi;
  DateTime? _terminTarihi;

  // Beden dağılımı - Dinamik liste
  final List<Map<String, dynamic>> _bedenler = [
    {'beden': 'S', 'adet': 0, 'bedenController': TextEditingController(text: 'S'), 'adetController': TextEditingController()},
    {'beden': 'M', 'adet': 0, 'bedenController': TextEditingController(text: 'M'), 'adetController': TextEditingController()},
    {'beden': 'L', 'adet': 0, 'bedenController': TextEditingController(text: 'L'), 'adetController': TextEditingController()},
  ];



  @override
  void dispose() {
    _tabController.dispose();
    
    _markaController.dispose();
    _itemNoController.dispose();
    _modelAdiController.dispose();
    _koleksiyonController.dispose();
    _iplikKarisimiController.dispose();
    _iplikMarkasiController.dispose();
    _iplikRenkKoduController.dispose();
    _iplikNumarasiController.dispose();
    _desenDetayiController.dispose();
    _renkKombinasyonuController.dispose();
    _gramajController.dispose();
    _igneNoController.dispose();
    _gaugeController.dispose();
    _teknikGramajController.dispose();
    _ozelTalimatlarController.dispose();
    _genelNotlarController.dispose();
    
    // Yeni manuel giriş controller'ları
    _sezonController.dispose();
    _urunKategorisiController.dispose();
    _trikoTipiController.dispose();
    _cinsiyetController.dispose();
    _yasGrubuController.dispose();
    _yakaTipiController.dispose();
    _kolTipiController.dispose();
    _anaIplikTuruController.dispose();
    _iplikKalinligiController.dispose();
    _desenTipiController.dispose();
    _makineTipiController.dispose();
    _orguSikligiController.dispose();
    _durumController.dispose();
    
    // Fiyatlandırma controller'ları
    _iplikKgFiyatiController.dispose();
    _iplikMaliyetiController.dispose();
    _makinaFiyatController.dispose();
    _makinaDkFiyatiController.dispose();
    _orguFiyatController.dispose();
    _dikimFiyatController.dispose();
    _utuFiyatController.dispose();
    _yikamaFiyatController.dispose();
    _ilikDugmeFiyatController.dispose();
    _fermuarFiyatController.dispose();
    _aksesuarFiyatController.dispose();
    _genelAksesuarFiyatController.dispose();
    _genelGiderFiyatController.dispose();
    _karMarjiController.dispose();
    _pesinFiyatController.dispose();
    _vadeOraniController.dispose();
    
    // Beden controller'larını dispose et
    for (var beden in _bedenler) {
      beden['bedenController']?.dispose();
      beden['adetController']?.dispose();
    }
    
    super.dispose();
  }

  int _calculateTotalQuantity() {
    int total = 0;
    for (var beden in _bedenler) {
      final controller = beden['adetController'] as TextEditingController;
      if (controller.text.isNotEmpty) {
        total += int.tryParse(controller.text) ?? 0;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _aktifDal = DalFormConfig.birincilDal;
    _tabController = TabController(length: 3, vsync: this);
    
    // Fiyat hesaplama listener'ları
    _iplikKgFiyatiController.addListener(_calculateIplikMaliyeti);
    _gramajController.addListener(_calculateIplikMaliyeti);
    _makinaFiyatController.addListener(_calculateOrguFiyati);
    _makinaDkFiyatiController.addListener(_calculateOrguFiyati);
    _addCalculationListeners();
  }



  void _addCalculationListeners() {
    // Otomatik hesaplama için listener'lar ekle
    final controllers = [
      _makinaDkFiyatiController,
      _orguFiyatController,
      _dikimFiyatController,
      _utuFiyatController,
      _yikamaFiyatController,
      _ilikDugmeFiyatController,
      _fermuarFiyatController,
      _aksesuarFiyatController,
      _genelAksesuarFiyatController,
      _genelGiderFiyatController,
      _karMarjiController, // Kar marjı değişikliklerini dinle
      _vadeOraniController, // Vade oranı değişikliklerini dinle
    ];
    
    for (var controller in controllers) {
      controller.addListener(() => _calculateTotalCost());
    }
  }

  void _calculateIplikMaliyeti() {
    final kgFiyat = _parseDouble(_iplikKgFiyatiController.text) ?? 0.0;
    final gramaj = _parseDouble(_gramajController.text) ?? 0.0;
    final maliyet = (kgFiyat * gramaj) ; // kg'den gram'a çevir
    _iplikMaliyetiController.text = maliyet.toStringAsFixed(2);
    _calculateTotalCost();
  }

  void _calculateOrguFiyati() {
    final makineSure = _parseDouble(_makinaFiyatController.text) ?? 0.0;
    final makineDkFiyati = _parseDouble(_makinaDkFiyatiController.text) ?? 0.0;
    final orguFiyati = makineSure * makineDkFiyati;
    _orguFiyatController.text = orguFiyati.toStringAsFixed(2);
    _calculateTotalCost();
  }

  void _calculateTotalCost() {
    // Final fiyatı hesapla (kar marjı dahil)
    final finalPrice = _calculateFinalPrice();
    _pesinFiyatController.text = finalPrice.toStringAsFixed(2);
    setState(() {}); // UI'yi güncelle
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    // Türkçe formattaki virgülü noktaya çevir
    final String normalizedValue = value.replaceAll(',', '.');
    return double.tryParse(normalizedValue);
  }

  double _calculateFinalPrice() {
    // Kırmızı renkli alanları topla (Excel'e göre)
    double redSum = 0.0;
    
    // İplik maliyeti (otomatik hesaplanan)
    final kgFiyat = _parseDouble(_iplikKgFiyatiController.text) ?? 0.0;
    final gramaj = _parseDouble(_gramajController.text) ?? 0.0;
    final iplikMaliyeti = (kgFiyat * gramaj) ;
    redSum += iplikMaliyeti;
    
    // Örgü fiyatı (otomatik hesaplanan: makine süresi × dk fiyatı)
    final orguFiyati = _parseDouble(_orguFiyatController.text) ?? 0.0;
    redSum += orguFiyati;
    
    // Kırmızı manuel girişler - hepsini topla
    redSum += _parseDouble(_dikimFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_utuFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_yikamaFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_ilikDugmeFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_fermuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_aksesuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_genelAksesuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_genelGiderFiyatController.text) ?? 0.0;
    
    // Yeşil renkli kar marjı çarpımı (manuel yazılır)
    final karMarjiYuzde = _parseDouble(_karMarjiController.text) ?? 0.0;
    final double karMarjiCarpan = 1 + (karMarjiYuzde / 100); // %0 -> 1.00, %30 -> 1.30
    
    // Final hesaplama: Kırmızıları topla, yeşil ile çarp
    double finalPrice = redSum * karMarjiCarpan;
    
    // Vade hesaplaması - Sadece vade seçildiyse ve vade oranı girilmişse
    if (_selectedVade > 0) {
      final vadeOrani = _parseDouble(_vadeOraniController.text) ?? 0.0;
      if (vadeOrani > 0) {
        finalPrice = finalPrice * (1 + vadeOrani / 100); // %10 -> 1.10 çarpanı
      }
    }
    
    
    setState(() {}); // UI'yi güncelle
    return finalPrice;
  }

  double _getCurrentTotalCost() {
    // Kar marjı olmadan toplam maliyeti hesapla
    double redSum = 0.0;
    
    // İplik maliyeti (otomatik hesaplanan)
    final kgFiyat = _parseDouble(_iplikKgFiyatiController.text) ?? 0.0;
    final gramaj = _parseDouble(_gramajController.text) ?? 0.0;
    final iplikMaliyeti = (kgFiyat * gramaj);
    redSum += iplikMaliyeti;
    
    // Örgü fiyatı (otomatik hesaplanan: makine süresi × dk fiyatı)
    final orguFiyati = _parseDouble(_orguFiyatController.text) ?? 0.0;
    redSum += orguFiyati;
    
    // Kırmızı manuel girişler - hepsini topla
    redSum += _parseDouble(_dikimFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_utuFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_yikamaFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_ilikDugmeFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_fermuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_aksesuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_genelAksesuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_genelGiderFiyatController.text) ?? 0.0;
    
    return redSum;
  }

  Future<void> _saveModel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Beden dağılımını JSON formatına çevir
      final bedenDagilimi = <String, dynamic>{};
      for (var beden in _bedenler) {
        final bedenController = beden['bedenController'] as TextEditingController;
        final adetController = beden['adetController'] as TextEditingController;
        if (bedenController.text.isNotEmpty && adetController.text.isNotEmpty) {
          final adet = int.tryParse(adetController.text) ?? 0;
          if (adet > 0) {
            bedenDagilimi[bedenController.text.trim()] = adet;
          }
        }
      }

      final modelData = {
        'marka': _markaController.text,
        'item_no': _itemNoController.text,
        'model_adi': _modelAdiController.text,
        'sezon': _sezonController.text,
        'koleksiyon': _koleksiyonController.text,
        'urun_kategorisi': _urunKategorisiController.text,
        'triko_tipi': _trikoTipiController.text,
        'uretim_dali': _aktifDal,
        'cinsiyet': _cinsiyetController.text,
        'yas_grubu': _yasGrubuController.text,
        'yaka_tipi': _yakaTipiController.text,
        'kol_tipi': _kolTipiController.text,
        'ana_iplik_turu': _anaIplikTuruController.text,
        'iplik_karisimi': _iplikKarisimiController.text,
        'iplik_kalinligi': _iplikKalinligiController.text,
        'iplik_markasi': _iplikMarkasiController.text,
        'iplik_renk_kodu': _iplikRenkKoduController.text,
        'iplik_numarasi': _iplikNumarasiController.text,
        'desen_tipi': _desenTipiController.text,
        'desen_detayi': _desenDetayiController.text,
        'renk': _renkKombinasyonuController.text,
        'renk_kombinasyonu': _renkKombinasyonuController.text,
        'bedenler': bedenDagilimi,
        'toplam_adet': _calculateTotalQuantity(),
        'gramaj': _gramajController.text,
        'makine_tipi': _makineTipiController.text,
        'igne_no': _igneNoController.text,
        'gauge': _gaugeController.text,
        'orgu_sikligi': _orguSikligiController.text,
        'teknik_gramaj': _teknikGramajController.text,
        'siparis_tarihi': _siparisTarihi?.toIso8601String(),
        'termin_tarihi': _terminTarihi?.toIso8601String(),
        'durum': _durumController.text.isNotEmpty ? _durumController.text : 'Beklemede',
        'ozel_talimatlar': _ozelTalimatlarController.text,
        'genel_notlar': _genelNotlarController.text,
        // Fiyatlandırma verileri
        'iplik_kg_fiyati': _parseDouble(_iplikKgFiyatiController.text),
        'iplik_maliyeti': _parseDouble(_iplikMaliyetiController.text),
        'makina_cikis_suresi': _parseDouble(_makinaFiyatController.text),
        'makina_dk_fiyati': _parseDouble(_makinaDkFiyatiController.text),
        'orgu_fiyat': _parseDouble(_orguFiyatController.text),
        'dikim_fiyat': _parseDouble(_dikimFiyatController.text),
        'utu_fiyat': _parseDouble(_utuFiyatController.text),
        'yikama_fiyat': _parseDouble(_yikamaFiyatController.text),
        'ilik_dugme_fiyat': _parseDouble(_ilikDugmeFiyatController.text),
        'fermuar_fiyat': _parseDouble(_fermuarFiyatController.text),
        'aksesuar_fiyat': _parseDouble(_aksesuarFiyatController.text),
        'genel_aksesuar_fiyat': _parseDouble(_genelAksesuarFiyatController.text),
        'genel_gider_fiyat': _parseDouble(_genelGiderFiyatController.text),
        'kar_marji': _parseDouble(_karMarjiController.text),
        'pesin_fiyat': _parseDouble(_pesinFiyatController.text),
        'vade_ay': _selectedVade,
        'vade_orani': _parseDouble(_vadeOraniController.text),
      };

      // firma_id ekle
      modelData['firma_id'] = TenantManager.instance.requireFirmaId;

      // Model kaydet ve ID al
      final response = await _supabase.from(DbTables.trikoTakip).insert(modelData).select('id').single();
      final modelId = response['id'].toString();
      
      // Beden dağılımını ayrı tabloya kaydet
      if (bedenDagilimi.isNotEmpty) {
        try {
          for (final entry in bedenDagilimi.entries) {
            await _supabase.from(DbTables.modelBedenDagilimi).insert({
              'model_id': modelId,
              'beden_kodu': entry.key,
              'siparis_adedi': entry.value,
              'firma_id': TenantManager.instance.requireFirmaId,
            });
          }
          debugPrint('Beden dağılımı kaydedildi: ${bedenDagilimi.length} beden');
        } catch (e) {
          debugPrint('Beden dağılımı kayıt hatası (tablo yoksa normal): $e');
        }
      }

      // Seçilen aksesuarları model_aksesuar tablosuna kaydet
      if (_selectedAksesuarlar.isNotEmpty) {
        for (final item in _selectedAksesuarlar) {
          final aksesuar = item['aksesuar'] as Map<String, dynamic>;
          final adetPerModel = item['adet_per_model'] as int;
          try {
            // Tüm kolonlarla dene (miktar, adet_per_model varsa)
            await _supabase.from(DbTables.modelAksesuar).insert({
              'model_id': modelId,
              'aksesuar_id': aksesuar['id'].toString(),
              'miktar': 1,
              'adet_per_model': adetPerModel,
              'firma_id': TenantManager.instance.requireFirmaId,
            });
            debugPrint('✅ Aksesuar kaydedildi: ${aksesuar['ad']}');
          } catch (e) {
            debugPrint('⚠️ Ek kolonlar başarısız, sadece zorunlu kolonlarla deneniyor: $e');
            try {
              // Yalnız zorunlu kolonlarla dene
              await _supabase.from(DbTables.modelAksesuar).insert({
                'model_id': modelId,
                'aksesuar_id': aksesuar['id'].toString(),
                'firma_id': TenantManager.instance.requireFirmaId,
              });
              debugPrint('✅ Aksesuar kaydedildi (zorunlu kolonlarla): ${aksesuar['ad']}');
            } catch (e2) {
              debugPrint('❌ Model aksesuar kayıt hatası: $e2');
            }
          }
        }
        debugPrint('Model aksesuarları işlendi: ${_selectedAksesuarlar.length} aksesuar');
      }

      if (mounted) {
        context.showSuccessSnackBar('Model başarıyla kaydedildi!');
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('Hata: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DalFormConfig.modelBaslik(_aktifDal)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveModel,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2),
              text: 'Model Bilgileri',
            ),
            Tab(
              icon: Icon(Icons.attach_money),
              text: 'Fiyatlandırma',
            ),
            Tab(
              icon: Icon(Icons.category),
              text: 'Aksesuarlar',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Model Bilgileri Sekmesi
                  _buildModelBilgileriTab(),
                  // Fiyatlandırma Sekmesi
                  _buildFiyatlandirmaTab(),
                  // Aksesuarlar Sekmesi
                  _buildAksesuarlarTab(),
                ],
              ),
            ),
    );
  }

}
