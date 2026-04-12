import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/dal_form_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/theme/app_theme.dart';

part 'model_duzenle_bilgiler.dart';
part 'model_duzenle_fiyatlandirma.dart';

class ModelDuzenlePage extends StatefulWidget {
  final String modelId;
  final Map<String, dynamic>? modelData;

  const ModelDuzenlePage({
    super.key,
    required this.modelId,
    this.modelData,
  });

  @override
  State<ModelDuzenlePage> createState() => _ModelDuzenlePageState();
}

class _ModelDuzenlePageState extends State<ModelDuzenlePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  late String _aktifDal;
  bool _isLoading = false;

  // Temel Bilgiler
  late TextEditingController _markaController;
  late TextEditingController _itemNoController;
  late TextEditingController _modelAdiController;
  late TextEditingController _sezonController;

  // Ürün Detayları
  late TextEditingController _urunKategorisiController;
  late TextEditingController _trikoTipiController;
  late TextEditingController _cinsiyetController;
  late TextEditingController _yakaTipiController;

  // İplik ve Materyal
  late TextEditingController _anaIplikTuruController;
  late TextEditingController _iplikKarisimiController;
  late TextEditingController _iplikMarkasiController;
  late TextEditingController _iplikRenkKoduController;
  late TextEditingController _iplikNumarasiController;

  // Renk ve Desen
  late TextEditingController _desenTipiController;
  late TextEditingController _desenDetayiController;
  late TextEditingController _renkKombinasyonuController;

  // Ölçü
  late TextEditingController _gramajController;

  // Teknik Örgü
  late TextEditingController _makineTipiController;
  late TextEditingController _igneNoController;
  late TextEditingController _gaugeController;
  late TextEditingController _orguSikligiController;
  late TextEditingController _teknikGramajController;

  // Tarihler
  DateTime? _siparisTarihi;
  DateTime? _terminTarihi;
  late TextEditingController _durumController;

  // Notlar
  late TextEditingController _ozelTalimatlarController;
  late TextEditingController _genelNotlarController;

  // Fiyatlandırma Controller'ları
  late TextEditingController _iplikKgFiyatiController;
  late TextEditingController _iplikMaliyetiController;
  late TextEditingController _makinaFiyatController;
  late TextEditingController _makinaDkFiyatiController;
  late TextEditingController _orguFiyatController;
  late TextEditingController _dikimFiyatController;
  late TextEditingController _utuFiyatController;
  late TextEditingController _yikamaFiyatController;
  late TextEditingController _ilikDugmeFiyatController;
  late TextEditingController _fermuarFiyatController;
  late TextEditingController _aksesuarFiyatController;
  late TextEditingController _genelAksesuarFiyatController;
  late TextEditingController _genelGiderFiyatController;
  late TextEditingController _karMarjiController;
  late TextEditingController _pesinFiyatController;
  late TextEditingController _vadeOraniController;
  int _selectedVade = 0;

  // Beden dağılımı - Dinamik liste
  final List<Map<String, dynamic>> _bedenler = [];

  @override
  void initState() {
    super.initState();
    final data = widget.modelData ?? {};
    _aktifDal = data['uretim_dali']?.toString() ?? DalFormConfig.birincilDal;
    _tabController = TabController(length: 2, vsync: this);

    // Temel Bilgiler
    _markaController = TextEditingController(text: data['marka']?.toString() ?? '');
    _itemNoController = TextEditingController(text: data['item_no']?.toString() ?? '');
    _modelAdiController = TextEditingController(text: data['model_adi']?.toString() ?? '');
    _sezonController = TextEditingController(text: data['sezon']?.toString() ?? '');

    // Ürün Detayları
    _urunKategorisiController = TextEditingController(text: data['urun_kategorisi']?.toString() ?? '');
    _trikoTipiController = TextEditingController(text: data['triko_tipi']?.toString() ?? '');
    _cinsiyetController = TextEditingController(text: data['cinsiyet']?.toString() ?? '');
    _yakaTipiController = TextEditingController(text: data['yaka_tipi']?.toString() ?? '');

    // İplik ve Materyal
    _anaIplikTuruController = TextEditingController(text: data['ana_iplik_turu']?.toString() ?? '');
    _iplikKarisimiController = TextEditingController(text: data['iplik_karisimi']?.toString() ?? '');
    _iplikMarkasiController = TextEditingController(text: data['iplik_markasi']?.toString() ?? '');
    _iplikRenkKoduController = TextEditingController(text: data['iplik_renk_kodu']?.toString() ?? '');
    _iplikNumarasiController = TextEditingController(text: data['iplik_numarasi']?.toString() ?? '');

    // Renk ve Desen
    _desenTipiController = TextEditingController(text: data['desen_tipi']?.toString() ?? '');
    _desenDetayiController = TextEditingController(text: data['desen_detayi']?.toString() ?? '');
    _renkKombinasyonuController = TextEditingController(text: data['renk_kombinasyonu']?.toString() ?? '');

    // Ölçü
    _gramajController = TextEditingController(text: data['gramaj']?.toString() ?? '');

    // Teknik Örgü
    _makineTipiController = TextEditingController(text: data['makine_tipi']?.toString() ?? '');
    _igneNoController = TextEditingController(text: data['igne_no']?.toString() ?? '');
    _gaugeController = TextEditingController(text: data['gauge']?.toString() ?? '');
    _orguSikligiController = TextEditingController(text: data['orgu_sikligi']?.toString() ?? '');
    _teknikGramajController = TextEditingController(text: data['teknik_gramaj']?.toString() ?? '');

    // Tarihler
    if (data['siparis_tarihi'] != null) {
      _siparisTarihi = DateTime.tryParse(data['siparis_tarihi'].toString());
    }
    if (data['termin_tarihi'] != null) {
      _terminTarihi = DateTime.tryParse(data['termin_tarihi'].toString());
    }
    _durumController = TextEditingController(text: data['durum']?.toString() ?? '');

    // Notlar
    _ozelTalimatlarController = TextEditingController(text: data['ozel_talimatlar']?.toString() ?? '');
    _genelNotlarController = TextEditingController(text: data['genel_notlar']?.toString() ?? '');

    // Fiyatlandırma
    _iplikKgFiyatiController = TextEditingController(text: _formatDouble(data['iplik_kg_fiyati']));
    _iplikMaliyetiController = TextEditingController(text: _formatDouble(data['iplik_maliyeti']));
    _makinaFiyatController = TextEditingController(text: _formatDouble(data['makina_cikis_suresi']));
    _makinaDkFiyatiController = TextEditingController(text: _formatDouble(data['makina_dk_fiyati']));
    _orguFiyatController = TextEditingController(text: _formatDouble(data['orgu_fiyat']));
    _dikimFiyatController = TextEditingController(text: _formatDouble(data['dikim_fiyat']));
    _utuFiyatController = TextEditingController(text: _formatDouble(data['utu_fiyat']));
    _yikamaFiyatController = TextEditingController(text: _formatDouble(data['yikama_fiyat']));
    _ilikDugmeFiyatController = TextEditingController(text: _formatDouble(data['ilik_dugme_fiyat']));
    _fermuarFiyatController = TextEditingController(text: _formatDouble(data['fermuar_fiyat']));
    _aksesuarFiyatController = TextEditingController(text: _formatDouble(data['aksesuar_fiyat']));
    _genelAksesuarFiyatController = TextEditingController(text: _formatDouble(data['genel_aksesuar_fiyat']));
    _genelGiderFiyatController = TextEditingController(text: _formatDouble(data['genel_gider_fiyat']));
    _karMarjiController = TextEditingController(text: _formatDouble(data['kar_marji']));
    _pesinFiyatController = TextEditingController(text: _formatDouble(data['pesin_fiyat']));
    _selectedVade = (data['vade_ay'] is int) ? data['vade_ay'] : (int.tryParse(data['vade_ay']?.toString() ?? '') ?? 0);
    _vadeOraniController = TextEditingController(text: _formatDouble(data['vade_orani']));

    // Beden dağılımını yükle
    _loadBedenDagilimi(data);

    // Fiyat hesaplama listener'ları
    _iplikKgFiyatiController.addListener(_calculateIplikMaliyeti);
    _gramajController.addListener(_calculateIplikMaliyeti);
    _makinaFiyatController.addListener(_calculateOrguFiyati);
    _makinaDkFiyatiController.addListener(_calculateOrguFiyati);
    _addCalculationListeners();
  }

  String _formatDouble(dynamic value) {
    if (value == null) return '';
    if (value is double) return value != 0 ? value.toStringAsFixed(2) : '';
    if (value is int) return value != 0 ? value.toDouble().toStringAsFixed(2) : '';
    final d = double.tryParse(value.toString());
    return d != null && d != 0 ? d.toStringAsFixed(2) : '';
  }

  void _loadBedenDagilimi(Map<String, dynamic> data) {
    if (data['bedenler'] != null) {
      try {
        if (data['bedenler'] is Map) {
          final Map<String, dynamic> bedenMap = Map<String, dynamic>.from(data['bedenler']);
          for (final entry in bedenMap.entries) {
            _bedenler.add({
              'beden': entry.key,
              'adet': entry.value,
              'bedenController': TextEditingController(text: entry.key),
              'adetController': TextEditingController(text: entry.value.toString()),
            });
          }
        }
      } catch (e) {
        debugPrint('Beden dağılımı yükleme hatası: $e');
      }
    }
    if (_bedenler.isEmpty) {
      _bedenler.add({
        'beden': '',
        'adet': 0,
        'bedenController': TextEditingController(),
        'adetController': TextEditingController(),
      });
    }
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

  void _addCalculationListeners() {
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
      _karMarjiController,
      _vadeOraniController,
    ];
    for (var controller in controllers) {
      controller.addListener(() => _calculateTotalCost());
    }
  }

  void _calculateIplikMaliyeti() {
    final kgFiyat = _parseDouble(_iplikKgFiyatiController.text) ?? 0.0;
    final gramaj = _parseDouble(_gramajController.text) ?? 0.0;
    final maliyet = kgFiyat * gramaj;
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
    final finalPrice = _calculateFinalPrice();
    _pesinFiyatController.text = finalPrice.toStringAsFixed(2);
    setState(() {});
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    final String normalizedValue = value.replaceAll(',', '.');
    return double.tryParse(normalizedValue);
  }

  double _calculateFinalPrice() {
    double redSum = 0.0;

    final kgFiyat = _parseDouble(_iplikKgFiyatiController.text) ?? 0.0;
    final gramaj = _parseDouble(_gramajController.text) ?? 0.0;
    final iplikMaliyeti = kgFiyat * gramaj;
    redSum += iplikMaliyeti;

    final orguFiyati = _parseDouble(_orguFiyatController.text) ?? 0.0;
    redSum += orguFiyati;

    redSum += _parseDouble(_dikimFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_utuFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_yikamaFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_ilikDugmeFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_fermuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_aksesuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_genelAksesuarFiyatController.text) ?? 0.0;
    redSum += _parseDouble(_genelGiderFiyatController.text) ?? 0.0;

    final karMarjiYuzde = _parseDouble(_karMarjiController.text) ?? 0.0;
    final double karMarjiCarpan = 1 + (karMarjiYuzde / 100);

    double finalPrice = redSum * karMarjiCarpan;

    if (_selectedVade > 0) {
      final vadeOrani = _parseDouble(_vadeOraniController.text) ?? 0.0;
      if (vadeOrani > 0) {
        finalPrice = finalPrice * (1 + vadeOrani / 100);
      }
    }

    setState(() {});
    return finalPrice;
  }

  double _getCurrentTotalCost() {
    double redSum = 0.0;

    final kgFiyat = _parseDouble(_iplikKgFiyatiController.text) ?? 0.0;
    final gramaj = _parseDouble(_gramajController.text) ?? 0.0;
    final iplikMaliyeti = kgFiyat * gramaj;
    redSum += iplikMaliyeti;

    final orguFiyati = _parseDouble(_orguFiyatController.text) ?? 0.0;
    redSum += orguFiyati;

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

  Future<void> _guncelleModel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Beden dağılımını Map formatına dönüştür
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

      await _supabase.from(DbTables.trikoTakip).update({
        'marka': _markaController.text.trim(),
        'item_no': _itemNoController.text.trim(),
        'model_adi': _modelAdiController.text.trim(),
        'sezon': _sezonController.text.trim(),
        'urun_kategorisi': _urunKategorisiController.text.trim(),
        'triko_tipi': _trikoTipiController.text.trim(),
        'cinsiyet': _cinsiyetController.text.trim(),
        'yaka_tipi': _yakaTipiController.text.trim(),
        'ana_iplik_turu': _anaIplikTuruController.text.trim(),
        'iplik_karisimi': _iplikKarisimiController.text.trim(),
        'iplik_markasi': _iplikMarkasiController.text.trim(),
        'iplik_renk_kodu': _iplikRenkKoduController.text.trim(),
        'iplik_numarasi': _iplikNumarasiController.text.trim(),
        'desen_tipi': _desenTipiController.text.trim(),
        'desen_detayi': _desenDetayiController.text.trim(),
        'renk': _renkKombinasyonuController.text.trim(),
        'renk_kombinasyonu': _renkKombinasyonuController.text.trim(),
        'bedenler': bedenDagilimi,
        'toplam_adet': _calculateTotalQuantity(),
        'gramaj': _gramajController.text.trim(),
        'makine_tipi': _makineTipiController.text.trim(),
        'igne_no': _igneNoController.text.trim(),
        'gauge': _gaugeController.text.trim(),
        'orgu_sikligi': _orguSikligiController.text.trim(),
        'teknik_gramaj': _teknikGramajController.text.trim(),
        'siparis_tarihi': _siparisTarihi?.toIso8601String(),
        'termin_tarihi': _terminTarihi?.toIso8601String(),
        'durum': _durumController.text.trim(),
        'ozel_talimatlar': _ozelTalimatlarController.text.trim(),
        'genel_notlar': _genelNotlarController.text.trim(),
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
      }).eq('id', widget.modelId);

      if (mounted) {
        Navigator.pop(context, true);
        context.showSnackBar('Model başarıyla güncellendi');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Hata: $e');
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
        title: const Text('Model Bilgilerini Düzenle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _guncelleModel,
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
                  _buildModelBilgileriTab(),
                  _buildFiyatlandirmaTab(),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();

    // Temel Bilgiler
    _markaController.dispose();
    _itemNoController.dispose();
    _modelAdiController.dispose();
    _sezonController.dispose();

    // Ürün Detayları
    _urunKategorisiController.dispose();
    _trikoTipiController.dispose();
    _cinsiyetController.dispose();
    _yakaTipiController.dispose();

    // İplik ve Materyal
    _anaIplikTuruController.dispose();
    _iplikKarisimiController.dispose();
    _iplikMarkasiController.dispose();
    _iplikRenkKoduController.dispose();
    _iplikNumarasiController.dispose();

    // Renk ve Desen
    _desenTipiController.dispose();
    _desenDetayiController.dispose();
    _renkKombinasyonuController.dispose();

    // Ölçü
    _gramajController.dispose();

    // Teknik Örgü
    _makineTipiController.dispose();
    _igneNoController.dispose();
    _gaugeController.dispose();
    _orguSikligiController.dispose();
    _teknikGramajController.dispose();

    // Tarihler ve Durum
    _durumController.dispose();

    // Notlar
    _ozelTalimatlarController.dispose();
    _genelNotlarController.dispose();

    // Fiyatlandırma
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
}
