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

class _GelismisRaporlarPageState extends State<GelismisRaporlarPage> with SingleTickerProviderStateMixin {
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


  final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  final List<String> zamanAraliklari = ['Bu Hafta', 'Bu Ay', 'Son 3 Ay', 'Bu Yıl', 'Tüm Zamanlar'];

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
      final modellerResponse = await _supabase.from(DbTables.trikoTakip).select('''
        id, marka, item_no, renk, adet, toplam_adet, yuklenen_adet, created_at, termin_tarihi,
        iplik_maliyeti, orgu_fiyat, dikim_fiyat, utu_fiyat, yikama_fiyat, 
        ilik_dugme_fiyat, aksesuar_fiyat, genel_aksesuar_fiyat, genel_gider_fiyat, pesin_fiyat, fermuar_fiyat, kar_marji
      ''').eq('firma_id', _firmaId).order('created_at', ascending: false);

      // Depo satışlarını getir
      final depoResponse = await _supabase.from(DbTables.urunDepo).select('*').eq('firma_id', _firmaId);

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
            } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
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
        selectedZamanAraligi = '${DateFormat('dd.MM.yyyy').format(secilen.start)} - ${DateFormat('dd.MM.yyyy').format(secilen.end)}';
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
                  (item['ilik_dugme_fiyat'] ?? 0).toDouble()) * yuklenenAdet;
      aksesuar += ((item['aksesuar_fiyat'] ?? 0).toDouble() +
                   (item['genel_aksesuar_fiyat'] ?? 0).toDouble() +
                   (item['fermuar_fiyat'] ?? 0).toDouble()) * yuklenenAdet;
      genelGider += ((item['genel_gider_fiyat'] ?? 0).toDouble()) * yuklenenAdet;
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
      if (item['renk'] != null) {
        final renk = item['renk'].toString();
        final adet = ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
        final yuklenenAdet = ((item['yuklenen_adet'] ?? 0) as num).toInt();
        // Gelir sadece yüklenen adet üzerinden hesaplanır
        final gelir = yuklenenAdet > 0 ? ((item['pesin_fiyat'] ?? 0).toDouble()) * yuklenenAdet : 0.0;
        
        if (!renkler.containsKey(renk)) {
          renkler[renk] = {'adet': 0, 'tutar': 0.0};
        }
        renkler[renk]!['adet'] = (renkler[renk]!['adet'] as int) + adet;
        renkler[renk]!['tutar'] = (renkler[renk]!['tutar'] as double) + gelir;
      }
    }
    
    // Sırala (en çok satışa göre)
    final sirali = Map.fromEntries(
      renkler.entries.toList()..sort((a, b) => (b.value['adet'] as int).compareTo(a.value['adet'] as int))
    );
    
    return sirali;
  }

  // STOK DEVİR HIZI HESAPLA
  Map<String, dynamic> _hesaplaStokDevirHizi() {
    final List<Map<String, dynamic>> satislar = [];
    
    for (var item in depoSatislari) {
      if (item['satildi'] == true && item['satis_tarihi'] != null && item['created_at'] != null) {
        try {
          final olusturma = DateTime.parse(item['created_at']);
          final satis = DateTime.parse(item['satis_tarihi']);
          final gun = satis.difference(olusturma).inDays;
          satislar.add({
            'model': item['model'] ?? item['item_no'] ?? 'Bilinmiyor',
            'gun': gun,
          });
        } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
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
    final ortalam = satislar.map((e) => e['gun'] as int).reduce((a, b) => a + b) / satislar.length;
    
    return {
      'ortalamaSure': ortalam,
      'enHizli': satislar.first['model'],
      'enYavas': satislar.last['model'],
    };
  }

  // SEZON ANALİZİ HESAPLA
  Map<String, Map<String, dynamic>> _hesaplaSezonAnalizi() {
    final Map<String, Map<String, dynamic>> aylar = {};
    final ayIsimleri = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
                        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    
    for (var item in filtrelenmisModeller) {
      if (item['created_at'] != null) {
        try {
          final tarih = DateTime.parse(item['created_at']);
          final ayAdi = ayIsimleri[tarih.month - 1];
          final adet = ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
          final yuklenenAdet = ((item['yuklenen_adet'] ?? 0) as num).toInt();
          // Gelir sadece yüklenen adet üzerinden hesaplanır
          final gelir = yuklenenAdet > 0 ? ((item['pesin_fiyat'] ?? 0).toDouble()) * yuklenenAdet : 0.0;
          
          if (!aylar.containsKey(ayAdi)) {
            aylar[ayAdi] = {'adet': 0, 'tutar': 0.0, 'ay': tarih.month};
          }
          aylar[ayAdi]!['adet'] = (aylar[ayAdi]!['adet'] as int) + adet;
          aylar[ayAdi]!['tutar'] = (aylar[ayAdi]!['tutar'] as double) + gelir;
        } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
      }
    }
    
    // Ay sırasına göre sırala
    final sirali = Map.fromEntries(
      aylar.entries.toList()..sort((a, b) => (a.value['ay'] as int).compareTo(b.value['ay'] as int))
    );
    
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
        GelismisRaporServisleri.getModelMaliyetAnalizi(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getKarZararAnalizi(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getTedarikciPerformansAnalizi(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getUretimVerimlilikAnalizi(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporServisleri.getMarkaBazliAnaliz(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporOperasyonServisleri.getTerminTakipAnalizi(),
        GelismisRaporOperasyonServisleri.getStokAnalizi(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporOperasyonServisleri.getSevkiyatAnalizi(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
        GelismisRaporOperasyonServisleri.getKaliteAnalizi(baslangicTarihi: baslangicTarihi, bitisTarihi: bitisTarihi),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veri yüklenirken hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _verileriYukle, tooltip: 'Yenile'),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Özet'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Kâr/Zarar'),
            Tab(icon: Icon(Icons.calculate), text: 'Maliyet'),
            Tab(icon: Icon(Icons.business), text: 'Tedarikçi'),
            Tab(icon: Icon(Icons.speed), text: 'Verimlilik'),
            Tab(icon: Icon(Icons.schedule), text: 'Termin'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Stok'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Sevkiyat'),
            Tab(icon: Icon(Icons.verified), text: 'Kalite'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Raporlar yükleniyor...')]))
          : Column(
              children: [
                // FİLTRE BARI
                _buildFiltreBari(),
                // TAB İÇERİĞİ
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
            ),
    );
  }

  Widget _buildFiltreBari() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          // Mobil görünüm - dikey düzen
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
            ),
            child: Column(
              children: [
                // İlk satır: Marka ve Model
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Marka',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        initialValue: secilenMarka,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü', overflow: TextOverflow.ellipsis)),
                          ...markalar.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            secilenMarka = value;
                            secilenModel = null;
                            _filtreUygula();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Yıl',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        initialValue: secilenYil,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...yillar.map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            secilenYil = value;
                            _filtreUygula();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // İkinci satır: Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _tarihAraligiSec,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: const Text('Tarih', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.clear_all, size: 20),
                      onPressed: _filtreleriTemizle,
                      tooltip: 'Temizle',
                      style: IconButton.styleFrom(backgroundColor: Colors.grey[200]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      onPressed: _pdfOlustur,
                      tooltip: 'PDF',
                      style: IconButton.styleFrom(backgroundColor: Colors.red[50]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_chart, size: 20),
                      onPressed: _excelOlustur,
                      tooltip: 'Excel',
                      style: IconButton.styleFrom(backgroundColor: Colors.green[50]),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        
        // Tablet ve Desktop görünüm
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
          ),
          child: Row(
            children: [
              // MARKA FİLTRESİ
              Expanded(
                flex: isNarrow ? 2 : 1,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Marka',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  initialValue: secilenMarka,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tüm Markalar')),
                    ...markalar.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      secilenMarka = value;
                      secilenModel = null;
                      _filtreUygula();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // MODEL FİLTRESİ
              if (!isNarrow) ...[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Model',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    initialValue: secilenModel,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tüm Modeller')),
                      ...modeller.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: secilenMarka == null ? null : (value) {
                      setState(() {
                        secilenModel = value;
                        _filtreUygula();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // YIL FİLTRESİ
              Expanded(
                flex: isNarrow ? 2 : 1,
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Yıl',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
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
                ),
              ),
              const SizedBox(width: 12),
              // TEMİZLE BUTONU
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _filtreleriTemizle,
                tooltip: 'Filtreleri Temizle',
                style: IconButton.styleFrom(backgroundColor: Colors.grey[200]),
              ),
              const SizedBox(width: 8),
              // TARİH ARALIĞI SEÇİCİ
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _tarihAraligiSec,
                tooltip: 'Tarih Aralığı',
                style: IconButton.styleFrom(backgroundColor: Colors.blue[50]),
              ),
              const SizedBox(width: 8),
              // PDF DIŞA AKTAR
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: _pdfOlustur,
                tooltip: 'PDF Oluştur',
                style: IconButton.styleFrom(backgroundColor: Colors.red[50]),
              ),
              const SizedBox(width: 8),
              // EXCEL DIŞA AKTAR
              IconButton(
                icon: const Icon(Icons.table_chart),
                onPressed: _excelOlustur,
                tooltip: 'Excel Oluştur',
                style: IconButton.styleFrom(backgroundColor: Colors.green[50]),
              ),
            ],
          ),
        );
      },
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
      final genelAksesuar = ((item['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
      final genelGider = ((item['genel_gider_fiyat'] ?? 0) as num).toDouble();
      final fermuar = ((item['fermuar_fiyat'] ?? 0) as num).toDouble();
      
      final birimMaliyet = iplik + orgu + dikim + utu + yikama + ilikDugme + aksesuar + genelAksesuar + genelGider + fermuar;
      
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
      if (secilenMarka != null && satis['marka'] != secilenMarka) dahilEt = false;
      
      if (dahilEt) {
        depoSatisGeliri += ((satis['satilan_tutar'] ?? 0) as num).toDouble();
        depoSatilanAdet += ((satis['satilan_adet'] ?? 0) as num).toInt();
      }
    }
    
    final kar = toplamSatis - toplamMaliyet + depoSatisGeliri;
    final karMarji = toplamSatis > 0 ? (kar / toplamSatis) * 100 : 0;
    final brutKar = toplamSatis - toplamMaliyet;
    final brutKarMarji = toplamSatis > 0 ? (brutKar / toplamSatis) * 100 : 0.0;
    final ortSiparisTutari = yuklenenModelSayisi > 0 ? toplamSatis / yuklenenModelSayisi : 0.0;
    final ortBirimMaliyet = toplamYuklenenAdet > 0 ? toplamMaliyet / toplamYuklenenAdet : 0.0;
    final ortBirimSatis = toplamYuklenenAdet > 0 ? toplamSatis / toplamYuklenenAdet : 0.0;
    
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
