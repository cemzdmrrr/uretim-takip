import 'package:flutter/material.dart' hide Border;
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:uretim_takip/utils/web_download.dart';
import 'package:flutter/painting.dart' show Border, BorderSide;
import 'package:uretim_takip/services/tenant_manager.dart';
import 'dart:math' as math;

part 'stok_yonetimi_aksesuarlar_dialog.dart';

class StokYonetimiAksesuarlarCokluBeden extends StatefulWidget {
  const StokYonetimiAksesuarlarCokluBeden({super.key});

  @override
  State<StokYonetimiAksesuarlarCokluBeden> createState() =>
      _StokYonetimiAksesuarlarCokluBedenState();
}

class _StokYonetimiAksesuarlarCokluBedenState
    extends State<StokYonetimiAksesuarlarCokluBeden>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _pageTabController;

  List<Map<String, dynamic>> aksesuarlar = [];
  // Aksesuar ID -> Model kullanım listesi (model_adi, toplam_adet, adet_per_model)
  Map<String, List<Map<String, dynamic>>> _modelKullanimlari = {};
  // Aksesuar ID -> toplam sarf miktarı (hareket_tipi='cikis')
  Map<String, int> _sarfToplamlari = {};
  // Aksesuar Beden ID -> toplam sarf miktarı (hareket_tipi='cikis')
  Map<String, int> _bedenSarfToplamlari = {};
  bool isLoading = true;
  String searchQuery = '';

  // Sarf raporu state
  List<Map<String, dynamic>> _sarfKayitlari = [];
  bool _sarfYukleniyor = false;
  String _sarfArama = '';
  DateTime? _sarfBaslangic;
  DateTime? _sarfBitis;
  String? _sarfTedarikciFiltre; // seçili tedarikçi adı
  String? _sarfModelFiltre;    // seçili model label

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _successColor = Color(0xFF059669);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _surfaceColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _pageTabController = TabController(length: 2, vsync: this);
    _pageTabController.addListener(() {
      if (_pageTabController.index == 1 && !_sarfYukleniyor) {
        _loadSarfKayitlari();
      }
    });
    _loadAksesuarlar();
  }

  @override
  void dispose() {
    _pageTabController.dispose();
    super.dispose();
  }

  Future<void> _loadSarfKayitlari() async {
    setState(() => _sarfYukleniyor = true);
    try {
      final firmaId = TenantManager.instance.requireFirmaId;

      final data = await supabase
          .from(DbTables.aksesuarStokHareketleri)
          .select('*, aksesuar_bedenler(id, beden, aksesuar_id, aksesuarlar(ad, sku, renk)), triko_takip(id, item_no, marka, model_adi)')
          .eq('firma_id', firmaId)
          .eq('hareket_tipi', 'cikis')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sarfKayitlari = List<Map<String, dynamic>>.from(data);
          _sarfYukleniyor = false;
        });
      }
    } catch (e) {
      debugPrint('Sarf kayıtları yüklenemedi: $e');
      if (mounted) {
        setState(() => _sarfYukleniyor = false);
        context.showErrorSnackBar('Sarf kayıtları yüklenemedi: $e');
      }
    }
  }

  Future<void> _loadAksesuarlar() async {
    try {
      setState(() => isLoading = true);

      final firmaId = TenantManager.instance.requireFirmaId;

      // Aksesuarları ve bedenlerini birleştirip getir
      final response = await supabase
          .from(DbTables.aksesuarlar)
          .select('''
            *,
            aksesuar_bedenler (
              id,
              beden,
              stok_miktari,
              durum
            )
          ''')
          .eq('firma_id', firmaId)
          .eq('durum', 'aktif')
          .order('created_at', ascending: false);

      // Model-aksesuar ilişkilerini yükle
      final modelAksesuarResponse = await supabase
          .from(DbTables.modelAksesuar)
          .select('aksesuar_id, adet_per_model, miktar, model_id')
          .eq('firma_id', firmaId);

      // Sarf toplamlarını yükle (kalan talep hesabı için)
      final sarfResponse = await supabase
          .from(DbTables.aksesuarStokHareketleri)
          .select('miktar, aksesuar_beden_id')
          .eq('firma_id', firmaId)
          .eq('hareket_tipi', 'cikis');

      // Yüklenen aksesuarlardan beden->aksesuar eşleşme haritası
      final Map<String, String> bedenAksesuarMap = {};
      for (var aksesuar in response) {
        final aksesuarId = aksesuar['id']?.toString();
        if (aksesuarId == null || aksesuarId.isEmpty) continue;

        final bedenler = aksesuar['aksesuar_bedenler'] as List? ?? [];
        for (var beden in bedenler) {
          final bedenId = beden['id']?.toString();
          if (bedenId != null && bedenId.isNotEmpty) {
            bedenAksesuarMap[bedenId] = aksesuarId;
          }
        }
      }

      // İlgili model ID'lerini topla ve model bilgilerini çek
      final modelIds = <String>{};
      for (var ma in modelAksesuarResponse) {
        final modelId = ma['model_id']?.toString();
        if (modelId != null) modelIds.add(modelId);
      }

      final Map<String, Map<String, dynamic>> modelBilgileri = {};
      if (modelIds.isNotEmpty) {
        final modellerResponse = await supabase
            .from(DbTables.trikoTakip)
            .select('id, model_adi, toplam_adet, adet, durum, bedenler')
            .eq('firma_id', firmaId)
            .inFilter('id', modelIds.toList());

        for (var model in modellerResponse) {
          modelBilgileri[model['id'].toString()] = model;
        }
      }

      // Aksesuar bazında model kullanımlarını grupla
      final Map<String, List<Map<String, dynamic>>> kullanimMap = {};
      for (var ma in modelAksesuarResponse) {
        final aksesuarId = ma['aksesuar_id']?.toString();
        final modelId = ma['model_id']?.toString();
        if (aksesuarId == null || modelId == null) continue;

        final model = modelBilgileri[modelId];
        if (model == null) continue;

        final modelAdi = model['model_adi']?.toString() ?? 'Bilinmeyen Model';
        final int modelAdet =
            (model['toplam_adet'] ?? model['adet'] ?? 0) as int;
        final int adetPerModel =
            (ma['adet_per_model'] ?? ma['miktar'] ?? 1) as int;
        final String durum = model['durum']?.toString() ?? '';
        final Map<String, dynamic> modelBedenler =
            (model['bedenler'] as Map<String, dynamic>?) ?? {};

        kullanimMap.putIfAbsent(aksesuarId, () => []);
        kullanimMap[aksesuarId]!.add({
          'model_id': modelId,
          'model_adi': modelAdi,
          'model_adet': modelAdet,
          'adet_per_model': adetPerModel,
          'gereken_adet': modelAdet * adetPerModel,
          'durum': durum,
          'bedenler': modelBedenler,
        });
      }

      // Sarf kayıtlarını aksesuar ve beden bazında topla
      final Map<String, int> sarfToplamMap = {};
      final Map<String, int> bedenSarfToplamMap = {};
      for (var kayit in sarfResponse) {
        final miktar = (kayit['miktar'] as num?)?.toInt() ?? 0;
        if (miktar <= 0) continue;

        final bedenId = kayit['aksesuar_beden_id']?.toString();
        if (bedenId != null && bedenId.isNotEmpty) {
          bedenSarfToplamMap[bedenId] =
              (bedenSarfToplamMap[bedenId] ?? 0) + miktar;
        }

        final aksesuarId = bedenId != null ? bedenAksesuarMap[bedenId] : null;
        if (aksesuarId != null && aksesuarId.isNotEmpty) {
          sarfToplamMap[aksesuarId] =
              (sarfToplamMap[aksesuarId] ?? 0) + miktar;
        }
      }

      setState(() {
        aksesuarlar = List<Map<String, dynamic>>.from(response);
        _modelKullanimlari = kullanimMap;
        _sarfToplamlari = sarfToplamMap;
        _bedenSarfToplamlari = bedenSarfToplamMap;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Aksesuarlar yükleme hatası: $e');
      setState(() => isLoading = false);
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  /// Tüm modellerin bu aksesuardan toplam talep ettiği adet
  int _getToplamTalep(Map<String, dynamic> aksesuar) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return 0;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return 0;
    return kullanimlar.fold(0, (sum, k) => sum + (k['gereken_adet'] as int));
  }

  int _getToplamSarf(Map<String, dynamic> aksesuar) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return 0;
    return _sarfToplamlari[aksesuarId] ?? 0;
  }

  int _getKalanToplamTalep(Map<String, dynamic> aksesuar) {
    final planlananTalep = _getToplamTalep(aksesuar);
    final toplamSarf = _getToplamSarf(aksesuar);
    return math.max(0, planlananTalep - toplamSarf);
  }

  /// Aksesuar beden adları model beden anahtarlarıyla eşleşiyor mu?
  bool _hasBedenEslesmesi(Map<String, dynamic> aksesuar) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return false;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return false;

    final bedenler = aksesuar['aksesuar_bedenler'] as List? ?? [];
    for (var beden in bedenler) {
      if (beden['durum'] != 'aktif') continue;
      final bedenAdi = beden['beden']?.toString() ?? '';
      for (var k in kullanimlar) {
        final modelBedenler = k['bedenler'] as Map<String, dynamic>? ?? {};
        if (modelBedenler.containsKey(bedenAdi)) return true;
      }
    }
    return false;
  }

  /// Belirli bir beden için tüm modellerden gelen talep
  /// Eşleşme varsa: model.bedenler[bedenAdi] * adet_per_model
  /// Eşleşme yoksa: toplam talep / aktif beden sayısı (eşit dağılım)
  int _getBedenTalep(Map<String, dynamic> aksesuar, String bedenAdi) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return 0;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return 0;

    // Beden eşleşmesi varsa direkt hesapla
    if (_hasBedenEslesmesi(aksesuar)) {
      int toplam = 0;
      for (var k in kullanimlar) {
        final modelBedenler = k['bedenler'] as Map<String, dynamic>? ?? {};
        final adetPerModel = k['adet_per_model'] as int? ?? 1;
        final bedenAdet = (modelBedenler[bedenAdi] as num?)?.toInt() ?? 0;
        toplam += bedenAdet * adetPerModel;
      }
      return toplam;
    }

    // Eşleşme yoksa toplam talebi aktif bedenler arasında eşit dağıt
    final bedenler = aksesuar['aksesuar_bedenler'] as List? ?? [];
    final aktifBedenSayisi =
        bedenler.where((b) => b['durum'] == 'aktif').length;
    if (aktifBedenSayisi == 0) return 0;
    final toplamTalep = _getToplamTalep(aksesuar);
    return (toplamTalep / aktifBedenSayisi).ceil();
  }

  int _getBedenSarf(Map<String, dynamic> beden) {
    final bedenId = beden['id']?.toString();
    if (bedenId == null || bedenId.isEmpty) return 0;
    return _bedenSarfToplamlari[bedenId] ?? 0;
  }

  int _getKalanBedenTalep(
      Map<String, dynamic> aksesuar, Map<String, dynamic> beden) {
    final bedenAdi = beden['beden']?.toString() ?? '';
    final planlananTalep = _getBedenTalep(aksesuar, bedenAdi);
    final bedenSarf = _getBedenSarf(beden);
    return math.max(0, planlananTalep - bedenSarf);
  }

  /// Stok yeterli mi? Çoklu beden aksesuarlar için beden bazlı kontrol
  bool _isStokYeterli(Map<String, dynamic> aksesuar) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return true;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return true;

    final bedenler = aksesuar['aksesuar_bedenler'] as List? ?? [];
    final aktifBedenler = bedenler.where((b) => b['durum'] == 'aktif').toList();

    if (aktifBedenler.isNotEmpty) {
      if (_hasBedenEslesmesi(aksesuar)) {
        // Beden adları eşleşiyor: her bedeni ayrı kontrol et
        for (var beden in aktifBedenler) {
          final stok = (beden['stok_miktari'] as int? ?? 0);
          final talep = _getKalanBedenTalep(aksesuar, beden);
          if (talep > 0 && stok < talep) return false;
        }
        return true;
      } else {
        // Beden adları eşleşmiyor: toplam stok vs toplam talep
        final toplamTalep = _getKalanToplamTalep(aksesuar);
        if (toplamTalep == 0) return true;
        return _getTotalStock(aksesuar) >= toplamTalep;
      }
    }

    // Bedensiz aksesuar: toplam kontrol
    final toplamTalep = _getKalanToplamTalep(aksesuar);
    if (toplamTalep == 0) return true;
    return _getTotalStock(aksesuar) >= toplamTalep;
  }

  List<Map<String, dynamic>> get filteredAksesuarlar {
    if (searchQuery.isEmpty) return aksesuarlar;

    return aksesuarlar.where((aksesuar) {
      final ad = aksesuar['ad']?.toString().toLowerCase() ?? '';
      final marka = aksesuar['marka']?.toString().toLowerCase() ?? '';
      final sku = aksesuar['sku']?.toString().toLowerCase() ?? '';
      final renk = aksesuar['renk']?.toString().toLowerCase() ?? '';

      return ad.contains(searchQuery.toLowerCase()) ||
          marka.contains(searchQuery.toLowerCase()) ||
          sku.contains(searchQuery.toLowerCase()) ||
          renk.contains(searchQuery.toLowerCase());
    }).toList();
  }

  int get _yetersizStokSayisi {
    return filteredAksesuarlar.where(_aksesuarKritikMi).length;
  }

  int get _toplamAksesuarStok {
    return filteredAksesuarlar.fold(0, (sum, a) => sum + _getTotalStock(a));
  }

  int get _toplamAksesuarTalep {
    return filteredAksesuarlar.fold(
      0,
      (sum, a) => sum + _getKalanToplamTalep(a),
    );
  }

  bool _aksesuarKritikMi(Map<String, dynamic> aksesuar) {
    final talep = _getKalanToplamTalep(aksesuar);
    if (talep > 0) return !_isStokYeterli(aksesuar);
    return _getTotalStock(aksesuar) < (aksesuar['minimum_stok'] ?? 10);
  }

  Future<void> _aksesuarToplamStokGuncelle(String aksesuarId) async {
    final firmaId = TenantManager.instance.requireFirmaId;
    final bedenler = await supabase
        .from(DbTables.aksesuarBedenler)
        .select('stok_miktari')
        .eq('firma_id', firmaId)
        .eq('aksesuar_id', aksesuarId)
        .eq('durum', 'aktif');

    final toplamStok = List<Map<String, dynamic>>.from(bedenler).fold<int>(
      0,
      (sum, beden) => sum + ((beden['stok_miktari'] as num?)?.toInt() ?? 0),
    );

    await supabase
        .from(DbTables.aksesuarlar)
        .update({
          'miktar': toplamStok,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('firma_id', firmaId)
        .eq('id', aksesuarId);
  }

  Widget _buildStokCard(Map<String, dynamic> aksesuar) {
    final totalStock = _getTotalStock(aksesuar);
    final kalanTalep = _getKalanToplamTalep(aksesuar);
    final aksesuarId = aksesuar['id']?.toString();
    final kullanimlar = aksesuarId != null
        ? _modelKullanimlari[aksesuarId] ?? []
        : <Map<String, dynamic>>[];
    final eksikAdet = kalanTalep > totalStock ? kalanTalep - totalStock : 0;

    final isLowStock = _aksesuarKritikMi(aksesuar);

    return InkWell(
      onTap: () => _showAksesuarDetayModal(aksesuar),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dar = constraints.maxWidth < 720;
            final bilgi = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? _dangerColor.withValues(alpha: 0.1)
                        : _successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: isLowStock ? _dangerColor : _successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aksesuar['ad'] ?? 'Adsız Aksesuar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildMiniBilgi('SKU', aksesuar['sku'] ?? '-'),
                          _buildMiniBilgi(
                              'Marka', aksesuar['marka'] ?? 'Belirtilmemiş'),
                          _buildMiniBilgi('Stok', '$totalStock'),
                          if (kalanTalep > 0)
                            _buildMiniBilgi('Kalan Talep', '$kalanTalep'),
                          if (kullanimlar.isNotEmpty)
                            _buildMiniBilgi('Model', '${kullanimlar.length}'),
                        ],
                      ),
                      if (isLowStock) ...[
                        const SizedBox(height: 8),
                        _buildDurumEtiketi(
                          kalanTalep > 0
                              ? '$eksikAdet adet eksik'
                              : 'Düşük stok',
                          _dangerColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final aksiyonlar = _buildAksesuarAksiyonlari(aksesuar);
            if (dar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bilgi,
                  const SizedBox(height: 10),
                  aksiyonlar,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: bilgi),
                const SizedBox(width: 12),
                aksiyonlar,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAksesuarAksiyonlari(Map<String, dynamic> aksesuar) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        IconButton(
          icon: const Icon(Icons.output_rounded),
          color: _warningColor,
          onPressed: () => _showSarfDialog(aksesuar),
          tooltip: 'Sarf',
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          color: _primaryColor,
          onPressed: () => _showAddEditDialog(aksesuar: aksesuar),
          tooltip: 'Düzenle',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: _dangerColor,
          onPressed: () => _deleteAksesuar(aksesuar),
          tooltip: 'Sil',
        ),
      ],
    );
  }

  void _showAksesuarDetayModal(Map<String, dynamic> aksesuar) {
    final totalStock = _getTotalStock(aksesuar);
    final toplamTalep = _getToplamTalep(aksesuar);
    final toplamSarf = _getToplamSarf(aksesuar);
    final kalanTalep = _getKalanToplamTalep(aksesuar);
    final stokYeterli = _isStokYeterli(aksesuar);
    final aksesuarId = aksesuar['id']?.toString();
    final kullanimlar = aksesuarId != null
        ? _modelKullanimlari[aksesuarId] ?? []
        : <Map<String, dynamic>>[];
    final eksikAdet = kalanTalep > totalStock ? kalanTalep - totalStock : 0;
    final bool isLowStock = kalanTalep > 0
        ? !stokYeterli
        : totalStock < (aksesuar['minimum_stok'] ?? 10);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory,
                        color: isLowStock
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        aksesuar['ad'] ?? 'Adsız Aksesuar',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // İçerik
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genel bilgiler
                      Row(
                        children: [
                          Expanded(
                              child: _buildDetayBilgi(
                                  'SKU', aksesuar['sku'] ?? 'Yok')),
                          Expanded(
                              child: _buildDetayBilgi('Marka',
                                  aksesuar['marka'] ?? 'Belirtilmemiş')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: _buildDetayBilgi(
                                  'Renk', aksesuar['renk'] ?? '-')),
                          Expanded(
                              child: _buildDetayBilgi(
                                  'Malzeme', aksesuar['malzeme'] ?? '-')),
                        ],
                      ),
                      if (aksesuar['birim_fiyat'] != null &&
                          (aksesuar['birim_fiyat'] as num) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildDetayBilgi(
                              'Birim Fiyat', '${aksesuar['birim_fiyat']} TL'),
                        ),
                      const Divider(height: 24),

                      // Stok özeti
                      Row(
                        children: [
                          Expanded(
                              child: _buildMiniInfo(
                                  'Mevcut Stok', '$totalStock', Colors.green)),
                          Expanded(
                              child: _buildMiniInfo(
                                  'Kalan Talep', '$kalanTalep', Colors.blue)),
                          Expanded(
                            child: _buildMiniInfo(
                              stokYeterli ? 'Fazla' : 'Eksik',
                              stokYeterli ? '${totalStock - kalanTalep}' : '$eksikAdet',
                              stokYeterli ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (toplamSarf > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Planlanan talep: $toplamTalep • Gerçekleşen sarf: $toplamSarf • Kalan: $kalanTalep',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Uyarı / başarı mesajı
                      if (!stokYeterli)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Stok yetersiz! Tüm modeller için $eksikAdet adet daha tedarik edilmeli.',
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (stokYeterli && kalanTalep > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Stok yeterli. ${totalStock - kalanTalep} adet fazla stok mevcut.',
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Model kullanım detayları
                      if (kullanimlar.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Model Bazlı Talep Analizi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: stokYeterli
                                  ? Colors.blue.shade800
                                  : Colors.red.shade800),
                        ),
                        const SizedBox(height: 8),
                        ...kullanimlar.map((k) {
                          final gerekenAdet = k['gereken_adet'] as int;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.label,
                                    size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    k['model_adi']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${k['model_adet']} adet × ${k['adet_per_model']}/model',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '= $gerekenAdet',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Beden detayları
                      const SizedBox(height: 16),
                      const Text(
                        'Beden Detayları:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      if (aksesuar['aksesuar_bedenler'] != null &&
                          (aksesuar['aksesuar_bedenler'] as List).isNotEmpty)
                        ...((aksesuar['aksesuar_bedenler'] as List)
                            .where((beden) => beden['durum'] == 'aktif')
                            .map((beden) {
                          final bedenAdi = beden['beden']?.toString() ?? '';
                          final stok = (beden['stok_miktari'] as int? ?? 0);
                            final bedenTalep = _getKalanBedenTalep(aksesuar, beden);
                          final bedenYeterli =
                              bedenTalep == 0 || stok >= bedenTalep;
                          final bedenEksik =
                              bedenTalep > stok ? bedenTalep - stok : 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    bedenAdi,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                                if (bedenTalep > 0) ...[
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value:
                                            (stok / bedenTalep).clamp(0.0, 1.0),
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation(
                                          bedenYeterli
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      '$stok / $bedenTalep ${bedenYeterli ? '✓' : '($bedenEksik eksik)'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: bedenYeterli
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: Text(
                                      '$stok adet',
                                      style: TextStyle(
                                        color: stok > 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }))
                      else
                        const Text(
                          'Beden bilgisi yok',
                          style: TextStyle(
                              color: Colors.grey, fontStyle: FontStyle.italic),
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

  Widget _buildDetayBilgi(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMiniBilgi(String baslik, String value) {
    return SizedBox(
      width: 118,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumEtiketi(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  void _deleteAksesuar(Map<String, dynamic> aksesuar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aksesuar Sil'),
        content: Text(
            '${aksesuar['ad']} adlı aksesuarı pasife almak istediğinizden emin misiniz?\n\nKayıt geçmişi korunur, aktif listeden kaldırılır.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final firmaId = TenantManager.instance.requireFirmaId;
                final aksesuarId = aksesuar['id']?.toString();
                if (aksesuarId == null) {
                  throw 'Aksesuar kaydı bulunamadı';
                }

                // Bedenleri pasife al
                await supabase
                    .from(DbTables.aksesuarBedenler)
                    .update({
                      'durum': 'pasif',
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('firma_id', firmaId)
                    .eq('aksesuar_id', aksesuarId);

                // Ana kaydı pasife al
                await supabase
                    .from(DbTables.aksesuarlar)
                    .update({
                      'durum': 'pasif',
                      'miktar': 0,
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('firma_id', firmaId)
                    .eq('id', aksesuarId);

                if (!context.mounted) return;
                Navigator.pop(context);
                context.showSuccessSnackBar('Aksesuar pasife alındı');

                await _loadAksesuarlar();
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAksesuarUstPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.category_outlined,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aksesuar Depo Yönetimi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bedenli aksesuar stok, talep ve sarf takibi',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAksesuarlar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
    );
  }

  Widget _buildAksesuarAracCubugu() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 760;
          final arama = SizedBox(
            width: dar ? constraints.maxWidth : 340,
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: const InputDecoration(
                labelText: 'Aksesuar, SKU, marka veya renk ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          );

          final aksiyonlar = [
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Aksesuar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _successColor,
                foregroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _downloadExcelTemplate,
              icon: const Icon(Icons.download),
              label: const Text('Şablon'),
            ),
            OutlinedButton.icon(
              onPressed: _importFromExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text('İçe Aktar'),
            ),
          ];

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              arama,
              ...aksiyonlar,
            ],
          );
        },
      ),
    );
  }

  Widget _buildAksesuarOzetleri() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final kartlar = [
          _buildOzetKutusu('Aksesuar', '${filteredAksesuarlar.length}',
              Icons.category_outlined, _primaryColor),
          _buildOzetKutusu('Yetersiz', '$_yetersizStokSayisi',
              Icons.warning_amber, _dangerColor),
          _buildOzetKutusu('Toplam Stok', '$_toplamAksesuarStok',
              Icons.inventory_2, _successColor),
          _buildOzetKutusu('Kalan Talep', '$_toplamAksesuarTalep',
              Icons.assignment, _warningColor),
        ];

        if (constraints.maxWidth < 520) {
          return Column(
            children: kartlar
                .map((kart) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: kart,
                    ))
                .toList(),
          );
        }

        if (constraints.maxWidth < 900) {
          final width = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kartlar
                .map((kart) => SizedBox(width: width, child: kart))
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

  Widget _buildOzetKutusu(
      String baslik, String deger, IconData icon, Color renk) {
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
              color: renk.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: renk, size: 20),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAksesuarListeAlani() {
    if (isLoading) return const LoadingWidget();
    if (filteredAksesuarlar.isEmpty) {
      return const Center(
        child: Text(
          'Henüz aksesuar eklenmemiş',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 84),
      itemCount: filteredAksesuarlar.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _buildStokCard(filteredAksesuarlar[index]),
    );
  }

  // ── Sarf Raporu ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filtreliSarfKayitlari {
    var liste = _sarfKayitlari;

    if (_sarfArama.isNotEmpty) {
      final q = _sarfArama.toLowerCase();
      liste = liste.where((k) {
        final aksAd = (k['aksesuar_bedenler']?['aksesuarlar']?['ad'] ?? '').toString().toLowerCase();
        final aksSku = (k['aksesuar_bedenler']?['aksesuarlar']?['sku'] ?? '').toString().toLowerCase();
        final beden = (k['aksesuar_bedenler']?['beden'] ?? '').toString().toLowerCase();
        final modelMarka = (k['triko_takip']?['marka'] ?? '').toString().toLowerCase();
        final modelItemNo = (k['triko_takip']?['item_no'] ?? '').toString().toLowerCase();
        final tedAdi = (k['tedarikci_adi'] ?? '').toString().toLowerCase();
        return aksAd.contains(q) || aksSku.contains(q) || beden.contains(q)
            || modelMarka.contains(q) || modelItemNo.contains(q)
            || tedAdi.contains(q);
      }).toList();
    }

    if (_sarfBaslangic != null) {
      liste = liste.where((k) {
        final t = DateTime.tryParse(k['created_at']?.toString() ?? '');
        return t != null && !t.isBefore(_sarfBaslangic!);
      }).toList();
    }

    if (_sarfBitis != null) {
      final bitis = _sarfBitis!.add(const Duration(days: 1));
      liste = liste.where((k) {
        final t = DateTime.tryParse(k['created_at']?.toString() ?? '');
        return t != null && t.isBefore(bitis);
      }).toList();
    }

    if (_sarfTedarikciFiltre != null && _sarfTedarikciFiltre!.isNotEmpty) {
      liste = liste.where((k) {
        return (k['tedarikci_adi']?.toString() ?? '') == _sarfTedarikciFiltre;
      }).toList();
    }

    if (_sarfModelFiltre != null && _sarfModelFiltre!.isNotEmpty) {
      liste = liste.where((k) {
        final marka = k['triko_takip']?['marka']?.toString() ?? '';
        final itemNo = k['triko_takip']?['item_no']?.toString() ?? '';
        final label = [marka, itemNo].where((s) => s.isNotEmpty).join(' - ');
        return label == _sarfModelFiltre;
      }).toList();
    }

    return liste;
  }

  String _tedarikciAdi(Map<String, dynamic> kayit) {
    final t = kayit['tedarikciler'];
    if (t == null) return '-';
    final sirket = t['sirket']?.toString() ?? '';
    final ad = t['ad']?.toString() ?? '';
    return sirket.isNotEmpty ? sirket : (ad.isNotEmpty ? ad : '-');
  }

  Future<void> _sarfExcelIndir(List<Map<String, dynamic>> kayitlar) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheetName = 'Sarf_Raporu';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      final headers = ['Tarih', 'Aksesuar', 'SKU', 'Renk', 'Beden', 'Model', 'Tedarikçi', 'Adet', 'Açıklama'];
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = headers[i];
      }

      for (int r = 0; r < kayitlar.length; r++) {
        final k = kayitlar[r];
        final aksAd = k['aksesuar_bedenler']?['aksesuarlar']?['ad']?.toString() ?? '';
        final aksSku = k['aksesuar_bedenler']?['aksesuarlar']?['sku']?.toString() ?? '';
        final aksRenk = k['aksesuar_bedenler']?['aksesuarlar']?['renk']?.toString() ?? '';
        final beden = k['aksesuar_bedenler']?['beden']?.toString() ?? '';
        final modelMarka = k['triko_takip']?['marka']?.toString() ?? '';
        final modelItemNo = k['triko_takip']?['item_no']?.toString() ?? '';
        final modelLabel = [modelMarka, modelItemNo].where((s) => s.isNotEmpty).join(' - ');
        final tedLabel = k['tedarikci_adi']?.toString() ?? '';
        final miktar = (k['miktar'] as int?) ?? 0;
        final aciklama = k['aciklama']?.toString() ?? '';
        final tarih = _formatTarih(k['created_at']?.toString());

        final rowData = [tarih, aksAd, aksSku, aksRenk, beden, modelLabel, tedLabel, miktar.toString(), aciklama];
        for (int c = 0; c < rowData.length; c++) {
          sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1)).value = rowData[c];
        }
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      final tarihStr = DateTime.now().toLocal();
      final dosyaAdi =
          'sarf_raporu_${tarihStr.year}${tarihStr.month.toString().padLeft(2, '0')}${tarihStr.day.toString().padLeft(2, '0')}.xlsx';
      downloadFileWeb(bytes, dosyaAdi, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      if (mounted) context.showSuccessSnackBar('Excel indirildi: $dosyaAdi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Excel indirilemedi: $e');
    }
  }

  String _formatTarih(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showSarfDuzenleDialog(Map<String, dynamic> kayit) async {
    final kayitId = kayit['id']?.toString();
    final bedenId = kayit['aksesuar_beden_id']?.toString();
    final aksesuarId = kayit['aksesuar_bedenler']?['aksesuar_id']?.toString();

    if (kayitId == null || bedenId == null) {
      context.showErrorSnackBar('Sarf kaydı bilgisi eksik');
      return;
    }

    final eskiAdet = (kayit['miktar'] as num?)?.toInt() ?? 0;
    final adetController = TextEditingController(text: '$eskiAdet');
    final aciklamaController =
        TextEditingController(text: kayit['aciklama']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sarf Kaydı Düzenle'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (kayit['aksesuar_bedenler']?['aksesuarlar']?['ad'] ?? '-')
                    .toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Beden: ${(kayit['aksesuar_bedenler']?['beden'] ?? '-').toString()}',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sarf Adedi *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aciklamaController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () async {
              final yeniAdet = int.tryParse(adetController.text.trim());
              if (yeniAdet == null || yeniAdet <= 0) {
                dialogContext.showErrorSnackBar('Geçerli bir adet giriniz');
                return;
              }

              try {
                final firmaId = TenantManager.instance.requireFirmaId;
                final delta = yeniAdet - eskiAdet;

                if (delta != 0) {
                  final beden = await supabase
                      .from(DbTables.aksesuarBedenler)
                      .select('stok_miktari')
                      .eq('firma_id', firmaId)
                      .eq('id', bedenId)
                      .single();

                  final mevcutStok =
                      (beden['stok_miktari'] as num?)?.toInt() ?? 0;

                  if (delta > 0 && mevcutStok < delta) {
                    if (!dialogContext.mounted) return;
                    dialogContext.showErrorSnackBar(
                      'Yetersiz stok. En fazla ${mevcutStok + eskiAdet} adede çıkabilirsiniz.',
                    );
                    return;
                  }

                  await supabase
                      .from(DbTables.aksesuarBedenler)
                      .update({
                        'stok_miktari': mevcutStok - delta,
                        'updated_at': DateTime.now().toIso8601String(),
                      })
                      .eq('firma_id', firmaId)
                      .eq('id', bedenId);
                }

                final updateData = <String, dynamic>{
                  'miktar': yeniAdet,
                  'aciklama': aciklamaController.text.trim().isEmpty
                      ? null
                      : aciklamaController.text.trim(),
                };

                final oncekiStok = (kayit['onceki_stok'] as num?)?.toInt();
                if (oncekiStok != null) {
                  updateData['yeni_stok'] = oncekiStok - yeniAdet;
                }

                await supabase
                    .from(DbTables.aksesuarStokHareketleri)
                    .update(updateData)
                    .eq('firma_id', firmaId)
                    .eq('id', kayitId);

                if (aksesuarId != null && aksesuarId.isNotEmpty) {
                  await _aksesuarToplamStokGuncelle(aksesuarId);
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                context.showSuccessSnackBar('Sarf kaydı güncellendi');

                await _loadAksesuarlar();
                await _loadSarfKayitlari();
              } catch (e) {
                if (!dialogContext.mounted) return;
                dialogContext.showErrorSnackBar('Güncelleme hatası: $e');
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSarfSilDialog(Map<String, dynamic> kayit) async {
    final kayitId = kayit['id']?.toString();
    final bedenId = kayit['aksesuar_beden_id']?.toString();
    final aksesuarId = kayit['aksesuar_bedenler']?['aksesuar_id']?.toString();
    final miktar = (kayit['miktar'] as num?)?.toInt() ?? 0;

    if (kayitId == null || bedenId == null) {
      context.showErrorSnackBar('Sarf kaydı bilgisi eksik');
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sarf Kaydını Sil'),
        content: Text(
          '${(kayit['aksesuar_bedenler']?['aksesuarlar']?['ad'] ?? '-')} için $miktar adet sarf kaydı silinecek.\n\nBu işlem stok miktarını geri ekler.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      final firmaId = TenantManager.instance.requireFirmaId;

      final beden = await supabase
          .from(DbTables.aksesuarBedenler)
          .select('stok_miktari')
          .eq('firma_id', firmaId)
          .eq('id', bedenId)
          .single();

      final mevcutStok = (beden['stok_miktari'] as num?)?.toInt() ?? 0;

      await supabase
          .from(DbTables.aksesuarBedenler)
          .update({
            'stok_miktari': mevcutStok + miktar,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firma_id', firmaId)
          .eq('id', bedenId);

      await supabase
          .from(DbTables.aksesuarStokHareketleri)
          .delete()
          .eq('firma_id', firmaId)
          .eq('id', kayitId);

      if (aksesuarId != null && aksesuarId.isNotEmpty) {
        await _aksesuarToplamStokGuncelle(aksesuarId);
      }

      context.showSuccessSnackBar('Sarf kaydı silindi');

      await _loadAksesuarlar();
      await _loadSarfKayitlari();
    } catch (e) {
      context.showErrorSnackBar('Silme hatası: $e');
    }
  }

  Widget _buildSarfIslemButonlari(Map<String, dynamic> kayit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Sarf kaydını düzenle',
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: _primaryColor,
          onPressed: () => _showSarfDuzenleDialog(kayit),
        ),
        IconButton(
          tooltip: 'Sarf kaydını sil',
          icon: const Icon(Icons.delete_outline, size: 18),
          color: _dangerColor,
          onPressed: () => _showSarfSilDialog(kayit),
        ),
      ],
    );
  }

  Widget _buildSarfRaporuTab() {
    final kayitlar = _filtreliSarfKayitlari;
    final toplamAdet = kayitlar.fold<int>(0, (s, k) => s + ((k['miktar'] as int?) ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Başlık + yenile
          Container(
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
                    color: _warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.output_rounded, color: _warningColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aksesuar Sarf Raporu',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      Text('Yapılan tüm sarf işlemlerinin kayıt ve geçmiş raporu',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadSarfKayitlari,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Yenile',
                ),
                IconButton(
                  onPressed: _sarfKayitlari.isEmpty
                      ? null
                      : () => _sarfExcelIndir(_filtreliSarfKayitlari),
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Excel İndir',
                  color: _successColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Özet
          LayoutBuilder(builder: (ctx, cs) {
            final kart1 = _buildOzetKutusu(
                'Toplam Sarf', '${kayitlar.length} kayıt', Icons.receipt_long, _warningColor);
            final kart2 = _buildOzetKutusu(
                'Toplam Adet', '$toplamAdet', Icons.numbers, _dangerColor);
            if (cs.maxWidth < 480) {
              return Column(children: [
                kart1,
                const SizedBox(height: 8),
                kart2,
              ]);
            }
            return Row(children: [
              Expanded(child: kart1),
              const SizedBox(width: 8),
              Expanded(child: kart2),
            ]);
          }),
          const SizedBox(height: 12),

          // Filtreler
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: LayoutBuilder(builder: (ctx, cs) {
              final dar = cs.maxWidth < 700;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: dar ? cs.maxWidth : 280,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Aksesuar, SKU, tedarikçi, beden ara',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _sarfArama = v),
                    ),
                  ),
                  SizedBox(
                    width: dar ? cs.maxWidth : 180,
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _sarfBaslangic ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (d != null) setState(() => _sarfBaslangic = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Başlangıç tarihi',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(
                          _sarfBaslangic != null
                              ? '${_sarfBaslangic!.day.toString().padLeft(2, '0')}.${_sarfBaslangic!.month.toString().padLeft(2, '0')}.${_sarfBaslangic!.year}'
                              : 'Seçiniz',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: dar ? cs.maxWidth : 180,
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _sarfBitis ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (d != null) setState(() => _sarfBitis = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Bitiş tarihi',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(
                          _sarfBitis != null
                              ? '${_sarfBitis!.day.toString().padLeft(2, '0')}.${_sarfBitis!.month.toString().padLeft(2, '0')}.${_sarfBitis!.year}'
                              : 'Seçiniz',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  if (_sarfBaslangic != null || _sarfBitis != null || _sarfArama.isNotEmpty ||
                      _sarfTedarikciFiltre != null || _sarfModelFiltre != null)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _sarfBaslangic = null;
                        _sarfBitis = null;
                        _sarfArama = '';
                        _sarfTedarikciFiltre = null;
                        _sarfModelFiltre = null;
                      }),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Temizle'),
                    ),
                  // Tedarikçi dropdown
                  Builder(builder: (_) {
                    final tedList = _sarfKayitlari
                        .map((k) => k['tedarikci_adi']?.toString() ?? '')
                        .where((s) => s.isNotEmpty)
                        .toSet()
                        .toList()..sort();
                    if (tedList.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      width: dar ? cs.maxWidth : 200,
                      child: DropdownButtonFormField<String>(
                        value: _sarfTedarikciFiltre,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tedarikçi',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...tedList.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) => setState(() => _sarfTedarikciFiltre = v),
                      ),
                    );
                  }),
                  // Model dropdown
                  Builder(builder: (_) {
                    final modelList = _sarfKayitlari.map((k) {
                      final marka = k['triko_takip']?['marka']?.toString() ?? '';
                      final itemNo = k['triko_takip']?['item_no']?.toString() ?? '';
                      return [marka, itemNo].where((s) => s.isNotEmpty).join(' - ');
                    }).where((s) => s.isNotEmpty).toSet().toList()..sort();
                    if (modelList.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      width: dar ? cs.maxWidth : 220,
                      child: DropdownButtonFormField<String>(
                        value: _sarfModelFiltre,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...modelList.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) => setState(() => _sarfModelFiltre = v),
                      ),
                    );
                  }),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),

          // Tablo veya liste
          if (_sarfYukleniyor)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: LoadingWidget(),
            )
          else if (kayitlar.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Henüz sarf kaydı bulunmuyor',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            _buildSarfTablosu(kayitlar),
        ],
      ),
    );
  }

  Widget _buildSarfTablosu(List<Map<String, dynamic>> kayitlar) {
    return LayoutBuilder(builder: (ctx, cs) {
      if (cs.maxWidth < 640) {
        return _buildSarfKartListesi(kayitlar);
      }
      return _buildSarfMasaustuTablosu(kayitlar);
    });
  }

  // ── Mobil: kart listesi ──────────────────────────────────────
  Widget _buildSarfKartListesi(List<Map<String, dynamic>> kayitlar) {
    return Column(
      children: kayitlar.map((k) {
        final aksAd = k['aksesuar_bedenler']?['aksesuarlar']?['ad']?.toString() ?? '-';
        final aksSku = k['aksesuar_bedenler']?['aksesuarlar']?['sku']?.toString() ?? '-';
        final beden = k['aksesuar_bedenler']?['beden']?.toString() ?? '-';
        final miktar = (k['miktar'] as int?) ?? 0;
        final aciklama = k['aciklama']?.toString() ?? '';
        final tarih = _formatTarih(k['created_at']?.toString());
        final modelMarka = k['triko_takip']?['marka']?.toString() ?? '';
        final modelItemNo = k['triko_takip']?['item_no']?.toString() ?? '';
        final modelLabel = [modelMarka, modelItemNo].where((s) => s.isNotEmpty).join(' - ');
        final tedLabel = k['tedarikci_adi']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst: aksesuar adı + adet
              Row(
                children: [
                  Expanded(
                    child: Text(aksAd,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _dangerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$miktar adet',
                        style: TextStyle(color: _dangerColor, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // SKU + Beden
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _sarfChip('SKU: $aksSku', const Color(0xFF64748B)),
                  _sarfChip(beden, _primaryColor),
                ],
              ),
              const SizedBox(height: 6),
              // Model
              if (modelLabel.isNotEmpty)
                _sarfInfoRow(Icons.style_outlined, modelLabel),
              // Tedarikçi
              if (tedLabel.isNotEmpty && tedLabel != '-')
                _sarfInfoRow(Icons.business_outlined, tedLabel),
              // Tarih
              _sarfInfoRow(Icons.access_time, tarih),
              // Açıklama
              if (aciklama.isNotEmpty)
                _sarfInfoRow(Icons.notes, aciklama),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: _buildSarfIslemButonlari(k),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sarfChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sarfInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ── Masaüstü: DataTable ──────────────────────────────────────
  Widget _buildSarfMasaustuTablosu(List<Map<String, dynamic>> kayitlar) {
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
              DataColumn(label: Text('Tarih')),
              DataColumn(label: Text('Aksesuar')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Beden')),
              DataColumn(label: Text('Model')),
              DataColumn(label: Text('Tedarikçi')),
              DataColumn(label: Text('Adet'), numeric: true),
              DataColumn(label: Text('Açıklama')),
              DataColumn(label: Text('İşlem')),
            ],
            rows: kayitlar.map((k) {
              final aksAd = k['aksesuar_bedenler']?['aksesuarlar']?['ad']?.toString() ?? '-';
              final aksSku = k['aksesuar_bedenler']?['aksesuarlar']?['sku']?.toString() ?? '-';
              final beden = k['aksesuar_bedenler']?['beden']?.toString() ?? '-';
              final miktar = (k['miktar'] as int?) ?? 0;
              final aciklama = k['aciklama']?.toString() ?? '';
              final tarih = _formatTarih(k['created_at']?.toString());
              final modelMarka = k['triko_takip']?['marka']?.toString() ?? '';
              final modelItemNo = k['triko_takip']?['item_no']?.toString() ?? '';
              final modelLabel = [modelMarka, modelItemNo].where((s) => s.isNotEmpty).join(' - ');
              final tedLabel = k['tedarikci_adi']?.toString() ?? '-';

              return DataRow(cells: [
                DataCell(Text(tarih, style: const TextStyle(fontSize: 12))),
                DataCell(SizedBox(
                  width: 160,
                  child: Text(aksAd,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                )),
                DataCell(Text(aksSku)),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(beden,
                      style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w700, fontSize: 12)),
                )),
                DataCell(SizedBox(
                  width: 130,
                  child: modelLabel.isEmpty
                      ? const Text('-', style: TextStyle(color: Colors.grey))
                      : Text(modelLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                )),
                DataCell(SizedBox(
                  width: 120,
                  child: Text(tedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _dangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$miktar',
                      style: TextStyle(color: _dangerColor, fontWeight: FontWeight.w800)),
                )),
                DataCell(SizedBox(
                  width: 140,
                  child: Text(aciklama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                )),
                DataCell(_buildSarfIslemButonlari(k)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _pageTabController,
              labelColor: _primaryColor,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: _primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Aksesuar Stok'),
                Tab(icon: Icon(Icons.output_rounded, size: 18), text: 'Sarf Raporu'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _pageTabController,
              children: [
                _buildStokTab(),
                _buildSarfRaporuTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStokTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ustBolum = [
          _buildAksesuarUstPanel(),
          const SizedBox(height: 12),
          _buildAksesuarAracCubugu(),
          const SizedBox(height: 12),
          _buildAksesuarOzetleri(),
          const SizedBox(height: 12),
        ];

        // Her zaman scroll+fixed liste yüksekliği kullan — overflow'u önler
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...ustBolum,
              SizedBox(
                height: (constraints.maxHeight - 32).clamp(300.0, 800.0),
                child: _buildAksesuarListeAlani(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Excel şablonu oluşturma
  Future<void> _downloadExcelTemplate() async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Aksesuar_Sablonu'];

      // Başlık satırı
      final headers = [
        'SKU Kodu*',
        'Aksesuar Adı*',
        'Marka',
        'Renk',
        'Renk Kodu',
        'Birim',
        'Birim Fiyat',
        'Malzeme',
        'Minimum Stok',
        'Açıklama',
        'Beden 1*',
        'Beden 1 Stok',
        'Beden 2',
        'Beden 2 Stok',
        'Beden 3',
        'Beden 3 Stok',
        'Beden 4',
        'Beden 4 Stok',
        'Beden 5',
        'Beden 5 Stok'
      ];

      // Başlıkları ekle
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = xl.CellStyle(
          backgroundColorHex: '#0066CC',
          fontColorHex: '#FFFFFF',
          bold: true,
        );
      }

      // Örnek satır ekle
      final exampleData = [
        'AKS001',
        'Örnek Düğme',
        'Coats',
        'Mavi',
        '#0000FF',
        'adet',
        '2.50',
        'Plastik',
        '50',
        'Örnek açıklama',
        'S',
        '100',
        'M',
        '150',
        'L',
        '120',
        '',
        '',
        '',
        ''
      ];

      for (int i = 0; i < exampleData.length; i++) {
        final cell = sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = exampleData[i];
      }

      // Açıklama sayfası ekle
      final instructionSheet = excel['Kullanim_Kilavuzu'];
      final instructions = [
        'AKSESUAR TOPLU EKLEME ŞABLONU KULLANIM KILAVUZU',
        '',
        'ZORUNLU ALANLAR (*):',
        '• SKU Kodu: Benzersiz ürün kodu',
        '• Aksesuar Adı: Ürün adı',
        '• Beden 1: En az bir beden bilgisi zorunlu',
        '',
        'DİĞER ALANLAR:',
        '• Marka: Üretici firma',
        '• Renk: Ürün rengi',
        '• Renk Kodu: Hex renk kodu (#000000)',
        '• Birim: Varsayılan "adet"',
        '• Birim Fiyat: Sayısal değer (TL)',
        '• Malzeme: Ürün malzemesi',
        '• Minimum Stok: Uyarı seviyesi (varsayılan 10)',
        '• Açıklama: Ek bilgiler',
        '',
        'BEDEN BİLGİLERİ:',
        '• En az 1, en fazla 5 beden ekleyebilirsiniz',
        '• Beden: S, M, L, XL, 75cm, 18mm gibi',
        '• Stok: Başlangıç stok miktarı (varsayılan 0)',
        '',
        'NOTLAR:',
        '• Boş satırları silin',
        '• SKU kodları tekrar etmemeli',
        '• Sayısal değerlerde Türkçe karakter kullanmayın'
      ];

      for (int i = 0; i < instructions.length; i++) {
        final cell = instructionSheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
        cell.value = instructions[i];
        if (i == 0) {
          cell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);
        } else if (instructions[i].endsWith(':')) {
          cell.cellStyle = xl.CellStyle(bold: true);
        }
      }

      // Excel dosyasını byte array'e çevir
      final bytes = excel.encode();
      if (bytes != null) {
        // Dosyayı indirme işlemi (web için)
        downloadFileWeb(bytes, 'aksesuar_sablonu.xlsx');

        context.showSuccessSnackBar('Excel şablonu indirildi');
      }
    } catch (e) {
      context.showErrorSnackBar('Hata: $e');
    }
  }

  // Excel dosyasından toplu import
  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final excel = xl.Excel.decodeBytes(bytes);
          final sheet = excel.tables.values.first;

          final List<Map<String, dynamic>> aksesuarListesi = [];
          int successCount = 0;
          int errorCount = 0;
          final List<String> errors = [];

          // İlk satır başlık, 2. satırdan itibaren veri
          for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
            try {
              final row = sheet.rows[rowIndex];

              // Boş satırları atla
              if (row.isEmpty ||
                  row[0]?.value?.toString().trim().isEmpty == true) {
                continue;
              }

              final sku = row[0]?.value?.toString().trim() ?? '';
              final ad = row[1]?.value?.toString().trim() ?? '';

              if (sku.isEmpty || ad.isEmpty) {
                errors
                    .add('Satır ${rowIndex + 1}: SKU ve Aksesuar Adı zorunlu');
                errorCount++;
                continue;
              }

              // Bedenler ve stokları kontrol et
              final List<Map<String, dynamic>> bedenler = [];
              for (int i = 10; i < 20; i += 2) {
                // Beden sütunları
                final beden =
                    row.length > i ? row[i]?.value?.toString().trim() : null;
                if (beden != null && beden.isNotEmpty) {
                  final stokStr = row.length > (i + 1)
                      ? row[i + 1]?.value?.toString()
                      : '0';
                  final stok = int.tryParse(stokStr ?? '0') ?? 0;
                  bedenler.add({
                    'beden': beden,
                    'stok_miktari': stok,
                  });
                }
              }

              if (bedenler.isEmpty) {
                errors.add(
                    'Satır ${rowIndex + 1}: En az bir beden bilgisi gerekli');
                errorCount++;
                continue;
              }

              // Aksesuar verisini hazırla
              final aksesuarData = {
                'sku': sku,
                'ad': ad,
                'marka': row.length > 2
                    ? (row[2]?.value?.toString().trim() ?? '')
                    : '',
                'renk': row.length > 3
                    ? (row[3]?.value?.toString().trim() ?? '')
                    : '',
                'renk_kodu': row.length > 4
                    ? (row[4]?.value?.toString().trim() ?? '')
                    : '',
                'birim': row.length > 5
                    ? (row[5]?.value?.toString().trim() ?? 'adet')
                    : 'adet',
                'birim_fiyat': row.length > 6
                    ? (double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0)
                    : 0.0,
                'malzeme': row.length > 7
                    ? (row[7]?.value?.toString().trim() ?? '')
                    : '',
                'minimum_stok': row.length > 8
                    ? (int.tryParse(row[8]?.value?.toString() ?? '10') ?? 10)
                    : 10,
                'aciklama': row.length > 9
                    ? (row[9]?.value?.toString().trim() ?? '')
                    : '',
                'durum': 'aktif',
                'bedenler': bedenler,
              };

              aksesuarListesi.add(aksesuarData);
            } catch (e) {
              errors.add('Satır ${rowIndex + 1}: $e');
              errorCount++;
            }
          }

          // Veritabanına kaydet
          for (final aksesuar in aksesuarListesi) {
            try {
              // Aksesuar kaydını oluştur
              final toplamStok = (aksesuar['bedenler'] as List).fold<int>(
                  0,
                  (sum, beden) =>
                      sum + ((beden['stok_miktari'] as num?)?.toInt() ?? 0));
              final result = await supabase
                  .from(DbTables.aksesuarlar)
                  .insert({
                    'sku': aksesuar['sku'],
                    'ad': aksesuar['ad'],
                    'marka': aksesuar['marka'],
                    'renk': aksesuar['renk'],
                    'renk_kodu': aksesuar['renk_kodu'],
                    'birim': aksesuar['birim'],
                    'birim_fiyat': aksesuar['birim_fiyat'],
                    'malzeme': aksesuar['malzeme'],
                    'minimum_stok': aksesuar['minimum_stok'],
                    'aciklama': aksesuar['aciklama'],
                    'miktar': toplamStok,
                    'durum': aksesuar['durum'],
                    'firma_id': TenantManager.instance.requireFirmaId,
                  })
                  .select('id')
                  .single();

              final aksesuarId = result['id'];

              // Bedenlerini ekle
              for (final beden in aksesuar['bedenler']) {
                await supabase.from(DbTables.aksesuarBedenler).insert({
                  'aksesuar_id': aksesuarId,
                  'beden': beden['beden'],
                  'stok_miktari': beden['stok_miktari'],
                  'durum': 'aktif',
                  'firma_id': TenantManager.instance.requireFirmaId,
                });
              }

              await _aksesuarToplamStokGuncelle(aksesuarId.toString());

              successCount++;
            } catch (e) {
              errors.add('${aksesuar['sku']}: $e');
              errorCount++;
            }
          }

          // Sonuç mesajı
          String message = 'Toplam: ${successCount + errorCount}\n';
          message += 'Başarılı: $successCount\n';
          if (errorCount > 0) {
            message += 'Hatalı: $errorCount\n\n';
            message += 'Hatalar:\n${errors.take(5).join('\n')}';
            if (errors.length > 5) {
              message += '\n... ve ${errors.length - 5} hata daha';
            }
          }

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Sonucu'),
              content: SingleChildScrollView(
                child: Text(message),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );

          if (successCount > 0) {
            await _loadAksesuarlar();
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }
}
