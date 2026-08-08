import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/iplik_model_tahsis_service.dart';
import 'package:uretim_takip/services/iplik_lokasyon_sayim_service.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class IplikSiparisTakipPage extends StatefulWidget {
  const IplikSiparisTakipPage({super.key});

  @override
  State<IplikSiparisTakipPage> createState() => _IplikSiparisTakipPageState();
}

class _IplikSiparisTakipPageState extends State<IplikSiparisTakipPage> {
  final supabase = Supabase.instance.client;
  final aramaController = TextEditingController();

  List<Map<String, dynamic>> siparisler = [];
  List<Map<String, dynamic>> tedarikciler = [];
  List<Map<String, dynamic>> modeller = [];
  List<Map<String, dynamic>> lokasyonlar = [];
  bool _yukleniyor = false;

  String aramaMetni = '';
  String durumFiltresi = 'tum';
  String? tedarikciFiltresi;
  String terminFiltresi = 'tum';
  String kaliteFiltresi = 'tum';
  String teslimFiltresi = 'tum';
  String siralama = 'termin';
  String? kalinlikFiltresi;
  String? karisimFiltresi;
  String? renkFiltresi;
  String? renkKoduFiltresi;
  String? lotFiltresi;
  String? modelFiltresi;
  final minFiyatController = TextEditingController();
  final maxFiyatController = TextEditingController();

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _successColor = Color(0xFF059669);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _surfaceColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    aramaController.dispose();
    minFiyatController.dispose();
    maxFiyatController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);

    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      final yeniTedarikciler = await _tedarikcileriYukle(firmaId);
      List<Map<String, dynamic>> yeniModeller = [];
      List<Map<String, dynamic>> yeniLokasyonlar = [];
      try {
        yeniModeller = await IplikModelTahsisService.modelleriGetir();
      } catch (_) {}
      try {
        yeniLokasyonlar = await IplikLokasyonSayimService.lokasyonlariGetir(
          sadeceAktif: true,
        );
      } catch (_) {}
      final tedarikciMap = {
        for (final tedarikci in yeniTedarikciler)
          if (tedarikci['id'] != null) tedarikci['id'].toString(): tedarikci,
      };

      List<Map<String, dynamic>> yeniSiparisler;
      try {
        final viewData = await supabase
            .from(DbTables.vSiparisTakip)
            .select()
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false);
        yeniSiparisler = List<Map<String, dynamic>>.from(viewData);
      } catch (viewError) {
        debugPrint(
          'Sipariş takip view firma filtresi desteklemiyor, tablo sorgusu deneniyor: $viewError',
        );
        final tableData = await supabase
            .from(DbTables.iplikSiparisleri)
            .select()
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false);
        yeniSiparisler = List<Map<String, dynamic>>.from(tableData);
      }

      yeniSiparisler = yeniSiparisler
          .map((siparis) => _normalizeSiparis(siparis, tedarikciMap))
          .toList();
      for (final siparis in yeniSiparisler) {
        try {
          siparis['model_tahsisleri'] =
              await IplikModelTahsisService.siparisTahsisleriGetir(
            siparis['id'].toString(),
          );
        } catch (_) {
          siparis['model_tahsisleri'] = <Map<String, dynamic>>[];
        }
      }

      setState(() {
        tedarikciler = yeniTedarikciler;
        siparisler = yeniSiparisler;
        modeller = yeniModeller;
        lokasyonlar = yeniLokasyonlar;
      });

      debugPrint('Sipariş takip verileri yüklendi: ${siparisler.length} adet');
    } catch (e) {
      debugPrint('Sipariş takip verisi yüklenirken hata: $e');
      if (mounted) context.showErrorSnackBar('Veri yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<List<Map<String, dynamic>>> _tedarikcileriYukle(String firmaId) async {
    try {
      final data = await supabase
          .from(DbTables.tedarikciler)
          .select('id, ad, sirket, telefon')
          .eq('firma_id', firmaId)
          .order('sirket');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Sipariş takip tedarikçi yükleme hatası: $e');
      return [];
    }
  }

  Map<String, dynamic> _normalizeSiparis(
    Map<String, dynamic> source,
    Map<String, Map<String, dynamic>> tedarikciMap,
  ) {
    final siparis = Map<String, dynamic>.from(source);
    final miktar = _num(siparis['miktar']);
    final teslimMiktari = _num(siparis['teslim_miktari']);
    final teslimYuzdesi = miktar > 0
        ? (siparis['teslim_yuzdesi'] == null
            ? (teslimMiktari / miktar) * 100
            : _num(siparis['teslim_yuzdesi']))
        : 0.0;
    final takipDurumu = _hesaplaTakipDurumu(siparis, miktar, teslimMiktari);
    final tedarikci = tedarikciMap[siparis['tedarikci_id']?.toString()];

    siparis['miktar'] = miktar;
    siparis['teslim_miktari'] = teslimMiktari;
    siparis['teslim_yuzdesi'] = math.max(0, teslimYuzdesi);
    siparis['takip_durumu'] = takipDurumu;
    siparis['kalan_miktar'] = math.max(0, miktar - teslimMiktari);
    siparis['tedarikci_adi'] = _firstText([
      siparis['tedarikci_adi'],
      tedarikci?['sirket'],
      tedarikci?['ad'],
    ]);
    siparis['tedarikci_telefon'] = _firstText([
      siparis['tedarikci_telefon'],
      tedarikci?['telefon'],
    ]);
    return siparis;
  }

  String _hesaplaTakipDurumu(
    Map<String, dynamic> siparis,
    double miktar,
    double teslimMiktari,
  ) {
    if (siparis['teslim_edildi'] == true ||
        teslimMiktari >= miktar && miktar > 0) {
      return 'tamamlandi';
    }
    final durum = siparis['durum']?.toString();
    if (durum == 'tamamlandi' || durum == 'teslim_edildi') return 'tamamlandi';
    if (durum == 'iptal') return 'iptal';

    final termin = _parseDate(siparis['termin_tarihi']);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (termin != null && termin.isBefore(todayDate)) return 'gecikti';
    if (teslimMiktari > 0) return 'kismi';
    return 'beklemede';
  }

  List<Map<String, dynamic>> get _filtreliSiparisler {
    final arama = aramaMetni.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    final result = siparisler.where((siparis) {
      final termin = _parseDate(siparis['termin_tarihi']);
      final teslimYuzdesi = _num(siparis['teslim_yuzdesi']);
      final metin =
          '${siparis['siparis_no']} ${siparis['iplik_adi']} ${siparis['iplik_kalinligi']} ${siparis['iplik_karisimi']} ${siparis['renk']} ${siparis['renk_kodu']} ${siparis['lot_no']} ${siparis['tedarikci_adi']} ${siparis['marka']} ${_siparisModelEtiketleri(siparis)}'
              .toLowerCase();

      final aramaUygun = arama.isEmpty || metin.contains(arama);
      final durumUygun =
          durumFiltresi == 'tum' || siparis['takip_durumu'] == durumFiltresi;
      final tedarikciUygun = tedarikciFiltresi == null ||
          siparis['tedarikci_id']?.toString() == tedarikciFiltresi;
      final kaliteUygun = kaliteFiltresi == 'tum' ||
          (siparis['kalite_durumu']?.toString() ?? '') == kaliteFiltresi;
      final teslimUygun = switch (teslimFiltresi) {
        'teslim_yok' => teslimYuzdesi <= 0,
        'kismi' => teslimYuzdesi > 0 && teslimYuzdesi < 100,
        'tam' => teslimYuzdesi >= 100,
        _ => true,
      };
      final terminUygun = switch (terminFiltresi) {
        'geciken' => termin != null &&
            termin.isBefore(today) &&
            siparis['takip_durumu'] != 'tamamlandi',
        'bugun' => termin != null && _sameDay(termin, today),
        'hafta' =>
          termin != null && !termin.isBefore(today) && !termin.isAfter(weekEnd),
        'termin_yok' => termin == null,
        _ => true,
      };

      final fiyat = siparis['birim_fiyat'] is num
          ? (siparis['birim_fiyat'] as num).toDouble()
          : null;
      final minFiyat = _parseDecimal(minFiyatController.text);
      final maxFiyat = _parseDecimal(maxFiyatController.text);
      return aramaUygun &&
          durumUygun &&
          tedarikciUygun &&
          kaliteUygun &&
          teslimUygun &&
          terminUygun &&
          _alanUyar(siparis['iplik_kalinligi'], kalinlikFiltresi) &&
          _alanUyar(siparis['iplik_karisimi'], karisimFiltresi) &&
          _alanUyar(siparis['renk'], renkFiltresi) &&
          _alanUyar(siparis['renk_kodu'], renkKoduFiltresi) &&
          _alanUyar(siparis['lot_no'], lotFiltresi) &&
          (modelFiltresi == null ||
              _siparisModelIdleri(siparis).contains(modelFiltresi)) &&
          (minFiyat == null || (fiyat != null && fiyat >= minFiyat)) &&
          (maxFiyat == null || (fiyat != null && fiyat <= maxFiyat));
    }).toList();

    result.sort((a, b) {
      switch (siralama) {
        case 'siparis_no':
          return (a['siparis_no'] ?? '').toString().compareTo(
                (b['siparis_no'] ?? '').toString(),
              );
        case 'teslim':
          return _num(b['teslim_yuzdesi']).compareTo(_num(a['teslim_yuzdesi']));
        case 'tedarikci':
          return (a['tedarikci_adi'] ?? '').toString().compareTo(
                (b['tedarikci_adi'] ?? '').toString(),
              );
        case 'created':
          return (b['created_at'] ?? '').toString().compareTo(
                (a['created_at'] ?? '').toString(),
              );
        case 'termin':
        default:
          final at = _parseDate(a['termin_tarihi']);
          final bt = _parseDate(b['termin_tarihi']);
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return at.compareTo(bt);
      }
    });
    return result;
  }

  bool _alanUyar(dynamic value, String? filtre) =>
      filtre == null || value?.toString() == filtre;

  List<String> _siparisModelIdleri(Map<String, dynamic> siparis) =>
      ((siparis['model_tahsisleri'] as List?) ?? const [])
          .map((item) => (item as Map)['model_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

  String _siparisModelEtiketleri(Map<String, dynamic> siparis) =>
      ((siparis['model_tahsisleri'] as List?) ?? const [])
          .map((item) {
            final model = (item as Map)['triko_takip'] as Map?;
            return '${model?['marka'] ?? ''} ${model?['item_no'] ?? ''}'.trim();
          })
          .where((text) => text.isNotEmpty)
          .join(', ');

  List<String> _alanDegerleri(String alan) {
    final values = siparisler
        .map((item) => item[alan]?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  Future<void> _siparisTakipExcelIndir() async {
    final filtreliSiparisler = _filtreliSiparisler;
    if (filtreliSiparisler.isEmpty) {
      context.showErrorSnackBar('Excel için sipariş kaydı bulunamadı');
      return;
    }

    try {
      final rapor = filtreliSiparisler.map((siparis) {
        final siparisMiktari = _num(siparis['miktar']);
        final teslimMiktari = _num(siparis['teslim_miktari']);
        final birimFiyat = _num(siparis['birim_fiyat']);
        return <String, dynamic>{
          'siparis_no': siparis['siparis_no'],
          'marka': siparis['marka'],
          'iplik_adi': siparis['iplik_adi'],
          'iplik_kalinligi': siparis['iplik_kalinligi'],
          'iplik_karisimi': siparis['iplik_karisimi'],
          'renk': siparis['renk'],
          'renk_kodu': siparis['renk_kodu'],
          'modeller': _siparisModelEtiketleri(siparis),
          'tedarikci': siparis['tedarikci_adi'],
          'siparis_miktari': siparisMiktari,
          'birim': siparis['birim'] ?? 'kg',
          'teslim_miktari': teslimMiktari,
          'kalan_miktar': _num(siparis['kalan_miktar']),
          'fazla_teslim': math.max(0, teslimMiktari - siparisMiktari),
          'teslim_yuzdesi': _num(siparis['teslim_yuzdesi']),
          'durum': _getDurumBilgi(siparis['takip_durumu']).metin,
          'kalite': _kaliteMetni(siparis['kalite_durumu']),
          'siparis_tarihi': siparis['siparis_tarihi'],
          'termin_tarihi': siparis['termin_tarihi'],
          'teslim_tarihi': siparis['teslim_tarihi'],
          'lot_no': siparis['lot_no'],
          'birim_fiyat': birimFiyat,
          'para_birimi': siparis['para_birimi'] ?? 'TL',
          'toplam_tutar':
              siparis['toplam_tutar'] ?? (siparisMiktari * birimFiyat),
          'aciklama': siparis['aciklama'],
        };
      }).toList();

      final zaman = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await ExcelHelper.exportToExcel(
        data: rapor,
        fileName: 'Iplik_Siparis_Takip_$zaman',
        columns: const {
          'siparis_no': 'Sipariş No',
          'marka': 'Marka',
          'iplik_adi': 'İplik Adı',
          'iplik_kalinligi': 'İplik Kalınlığı',
          'iplik_karisimi': 'İplik Karışımı',
          'renk': 'Renk',
          'renk_kodu': 'Renk Kodu',
          'modeller': 'Modeller',
          'tedarikci': 'Tedarikçi',
          'siparis_miktari': 'Sipariş Miktarı',
          'birim': 'Birim',
          'teslim_miktari': 'Teslim Miktarı',
          'kalan_miktar': 'Kalan Miktar',
          'fazla_teslim': 'Fazla Teslim',
          'teslim_yuzdesi': 'Teslim Yüzdesi',
          'durum': 'Durum',
          'kalite': 'Kalite',
          'siparis_tarihi': 'Sipariş Tarihi',
          'termin_tarihi': 'Termin Tarihi',
          'teslim_tarihi': 'Teslim Tarihi',
          'lot_no': 'Lot / Parti No',
          'birim_fiyat': 'Birim Fiyat',
          'para_birimi': 'Para Birimi',
          'toplam_tutar': 'Toplam Tutar',
          'aciklama': 'Açıklama',
        },
      );

      if (mounted) {
        context.showSuccessSnackBar(
          '${rapor.length} sipariş Excel dosyasına aktarıldı',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Excel oluşturma hatası: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtreliSiparisler = _filtreliSiparisler;
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 1100;
      final content = [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildOzetler(),
        const SizedBox(height: 12),
        _buildFiltreler(),
        const SizedBox(height: 12),
      ];

      if (isMobile) {
        return Scaffold(
          backgroundColor: _surfaceColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...content,
                if (_yukleniyor)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: LoadingWidget(),
                  )
                else if (filtreliSiparisler.isEmpty)
                  SizedBox(
                    height: 320,
                    child: _buildBosDurum(),
                  )
                else
                  _buildKartListe(
                    filtreliSiparisler,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: _surfaceColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...content,
              if (_yukleniyor)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: LoadingWidget(),
                )
              else if (filtreliSiparisler.isEmpty)
                SizedBox(
                  height: 320,
                  child: _buildBosDurum(),
                )
              else
                _buildTablo(filtreliSiparisler),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.local_shipping_outlined, color: _primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İplik Sipariş Takip',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const Text(
                  'Termin, teslimat, kalite ve stok işleme takibi',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _verileriYukle,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
    );
  }

  Widget _buildOzetler() {
    final toplam = siparisler.length;
    final bekleyen =
        siparisler.where((s) => s['takip_durumu'] == 'beklemede').length;
    final kismi = siparisler.where((s) => s['takip_durumu'] == 'kismi').length;
    final geciken =
        siparisler.where((s) => s['takip_durumu'] == 'gecikti').length;
    final tamamlanan =
        siparisler.where((s) => s['takip_durumu'] == 'tamamlandi').length;
    final kalanKg = siparisler.fold<double>(
      0,
      (sum, siparis) => sum + _num(siparis['kalan_miktar']),
    );

    final kartlar = [
      _buildOzetKart(
          'Toplam', toplam.toString(), Icons.receipt_long, _primaryColor),
      _buildOzetKart('Bekleyen', bekleyen.toString(), Icons.hourglass_empty,
          _warningColor),
      _buildOzetKart('Kısmi', kismi.toString(), Icons.call_received,
          const Color(0xFF7C3AED)),
      _buildOzetKart(
          'Geciken', geciken.toString(), Icons.warning_amber, _dangerColor),
      _buildOzetKart('Tamamlanan', tamamlanan.toString(),
          Icons.check_circle_outline, _successColor),
      _buildOzetKart('Kalan Kg', kalanKg.toStringAsFixed(1), Icons.scale,
          const Color(0xFF0891B2)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kartlar
                .map((kart) => SizedBox(width: 170, child: kart))
                .toList(),
          );
        }
        return Row(
          children: kartlar
              .map((kart) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: kart,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildOzetKart(
      String baslik, String deger, IconData icon, Color renk) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: renk, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deger,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltreler() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final full = constraints.maxWidth < 720;
          final width = full
              ? constraints.maxWidth
              : constraints.maxWidth < 1200
                  ? 180.0
                  : 210.0;
          final searchWidth = full
              ? constraints.maxWidth
              : constraints.maxWidth < 1200
                  ? 300.0
                  : 330.0;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: aramaController,
                  decoration: const InputDecoration(
                    labelText: 'Sipariş no, iplik, renk, tedarikçi ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => aramaMetni = value),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  label: 'Durum',
                  value: durumFiltresi,
                  items: const {
                    'tum': 'Tümü',
                    'beklemede': 'Bekleyen',
                    'kismi': 'Kısmi',
                    'gecikti': 'Geciken',
                    'tamamlandi': 'Tamamlanan',
                    'iptal': 'İptal',
                  },
                  onChanged: (v) => setState(() => durumFiltresi = v),
                ),
              ),
              for (final filter in [
                ('Kalınlık', 'iplik_kalinligi', kalinlikFiltresi),
                ('Karışım', 'iplik_karisimi', karisimFiltresi),
                ('Renk', 'renk', renkFiltresi),
                ('Renk kodu', 'renk_kodu', renkKoduFiltresi),
                ('Lot', 'lot_no', lotFiltresi),
              ])
                SizedBox(
                  width: width,
                  child: DropdownButtonFormField<String?>(
                    initialValue: filter.$3,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: filter.$1,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tümü'),
                      ),
                      ..._alanDegerleri(filter.$2).map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      switch (filter.$2) {
                        case 'iplik_kalinligi':
                          kalinlikFiltresi = value;
                        case 'iplik_karisimi':
                          karisimFiltresi = value;
                        case 'renk':
                          renkFiltresi = value;
                        case 'renk_kodu':
                          renkKoduFiltresi = value;
                        case 'lot_no':
                          lotFiltresi = value;
                      }
                    }),
                  ),
                ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<String?>(
                  initialValue: modelFiltresi,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tüm modeller'),
                    ),
                    ...modeller.map(
                      (model) => DropdownMenuItem<String?>(
                        value: model['id']?.toString(),
                        child: Text(
                          '${model['marka'] ?? '-'} - ${model['item_no'] ?? '-'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => modelFiltresi = value),
                ),
              ),
              for (final item in [
                ('Min. fiyat', minFiyatController),
                ('Maks. fiyat', maxFiyatController),
              ])
                SizedBox(
                  width: width,
                  child: TextField(
                    controller: item.$2,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: item.$1,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<String?>(
                  initialValue: tedarikciFiltresi,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tedarikçi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tüm tedarikçiler'),
                    ),
                    ...tedarikciler.map(
                      (tedarikci) => DropdownMenuItem<String?>(
                        value: tedarikci['id']?.toString(),
                        child: Text(
                          _firstText([tedarikci['sirket'], tedarikci['ad']]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => tedarikciFiltresi = value),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  label: 'Termin',
                  value: terminFiltresi,
                  items: const {
                    'tum': 'Tümü',
                    'geciken': 'Geciken',
                    'bugun': 'Bugün',
                    'hafta': 'Bu hafta',
                    'termin_yok': 'Termin yok',
                  },
                  onChanged: (v) => setState(() => terminFiltresi = v),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  label: 'Teslim',
                  value: teslimFiltresi,
                  items: const {
                    'tum': 'Tümü',
                    'teslim_yok': 'Teslim yok',
                    'kismi': 'Kısmi',
                    'tam': 'Tam',
                  },
                  onChanged: (v) => setState(() => teslimFiltresi = v),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  label: 'Kalite',
                  value: kaliteFiltresi,
                  items: const {
                    'tum': 'Tümü',
                    'onaylandi': 'Onaylandı',
                    'beklemede': 'Kontrol bekliyor',
                    'sartli_kabul': 'Şartlı kabul',
                    'reddedildi': 'Reddedildi',
                  },
                  onChanged: (v) => setState(() => kaliteFiltresi = v),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  label: 'Sıralama',
                  value: siralama,
                  items: const {
                    'termin': 'Termin',
                    'created': 'Son kayıt',
                    'siparis_no': 'Sipariş no',
                    'tedarikci': 'Tedarikçi',
                    'teslim': 'Teslim oranı',
                  },
                  onChanged: (v) => setState(() => siralama = v),
                ),
              ),
              SizedBox(
                width: full ? constraints.maxWidth : null,
                child: OutlinedButton.icon(
                  onPressed: _filtreliSiparisler.isEmpty
                      ? null
                      : _siparisTakipExcelIndir,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Excel'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => onChanged(value ?? items.keys.first),
    );
  }

  Widget _buildTablo(List<Map<String, dynamic>> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          dataRowMinHeight: 58,
          dataRowMaxHeight: 92,
          columnSpacing: constraints.maxWidth >= 1500 ? 18 : 10,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: Text('Sipariş')),
            DataColumn(label: Text('İplik')),
            DataColumn(label: Text('Modeller')),
            DataColumn(label: Text('Tedarikçi')),
            DataColumn(label: Text('Termin')),
            DataColumn(label: Text('Miktar')),
            DataColumn(label: Text('Teslim')),
            DataColumn(label: Text('Durum')),
            DataColumn(label: Text('İşlem')),
          ],
          rows: data.map((siparis) {
            final durum = _getDurumBilgi(siparis['takip_durumu']);
            return DataRow(
              cells: [
                DataCell(_tableText(
                    siparis['siparis_no']?.toString() ?? '-', 105, true)),
                DataCell(_buildIplikTabloHucre(siparis)),
                DataCell(_tableText(
                    _siparisModelEtiketleri(siparis).isEmpty
                        ? '-'
                        : _siparisModelEtiketleri(siparis),
                    150,
                    false)),
                DataCell(_tableText(
                    siparis['tedarikci_adi']?.toString() ?? '-', 140, false)),
                DataCell(Text(_formatTarih(siparis['termin_tarihi']))),
                DataCell(Text(
                    '${_num(siparis['miktar']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}')),
                DataCell(_buildTeslimHucre(siparis, width: 130)),
                DataCell(_buildDurumTabloHucre(siparis, durum)),
                DataCell(_buildAksiyonlar(siparis, compact: true)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIplikTabloHucre(Map<String, dynamic> siparis) {
    final detaylar = [
      siparis['iplik_kalinligi'],
      siparis['iplik_karisimi'],
      siparis['renk'],
      siparis['renk_kodu'],
      siparis['lot_no'],
    ]
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty && value != '-')
        .join(' • ');
    return SizedBox(
      width: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            siparis['iplik_adi']?.toString() ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (detaylar.isNotEmpty)
            Text(
              detaylar,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildDurumTabloHucre(
    Map<String, dynamic> siparis,
    _DurumBilgi durum,
  ) {
    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _durumEtiketi(durum.metin, durum.renk),
          const SizedBox(height: 3),
          Text(
            'Kalite: ${_kaliteMetni(siparis['kalite_durumu'])}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: _kaliteRengi(siparis['kalite_durumu']),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKartListe(
    List<Map<String, dynamic>> data, {
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildSiparisKart(data[index]),
    );
  }

  Widget _buildSiparisKart(Map<String, dynamic> siparis) {
    final durum = _getDurumBilgi(siparis['takip_durumu']);
    final birim = siparis['birim'] ?? 'kg';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${siparis['siparis_no'] ?? '-'} - ${siparis['iplik_adi'] ?? '-'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              _durumEtiketi(durum.metin, durum.renk),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _miniBilgi(
                  'Renk',
                  _siparisRengi(siparis).isNotEmpty
                      ? _siparisRengi(siparis)
                      : '-',
                  width: 220,
                  maxLines: 3),
              _miniBilgi(
                  'Tedarikçi', siparis['tedarikci_adi']?.toString() ?? '-'),
              _miniBilgi('Termin', _formatTarih(siparis['termin_tarihi'])),
              _miniBilgi('Sipariş',
                  '${_num(siparis['miktar']).toStringAsFixed(1)} $birim'),
              _miniBilgi('Teslim',
                  '${_num(siparis['teslim_miktari']).toStringAsFixed(1)} $birim'),
              _miniBilgi('Kalan',
                  '${_num(siparis['kalan_miktar']).toStringAsFixed(1)} $birim'),
            ],
          ),
          const SizedBox(height: 12),
          _buildTeslimHucre(siparis),
          const SizedBox(height: 12),
          Row(children: [_buildAksiyonlar(siparis)]),
        ],
      ),
    );
  }

  Widget _buildTeslimHucre(Map<String, dynamic> siparis, {double? width}) {
    final yuzde = math.max(0, _num(siparis['teslim_yuzdesi']));
    final progressYuzde = yuzde.clamp(0, 100).toDouble();
    final color = yuzde >= 100
        ? _successColor
        : yuzde > 0
            ? _primaryColor
            : _warningColor;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: progressYuzde / 100,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '%${yuzde.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${_num(siparis['teslim_miktari']).toStringAsFixed(1)} / ${_num(siparis['miktar']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiyonlar(Map<String, dynamic> siparis,
      {bool compact = false}) {
    final tamamlandi = siparis['takip_durumu'] == 'tamamlandi';
    final duzenlenebilir = _siparisDuzenlenebilir(siparis);
    final teslimatEklenebilir = siparis['takip_durumu'] != 'iptal';
    final tamamlanabilir = !tamamlandi;

    return SizedBox(
      width: compact ? 34 : 40,
      height: compact ? 34 : 40,
      child: PopupMenuButton<String>(
        tooltip: 'İşlemler',
        icon: const Icon(Icons.more_vert),
        iconColor: const Color(0xFF475569),
        padding: EdgeInsets.zero,
        splashRadius: compact ? 18 : 20,
        onSelected: (value) {
          switch (value) {
            case 'detay':
              _siparisDetayGoster(siparis);
              break;
            case 'duzenle':
              _siparisDuzenle(siparis);
              break;
            case 'sil':
              _siparisSil(siparis);
              break;
            case 'teslimat':
              _teslimatEkle(siparis);
              break;
            case 'tahsis':
              _siparisModelTahsisDialogu(siparis);
              break;
            case 'tamamla':
              _siparisiBitir(siparis);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'detay',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.visibility_outlined),
              title: Text('Detay'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
            ),
          ),
          PopupMenuItem(
            value: 'tahsis',
            enabled: duzenlenebilir,
            child: const ListTile(
              dense: true,
              leading: Icon(Icons.link),
              title: Text('Model tahsisleri'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
            ),
          ),
          PopupMenuItem(
            value: 'duzenle',
            enabled: duzenlenebilir,
            child: const ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined),
              title: Text('Düzenle'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
            ),
          ),
          PopupMenuItem(
            value: 'sil',
            enabled: duzenlenebilir,
            child: const ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline, color: _dangerColor),
              title: Text('Sil'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
            ),
          ),
          const PopupMenuDivider(height: 4),
          PopupMenuItem(
            value: 'teslimat',
            enabled: teslimatEklenebilir,
            child: const ListTile(
              dense: true,
              leading: Icon(Icons.add_box_outlined, color: _successColor),
              title: Text('Teslimat gir'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
            ),
          ),
          PopupMenuItem(
            value: 'tamamla',
            enabled: tamamlanabilir,
            child: const ListTile(
              dense: true,
              leading: Icon(Icons.task_alt, color: _warningColor),
              title: Text('Tamamlandı işaretle'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
            ),
          ),
        ],
      ),
    );
  }

  bool _siparisDuzenlenebilir(Map<String, dynamic> siparis) {
    return siparis['takip_durumu'] != 'tamamlandi' &&
        _num(siparis['teslim_miktari']) <= 0;
  }

  Future<bool> _siparisTeslimatsizMi(Map<String, dynamic> siparis) async {
    if (!_siparisDuzenlenebilir(siparis)) return false;
    final teslimatlar = await _teslimatGecmisiYukle(siparis['id']);
    return teslimatlar.isEmpty;
  }

  Future<void> _siparisModelTahsisDialogu(
    Map<String, dynamic> siparis,
  ) async {
    final mevcut = List<Map<String, dynamic>>.from(
      siparis['model_tahsisleri'] as List? ?? const [],
    );
    final controllers = <String, TextEditingController>{};
    for (final model in modeller) {
      final id = model['id'].toString();
      var text = '';
      for (final item in mevcut) {
        if (item['model_id']?.toString() == id) {
          text = item['tahsis_miktari']?.toString() ?? '';
          break;
        }
      }
      controllers[id] = TextEditingController(text: text);
    }
    final limit = _num(siparis['miktar']);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final toplam = controllers.values.fold<double>(
            0,
            (sum, item) => sum + (_parseDecimal(item.text) ?? 0),
          );
          return AlertDialog(
            title: Text('Model Tahsisleri - ${siparis['siparis_no'] ?? ''}'),
            content: SizedBox(
              width: 620,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sipariş: ${limit.toStringAsFixed(2)} kg • '
                    'Tahsis: ${toplam.toStringAsFixed(2)} kg • '
                    'Kalan: ${(limit - toplam).clamp(0, double.infinity).toStringAsFixed(2)} kg',
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: modeller.length,
                      itemBuilder: (_, index) {
                        final model = modeller[index];
                        return ListTile(
                          title: Text(
                            '${model['marka'] ?? '-'} - ${model['item_no'] ?? '-'}',
                          ),
                          trailing: SizedBox(
                            width: 130,
                            child: TextField(
                              controller: controllers[model['id'].toString()],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Tahsis (kg)',
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: toplam > limit
                    ? null
                    : () async {
                        final tahsisler = <Map<String, dynamic>>[];
                        for (final model in modeller) {
                          final miktar = _parseDecimal(
                                controllers[model['id'].toString()]!.text,
                              ) ??
                              0;
                          if (miktar > 0) {
                            tahsisler.add({
                              'model_id': model['id'],
                              'tahsis_miktari': miktar,
                            });
                          }
                        }
                        try {
                          await IplikModelTahsisService
                              .siparisTahsisleriniKaydet(
                            siparis['id'].toString(),
                            tahsisler,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          await _verileriYukle();
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          dialogContext.showErrorSnackBar('Tahsis hatası: $e');
                        }
                      },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _siparisDuzenle(Map<String, dynamic> siparis) async {
    if (!await _siparisTeslimatsizMi(siparis)) {
      if (mounted) {
        context.showErrorSnackBar(
          'Teslimat başlamış sipariş düzenlenemez',
        );
      }
      return;
    }

    final siparisNoController =
        TextEditingController(text: siparis['siparis_no']?.toString() ?? '');
    final markaController =
        TextEditingController(text: siparis['marka']?.toString() ?? '');
    final iplikAdiController =
        TextEditingController(text: siparis['iplik_adi']?.toString() ?? '');
    final kalinlikController = TextEditingController(
        text: siparis['iplik_kalinligi']?.toString() ?? '');
    final karisimController = TextEditingController(
        text: siparis['iplik_karisimi']?.toString() ?? '');
    final renkController =
        TextEditingController(text: siparis['renk']?.toString() ?? '');
    final renkKoduController =
        TextEditingController(text: siparis['renk_kodu']?.toString() ?? '');
    final lotController =
        TextEditingController(text: siparis['lot_no']?.toString() ?? '');
    final miktarController = TextEditingController(
      text: _num(siparis['miktar']).toStringAsFixed(1),
    );
    final birimFiyatController = TextEditingController(
      text: siparis['birim_fiyat']?.toString() ?? '',
    );
    final aciklamaController =
        TextEditingController(text: siparis['aciklama']?.toString() ?? '');
    DateTime? terminTarihi = _parseDate(siparis['termin_tarihi']);
    DateTime siparisTarihi =
        _parseDate(siparis['siparis_tarihi']) ?? DateTime.now();
    String paraBirimi = siparis['para_birimi']?.toString() ?? 'TL';
    String durum = siparis['durum']?.toString() ?? 'beklemede';
    String kaliteDurumu = siparis['kalite_durumu']?.toString() ?? 'onaylandi';

    try {
      if (!mounted) return;
      final kaydedildi = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Sipariş Düzenle'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: siparisNoController,
                      decoration: const InputDecoration(
                        labelText: 'Sipariş No *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: markaController,
                      decoration: const InputDecoration(
                        labelText: 'Marka *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: iplikAdiController,
                      decoration: const InputDecoration(
                        labelText: 'İplik adı *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: kalinlikController,
                      decoration: const InputDecoration(
                        labelText: 'İplik kalınlığı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: karisimController,
                      decoration: const InputDecoration(
                        labelText: 'İplik karışımı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: renkController,
                      decoration: const InputDecoration(
                        labelText: 'Renk',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: renkKoduController,
                      decoration: const InputDecoration(
                        labelText: 'Renk kodu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: lotController,
                      decoration: const InputDecoration(
                        labelText: 'Lot / Parti No',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: miktarController,
                      decoration: const InputDecoration(
                        labelText: 'Miktar *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: birimFiyatController,
                            decoration: const InputDecoration(
                              labelText: 'Birim fiyat',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: paraBirimi,
                            decoration: const InputDecoration(
                              labelText: 'Para birimi',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'TL', child: Text('TL')),
                              DropdownMenuItem(
                                  value: 'USD', child: Text('USD')),
                              DropdownMenuItem(
                                  value: 'EUR', child: Text('EUR')),
                            ],
                            onChanged: (value) => setDialogState(
                              () => paraBirimi = value ?? 'TL',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _datePickerField(
                            label: 'Sipariş tarihi',
                            value: siparisTarihi,
                            onChanged: (value) =>
                                setDialogState(() => siparisTarihi = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _datePickerField(
                            label: 'Termin',
                            value: terminTarihi,
                            onChanged: (value) =>
                                setDialogState(() => terminTarihi = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            label: 'Durum',
                            value: durum,
                            items: const {
                              'beklemede': 'Bekleyen',
                              'iptal': 'İptal',
                            },
                            onChanged: (value) =>
                                setDialogState(() => durum = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dropdown(
                            label: 'Kalite',
                            value: kaliteDurumu,
                            items: const {
                              'onaylandi': 'Onaylandı',
                              'beklemede': 'Kontrol bekliyor',
                              'sartli_kabul': 'Şartlı kabul',
                              'reddedildi': 'Reddedildi',
                            },
                            onChanged: (value) =>
                                setDialogState(() => kaliteDurumu = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: aciklamaController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      );

      if (kaydedildi != true) return;
      final siparisNo = siparisNoController.text.trim();
      final miktar = _parseDecimal(miktarController.text);
      if (siparisNo.isEmpty ||
          iplikAdiController.text.trim().isEmpty ||
          miktar == null ||
          miktar <= 0) {
        throw 'Sipariş no, iplik adı ve geçerli miktar zorunludur';
      }
      final birimFiyat = birimFiyatController.text.trim().isNotEmpty
          ? _parseDecimal(birimFiyatController.text)
          : null;
      final firmaId = TenantManager.instance.requireFirmaId;
      final mevcutSiparisNo = siparis['siparis_no']?.toString().trim() ?? '';
      if (siparisNo != mevcutSiparisNo) {
        final cakisanSiparis = await supabase
            .from(DbTables.iplikSiparisleri)
            .select('id')
            .eq('firma_id', firmaId)
            .eq('siparis_no', siparisNo)
            .neq('id', siparis['id'])
            .maybeSingle();
        if (cakisanSiparis != null) {
          throw 'Bu sipariş no aynı firmada başka bir siparişte kullanılıyor';
        }
      }

      await supabase
          .from(DbTables.iplikSiparisleri)
          .update({
            'siparis_no': siparisNo,
            'marka': markaController.text.trim(),
            'iplik_adi': iplikAdiController.text.trim(),
            'iplik_kalinligi': kalinlikController.text.trim().isEmpty
                ? null
                : kalinlikController.text.trim(),
            'iplik_karisimi': karisimController.text.trim().isEmpty
                ? null
                : karisimController.text.trim(),
            'renk': renkController.text.trim().isNotEmpty
                ? renkController.text.trim()
                : null,
            'renk_kodu': renkKoduController.text.trim().isEmpty
                ? null
                : renkKoduController.text.trim(),
            'lot_no': lotController.text.trim().isEmpty
                ? null
                : lotController.text.trim(),
            'miktar': miktar,
            'birim_fiyat': birimFiyat,
            'para_birimi': paraBirimi,
            'toplam_tutar': birimFiyat != null ? miktar * birimFiyat : null,
            'termin_tarihi': terminTarihi?.toIso8601String(),
            'siparis_tarihi': siparisTarihi.toIso8601String(),
            'durum': durum,
            'kalite_durumu': kaliteDurumu,
            'aciklama': aciklamaController.text.trim().isNotEmpty
                ? aciklamaController.text.trim()
                : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', siparis['id'])
          .eq('firma_id', firmaId);

      await _verileriYukle();
      if (mounted) context.showSuccessSnackBar('Sipariş güncellendi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Hata: $e');
    } finally {
      siparisNoController.dispose();
      markaController.dispose();
      iplikAdiController.dispose();
      kalinlikController.dispose();
      karisimController.dispose();
      renkController.dispose();
      renkKoduController.dispose();
      lotController.dispose();
      miktarController.dispose();
      birimFiyatController.dispose();
      aciklamaController.dispose();
    }
  }

  Future<void> _siparisSil(Map<String, dynamic> siparis) async {
    if (!await _siparisTeslimatsizMi(siparis)) {
      if (mounted) {
        context.showErrorSnackBar('Teslimat başlamış sipariş silinemez');
      }
      return;
    }

    if (!mounted) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sipariş Sil'),
        content: Text(
          '${siparis['siparis_no'] ?? '-'} numaralı sipariş silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _dangerColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    try {
      await supabase
          .from(DbTables.iplikSiparisleri)
          .delete()
          .eq('id', siparis['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId);
      await _verileriYukle();
      if (mounted) context.showSuccessSnackBar('Sipariş silindi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Silme hatası: $e');
    }
  }

  Widget _datePickerField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final tarih = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (tarih != null) onChanged(tarih);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child:
            Text(value == null ? '-' : DateFormat('dd.MM.yyyy').format(value)),
      ),
    );
  }

  Future<void> _teslimatEkle(Map<String, dynamic> siparis) async {
    final mevcutKalan = _num(siparis['kalan_miktar']);
    final miktarController = TextEditingController(
      text: mevcutKalan > 0 ? mevcutKalan.toStringAsFixed(1) : '',
    );
    final lotNoController = TextEditingController();
    final aciklamaController = TextEditingController();
    DateTime teslimatTarihi = DateTime.now();
    String kaliteDurumu = 'onaylandi';
    String? lokasyonId =
        lokasyonlar.isEmpty ? null : lokasyonlar.first['id']?.toString();

    try {
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final kalanMiktar = _num(siparis['kalan_miktar']);
            final girilenMiktar =
                _parseDecimal(miktarController.text.trim()) ?? 0;
            final fazlaTeslim = math.max(
              0,
              _num(siparis['teslim_miktari']) +
                  girilenMiktar -
                  _num(siparis['miktar']),
            );
            return AlertDialog(
              title: Text('Teslimat Gir - ${siparis['siparis_no'] ?? '-'}'),
              content: SizedBox(
                width: math.min(
                  500,
                  math.max(200, MediaQuery.sizeOf(context).width - 64),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTeslimatOzetKutusu(siparis),
                      const SizedBox(height: 14),
                      TextField(
                        controller: miktarController,
                        decoration: InputDecoration(
                          labelText: 'Teslim edilen miktar *',
                          helperText:
                              'Kalan: ${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}. Sipariş üzeri teslimat kabul edilir.',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      if (fazlaTeslim > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            'Sipariş miktarından ${fazlaTeslim.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'} fazla teslimat giriliyor.',
                            style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: lotNoController,
                        decoration: const InputDecoration(
                          labelText: 'Lot / Parti No',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: kaliteDurumu,
                        decoration: const InputDecoration(
                          labelText: 'Kalite durumu',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'onaylandi', child: Text('Onaylandı')),
                          DropdownMenuItem(
                              value: 'beklemede',
                              child: Text('Kontrol bekliyor')),
                          DropdownMenuItem(
                              value: 'sartli_kabul',
                              child: Text('Şartlı kabul')),
                          DropdownMenuItem(
                              value: 'reddedildi', child: Text('Reddedildi')),
                        ],
                        onChanged: (value) => setDialogState(
                            () => kaliteDurumu = value ?? 'onaylandi'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: lokasyonId,
                        decoration: const InputDecoration(
                          labelText: 'İplik Lokasyonu *',
                          border: OutlineInputBorder(),
                        ),
                        items: lokasyonlar
                            .map((item) => DropdownMenuItem(
                                  value: item['id']?.toString(),
                                  child: Text('${item['kod']} - ${item['ad']}'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => lokasyonId = value),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final tarih = await showDatePicker(
                            context: context,
                            initialDate: teslimatTarihi,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (tarih != null) {
                            setDialogState(() => teslimatTarihi = tarih);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Teslimat tarihi',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                              DateFormat('dd.MM.yyyy').format(teslimatTarihi)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: aciklamaController,
                        decoration: const InputDecoration(
                          labelText: 'Not',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final miktar = _parseDecimal(miktarController.text);
                      if (miktar == null || miktar <= 0) {
                        throw 'Geçerli bir miktar girin';
                      }
                      if (lokasyonId == null) throw 'Lokasyon seçin';
                      final lotNo = lotNoController.text.trim().isNotEmpty
                          ? lotNoController.text.trim()
                          : null;
                      await _siparisTeslimatKaydet(
                        siparis: siparis,
                        miktar: miktar,
                        lotNo: lotNo,
                        kaliteDurumu: kaliteDurumu,
                        teslimatTarihi: teslimatTarihi,
                        aciklama: aciklamaController.text.trim().isNotEmpty
                            ? aciklamaController.text.trim()
                            : null,
                        lokasyonId: lokasyonId!,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await _verileriYukle();
                      if (!context.mounted) return;
                      context.showSuccessSnackBar('Teslimat stoka işlendi');
                    } catch (e) {
                      if (context.mounted) {
                        context.showErrorSnackBar('Hata: $e');
                      }
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      miktarController.dispose();
      lotNoController.dispose();
      aciklamaController.dispose();
    }
  }

  Widget _buildTeslimatOzetKutusu(Map<String, dynamic> siparis) {
    final siparisMiktari = _num(siparis['miktar']);
    final teslimMiktari = _num(siparis['teslim_miktari']);
    final fazlaTeslim = math.max(0, teslimMiktari - siparisMiktari);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${siparis['iplik_adi'] ?? '-'} - ${_siparisRengi(siparis).isNotEmpty ? _siparisRengi(siparis) : '-'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
              'Sipariş: ${_num(siparis['miktar']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
          Text(
              'Teslim: ${_num(siparis['teslim_miktari']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
          Text(
            'Kalan: ${_num(siparis['kalan_miktar']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _warningColor),
          ),
          if (fazlaTeslim > 0)
            Text(
              'Fazla teslim: ${fazlaTeslim.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF9A3412),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _siparisTeslimatKaydet({
    required Map<String, dynamic> siparis,
    required double miktar,
    required String? lotNo,
    required String kaliteDurumu,
    required DateTime teslimatTarihi,
    String? aciklama,
    required String lokasyonId,
  }) async {
    try {
      await supabase.rpc(
        'iplik_lokasyonlu_siparis_teslimat_kaydet',
        params: {
          'p_firma_id': TenantManager.instance.requireFirmaId,
          'p_siparis_id': siparis['id'],
          'p_miktar': miktar,
          'p_lot_no': lotNo,
          'p_kalite_durumu': kaliteDurumu,
          'p_teslimat_tarihi': teslimatTarihi.toIso8601String().split('T')[0],
          'p_aciklama': aciklama,
          'p_lokasyon_id': lokasyonId,
        },
      );
    } catch (rpcError) {
      throw Exception('Lokasyonlu teslimat kaydedilemedi: $rpcError');
    }
  }

  // ignore: unused_element
  Future<void> _teslimatFallbackKaydet({
    required Map<String, dynamic> siparis,
    required double miktar,
    required String? lotNo,
    required String kaliteDurumu,
    required DateTime teslimatTarihi,
    String? aciklama,
  }) async {
    final siparisMiktari = _num(siparis['miktar']);
    final toplamTeslim = _num(siparis['teslim_miktari']) + miktar;
    final teslimYuzdesi =
        siparisMiktari > 0 ? (toplamTeslim / siparisMiktari) * 100 : 0;
    final teslimEdildi = siparisMiktari > 0 && toplamTeslim >= siparisMiktari;
    final firmaId = TenantManager.instance.requireFirmaId;

    await supabase
        .from(DbTables.iplikSiparisleri)
        .update({
          'teslim_miktari': toplamTeslim,
          'teslim_yuzdesi': teslimYuzdesi,
          'teslim_tarihi': teslimatTarihi.toIso8601String().split('T')[0],
          'teslim_edildi': teslimEdildi,
          'lot_no': lotNo,
          'kalite_durumu': kaliteDurumu,
          'durum': teslimEdildi ? 'teslim_edildi' : 'beklemede',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', siparis['id'])
        .eq('firma_id', firmaId);

    final stokData = {
      'ad': siparis['iplik_adi'],
      'renk': siparis['renk'],
      'lot_no': lotNo,
      'miktar': miktar,
      'birim': siparis['birim'] ?? 'kg',
      'birim_fiyat': siparis['birim_fiyat'],
      'para_birimi': siparis['para_birimi'] ?? 'TL',
      'tedarikci_id': siparis['tedarikci_id'],
      'firma_id': firmaId,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (siparis['birim_fiyat'] != null) {
      stokData['toplam_deger'] = miktar * _num(siparis['birim_fiyat']);
    }

    final stokId = await _stokSatiriKaydetVeyaGuncelle(
      stokData: stokData,
      miktar: miktar,
    );

    await supabase.from(DbTables.iplikHareketleri).insert({
      'iplik_id': stokId,
      'hareket_tipi': 'giris',
      'miktar': miktar,
      'aciklama': aciklama?.isNotEmpty == true
          ? aciklama
          : 'Sipariş teslimatından otomatik stok girişi - ${siparis['siparis_no']}',
      'firma_id': firmaId,
    });

    await _teslimatKaydiEkle(
      siparis: siparis,
      miktar: miktar,
      lotNo: lotNo,
      kaliteDurumu: kaliteDurumu,
      teslimatTarihi: teslimatTarihi,
      aciklama: aciklama,
    );
  }

  Future<dynamic> _stokSatiriKaydetVeyaGuncelle({
    required Map<String, dynamic> stokData,
    required double miktar,
  }) async {
    final firmaId = TenantManager.instance.requireFirmaId;
    final mevcutStok = await _ayniStokSatiriniBul(
      firmaId: firmaId,
      renk: stokData['renk'],
      lotNo: stokData['lot_no'],
    );

    if (mevcutStok != null) {
      final yeniMiktar = _num(mevcutStok['miktar']) + miktar;
      final birimFiyat = _num(stokData['birim_fiyat']);
      final updateData = <String, dynamic>{
        'miktar': yeniMiktar,
        'birim': stokData['birim'] ?? mevcutStok['birim'] ?? 'kg',
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (stokData['birim_fiyat'] != null) {
        updateData['birim_fiyat'] = stokData['birim_fiyat'];
        updateData['para_birimi'] =
            stokData['para_birimi'] ?? mevcutStok['para_birimi'];
        updateData['toplam_deger'] = yeniMiktar * birimFiyat;
      }
      if (stokData['tedarikci_id'] != null) {
        updateData['tedarikci_id'] = stokData['tedarikci_id'];
      }

      await supabase
          .from(DbTables.iplikStoklari)
          .update(updateData)
          .eq('id', mevcutStok['id'])
          .eq('firma_id', firmaId);
      return mevcutStok['id'];
    }

    final stokResponse = await supabase
        .from(DbTables.iplikStoklari)
        .insert(stokData)
        .select('id')
        .single();
    return stokResponse['id'];
  }

  Future<Map<String, dynamic>?> _ayniStokSatiriniBul({
    required String firmaId,
    required dynamic renk,
    required dynamic lotNo,
  }) async {
    final data = await supabase
        .from(DbTables.iplikStoklari)
        .select('id, ad, renk, lot_no, miktar, birim, birim_fiyat, para_birimi')
        .eq('firma_id', firmaId)
        .order('created_at');

    for (final stok in List<Map<String, dynamic>>.from(data)) {
      if (_ayniStokAnahtari(
        stok,
        renk: renk,
        lotNo: lotNo,
      )) {
        return stok;
      }
    }
    return null;
  }

  Future<void> _teslimatKaydiEkle({
    required Map<String, dynamic> siparis,
    required double miktar,
    required String? lotNo,
    required String kaliteDurumu,
    required DateTime teslimatTarihi,
    String? aciklama,
  }) async {
    try {
      await supabase.from(DbTables.iplikSiparisTeslimatlar).insert({
        'siparis_id': siparis['id'],
        'firma_id': TenantManager.instance.requireFirmaId,
        'teslim_kg': miktar,
        'iplik_lotu': lotNo,
        'gelis_tarihi': teslimatTarihi.toIso8601String().split('T')[0],
        'teslimat_durumu': miktar >= _num(siparis['kalan_miktar'])
            ? 'tam_teslimat'
            : 'kismi_teslimat',
        'kalite_durumu': kaliteDurumu,
        'aciklama': aciklama,
      });
    } catch (e) {
      debugPrint('Teslimat geçmişi kaydı eklenemedi: $e');
    }
  }

  Future<void> _siparisiBitir(Map<String, dynamic> siparis) async {
    final notController = TextEditingController();
    try {
      final kalanMiktar = _num(siparis['kalan_miktar']);
      final onay = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Siparişi Tamamlandı İşaretle'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sipariş: ${siparis['siparis_no'] ?? '-'}'),
                Text('İplik: ${siparis['iplik_adi'] ?? '-'}'),
                Text(
                    'Kalan: ${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
                if (kalanMiktar > 0) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Bu sipariş eksik teslim edilmiş görünüyor. Tamamlandı işaretlenecekse not girin.',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: _warningColor),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notController,
                    decoration: const InputDecoration(
                      labelText: 'Tamamlama notu',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tamamlandı İşaretle'),
            ),
          ],
        ),
      );

      if (onay != true) return;
      if (kalanMiktar > 0 && notController.text.trim().isEmpty) {
        if (mounted) {
          context.showErrorSnackBar('Eksik teslimat için not zorunlu');
        }
        return;
      }

      final eskiAciklama = siparis['aciklama']?.toString();
      final yeniAciklama = [
        if (eskiAciklama != null && eskiAciklama.trim().isNotEmpty)
          eskiAciklama,
        if (notController.text.trim().isNotEmpty)
          'Manuel tamamlama: ${notController.text.trim()}',
      ].join('\n');

      await supabase
          .from(DbTables.iplikSiparisleri)
          .update({
            'durum': 'teslim_edildi',
            'teslim_edildi': true,
            'kapanma_tarihi': DateTime.now().toIso8601String().split('T')[0],
            'aciklama': yeniAciklama.isNotEmpty ? yeniAciklama : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', siparis['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId);

      await _verileriYukle();
      if (mounted) {
        context.showSuccessSnackBar('Sipariş tamamlandı işaretlendi');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Hata: $e');
    } finally {
      notController.dispose();
    }
  }

  Future<void> _siparisDetayGoster(Map<String, dynamic> siparis) async {
    final teslimatlar = await _teslimatGecmisiYukle(siparis['id']);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: math.min(MediaQuery.of(context).size.width * 0.92, 920),
          height: math.min(MediaQuery.of(context).size.height * 0.88, 760),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sipariş Detayı - ${siparis['siparis_no'] ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Özet'),
                          Tab(text: 'Teslimatlar'),
                          Tab(text: 'Stok Bağlantısı'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildDetayOzet(siparis),
                            _buildTeslimatGecmisi(teslimatlar),
                            _buildStokBaglantisi(siparis, teslimatlar),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _teslimatGecmisiYukle(
      dynamic siparisId) async {
    try {
      final data = await supabase
          .from(DbTables.iplikSiparisTeslimatlar)
          .select()
          .eq('siparis_id', siparisId)
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .order('gelis_tarihi', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Teslimat geçmişi yüklenemedi: $e');
      return [];
    }
  }

  Widget _buildDetayOzet(Map<String, dynamic> siparis) {
    final durum = _getDurumBilgi(siparis['takip_durumu']);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTeslimHucre(siparis),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _detayBilgi('İplik', siparis['iplik_adi']),
              _detayBilgi('İplik kalınlığı', siparis['iplik_kalinligi']),
              _detayBilgi('İplik karışımı', siparis['iplik_karisimi']),
              _detayBilgi('Renk', siparis['renk']),
              _detayBilgi('Renk kodu', siparis['renk_kodu']),
              _detayBilgi('Lot', siparis['lot_no']),
              _detayBilgi('Modeller', _siparisModelEtiketleri(siparis)),
              _detayBilgi('Renk', _siparisRengi(siparis)),
              _detayBilgi('Marka', siparis['marka']),
              _detayBilgi('Tedarikçi', siparis['tedarikci_adi']),
              _detayBilgi('Telefon', siparis['tedarikci_telefon']),
              _detayBilgi('Termin', _formatTarih(siparis['termin_tarihi'])),
              _detayBilgi('Sipariş miktarı',
                  '${_num(siparis['miktar']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
              _detayBilgi('Teslim',
                  '${_num(siparis['teslim_miktari']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
              _detayBilgi('Kalan',
                  '${_num(siparis['kalan_miktar']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}'),
              _detayBilgi('Durum', durum.metin),
              _detayBilgi('Kalite', _kaliteMetni(siparis['kalite_durumu'])),
              _detayBilgi('Lot', siparis['lot_no']),
            ],
          ),
          if (siparis['aciklama']?.toString().trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                siparis['aciklama'].toString(),
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeslimatGecmisi(List<Map<String, dynamic>> teslimatlar) {
    if (teslimatlar.isEmpty) {
      return const Center(child: Text('Teslimat geçmişi bulunamadı'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: teslimatlar.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = teslimatlar[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.inventory_outlined, color: _successColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_num(item['teslim_kg']).toStringAsFixed(1)} kg - Lot: ${item['iplik_lotu'] ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Tarih: ${_formatTarih(item['gelis_tarihi'])} | Kalite: ${_kaliteMetni(item['kalite_durumu'])}',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 12),
                    ),
                    if (item['aciklama']?.toString().trim().isNotEmpty == true)
                      Text(
                        item['aciklama'].toString(),
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStokBaglantisi(
    Map<String, dynamic> siparis,
    List<Map<String, dynamic>> teslimatlar,
  ) {
    final toplamTeslim = teslimatlar.fold<double>(
      0,
      (sum, item) => sum + _num(item['teslim_kg']),
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detayBilgi('Stoka işlenen teslimat',
              '${toplamTeslim.toStringAsFixed(1)} kg'),
          _detayBilgi('Son lot', siparis['lot_no']),
          _detayBilgi('Tedarikçi', siparis['tedarikci_adi']),
          const SizedBox(height: 12),
          const Text(
            'Teslimat girildiğinde iplik stoğuna giriş hareketi oluşur. Yeni RPC aktifse sipariş, stok ve hareket tek transaction içinde işlenir.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _detayBilgi(String baslik, dynamic deger) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(
            deger?.toString().trim().isNotEmpty == true
                ? deger.toString()
                : '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildBosDurum() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 58, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('Sipariş bulunamadı',
              style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Arama veya filtreleri değiştirin',
              style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _tableText(String value, double width, bool bold) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
      ),
    );
  }

  Widget _miniBilgi(
    String baslik,
    String deger, {
    double width = 145,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(
            deger,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _durumEtiketi(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  _DurumBilgi _getDurumBilgi(dynamic durum) {
    switch (durum?.toString()) {
      case 'tamamlandi':
        return const _DurumBilgi('Tamamlandı', _successColor);
      case 'gecikti':
        return const _DurumBilgi('Geciken', _dangerColor);
      case 'kismi':
        return const _DurumBilgi('Kısmi', _primaryColor);
      case 'iptal':
        return const _DurumBilgi('İptal', Color(0xFF64748B));
      case 'beklemede':
      default:
        return const _DurumBilgi('Bekleyen', _warningColor);
    }
  }

  String _kaliteMetni(dynamic kalite) {
    switch (kalite?.toString()) {
      case 'onaylandi':
        return 'Onaylandı';
      case 'beklemede':
        return 'Kontrol bekliyor';
      case 'sartli_kabul':
        return 'Şartlı kabul';
      case 'reddedildi':
        return 'Reddedildi';
      default:
        return '-';
    }
  }

  Color _kaliteRengi(dynamic kalite) {
    switch (kalite?.toString()) {
      case 'onaylandi':
        return _successColor;
      case 'reddedildi':
        return _dangerColor;
      case 'sartli_kabul':
        return _warningColor;
      case 'beklemede':
        return _primaryColor;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _siparisRengi(Map<String, dynamic> siparis) {
    return siparis['renk']?.toString().trim() ?? '';
  }

  bool _ayniStokAnahtari(
    Map<String, dynamic> stok, {
    required dynamic renk,
    required dynamic lotNo,
  }) {
    final stokRenk = _stokAnahtarMetni(stok['renk']);
    final hedefRenk = _stokAnahtarMetni(renk);
    final stokLot = _stokAnahtarMetni(stok['lot_no']);
    final hedefLot = _stokAnahtarMetni(lotNo);
    if (hedefRenk.isEmpty || hedefLot.isEmpty) return false;
    return stokRenk == hedefRenk && stokLot == hedefLot;
  }

  String _stokAnahtarMetni(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i');
  }

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  double _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return '-';
  }

  DateTime? _parseDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  String _formatTarih(dynamic value) {
    final tarih = _parseDate(value);
    if (tarih == null) return '-';
    return DateFormat('dd.MM.yyyy').format(tarih);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DurumBilgi {
  const _DurumBilgi(this.metin, this.renk);

  final String metin;
  final Color renk;
}
