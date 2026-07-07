import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
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
  bool _yukleniyor = false;

  String aramaMetni = '';
  String durumFiltresi = 'tum';
  String? tedarikciFiltresi;
  String terminFiltresi = 'tum';
  String kaliteFiltresi = 'tum';
  String teslimFiltresi = 'tum';
  String siralama = 'termin';

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
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);

    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      final yeniTedarikciler = await _tedarikcileriYukle(firmaId);
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

      setState(() {
        tedarikciler = yeniTedarikciler;
        siparisler = yeniSiparisler;
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
    siparis['teslim_yuzdesi'] = teslimYuzdesi.clamp(0, 100).toDouble();
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
          '${siparis['siparis_no']} ${siparis['iplik_adi']} ${siparis['renk']} ${siparis['tedarikci_adi']} ${siparis['marka']}'
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

      return aramaUygun &&
          durumUygun &&
          tedarikciUygun &&
          kaliteUygun &&
          teslimUygun &&
          terminUygun;
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

  @override
  Widget build(BuildContext context) {
    final filtreliSiparisler = _filtreliSiparisler;
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;
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
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columnSpacing: 20,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('Sipariş')),
              DataColumn(label: Text('İplik / Renk')),
              DataColumn(label: Text('Tedarikçi')),
              DataColumn(label: Text('Termin')),
              DataColumn(label: Text('Miktar')),
              DataColumn(label: Text('Teslim')),
              DataColumn(label: Text('Durum')),
              DataColumn(label: Text('Kalite')),
              DataColumn(label: Text('İşlem')),
            ],
            rows: data.map((siparis) {
              final durum = _getDurumBilgi(siparis['takip_durumu']);
              return DataRow(
                cells: [
                  DataCell(_tableText(
                      siparis['siparis_no']?.toString() ?? '-', 120, true)),
                  DataCell(_tableText(
                    '${siparis['iplik_adi'] ?? '-'} / ${_siparisRengi(siparis).isNotEmpty ? _siparisRengi(siparis) : '-'}',
                    210,
                    true,
                  )),
                  DataCell(_tableText(
                      siparis['tedarikci_adi']?.toString() ?? '-', 170, false)),
                  DataCell(Text(_formatTarih(siparis['termin_tarihi']))),
                  DataCell(Text(
                      '${_num(siparis['miktar']).toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}')),
                  DataCell(_buildTeslimHucre(siparis, width: 150)),
                  DataCell(_durumEtiketi(durum.metin, durum.renk)),
                  DataCell(_durumEtiketi(_kaliteMetni(siparis['kalite_durumu']),
                      _kaliteRengi(siparis['kalite_durumu']))),
                  DataCell(_buildAksiyonlar(siparis, compact: true)),
                ],
              );
            }).toList(),
          ),
        ),
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
                      : '-'),
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
    final yuzde = _num(siparis['teslim_yuzdesi']).clamp(0, 100).toDouble();
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
                    value: yuzde / 100,
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
    final kalan = _num(siparis['kalan_miktar']);
    final duzenlenebilir = _siparisDuzenlenebilir(siparis);
    final teslimatEklenebilir = !tamamlandi && kalan > 0;
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

  Future<void> _siparisDuzenle(Map<String, dynamic> siparis) async {
    if (!await _siparisTeslimatsizMi(siparis)) {
      if (mounted) {
        context.showErrorSnackBar(
          'Teslimat başlamış sipariş düzenlenemez',
        );
      }
      return;
    }

    final markaController =
        TextEditingController(text: siparis['marka']?.toString() ?? '');
    final iplikAdiController =
        TextEditingController(text: siparis['iplik_adi']?.toString() ?? '');
    final renkController =
        TextEditingController(text: siparis['renk']?.toString() ?? '');
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
            title: Text('Sipariş Düzenle - ${siparis['siparis_no'] ?? '-'}'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      controller: renkController,
                      decoration: const InputDecoration(
                        labelText: 'Renk',
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
      final miktar = _parseDecimal(miktarController.text);
      if (markaController.text.trim().isEmpty ||
          iplikAdiController.text.trim().isEmpty ||
          miktar == null ||
          miktar <= 0) {
        throw 'Marka, iplik adı ve geçerli miktar zorunludur';
      }
      final birimFiyat = birimFiyatController.text.trim().isNotEmpty
          ? _parseDecimal(birimFiyatController.text)
          : null;

      await supabase
          .from(DbTables.iplikSiparisleri)
          .update({
            'marka': markaController.text.trim(),
            'iplik_adi': iplikAdiController.text.trim(),
            'renk': renkController.text.trim().isNotEmpty
                ? renkController.text.trim()
                : null,
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
          .eq('firma_id', TenantManager.instance.requireFirmaId);

      await _verileriYukle();
      if (mounted) context.showSuccessSnackBar('Sipariş güncellendi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Hata: $e');
    } finally {
      markaController.dispose();
      iplikAdiController.dispose();
      renkController.dispose();
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
    final miktarController = TextEditingController(
      text: _num(siparis['kalan_miktar']).toStringAsFixed(1),
    );
    final lotNoController = TextEditingController();
    final aciklamaController = TextEditingController();
    DateTime teslimatTarihi = DateTime.now();
    String kaliteDurumu = 'onaylandi';

    try {
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final kalanMiktar = _num(siparis['kalan_miktar']);
            return AlertDialog(
              title: Text('Teslimat Gir - ${siparis['siparis_no'] ?? '-'}'),
              content: SizedBox(
                width: 460,
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
                              'Maksimum: ${kalanMiktar.toStringAsFixed(1)} ${siparis['birim'] ?? 'kg'}',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
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
                      if (miktar > kalanMiktar) {
                        throw 'Teslim miktarı kalan miktardan fazla olamaz';
                      }

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
  }) async {
    try {
      await supabase.rpc(
        'iplik_siparis_teslimat_kaydet',
        params: {
          'p_firma_id': TenantManager.instance.requireFirmaId,
          'p_siparis_id': siparis['id'],
          'p_miktar': miktar,
          'p_lot_no': lotNo,
          'p_kalite_durumu': kaliteDurumu,
          'p_teslimat_tarihi': teslimatTarihi.toIso8601String().split('T')[0],
          'p_aciklama': aciklama,
        },
      );
    } catch (rpcError) {
      debugPrint(
          'İplik teslimat RPC kullanılamadı, klasik teslimat deneniyor: $rpcError');
      await _teslimatFallbackKaydet(
        siparis: siparis,
        miktar: miktar,
        lotNo: lotNo,
        kaliteDurumu: kaliteDurumu,
        teslimatTarihi: teslimatTarihi,
        aciklama: aciklama,
      );
    }
  }

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

  Widget _miniBilgi(String baslik, String deger) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(
            deger,
            maxLines: 1,
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
