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
import 'package:uretim_takip/utils/excel_export.dart';

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

class _UretimRaporuPageState extends State<UretimRaporuPage>
    with SingleTickerProviderStateMixin {
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
    {
      'key': 'kalite_kontrol',
      'label': 'Kalite Kontrol',
      'color': Colors.indigo
    },
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
        .stream(primaryKey: ['id']).listen((_) {
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
        _hata = e is AppException
            ? e.message
            : 'Veriler yüklenirken hata oluştu: $e';
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
        return {
          'label': 'Dokuma',
          'color': Colors.brown,
          'icon': Icons.grid_on
        };
      case 'nakis':
        return {'label': 'Nakış', 'color': Colors.pink, 'icon': Icons.brush};
      case 'konfeksiyon':
        return {
          'label': 'Konfeksiyon',
          'color': Colors.orange,
          'icon': Icons.checkroom
        };
      case 'yikama':
        return {
          'label': 'Yıkama',
          'color': Colors.blue,
          'icon': Icons.local_laundry_service
        };
      case 'utu':
        return {'label': 'Ütü', 'color': Colors.purple, 'icon': Icons.iron};
      case 'ilik_dugme':
        return {
          'label': 'İlik Düğme',
          'color': Colors.teal,
          'icon': Icons.radio_button_checked
        };
      case 'kalite_kontrol':
        return {
          'label': 'Kalite',
          'color': Colors.indigo,
          'icon': Icons.verified
        };
      case 'paketleme':
        return {
          'label': 'Paketleme',
          'color': Colors.green,
          'icon': Icons.inventory_2
        };
      case 'tamamlandi':
        return {
          'label': 'Tamamlandı',
          'color': Colors.green.shade700,
          'icon': Icons.check_circle
        };
      case 'beklemede':
        return {
          'label': 'Beklemede',
          'color': Colors.grey,
          'icon': Icons.hourglass_empty
        };
      default:
        return {
          'label': 'Beklemede',
          'color': Colors.grey,
          'icon': Icons.hourglass_empty
        };
    }
  }

  String _durumMetni(dynamic durum) {
    if (durum == null) return 'Bekliyor';
    switch (durum.toString()) {
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
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'kismi_tamamlandi':
        return 'Kısmi Tamamlandı';
      case 'reddedildi':
        return 'Reddedildi';
      default:
        return durum.toString();
    }
  }

  Color _getDurumRenk(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return Colors.green;
      case 'uretimde':
      case 'isleniyor':
        return Colors.orange;
      case 'atandi':
      case 'onaylandi':
        return Colors.blue;
      case 'reddedildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDurumMetin(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'uretimde':
      case 'isleniyor':
        return 'İşlemde';
      case 'atandi':
        return 'Atandı';
      case 'onaylandi':
        return 'Onaylandı';
      case 'reddedildi':
        return 'Reddedildi';
      case 'beklemede':
        return 'Beklemede';
      default:
        return 'Bekliyor';
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
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildPageHeader(),
            _buildTabBar(),
            Expanded(child: _buildRaporBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildRaporBody() {
    if (_yukleniyor) {
      return const LoadingWidget(mesaj: 'Üretim verileri yükleniyor...');
    }

    if (_hata != null) {
      return Center(
        child: _buildPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 14),
              Text(_hata!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _verileriYukle,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
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
    );
  }

  Widget _buildPageHeader() {
    final toplamModel = _ozet['toplam_model'] ?? _tumModeller.length;
    final toplamAdet = _ozet['toplam_adet'] ?? 0;
    final geciken = _ozet['geciken_siparis'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final title = Row(
                children: [
                  Tooltip(
                    message: 'Geri',
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF334155),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assessment_rounded,
                        color: Color(0xFF1565C0), size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Üretim Raporu',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildInfoPill(Icons.inventory_2_rounded,
                                '$toplamModel model', const Color(0xFF1565C0)),
                            _buildInfoPill(Icons.numbers_rounded,
                                '$toplamAdet adet', const Color(0xFF0F766E)),
                            _buildInfoPill(
                              Icons.warning_amber_rounded,
                              '$geciken geciken',
                              geciken == 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFD32F2F),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  _buildToolbarButton(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Karşılaştır',
                    onPressed: _modelKarsilastirmaDialogu,
                  ),
                  _buildToolbarButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    onPressed: _exportPdf,
                  ),
                  _buildToolbarButton(
                    icon: Icons.file_download_rounded,
                    label: 'Excel',
                    onPressed: _exportExcel,
                    filled: true,
                  ),
                  Tooltip(
                    message: 'Yenile',
                    child: IconButton.filledTonal(
                      onPressed: _verileriYukle,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ],
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final style = filled
        ? FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF334155),
            side: const BorderSide(color: Color(0xFFD8E0EA)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );

    return filled
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: style,
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: style,
          );
  }

  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFF1565C0),
            indicatorWeight: 3,
            labelColor: const Color(0xFF1565C0),
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Özet'),
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'Modeller'),
              Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Grafikler'),
              Tab(
                  icon: Icon(Icons.local_fire_department_rounded),
                  text: 'Fire'),
              Tab(icon: Icon(Icons.schedule_rounded), text: 'Termin'),
              Tab(icon: Icon(Icons.business_rounded), text: 'Tedarikçi'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              letterSpacing: 0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
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
