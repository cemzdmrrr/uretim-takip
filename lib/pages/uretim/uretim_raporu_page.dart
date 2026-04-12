import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/uretim_raporu_service.dart';
import 'package:uretim_takip/pages/model/model_detay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:uretim_takip/utils/web_download.dart';

part 'uretim_raporu_filtreler.dart';
part 'uretim_raporu_tabs.dart';
part 'uretim_raporu_charts.dart';
part 'uretim_raporu_kpi.dart';
part 'uretim_raporu_export.dart';

class UretimRaporuPage extends StatefulWidget {
  const UretimRaporuPage({super.key});

  @override
  State<UretimRaporuPage> createState() => _UretimRaporuPageState();
}

class _UretimRaporuPageState extends State<UretimRaporuPage> with SingleTickerProviderStateMixin {
  final _service = UretimRaporuService();
  final _supabase = Supabase.instance.client;
  bool _yukleniyor = true;
  String? _hata;
  late TabController _tabController;
  StreamSubscription? _realtimeSubscription;
  
  // Arama
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = '';
  Timer? _aramaDebounce;
  
  // Filtreler
  String _secilenMarka = 'Tümü';
  String _secilenDurum = 'Tümü';
  String _secilenAsama = 'Tümü';
  DateTimeRange? _tarihAraligi;
  List<String> _markaListesi = ['Tümü'];
  
  // Aşama listesi
  final List<Map<String, dynamic>> _asamaListesi = [
    {'key': 'Tümü', 'label': 'Tüm Aşamalar', 'color': Colors.grey},
    {'key': 'beklemede', 'label': 'Beklemede', 'color': Colors.grey},
    {'key': 'dokuma', 'label': 'Dokuma', 'color': Colors.brown},
    {'key': 'konfeksiyon', 'label': 'Konfeksiyon', 'color': Colors.orange},
    {'key': 'yikama', 'label': 'Yıkama', 'color': Colors.blue},
    {'key': 'utu', 'label': 'Ütü', 'color': Colors.purple},
    {'key': 'ilik_dugme', 'label': 'İlik Düğme', 'color': Colors.teal},
    {'key': 'kalite_kontrol', 'label': 'Kalite Kontrol', 'color': Colors.indigo},
    {'key': 'paketleme', 'label': 'Paketleme', 'color': Colors.green},
  ];
  
  // Veriler — ham ve filtrelenmiş
  List<Map<String, dynamic>> _tumModeller = [];
  List<Map<String, dynamic>> _modeller = [];
  Map<String, dynamic> _ozet = {};
  Map<String, Map<String, int>> _fireAnaliz = {};
  List<Map<String, dynamic>> _tedarikciler = [];
  
  // Pagination
  static const int _sayfaBasinaModel = 20;
  int _gorunenModelSayisi = _sayfaBasinaModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _verileriYukle();
    _realtimeBaslat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aramaController.dispose();
    _aramaDebounce?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  /// Realtime subscription ile otomatik güncelleme
  void _realtimeBaslat() {
    _realtimeSubscription = _supabase
        .from(DbTables.trikoTakip)
        .stream(primaryKey: ['id'])
        .listen((_) {
      _aramaDebounce?.cancel();
      _aramaDebounce = Timer(const Duration(seconds: 2), () {
        if (mounted) _verileriYukle();
      });
    });
  }

  /// DB'den tüm veriyi çeker (service aracılığıyla)
  Future<void> _verileriYukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final data = await _service.verileriYukle();
      _tumModeller = data.modeller;
      _markaListesi = data.markaListesi;
      _tedarikciler = data.tedarikciler;
      _filtreleriUygula();
    } catch (e) {
      setState(() {
        _hata = e is AppException ? e.message : 'Veriler yüklenirken hata oluştu: $e';
        _yukleniyor = false;
      });
    }
  }

  /// Client-side filtreleme — DB'ye gitmeden anlık filtre uygular
  void _filtreleriUygula() {
    final sonuc = UretimRaporuService.filtrele(
      tumModeller: _tumModeller,
      secilenMarka: _secilenMarka,
      secilenDurum: _secilenDurum,
      secilenAsama: _secilenAsama,
      aramaMetni: _aramaMetni,
      tarihAraligi: _tarihAraligi,
    );

    setState(() {
      _modeller = sonuc.modeller;
      _ozet = sonuc.ozet;
      _fireAnaliz = Map<String, Map<String, int>>.from(
        (_ozet['fire_analiz'] as Map<String, Map<String, int>>?) ?? {},
      );
      _gorunenModelSayisi = _sayfaBasinaModel;
      _yukleniyor = false;
    });
  }

  /// Arama debounce — her tuşta değil, yazma durduğunda filtrele
  void _aramaYap(String value) {
    _aramaDebounce?.cancel();
    _aramaDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _aramaMetni = value);
      _filtreleriUygula();
    });
  }

  // ==================== FİLTRE PRESET ====================
  static const _presetKey = 'uretim_raporu_filtre_presets';
  
  Future<List<Map<String, dynamic>>> _filtrePresetleriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_presetKey);
    if (json == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
  }

  Future<void> _filtrePresetKaydet(String ad) async {
    final prefs = await SharedPreferences.getInstance();
    final presets = await _filtrePresetleriYukle();
    presets.add({
      'ad': ad,
      'marka': _secilenMarka,
      'durum': _secilenDurum,
      'asama': _secilenAsama,
      'arama': _aramaMetni,
    });
    await prefs.setString(_presetKey, jsonEncode(presets));
  }

  Future<void> _filtrePresetSil(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final presets = await _filtrePresetleriYukle();
    if (index < presets.length) {
      presets.removeAt(index);
      await prefs.setString(_presetKey, jsonEncode(presets));
    }
  }

  void _filtrePresetUygula(Map<String, dynamic> preset) {
    setState(() {
      _secilenMarka = preset['marka']?.toString() ?? 'Tümü';
      _secilenDurum = preset['durum']?.toString() ?? 'Tümü';
      _secilenAsama = preset['asama']?.toString() ?? 'Tümü';
      _aramaMetni = preset['arama']?.toString() ?? '';
      _aramaController.text = _aramaMetni;
    });
    _filtreleriUygula();
  }

  Map<String, dynamic> _getAsamaBilgisi(String asamaKey) {
    switch (asamaKey) {
      case 'dokuma':
        return {'label': 'Dokuma', 'color': Colors.brown, 'icon': Icons.grid_on};
      case 'nakis':
        return {'label': 'Nakış', 'color': Colors.pink, 'icon': Icons.brush};
      case 'konfeksiyon':
        return {'label': 'Konfeksiyon', 'color': Colors.orange, 'icon': Icons.checkroom};
      case 'yikama':
        return {'label': 'Yıkama', 'color': Colors.blue, 'icon': Icons.local_laundry_service};
      case 'utu':
        return {'label': 'Ütü', 'color': Colors.purple, 'icon': Icons.iron};
      case 'ilik_dugme':
        return {'label': 'İlik Düğme', 'color': Colors.teal, 'icon': Icons.radio_button_checked};
      case 'kalite_kontrol':
        return {'label': 'Kalite', 'color': Colors.indigo, 'icon': Icons.verified};
      case 'paketleme':
        return {'label': 'Paketleme', 'color': Colors.green, 'icon': Icons.inventory_2};
      case 'tamamlandi':
        return {'label': 'Tamamlandı', 'color': Colors.green.shade700, 'icon': Icons.check_circle};
      case 'beklemede':
        return {'label': 'Beklemede', 'color': Colors.grey, 'icon': Icons.hourglass_empty};
      default:
        return {'label': 'Beklemede', 'color': Colors.grey, 'icon': Icons.hourglass_empty};
    }
  }

  String _durumMetni(dynamic durum) {
    if (durum == null) return 'Bekliyor';
    switch (durum.toString()) {
      case 'atandi': return 'Atandı';
      case 'beklemede': return 'Beklemede';
      case 'onaylandi': return 'Onaylandı';
      case 'uretimde': return 'Üretimde';
      case 'baslatildi': return 'Başlatıldı';
      case 'tamamlandi': return 'Tamamlandı';
      case 'kismi_tamamlandi': return 'Kısmi Tamamlandı';
      case 'reddedildi': return 'Reddedildi';
      default: return durum.toString();
    }
  }

  Color _getDurumRenk(String durum) {
    switch (durum) {
      case 'tamamlandi': return Colors.green;
      case 'uretimde':
      case 'isleniyor': return Colors.orange;
      case 'atandi':
      case 'onaylandi': return Colors.blue;
      case 'reddedildi': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDurumMetin(String durum) {
    switch (durum) {
      case 'tamamlandi': return 'Tamamlandı';
      case 'uretimde':
      case 'isleniyor': return 'İşlemde';
      case 'atandi': return 'Atandı';
      case 'onaylandi': return 'Onaylandı';
      case 'reddedildi': return 'Reddedildi';
      case 'beklemede': return 'Beklemede';
      default: return 'Bekliyor';
    }
  }

  /// Model detay sayfasına yönlendir
  void _modelDetayaGit(Map<String, dynamic> model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelDetay(
          modelId: model['id'].toString(),
          modelData: model,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üretim Raporu'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: _modelKarsilastirmaDialogu,
            tooltip: 'Model Karşılaştır',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
            tooltip: 'PDF Rapor',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportExcel,
            tooltip: 'Excel\'e Aktar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
            tooltip: 'Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Özet'),
            Tab(icon: Icon(Icons.list_alt), text: 'Modeller'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Grafikler'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Fire'),
            Tab(icon: Icon(Icons.schedule), text: 'Termin'),
            Tab(icon: Icon(Icons.business), text: 'Tedarikçi'),
          ],
        ),
      ),
      body: _yukleniyor
          ? const LoadingWidget(mesaj: 'Üretim verileri yükleniyor...')
          : _hata != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_hata!, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _verileriYukle,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildKpiDashboard(),
                    Column(
                      children: [
                        _buildFiltreler(),
                        _buildOzetKartlari(),
                        Expanded(child: _buildModelListesi()),
                      ],
                    ),
                    _buildGrafiklerTab(),
                    _buildFireAnaliziTab(),
                    _buildTerminTakibiTab(),
                    _buildTedarikciTab(),
                  ],
                ),
    );
  }

  String _escapeCsvField(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class _KarsilastirmaSatir {
  final String baslik;
  final String deger1;
  final String deger2;
  const _KarsilastirmaSatir(this.baslik, this.deger1, this.deger2);
}
