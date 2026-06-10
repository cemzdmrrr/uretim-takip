import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uretim_takip/models/rapor_filtresi.dart';
import 'package:uretim_takip/pages/model/model_detay.dart';
import 'package:uretim_takip/services/gelismis_rapor_servisleri.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class GelismisRaporlarPage extends StatefulWidget {
  const GelismisRaporlarPage({super.key});

  @override
  State<GelismisRaporlarPage> createState() => _GelismisRaporlarPageState();
}

class _GelismisRaporlarPageState extends State<GelismisRaporlarPage> {
  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final _number = NumberFormat.decimalPattern('tr_TR');
  final _date = DateFormat('dd.MM.yyyy', 'tr_TR');
  final _searchController = TextEditingController();
  final _tableScrollController = ScrollController();
  final _expandedModelIds = <String>{};

  bool _loading = true;
  Map<String, dynamic> _rapor = {};
  DateTime? _baslangic;
  DateTime? _bitis;
  String _hizliTarih = 'Tüm Zamanlar';
  String _durumFiltresi = 'tum';
  String _markaFiltresi = 'tum';
  String _arama = '';

  @override
  void initState() {
    super.initState();
    _raporuYukle();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  Future<void> _raporuYukle() async {
    setState(() => _loading = true);
    final rapor = await GelismisRaporServisleri.getYuklemeFinansAnalizi(
      baslangicTarihi: _baslangic,
      bitisTarihi: _bitis,
      filtre: RaporFiltresi(
        baslangicTarihi: _baslangic,
        bitisTarihi: _bitis,
      ),
    );
    if (!mounted) return;
    setState(() {
      _rapor = rapor;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _modeller {
    final modeller =
        List<Map<String, dynamic>>.from(_rapor['modelFinanslari'] ?? []);
    return modeller.where((model) {
      final durum = model['durum']?.toString() ?? '';
      if (_durumFiltresi != 'tum' && durum != _durumFiltresi) return false;

      final marka = model['marka']?.toString() ?? '';
      if (_markaFiltresi != 'tum' && marka != _markaFiltresi) return false;

      if (_arama.trim().isEmpty) return true;
      final q = _arama.toLowerCase();
      final metin =
          '${model['marka'] ?? ''} ${model['itemNo'] ?? ''} ${model['renk'] ?? ''}'
              .toLowerCase();
      return metin.contains(q);
    }).toList();
  }

  List<String> get _markalar {
    final markalar = <String>{};
    for (final marka in List<Map<String, dynamic>>.from(
      _rapor['markaAnalizi'] ?? [],
    )) {
      final ad = marka['marka']?.toString();
      if (ad != null && ad.trim().isNotEmpty) markalar.add(ad);
    }
    for (final model in List<Map<String, dynamic>>.from(
      _rapor['modelFinanslari'] ?? [],
    )) {
      final ad = model['marka']?.toString();
      if (ad != null && ad.trim().isNotEmpty) markalar.add(ad);
    }
    if (_markaFiltresi != 'tum') markalar.add(_markaFiltresi);
    return markalar.toList()..sort();
  }

  bool get _filtreAktif =>
      _durumFiltresi != 'tum' ||
      _markaFiltresi != 'tum' ||
      _arama.trim().isNotEmpty;

  Map<String, dynamic> get _aktifRapor {
    if (!_filtreAktif) return _rapor;
    final modeller = _modeller;
    final durumDagilimi = <String, int>{};
    final markaAnalizi = <String, Map<String, dynamic>>{};
    final maliyetDagilimi = <String, double>{};
    double toplamHedefMaliyet = 0;
    double toplamGercekMaliyet = 0;
    double toplamUretimMaliyeti = 0;
    double toplamOperasyonelGider = 0;
    double toplamFireMaliyeti = 0;
    double toplamSatisGeliri = 0;
    double toplamBrutKar = 0;
    double toplamKar = 0;
    double toplamKayipKazanc = 0;
    int toplamSiparisAdedi = 0;
    int toplamUretilenAdet = 0;
    int toplamDonemYuklenenAdet = 0;
    int toplamYuklenenAdet = 0;
    int toplamKalanAdet = 0;
    int toplamFireAdedi = 0;
    int zararModelSayisi = 0;
    int hedefAltiSayisi = 0;
    int fiyatEksikSayisi = 0;
    int maliyetEksikSayisi = 0;
    int hesaplanabilirModelSayisi = 0;

    for (final model in modeller) {
      final durum = model['durum']?.toString() ?? '';
      durumDagilimi[durum] = (durumDagilimi[durum] ?? 0) + 1;
      if (durum == 'zarar_riski') zararModelSayisi++;
      if (durum == 'hedef_alti') hedefAltiSayisi++;
      if (durum == 'fiyat_eksik') fiyatEksikSayisi++;
      if (durum == 'maliyet_eksik') maliyetEksikSayisi++;
      if (_nullableNum(model['netKar']) != null) hesaplanabilirModelSayisi++;

      toplamHedefMaliyet += _num(model['hedefMaliyet']);
      toplamGercekMaliyet += _num(model['gercekMaliyet']);
      toplamUretimMaliyeti += _num(model['toplamUretimMaliyeti']);
      toplamOperasyonelGider += _num(model['toplamOperasyonelMaliyet']);
      toplamFireMaliyeti += _num(model['fireMaliyeti']);
      toplamSatisGeliri += _num(model['satisGeliri']);
      toplamBrutKar += _num(model['brutKar']);
      toplamKar += _num(model['netKar']);
      toplamKayipKazanc += _num(model['kayipKazanc']);
      toplamSiparisAdedi += _num(model['siparisAdedi']).round();
      toplamUretilenAdet += _num(model['uretilenAdet']).round();
      toplamDonemYuklenenAdet += _num(model['donemYuklenenAdet']).round();
      toplamYuklenenAdet += _num(model['toplamYuklenenAdet']).round();
      toplamKalanAdet += _num(model['kalanAdet']).round();
      toplamFireAdedi += _num(model['fireAdedi']).round();

      final marka = model['marka']?.toString().trim().isNotEmpty == true
          ? model['marka'].toString()
          : 'Diğer';
      final markaSatiri = markaAnalizi.putIfAbsent(
        marka,
        () => {
          'marka': marka,
          'modelSayisi': 0,
          'siparisAdedi': 0,
          'ciro': 0.0,
          'maliyet': 0.0,
          'kar': 0.0,
        },
      );
      markaSatiri['modelSayisi'] = _num(markaSatiri['modelSayisi']).round() + 1;
      markaSatiri['siparisAdedi'] = _num(markaSatiri['siparisAdedi']).round() +
          _num(model['siparisAdedi']).round();
      markaSatiri['ciro'] =
          _num(markaSatiri['ciro']) + _num(model['satisGeliri']);
      markaSatiri['maliyet'] =
          _num(markaSatiri['maliyet']) + _num(model['genelToplamMaliyet']);
      markaSatiri['kar'] = _num(markaSatiri['kar']) + _num(model['netKar']);

      final kalemler =
          List<Map<String, dynamic>>.from(model['maliyetKalemleri'] ?? []);
      for (final kalem in kalemler) {
        final ad = kalem['ad']?.toString() ?? 'Diğer';
        maliyetDagilimi[ad] = (maliyetDagilimi[ad] ?? 0) +
            _num(kalem['gercekBirim']) * _num(model['donemYuklenenAdet']);
      }
      if (_num(model['fireMaliyeti']) > 0) {
        maliyetDagilimi['Fire Maliyeti'] =
            (maliyetDagilimi['Fire Maliyeti'] ?? 0) +
                _num(model['fireMaliyeti']);
      }
      if (_num(model['toplamOperasyonelMaliyet']) > 0) {
        maliyetDagilimi['Operasyonel Gider'] =
            (maliyetDagilimi['Operasyonel Gider'] ?? 0) +
                _num(model['toplamOperasyonelMaliyet']);
      }
    }

    final toplamGenelToplamMaliyet =
        toplamUretimMaliyeti + toplamOperasyonelGider + toplamFireMaliyeti;
    final markalar = markaAnalizi.values.map((marka) {
      final ciro = _num(marka['ciro']);
      final maliyet = _num(marka['maliyet']);
      final kar = _num(marka['kar']);
      return {
        ...marka,
        'karMarji': maliyet > 0 ? (kar / maliyet) * 100 : 0.0,
        'netKarMarji': ciro > 0 ? (kar / ciro) * 100 : 0.0,
      };
    }).toList()
      ..sort((a, b) => _num(b['kar']).compareTo(_num(a['kar'])));
    final zararli = modeller
        .where((model) => _num(model['netKar']) < 0)
        .toList()
      ..sort((a, b) => _num(a['netKar']).compareTo(_num(b['netKar'])));
    final karli = modeller.where((model) => _num(model['netKar']) > 0).toList()
      ..sort((a, b) => _num(b['netKar']).compareTo(_num(a['netKar'])));

    return {
      ..._rapor,
      'modelFinanslari': modeller,
      'durumDagilimi': durumDagilimi,
      'markaAnalizi': markalar,
      'maliyetDagilimi': maliyetDagilimi.entries
          .map((entry) => {'ad': entry.key, 'tutar': entry.value})
          .where((entry) => _num(entry['tutar']) > 0)
          .toList()
        ..sort((a, b) => _num(b['tutar']).compareTo(_num(a['tutar']))),
      'enKarliModeller': karli.take(10).toList(),
      'enZararliModeller': zararli.take(10).toList(),
      'toplamModel': modeller.length,
      'toplamSiparisAdedi': toplamSiparisAdedi,
      'toplamUretilenAdet': toplamUretilenAdet,
      'toplamDonemYuklenenAdet': toplamDonemYuklenenAdet,
      'toplamYuklenenAdet': toplamYuklenenAdet,
      'toplamKalanAdet': toplamKalanAdet,
      'toplamHedefMaliyet': toplamHedefMaliyet,
      'toplamGercekMaliyet': toplamGercekMaliyet,
      'toplamUretimMaliyeti': toplamUretimMaliyeti,
      'toplamOperasyonelGider': toplamOperasyonelGider,
      'genelToplamMaliyet': toplamGenelToplamMaliyet,
      'toplamSatisGeliri': toplamSatisGeliri,
      'toplamBrutKar': toplamBrutKar,
      'toplamNetKar': toplamKar,
      'toplamKar': toplamKar,
      'toplamKayipKazanc': toplamKayipKazanc,
      'ortalamaKarMarji': toplamGenelToplamMaliyet > 0
          ? (toplamKar / toplamGenelToplamMaliyet) * 100
          : 0.0,
      'ortalamaNetKarMarji':
          toplamSatisGeliri > 0 ? (toplamKar / toplamSatisGeliri) * 100 : 0.0,
      'maliyetSapmasi': toplamGercekMaliyet - toplamHedefMaliyet,
      'maliyetSapmaOrani': toplamHedefMaliyet > 0
          ? ((toplamGercekMaliyet - toplamHedefMaliyet) / toplamHedefMaliyet) *
              100
          : 0.0,
      'toplamFireAdedi': toplamFireAdedi,
      'toplamFireMaliyeti': toplamFireMaliyeti,
      'fireOrani': toplamSiparisAdedi > 0
          ? (toplamFireAdedi / toplamSiparisAdedi) * 100
          : 0.0,
      'zararModelSayisi': zararModelSayisi,
      'hedefAltiSayisi': hedefAltiSayisi,
      'fiyatEksikSayisi': fiyatEksikSayisi,
      'maliyetEksikSayisi': maliyetEksikSayisi,
      'hesaplanabilirModelSayisi': hesaplanabilirModelSayisi,
    };
  }

  Future<void> _tarihAraligiSec() async {
    final secim = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      initialDateRange: _baslangic != null && _bitis != null
          ? DateTimeRange(start: _baslangic!, end: _bitis!)
          : null,
      locale: const Locale('tr', 'TR'),
    );
    if (secim == null) return;
    setState(() {
      _baslangic = secim.start;
      _bitis = secim.end;
      _hizliTarih = '${_date.format(secim.start)} - ${_date.format(secim.end)}';
    });
    await _raporuYukle();
  }

  Future<void> _hizliTarihSec(String deger) async {
    final now = DateTime.now();
    setState(() {
      _hizliTarih = deger;
      switch (deger) {
        case 'Bugün':
          _baslangic = DateTime(now.year, now.month, now.day);
          _bitis = now;
          break;
        case 'Bu Hafta':
          _baslangic = now.subtract(const Duration(days: 7));
          _bitis = now;
          break;
        case 'Bu Ay':
          _baslangic = DateTime(now.year, now.month, 1);
          _bitis = now;
          break;
        case 'Son 3 Ay':
          _baslangic = DateTime(now.year, now.month - 3, 1);
          _bitis = now;
          break;
        case 'Bu Yıl':
          _baslangic = DateTime(now.year, 1, 1);
          _bitis = now;
          break;
        default:
          _baslangic = null;
          _bitis = null;
      }
    });
    await _raporuYukle();
  }

  void _modelDetayAc(Map<String, dynamic> model) {
    final modelId = model['id']?.toString();
    if (modelId == null || modelId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModelDetay(
          modelId: modelId,
          modelData: {
            'id': modelId,
            'marka': model['marka'],
            'item_no': model['itemNo'],
            'renk': model['renk'],
            'toplam_adet': model['siparisAdedi'],
            'yuklenen_adet': model['toplamYuklenenAdet'],
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFiltreler(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _raporuYukle,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVeriNotu(),
                            const SizedBox(height: 12),
                            _buildKpiAlani(),
                            const SizedBox(height: 12),
                            _buildDurumOzeti(),
                            const SizedBox(height: 12),
                            _buildDashboardGrafikleri(),
                            const SizedBox(height: 12),
                            _buildMarkaAnalizi(),
                            const SizedBox(height: 12),
                            _buildKarZararListeleri(),
                            const SizedBox(height: 12),
                            _buildModelTablosu(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.analytics, color: Color(0xFF0F766E)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yükleme Finans Raporu',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Yüklenen modellerde hedef maliyet, gerçekleşen maliyet, fire ve kar/zarar takibi',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _raporuYukle,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltreler() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 820;
          final tarih = DropdownButtonFormField<String>(
            key: ValueKey(_hizliTarih),
            initialValue: _hizliTarih,
            decoration: _inputDecoration('Dönem'),
            items: const [
              'Bugün',
              'Tüm Zamanlar',
              'Bu Hafta',
              'Bu Ay',
              'Son 3 Ay',
              'Bu Yıl',
            ].map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value != null) _hizliTarihSec(value);
            },
          );
          final durum = DropdownButtonFormField<String>(
            key: ValueKey(_durumFiltresi),
            initialValue: _durumFiltresi,
            decoration: _inputDecoration('Durum'),
            items: const [
              DropdownMenuItem(value: 'tum', child: Text('Tümü')),
              DropdownMenuItem(value: 'hedefte', child: Text('Hedefte')),
              DropdownMenuItem(value: 'hedef_alti', child: Text('Hedef Altı')),
              DropdownMenuItem(
                  value: 'zarar_riski', child: Text('Zarar Riski')),
              DropdownMenuItem(
                  value: 'maliyet_eksik', child: Text('Maliyet Eksik')),
              DropdownMenuItem(
                  value: 'fiyat_eksik', child: Text('Fiyat Eksik')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _durumFiltresi = value);
            },
          );
          final marka = DropdownButtonFormField<String>(
            key: ValueKey(_markaFiltresi),
            initialValue: _markaFiltresi,
            decoration: _inputDecoration('Marka'),
            items: [
              const DropdownMenuItem(value: 'tum', child: Text('Tümü')),
              ..._markalar.map(
                (item) => DropdownMenuItem(value: item, child: Text(item)),
              ),
            ],
            onChanged: (value) async {
              if (value == null) return;
              setState(() => _markaFiltresi = value);
            },
          );
          final arama = TextField(
            controller: _searchController,
            decoration: _inputDecoration('Model, marka veya renk ara').copyWith(
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _arama = value),
          );
          final tarihButonu = OutlinedButton.icon(
            onPressed: _tarihAraligiSec,
            icon: const Icon(Icons.date_range, size: 18),
            label: const Text('Tarih Seç'),
          );

          final excelButonu = OutlinedButton.icon(
            onPressed: _excelAktar,
            icon: const Icon(Icons.table_view, size: 18),
            label: const Text('Excel'),
          );
          final pdfButonu = OutlinedButton.icon(
            onPressed: _pdfAktar,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
          );

          if (dar) {
            return Column(
              children: [
                tarih,
                const SizedBox(height: 8),
                durum,
                const SizedBox(height: 8),
                marka,
                const SizedBox(height: 8),
                arama,
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: tarihButonu),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: excelButonu),
                    const SizedBox(width: 8),
                    Expanded(child: pdfButonu),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 180, child: tarih),
              const SizedBox(width: 10),
              SizedBox(width: 190, child: durum),
              const SizedBox(width: 10),
              SizedBox(width: 190, child: marka),
              const SizedBox(width: 10),
              Expanded(child: arama),
              const SizedBox(width: 10),
              tarihButonu,
              const SizedBox(width: 8),
              excelButonu,
              const SizedBox(width: 8),
              pdfButonu,
            ],
          );
        },
      ),
    );
  }

  Widget _buildVeriNotu() {
    final hata = _rapor['hata']?.toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            (hata == null ? Colors.blue : Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              (hata == null ? Colors.blue : Colors.red).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hata == null ? Icons.info_outline : Icons.error_outline,
            color: hata == null ? Colors.blue.shade700 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hata ??
                  'Kar/zarar sadece satış fiyatı ve gerçekleşen maliyeti olan yükleme kayıtlarında hesaplanır. Eksik veriler tahmin edilmez.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiAlani() {
    final rapor = _aktifRapor;
    final kartlar = [
      _KpiData('Yüklenen Model', '${rapor['toplamModel'] ?? 0}', Icons.category,
          Colors.blue),
      _KpiData(
          'Dönem Yüklenen',
          '${_adet(rapor['toplamDonemYuklenenAdet'])} adet',
          Icons.upload,
          Colors.indigo),
      _KpiData('Toplam Yüklenen', '${_adet(rapor['toplamYuklenenAdet'])} adet',
          Icons.local_shipping, Colors.teal),
      _KpiData('Kalan', '${_adet(rapor['toplamKalanAdet'])} adet',
          Icons.inventory_2, Colors.orange),
      _KpiData('Hedef Maliyet', _para(rapor['toplamHedefMaliyet']), Icons.flag,
          Colors.blueGrey),
      _KpiData('Gerçek Maliyet', _para(rapor['toplamGercekMaliyet']),
          Icons.receipt_long, Colors.deepPurple),
      _KpiData(
          'Kar / Zarar',
          _para(rapor['toplamKar']),
          _num(rapor['toplamKar']) >= 0
              ? Icons.trending_up
              : Icons.trending_down,
          _num(rapor['toplamKar']) >= 0 ? Colors.green : Colors.red),
      _KpiData('Fire Maliyeti', _para(rapor['toplamFireMaliyeti']),
          Icons.warning_amber, Colors.redAccent),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1120
          ? 4
          : constraints.maxWidth >= 760
              ? 3
              : constraints.maxWidth >= 520
                  ? 2
                  : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kartlar.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: columns == 1 ? 4.4 : 3.0,
        ),
        itemBuilder: (context, index) => _buildKpiKart(kartlar[index]),
      );
    });
  }

  Widget _buildKpiKart(_KpiData data) {
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 4),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: TextStyle(
                      color: data.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumOzeti() {
    final rapor = _aktifRapor;
    final items = [
      ('Hedefte', rapor['durumDagilimi']?['hedefte'] ?? 0, Colors.green),
      ('Hedef Altı', rapor['hedefAltiSayisi'] ?? 0, Colors.orange),
      ('Zarar Riski', rapor['zararModelSayisi'] ?? 0, Colors.red),
      ('Maliyet Eksik', rapor['maliyetEksikSayisi'] ?? 0, Colors.blueGrey),
      ('Fiyat Eksik', rapor['fiyatEksikSayisi'] ?? 0, Colors.purple),
      ('Hesaplanabilir', rapor['hesaplanabilirModelSayisi'] ?? 0, Colors.teal),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: item.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: item.$3.withValues(alpha: 0.2)),
            ),
            child: Text(
              '${item.$1}: ${item.$2}',
              style: TextStyle(color: item.$3, fontWeight: FontWeight.w700),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboardGrafikleri() {
    final rapor = _aktifRapor;
    final aylik = List<Map<String, dynamic>>.from(rapor['aylikAnaliz'] ?? []);
    final maliyet =
        List<Map<String, dynamic>>.from(rapor['maliyetDagilimi'] ?? []);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dar = constraints.maxWidth < 900;
        final finans = _buildAnalizPaneli(
          baslik: 'Finans Performansi',
          icon: Icons.show_chart,
          children: [
            _metrikSatiri(
                'Toplam Ciro', _para(rapor['toplamSatisGeliri']), Colors.teal),
            _metrikSatiri('Toplam Uretim Maliyeti',
                _para(rapor['toplamUretimMaliyeti']), Colors.deepPurple),
            _metrikSatiri('Operasyonel Gider',
                _para(rapor['toplamOperasyonelGider']), Colors.blueGrey),
            _metrikSatiri(
              'Net Kar',
              _para(rapor['toplamNetKar'] ?? rapor['toplamKar']),
              _num(rapor['toplamNetKar'] ?? rapor['toplamKar']) >= 0
                  ? Colors.green
                  : Colors.red,
            ),
            _metrikSatiri('Kayip Kazanc', _para(rapor['toplamKayipKazanc']),
                Colors.orange),
          ],
        );
        final grafik = _buildAnalizPaneli(
          baslik: 'Aylik Ciro ve Kar',
          icon: Icons.bar_chart,
          children: aylik.isEmpty
              ? [const Text('Aylik grafik icin yukleme verisi yok.')]
              : [_miniBarGrafik(aylik, 'ciro', 'kar')],
        );
        final dagilim = _buildAnalizPaneli(
          baslik: 'Maliyet Dagilimi',
          icon: Icons.pie_chart,
          children: maliyet.isEmpty
              ? [const Text('Maliyet dagilimi icin veri yok.')]
              : [_dagilimListesi(maliyet.take(8).toList())],
        );
        final uretim = _buildAnalizPaneli(
          baslik: 'Uretim ve Yukleme',
          icon: Icons.factory,
          children: [
            _metrikSatiri('Toplam Siparis',
                '${_adet(rapor['toplamSiparisAdedi'])} adet', Colors.blue),
            _metrikSatiri('Uretilen',
                '${_adet(rapor['toplamUretilenAdet'])} adet', Colors.indigo),
            _metrikSatiri('Yuklenen',
                '${_adet(rapor['toplamYuklenenAdet'])} adet', Colors.teal),
            _metrikSatiri(
                'Fire', '${_adet(rapor['toplamFireAdedi'])} adet', Colors.red),
          ],
        );

        if (dar) {
          return Column(
            children: [
              finans,
              const SizedBox(height: 10),
              grafik,
              const SizedBox(height: 10),
              dagilim,
              const SizedBox(height: 10),
              uretim,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: finans),
            const SizedBox(width: 10),
            Expanded(child: grafik),
            const SizedBox(width: 10),
            Expanded(child: dagilim),
            const SizedBox(width: 10),
            Expanded(child: uretim),
          ],
        );
      },
    );
  }

  Widget _buildMarkaAnalizi() {
    final markalar =
        List<Map<String, dynamic>>.from(_aktifRapor['markaAnalizi'] ?? []);
    if (markalar.isEmpty) return const SizedBox.shrink();
    return _buildAnalizPaneli(
      baslik: 'Marka Bazli Karlilik',
      icon: Icons.business,
      children: markalar.take(8).map((marka) {
        return _listeSatiri(
          marka['marka']?.toString() ?? '-',
          '${_para(marka['ciro'])} ciro',
          _para(marka['kar']),
          _num(marka['kar']) >= 0 ? Colors.green : Colors.red,
        );
      }).toList(),
    );
  }

  Widget _buildKarZararListeleri() {
    final karli =
        List<Map<String, dynamic>>.from(_aktifRapor['enKarliModeller'] ?? []);
    final zararli =
        List<Map<String, dynamic>>.from(_aktifRapor['enZararliModeller'] ?? []);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sol = _buildAnalizPaneli(
          baslik: 'En Karli 10 Model',
          icon: Icons.trending_up,
          children: karli.isEmpty
              ? [const Text('Karli model bulunamadi.')]
              : karli
                  .map((model) => _listeSatiri(
                        '${model['marka'] ?? '-'} - ${model['itemNo'] ?? '-'}',
                        _oranNullable(model['karMarji']),
                        _para(model['netKar']),
                        Colors.green,
                      ))
                  .toList(),
        );
        final sag = _buildAnalizPaneli(
          baslik: 'En Zararli 10 Model',
          icon: Icons.trending_down,
          children: zararli.isEmpty
              ? [const Text('Zararli model bulunamadi.')]
              : zararli
                  .map((model) => _listeSatiri(
                        '${model['marka'] ?? '-'} - ${model['itemNo'] ?? '-'}',
                        _oranNullable(model['karMarji']),
                        _para(model['netKar']),
                        Colors.red,
                      ))
                  .toList(),
        );
        if (constraints.maxWidth < 820) {
          return Column(children: [sol, const SizedBox(height: 10), sag]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sol),
            const SizedBox(width: 10),
            Expanded(child: sag)
          ],
        );
      },
    );
  }

  Widget _buildAnalizPaneli({
    required String baslik,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: const Color(0xFF0F766E), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _metrikSatiri(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Color(0xFF64748B)))),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _listeSatiri(String baslik, String alt, String deger, Color renk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(alt,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Text(deger,
              style: TextStyle(color: renk, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _miniBarGrafik(
    List<Map<String, dynamic>> rows,
    String primaryKey,
    String secondaryKey,
  ) {
    final maxDeger = rows.fold<double>(0, (max, row) {
      final a = _num(row[primaryKey]).abs();
      final b = _num(row[secondaryKey]).abs();
      return [max, a, b].reduce((x, y) => x > y ? x : y);
    });
    return Column(
      children: rows.take(8).map((row) {
        final primary = _num(row[primaryKey]);
        final secondary = _num(row[secondaryKey]);
        final primaryWidth = maxDeger <= 0 ? 0.0 : (primary.abs() / maxDeger);
        final secondaryWidth =
            maxDeger <= 0 ? 0.0 : (secondary.abs() / maxDeger);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row['ay']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              _bar(primaryWidth, Colors.teal),
              const SizedBox(height: 3),
              _bar(secondaryWidth, secondary >= 0 ? Colors.green : Colors.red),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _dagilimListesi(List<Map<String, dynamic>> rows) {
    final toplam = rows.fold<double>(0, (sum, row) => sum + _num(row['tutar']));
    return Column(
      children: rows.map((row) {
        final tutar = _num(row['tutar']);
        final oran = toplam <= 0 ? 0.0 : tutar / toplam;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(row['ad']?.toString() ?? '-')),
                  Text(_para(tutar),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              _bar(oran, Colors.deepPurple),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _bar(double oran, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * oran.clamp(0, 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelTablosu() {
    final modeller = _modeller;
    if (modeller.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child:
              Text('Seçili filtrelerde yükleme kaydı olan model bulunamadı.'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.table_chart, color: Color(0xFF0F766E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Model Bazlı Finans Detayı (${modeller.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ScrollConfiguration(
            behavior: const _ReportScrollBehavior(),
            child: Scrollbar(
              controller: _tableScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 10,
              child: SingleChildScrollView(
                controller: _tableScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  width: 1900,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFinansBaslikSatiri(),
                      ...modeller.map(_buildModelFinansSatiri),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinansBaslikSatiri() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _headerCell('', 44),
          _headerCell('Durum', 120),
          _headerCell('Model', 300),
          _headerCell('Renk', 100),
          _headerCell('Sipariş', 90, align: TextAlign.right),
          _headerCell('Dönem Yüklenen', 130, align: TextAlign.right),
          _headerCell('Toplam Yüklenen', 140, align: TextAlign.right),
          _headerCell('Kalan', 90, align: TextAlign.right),
          _headerCell('Birim Hedef', 120, align: TextAlign.right),
          _headerCell('Birim Gerçek', 120, align: TextAlign.right),
          _headerCell('Satış Fiyatı', 120, align: TextAlign.right),
          _headerCell('Hedef Maliyet', 130, align: TextAlign.right),
          _headerCell('Gerçek Maliyet', 130, align: TextAlign.right),
          _headerCell('Sapma', 110, align: TextAlign.right),
          _headerCell('Fire', 120, align: TextAlign.right),
          _headerCell('Fire Maliyeti', 120, align: TextAlign.right),
          _headerCell('Kar/Zarar', 130, align: TextAlign.right),
          _headerCell('Gerçek Kâr Oranı', 120, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildModelFinansSatiri(Map<String, dynamic> model) {
    final modelId = model['id']?.toString() ?? '';
    final expanded = _expandedModelIds.contains(modelId);
    final durum = model['durum']?.toString() ?? '';
    final kar = _nullableNum(model['kar']);
    final sapma = _nullableNum(model['maliyetSapmasi']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (modelId.isEmpty) return;
            setState(() {
              if (expanded) {
                _expandedModelIds.remove(modelId);
              } else {
                _expandedModelIds.add(modelId);
              }
            });
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: expanded ? const Color(0xFFF8FAFC) : Colors.white,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                _cell(
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF475569),
                  ),
                  44,
                ),
                _cell(_durumChip(durum), 120),
                _cell(
                  Text(
                    '${model['marka'] ?? '-'} • ${model['itemNo'] ?? '-'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  300,
                ),
                _textCell(model['renk']?.toString() ?? '-', 100),
                _textCell(_adet(model['siparisAdedi']), 90,
                    align: TextAlign.right),
                _textCell(_adet(model['donemYuklenenAdet']), 130,
                    align: TextAlign.right),
                _textCell(_adet(model['toplamYuklenenAdet']), 140,
                    align: TextAlign.right),
                _textCell(_adet(model['kalanAdet']), 90,
                    align: TextAlign.right),
                _textCell(_paraNullable(model['planBirimMaliyet']), 120,
                    align: TextAlign.right),
                _textCell(_paraNullable(model['gercekBirimMaliyet']), 120,
                    align: TextAlign.right),
                _textCell(_paraNullable(model['satisBirimFiyati']), 120,
                    align: TextAlign.right),
                _textCell(_paraNullable(model['hedefMaliyet']), 130,
                    align: TextAlign.right),
                _textCell(_paraNullable(model['gercekMaliyet']), 130,
                    align: TextAlign.right),
                _textCell(
                  _paraNullable(sapma),
                  110,
                  align: TextAlign.right,
                  color: sapma == null
                      ? Colors.blueGrey
                      : (sapma <= 0 ? Colors.green : Colors.red),
                  fontWeight: FontWeight.w800,
                ),
                _textCell(
                  '${_adet(model['fireAdedi'])} / %${_num(model['fireOrani']).toStringAsFixed(1)}',
                  120,
                  align: TextAlign.right,
                ),
                _textCell(_paraNullable(model['fireBirimMaliyeti']), 120,
                    align: TextAlign.right),
                _textCell(
                  _paraNullable(kar),
                  130,
                  align: TextAlign.right,
                  color: kar == null
                      ? Colors.blueGrey
                      : (kar >= 0 ? Colors.green : Colors.red),
                  fontWeight: FontWeight.w800,
                ),
                _textCell(_oranNullable(model['karMarji']), 120,
                    align: TextAlign.right),
              ],
            ),
          ),
        ),
        if (expanded) _buildModelMaliyetDetayi(model),
      ],
    );
  }

  Widget _buildModelMaliyetDetayi(Map<String, dynamic> model) {
    final kalemler =
        List<Map<String, dynamic>>.from(model['maliyetKalemleri'] ?? []);
    final adet = _num(model['donemYuklenenAdet']).round();
    final kaynak = model['fiyatlandirmaKaynak']?.toString() ?? 'Fiyatlandırma';

    return Container(
      width: 1900,
      padding: const EdgeInsets.fromLTRB(44, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.price_change, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maliyet detayları • Kaynak: $kaynak',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _modelDetayAc(model),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Model Detayı'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ozetChip('Satış', _paraNullable(model['satisBirimFiyati'])),
              _ozetChip(
                  'Birim hedef', _paraNullable(model['planBirimMaliyet'])),
              _ozetChip(
                  'Birim gerçek', _paraNullable(model['gercekBirimMaliyet'])),
              _ozetChip(
                  'Fire birim', _paraNullable(model['fireBirimMaliyeti'])),
              _ozetChip(
                  'Hedef kar oranı', _oranNullable(model['hedefKarOrani'])),
              _ozetChip('Gerçek kar oranı', _oranNullable(model['karMarji'])),
              _ozetChip('Net kar marjı', _oranNullable(model['netKarMarji'])),
            ],
          ),
          const SizedBox(height: 12),
          if (kalemler.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Bu modelin fiyatlandırma bölümünde maliyet kalemi bulunamadı.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            Container(
              width: 1160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        _headerCell('Kalem', 260),
                        _headerCell('Plan Birim', 150, align: TextAlign.right),
                        _headerCell('Gerçek Birim', 150,
                            align: TextAlign.right),
                        _headerCell('Plan Toplam', 170, align: TextAlign.right),
                        _headerCell('Gerçek Toplam', 170,
                            align: TextAlign.right),
                        _headerCell('Kaynak', 250),
                      ],
                    ),
                  ),
                  ...kalemler.map((kalem) => _buildMaliyetKalemiSatiri(
                        kalem,
                        adet,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaliyetKalemiSatiri(Map<String, dynamic> kalem, int adet) {
    final planBirim = _num(kalem['planBirim']);
    final gercekBirim = _num(kalem['gercekBirim']);
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _textCell(kalem['ad']?.toString() ?? '-', 260,
              fontWeight: FontWeight.w700),
          _textCell(_para(planBirim), 150, align: TextAlign.right),
          _textCell(_para(gercekBirim), 150, align: TextAlign.right),
          _textCell(_para(planBirim * adet), 170, align: TextAlign.right),
          _textCell(_para(gercekBirim * adet), 170, align: TextAlign.right),
          _textCell(_kalemKaynakMetni(kalem['kaynak']), 250),
        ],
      ),
    );
  }

  Widget _ozetChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _headerCell(String text, double width,
      {TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _cell(Widget child, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: child,
      ),
    );
  }

  Widget _textCell(
    String text,
    double width, {
    TextAlign align = TextAlign.left,
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _cell(
      Text(
        text,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? const Color(0xFF1E293B),
          fontWeight: fontWeight,
        ),
      ),
      width,
    );
  }

  String _kalemKaynakMetni(dynamic kaynak) {
    switch (kaynak?.toString()) {
      case 'model_fiyatlandirma':
        return 'Model fiyatlandırma';
      case 'plan':
        return 'Aktif maliyet planı';
      default:
        return kaynak?.toString().isNotEmpty == true
            ? kaynak.toString()
            : 'Fiyatlandırma';
    }
  }

  Future<void> _excelAktar() async {
    final rows = _modeller.map((model) {
      return {
        'marka': model['marka'] ?? '',
        'model': model['itemNo'] ?? '',
        'renk': model['renk'] ?? '',
        'siparis_adedi': _num(model['siparisAdedi']).round(),
        'uretilen_adet': _num(model['uretilenAdet']).round(),
        'yuklenen_adet': _num(model['toplamYuklenenAdet']).round(),
        'satis_fiyati': _num(model['satisBirimFiyati']),
        'toplam_ciro': _num(model['satisGeliri']),
        'uretim_maliyeti': _num(model['toplamUretimMaliyeti']),
        'operasyonel_maliyet': _num(model['toplamOperasyonelMaliyet']),
        'fire_maliyeti': _num(model['fireMaliyeti']),
        'genel_toplam_maliyet': _num(model['genelToplamMaliyet']),
        'brut_kar': _num(model['brutKar']),
        'net_kar': _num(model['netKar']),
        'hedef_kar_orani': _num(model['hedefKarOrani']),
        'gercek_kar_orani': _num(model['karMarji']),
        'net_kar_marji': _num(model['netKarMarji']),
        'birim_kar': _num(model['birimKar']),
        'kayip_kazanc': _num(model['kayipKazanc']),
      };
    }).toList();
    if (rows.isEmpty) {
      context.showErrorSnackBar('Dışa aktarılacak model yok');
      return;
    }

    try {
      await ExcelHelper.exportToExcel(
        data: rows,
        fileName:
            'Gelismis_Finans_Raporu_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
        columns: const {
          'marka': 'Marka',
          'model': 'Model',
          'renk': 'Renk',
          'siparis_adedi': 'Sipariş Adedi',
          'uretilen_adet': 'Üretilen Adet',
          'yuklenen_adet': 'Yüklenen Adet',
          'satis_fiyati': 'Satış Fiyatı',
          'toplam_ciro': 'Toplam Ciro',
          'uretim_maliyeti': 'Üretim Maliyeti',
          'operasyonel_maliyet': 'Operasyonel Maliyet',
          'fire_maliyeti': 'Fire Maliyeti',
          'genel_toplam_maliyet': 'Genel Toplam Maliyet',
          'brut_kar': 'Brüt Kar',
          'net_kar': 'Net Kar',
          'hedef_kar_orani': 'Hedef Kâr Oranı',
          'gercek_kar_orani': 'Gerçek Kâr Oranı',
          'net_kar_marji': 'Net Kâr Marjı',
          'birim_kar': 'Birim Kar',
          'kayip_kazanc': 'Kayıp Kazanç',
        },
      );
      if (!mounted) return;
      context.showSuccessSnackBar('Excel raporu oluşturuldu');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Excel aktarımı başarısız: $e');
    }
  }

  Future<void> _pdfAktar() async {
    final doc = pw.Document();
    final rows = _modeller.take(30).map((model) {
      return [
        '${model['marka'] ?? '-'} ${model['itemNo'] ?? '-'}',
        _para(model['satisGeliri']),
        _para(model['genelToplamMaliyet']),
        _para(model['netKar']),
        _oranNullable(model['karMarji']),
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Text('Gelismis Finans ve Karlilik Raporu',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Donem: $_hizliTarih'),
          pw.Text(
              'Marka: ${_markaFiltresi == 'tum' ? 'Tum markalar' : _markaFiltresi}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Model',
              'Ciro',
              'Maliyet',
              'Net Kar',
              'Gercek Kar Orani'
            ],
            data: rows,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle:
                pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('PDF aktarımı başarısız: $e');
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _durumChip(String durum) {
    final color = _durumRengi(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        _durumMetni(durum),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _durumMetni(String durum) {
    switch (durum) {
      case 'hedefte':
        return 'Hedefte';
      case 'hedef_alti':
        return 'Hedef Altı';
      case 'zarar_riski':
        return 'Zarar Riski';
      case 'maliyet_eksik':
        return 'Maliyet Eksik';
      case 'fiyat_eksik':
        return 'Fiyat Eksik';
      default:
        return 'Kontrol';
    }
  }

  Color _durumRengi(String durum) {
    switch (durum) {
      case 'hedefte':
        return Colors.green;
      case 'hedef_alti':
        return Colors.orange;
      case 'zarar_riski':
        return Colors.red;
      case 'maliyet_eksik':
        return Colors.blueGrey;
      case 'fiyat_eksik':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  String _para(dynamic value) => _currency.format(_num(value));

  String _paraNullable(dynamic value) {
    final parsed = _nullableNum(value);
    return parsed == null ? 'Eksik' : _currency.format(parsed);
  }

  String _oranNullable(dynamic value) {
    final parsed = _nullableNum(value);
    return parsed == null ? 'Eksik' : '%${parsed.toStringAsFixed(1)}';
  }

  String _adet(dynamic value) => _number.format(_num(value).round());

  double _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  double? _nullableNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}

class _ReportScrollBehavior extends MaterialScrollBehavior {
  const _ReportScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
