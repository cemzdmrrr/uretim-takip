import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uretim_takip/services/gelismis_rapor_servisleri.dart';
import 'package:uretim_takip/services/gelismis_rapor_operasyon_servisleri.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'gelismis_raporlar_stok.dart';
part 'gelismis_raporlar_sevkiyat.dart';
part 'gelismis_raporlar_kalite.dart';
part 'gelismis_raporlar_export.dart';
part 'gelismis_raporlar_tabs.dart';

class GelismisRaporlarPage extends StatefulWidget {
  const GelismisRaporlarPage({super.key});

  @override
  State<GelismisRaporlarPage> createState() => _GelismisRaporlarPageState();
}

class _GelismisRaporlarPageState extends State<GelismisRaporlarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  // Filtreler
  String? secilenMarka;
  String? secilenModel;
  int? secilenYil;

  List<String> markalar = [];
  List<String> modeller = [];
  List<int> yillar = [];

  // Ham veriler
  List<Map<String, dynamic>> tumModeller = [];
  List<Map<String, dynamic>> filtrelenmisModeller = [];
  List<Map<String, dynamic>> depoSatislari = [];

  String selectedZamanAraligi = 'Bu Ay';
  bool isLoading = false;
  DateTime? baslangicTarihi;
  DateTime? bitisTarihi;

  Map<String, dynamic> maliyetVerileri = {};
  Map<String, dynamic> karZararVerileri = {};
  Map<String, dynamic> tedarikciVerileri = {};
  Map<String, dynamic> verimlilikVerileri = {};
  Map<String, dynamic> markaVerileri = {};
  Map<String, dynamic> terminVerileri = {};
  Map<String, dynamic> stokVerileri = {};
  Map<String, dynamic> sevkiyatVerileri = {};
  Map<String, dynamic> kaliteVerileri = {};

  final currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  final List<String> zamanAraliklari = [
    'Bu Hafta',
    'Bu Ay',
    'Son 3 Ay',
    'Bu Yıl',
    'Tüm Zamanlar'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _setTarihAraligi();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => isLoading = true);
    try {
      // Tüm modelleri getir
      final modellerResponse =
          await _supabase.from(DbTables.trikoTakip).select('''
        id, marka, item_no, renk, renk_kombinasyonu, adet, toplam_adet, yuklenen_adet, created_at, termin_tarihi,
        iplik_maliyeti, orgu_fiyat, dikim_fiyat, utu_fiyat, yikama_fiyat, 
        ilik_dugme_fiyat, aksesuar_fiyat, genel_aksesuar_fiyat, genel_gider_fiyat, pesin_fiyat, fermuar_fiyat, kar_marji
      ''').eq('firma_id', _firmaId).order('created_at', ascending: false);

      // Depo satışlarını getir
      final depoResponse = await _supabase
          .from(DbTables.urunDepo)
          .select('*')
          .eq('firma_id', _firmaId);

      setState(() {
        tumModeller = List<Map<String, dynamic>>.from(modellerResponse);
        depoSatislari = List<Map<String, dynamic>>.from(depoResponse);

        // Markaları çıkar
        final markaSet = <String>{};
        for (var item in tumModeller) {
          if (item['marka'] != null && item['marka'].toString().isNotEmpty) {
            markaSet.add(item['marka'].toString());
          }
        }
        markalar = markaSet.toList()..sort();

        // Yılları çıkar
        final yilSet = <int>{};
        for (var item in tumModeller) {
          if (item['created_at'] != null) {
            try {
              final tarih = DateTime.parse(item['created_at']);
              yilSet.add(tarih.year);
            } catch (e) {
              AppLogger.debug('Veri isleme hatasi: $e');
            }
          }
        }
        yillar = yilSet.toList()..sort((a, b) => b.compareTo(a));

        _filtreUygula();
      });

      await _loadAllData();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        context.showErrorSnackBar('Veri yükleme hatası: $e');
      }
    }
  }

  void _filtreUygula() {
    filtrelenmisModeller = tumModeller.where((item) {
      // Marka filtresi
      if (secilenMarka != null && item['marka'] != secilenMarka) {
        return false;
      }
      // Model filtresi
      if (secilenModel != null && item['item_no'] != secilenModel) {
        return false;
      }
      // Yıl filtresi
      if (secilenYil != null && item['created_at'] != null) {
        try {
          final tarih = DateTime.parse(item['created_at']);
          if (tarih.year != secilenYil) return false;
        } catch (e) {
          return false;
        }
      }
      return true;
    }).toList();

    // Modelleri güncelle (seçilen markaya göre)
    if (secilenMarka != null) {
      final modelSet = <String>{};
      for (var item in tumModeller) {
        if (item['marka'] == secilenMarka &&
            item['item_no'] != null &&
            item['item_no'].toString().isNotEmpty) {
          modelSet.add(item['item_no'].toString());
        }
      }
      modeller = modelSet.toList()..sort();
    } else {
      modeller = [];
      secilenModel = null;
    }
  }

  void _filtreleriTemizle() {
    setState(() {
      secilenMarka = null;
      secilenModel = null;
      secilenYil = null;
      _filtreUygula();
    });
  }

  // TARİH ARALIĞI SEÇİCİ
  Future<void> _tarihAraligiSec() async {
    final DateTimeRange? secilen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: baslangicTarihi != null && bitisTarihi != null
          ? DateTimeRange(start: baslangicTarihi!, end: bitisTarihi!)
          : null,
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (secilen != null) {
      setState(() {
        baslangicTarihi = secilen.start;
        bitisTarihi = secilen.end;
        selectedZamanAraligi =
            '${DateFormat('dd.MM.yyyy').format(secilen.start)} - ${DateFormat('dd.MM.yyyy').format(secilen.end)}';
      });
      await _loadAllData();
    }
  }

  // PDF OLUŞTUR
  // MALİYET DAĞILIMI HESAPLA
  Map<String, dynamic> _hesaplaMaliyetDagilimi() {
    double iplik = 0, iscilik = 0, aksesuar = 0, genelGider = 0;

    for (var item in filtrelenmisModeller) {
      // Sadece yüklenen adet üzerinden maliyet hesapla
      final yuklenenAdet = ((item['yuklenen_adet'] ?? 0) as num).toInt();
      if (yuklenenAdet <= 0) continue;

      iplik += ((item['iplik_maliyeti'] ?? 0).toDouble()) * yuklenenAdet;
      iscilik += ((item['orgu_fiyat'] ?? 0).toDouble() +
              (item['dikim_fiyat'] ?? 0).toDouble() +
              (item['utu_fiyat'] ?? 0).toDouble() +
              (item['yikama_fiyat'] ?? 0).toDouble() +
              (item['ilik_dugme_fiyat'] ?? 0).toDouble()) *
          yuklenenAdet;
      aksesuar += ((item['aksesuar_fiyat'] ?? 0).toDouble() +
              (item['genel_aksesuar_fiyat'] ?? 0).toDouble() +
              (item['fermuar_fiyat'] ?? 0).toDouble()) *
          yuklenenAdet;
      genelGider +=
          ((item['genel_gider_fiyat'] ?? 0).toDouble()) * yuklenenAdet;
    }

    final toplam = iplik + iscilik + aksesuar + genelGider;

    return {
      'iplik': iplik,
      'iscilik': iscilik,
      'aksesuar': aksesuar,
      'genelGider': genelGider,
      'toplam': toplam,
      'iplikOran': toplam > 0 ? (iplik / toplam * 100) : 0.0,
      'iscilikOran': toplam > 0 ? (iscilik / toplam * 100) : 0.0,
      'aksesuarOran': toplam > 0 ? (aksesuar / toplam * 100) : 0.0,
      'genelGiderOran': toplam > 0 ? (genelGider / toplam * 100) : 0.0,
    };
  }

  // RENK ANALİZİ HESAPLA
  Map<String, Map<String, dynamic>> _hesaplaRenkAnalizi() {
    final Map<String, Map<String, dynamic>> renkler = {};

    // Depo satışlarından renk bazlı satışlar
    for (var satis in depoSatislari) {
      if (satis['satildi'] == true && satis['renk'] != null) {
        final renk = satis['renk'].toString();
        final adet = (satis['satilan_adet'] ?? 0) as int;
        final tutar = (satis['satilan_tutar'] ?? 0).toDouble();

        if (!renkler.containsKey(renk)) {
          renkler[renk] = {'adet': 0, 'tutar': 0.0};
        }
        renkler[renk]!['adet'] = (renkler[renk]!['adet'] as int) + adet;
        renkler[renk]!['tutar'] = (renkler[renk]!['tutar'] as double) + tutar;
      }
    }

    // Tüm modellerden renk dağılımı (sadece yüklenen modeller gelir hesabına katılır)
    for (var item in filtrelenmisModeller) {
      final renk = _modelRengi(item);
      if (renk.isNotEmpty) {
        final adet =
            ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
        final yuklenenAdet = ((item['yuklenen_adet'] ?? 0) as num).toInt();
        // Gelir sadece yüklenen adet üzerinden hesaplanır
        final gelir = yuklenenAdet > 0
            ? ((item['pesin_fiyat'] ?? 0).toDouble()) * yuklenenAdet
            : 0.0;

        if (!renkler.containsKey(renk)) {
          renkler[renk] = {'adet': 0, 'tutar': 0.0};
        }
        renkler[renk]!['adet'] = (renkler[renk]!['adet'] as int) + adet;
        renkler[renk]!['tutar'] = (renkler[renk]!['tutar'] as double) + gelir;
      }
    }

    // Sırala (en çok satışa göre)
    final sirali = Map.fromEntries(renkler.entries.toList()
      ..sort((a, b) =>
          (b.value['adet'] as int).compareTo(a.value['adet'] as int)));

    return sirali;
  }

  String _modelRengi(Map<String, dynamic> item) {
    for (final key in ['renk', 'renk_kombinasyonu']) {
      final value = item[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final itemNo = item['item_no']?.toString().trim();
    if (itemNo == null || itemNo.isEmpty) return '';

    final parts = itemNo
        .replaceAll(RegExp(r'[-_/]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length < 2) return '';

    final suffix = parts.last.replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü]'), '');
    if (suffix.length < 2 ||
        suffix.length > 10 ||
        RegExp(r'^\d+$').hasMatch(suffix)) {
      return '';
    }

    return _renkKodunuGenislet(suffix);
  }

  String _renkKodunuGenislet(String kod) {
    final normalized = kod
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');

    const renkKodlari = {
      'KAH': 'KAHVE',
      'KHV': 'KAHVE',
      'BRD': 'BORDO',
      'LAC': 'LACİVERT',
      'LACI': 'LACİVERT',
      'EKR': 'EKRU',
      'VIZ': 'VİZON',
      'BEJ': 'BEJ',
      'SYH': 'SİYAH',
      'SIY': 'SİYAH',
      'BEY': 'BEYAZ',
      'MAV': 'MAVİ',
      'MVI': 'MAVİ',
      'YES': 'YEŞİL',
      'YSL': 'YEŞİL',
      'KIR': 'KIRMIZI',
      'KRM': 'KIRMIZI',
      'GRI': 'GRİ',
      'GR': 'GRİ',
      'MOR': 'MOR',
      'PEM': 'PEMBE',
      'PUD': 'PUDRA',
      'SRT': 'SARI',
    };

    return renkKodlari[normalized] ?? kod.toUpperCase();
  }

  // STOK DEVİR HIZI HESAPLA
  Map<String, dynamic> _hesaplaStokDevirHizi() {
    final List<Map<String, dynamic>> satislar = [];

    for (var item in depoSatislari) {
      if (item['satildi'] == true &&
          item['satis_tarihi'] != null &&
          item['created_at'] != null) {
        try {
          final olusturma = DateTime.parse(item['created_at']);
          final satis = DateTime.parse(item['satis_tarihi']);
          final gun = satis.difference(olusturma).inDays;
          satislar.add({
            'model': item['model'] ?? item['item_no'] ?? 'Bilinmiyor',
            'gun': gun,
          });
        } catch (e) {
          AppLogger.debug('Veri isleme hatasi: $e');
        }
      }
    }

    if (satislar.isEmpty) {
      return {
        'ortalamaSure': 0.0,
        'enHizli': '-',
        'enYavas': '-',
      };
    }

    satislar.sort((a, b) => (a['gun'] as int).compareTo(b['gun'] as int));
    final ortalam =
        satislar.map((e) => e['gun'] as int).reduce((a, b) => a + b) /
            satislar.length;

    return {
      'ortalamaSure': ortalam,
      'enHizli': satislar.first['model'],
      'enYavas': satislar.last['model'],
    };
  }

  // SEZON ANALİZİ HESAPLA
  Map<String, Map<String, dynamic>> _hesaplaSezonAnalizi() {
    final Map<String, Map<String, dynamic>> aylar = {};
    final ayIsimleri = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];

    for (var item in filtrelenmisModeller) {
      if (item['created_at'] != null) {
        try {
          final tarih = DateTime.parse(item['created_at']);
          final ayAdi = ayIsimleri[tarih.month - 1];
          final adet =
              ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
          final yuklenenAdet = ((item['yuklenen_adet'] ?? 0) as num).toInt();
          // Gelir sadece yüklenen adet üzerinden hesaplanır
          final gelir = yuklenenAdet > 0
              ? ((item['pesin_fiyat'] ?? 0).toDouble()) * yuklenenAdet
              : 0.0;

          if (!aylar.containsKey(ayAdi)) {
            aylar[ayAdi] = {'adet': 0, 'tutar': 0.0, 'ay': tarih.month};
          }
          aylar[ayAdi]!['adet'] = (aylar[ayAdi]!['adet'] as int) + adet;
          aylar[ayAdi]!['tutar'] = (aylar[ayAdi]!['tutar'] as double) + gelir;
        } catch (e) {
          AppLogger.debug('Veri isleme hatasi: $e');
        }
      }
    }

    // Ay sırasına göre sırala
    final sirali = Map.fromEntries(aylar.entries.toList()
      ..sort((a, b) => (a.value['ay'] as int).compareTo(b.value['ay'] as int)));

    return sirali;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setTarihAraligi() {
    final now = DateTime.now();
    switch (selectedZamanAraligi) {
      case 'Bu Hafta':
        baslangicTarihi = now.subtract(const Duration(days: 7));
        bitisTarihi = now;
        break;
      case 'Bu Ay':
        baslangicTarihi = DateTime(now.year, now.month, 1);
        bitisTarihi = now;
        break;
      case 'Son 3 Ay':
        baslangicTarihi = DateTime(now.year, now.month - 3, 1);
        bitisTarihi = now;
        break;
      case 'Bu Yıl':
        baslangicTarihi = DateTime(now.year, 1, 1);
        bitisTarihi = now;
        break;
      case 'Tüm Zamanlar':
        baslangicTarihi = null;
        bitisTarihi = null;
        break;
    }
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        GelismisRaporServisleri.getModelMaliyetAnalizi(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getKarZararAnalizi(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getTedarikciPerformansAnalizi(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getUretimVerimlilikAnalizi(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getMarkaBazliAnaliz(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporOperasyonServisleri.getTerminTakipAnalizi(),
        GelismisRaporOperasyonServisleri.getStokAnalizi(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporOperasyonServisleri.getSevkiyatAnalizi(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporOperasyonServisleri.getKaliteAnalizi(
            baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
      ]);
      setState(() {
        maliyetVerileri = results[0];
        karZararVerileri = results[1];
        tedarikciVerileri = results[2];
        verimlilikVerileri = results[3];
        markaVerileri = results[4];
        terminVerileri = results[5];
        stokVerileri = results[6];
        sevkiyatVerileri = results[7];
        kaliteVerileri = results[8];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Veri yüklenirken hata: $e'),
            backgroundColor: Colors.red));
      }
    }
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
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('Raporlar yükleniyor...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFiltreBari(),
        Expanded(
          child: TabBarView(controller: _tabController, children: [
            _buildOzetTab(),
            _buildKarZararTab(),
            _buildMaliyetTab(),
            _buildTedarikciTab(),
            _buildVerimlilikTab(),
            _buildTerminTab(),
            _buildStokTab(),
            _buildSevkiyatTab(),
            _buildKaliteTab(),
          ]),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    final ozet = _hesaplaFiltrelenmisOzet();
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
              final narrow = constraints.maxWidth < 780;
              final titleBlock = Row(
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
                    child: const Icon(Icons.analytics_rounded,
                        color: Color(0xFF1565C0), size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gelişmiş Raporlar',
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
                            _buildInfoPill(
                                Icons.inventory_2_rounded,
                                '${ozet['toplamUrun']} model',
                                const Color(0xFF1565C0)),
                            _buildInfoPill(
                                Icons.local_shipping_rounded,
                                '${ozet['toplamYuklenenAdet']} yüklenen',
                                const Color(0xFF0F766E)),
                            _buildInfoPill(
                              Icons.trending_up_rounded,
                              currencyFormat.format(ozet['kar']),
                              (ozet['kar'] as double) >= 0
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
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    onPressed: _pdfOlustur,
                  ),
                  _buildToolbarButton(
                    icon: Icons.table_chart_rounded,
                    label: 'Excel',
                    onPressed: _excelOlustur,
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
                    titleBlock,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleBlock),
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
              Tab(
                  icon: Icon(Icons.account_balance_wallet_rounded),
                  text: 'Kâr/Zarar'),
              Tab(icon: Icon(Icons.calculate_rounded), text: 'Maliyet'),
              Tab(icon: Icon(Icons.business_rounded), text: 'Tedarikçi'),
              Tab(icon: Icon(Icons.speed_rounded), text: 'Verimlilik'),
              Tab(icon: Icon(Icons.schedule_rounded), text: 'Termin'),
              Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Stok'),
              Tab(icon: Icon(Icons.local_shipping_rounded), text: 'Sevkiyat'),
              Tab(icon: Icon(Icons.verified_rounded), text: 'Kalite'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltreBari() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 680;

        return Padding(
          padding: EdgeInsets.fromLTRB(
              isMobile ? 10 : 16, 14, isMobile ? 10 : 16, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: _buildPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Filtreler',
                      Icons.tune_rounded,
                      const Color(0xFF1565C0),
                      trailing: '${filtrelenmisModeller.length} kayıt',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: isMobile ? double.infinity : 220,
                          child: _buildMarkaDropdown(),
                        ),
                        SizedBox(
                          width: isMobile ? double.infinity : 220,
                          child: _buildModelDropdown(),
                        ),
                        SizedBox(
                          width: isMobile ? double.infinity : 150,
                          child: _buildYilDropdown(),
                        ),
                        _buildToolbarButton(
                          icon: Icons.date_range_rounded,
                          label: selectedZamanAraligi,
                          onPressed: _tarihAraligiSec,
                        ),
                        Tooltip(
                          message: 'Filtreleri Temizle',
                          child: IconButton.filledTonal(
                            onPressed: _filtreleriTemizle,
                            icon: const Icon(Icons.clear_all_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarkaDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _dropdownDecoration('Marka'),
      initialValue: secilenMarka,
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tüm Markalar')),
        ...markalar.map((m) => DropdownMenuItem(
            value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (value) {
        setState(() {
          secilenMarka = value;
          secilenModel = null;
          _filtreUygula();
        });
      },
    );
  }

  Widget _buildModelDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _dropdownDecoration('Model'),
      initialValue: secilenModel,
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tüm Modeller')),
        ...modeller.map((m) => DropdownMenuItem(
            value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: secilenMarka == null
          ? null
          : (value) {
              setState(() {
                secilenModel = value;
                _filtreUygula();
              });
            },
    );
  }

  Widget _buildYilDropdown() {
    return DropdownButtonFormField<int>(
      decoration: _dropdownDecoration('Yıl'),
      initialValue: secilenYil,
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tüm Yıllar')),
        ...yillar.map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
      ],
      onChanged: (value) {
        setState(() {
          secilenYil = value;
          _filtreUygula();
        });
      },
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.4),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
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
            label: Text(label, overflow: TextOverflow.ellipsis),
            style: style,
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label, overflow: TextOverflow.ellipsis),
            style: style,
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

  // Filtrelenmiş özet hesaplama
  Map<String, dynamic> _hesaplaFiltrelenmisOzet() {
    final int toplamUrun = filtrelenmisModeller.length;
    int toplamAdet = 0;
    int toplamYuklenenAdet = 0;
    int yuklenenModelSayisi = 0;
    double toplamMaliyet = 0;
    double toplamSatis = 0;

    for (var item in filtrelenmisModeller) {
      final adet = ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
      toplamAdet += adet;

      // Maliyet kalemleri
      final iplik = ((item['iplik_maliyeti'] ?? 0) as num).toDouble();
      final orgu = ((item['orgu_fiyat'] ?? 0) as num).toDouble();
      final dikim = ((item['dikim_fiyat'] ?? 0) as num).toDouble();
      final utu = ((item['utu_fiyat'] ?? 0) as num).toDouble();
      final yikama = ((item['yikama_fiyat'] ?? 0) as num).toDouble();
      final ilikDugme = ((item['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
      final aksesuar = ((item['aksesuar_fiyat'] ?? 0) as num).toDouble();
      final genelAksesuar =
          ((item['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
      final genelGider = ((item['genel_gider_fiyat'] ?? 0) as num).toDouble();
      final fermuar = ((item['fermuar_fiyat'] ?? 0) as num).toDouble();

      final birimMaliyet = iplik +
          orgu +
          dikim +
          utu +
          yikama +
          ilikDugme +
          aksesuar +
          genelAksesuar +
          genelGider +
          fermuar;

      // Sadece yüklenen adet üzerinden hesapla - yükleme yoksa satış/maliyet yok
      final yuklenenAdet = ((item['yuklenen_adet'] ?? 0) as num).toInt();
      if (yuklenenAdet > 0) {
        yuklenenModelSayisi++;
        toplamYuklenenAdet += yuklenenAdet;
        toplamMaliyet += birimMaliyet * yuklenenAdet;
        final satis = ((item['pesin_fiyat'] ?? 0) as num).toDouble();
        toplamSatis += satis * yuklenenAdet;
      }
    }

    // Depo satışları
    double depoSatisGeliri = 0;
    int depoSatilanAdet = 0;
    for (var satis in depoSatislari) {
      bool dahilEt = true;
      if (secilenMarka != null && satis['marka'] != secilenMarka) {
        dahilEt = false;
      }

      if (dahilEt) {
        depoSatisGeliri += ((satis['satilan_tutar'] ?? 0) as num).toDouble();
        depoSatilanAdet += ((satis['satilan_adet'] ?? 0) as num).toInt();
      }
    }

    final kar = toplamSatis - toplamMaliyet + depoSatisGeliri;
    final karMarji = toplamSatis > 0 ? (kar / toplamSatis) * 100 : 0;
    final brutKar = toplamSatis - toplamMaliyet;
    final brutKarMarji = toplamSatis > 0 ? (brutKar / toplamSatis) * 100 : 0.0;
    final ortSiparisTutari =
        yuklenenModelSayisi > 0 ? toplamSatis / yuklenenModelSayisi : 0.0;
    final ortBirimMaliyet =
        toplamYuklenenAdet > 0 ? toplamMaliyet / toplamYuklenenAdet : 0.0;
    final ortBirimSatis =
        toplamYuklenenAdet > 0 ? toplamSatis / toplamYuklenenAdet : 0.0;

    return {
      'toplamUrun': toplamUrun,
      'toplamAdet': toplamAdet,
      'toplamYuklenenAdet': toplamYuklenenAdet,
      'yuklenenModelSayisi': yuklenenModelSayisi,
      'toplamMaliyet': toplamMaliyet,
      'toplamSatis': toplamSatis,
      'depoSatisGeliri': depoSatisGeliri,
      'depoSatilanAdet': depoSatilanAdet,
      'kar': kar,
      'karMarji': karMarji,
      'brutKar': brutKar,
      'brutKarMarji': brutKarMarji,
      'ortSiparisTutari': ortSiparisTutari,
      'ortBirimMaliyet': ortBirimMaliyet,
      'ortBirimSatis': ortBirimSatis,
    };
  }
}
