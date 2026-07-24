import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_package;
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/pages/stok/iplik_siparis_takip_page.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/user_role_service.dart';

part 'iplik_stoklari_crud.dart';
part 'iplik_stoklari_detay.dart';
part 'iplik_stoklari_siparis.dart';

class IplikStoklariPage extends StatefulWidget {
  const IplikStoklariPage({super.key});

  @override
  State<IplikStoklariPage> createState() => _IplikStoklariPageState();
}

class _IplikStoklariPageState extends State<IplikStoklariPage> {
  final supabase = Supabase.instance.client;
  String? kullaniciRolu;
  Set<String> _kullaniciRolleri = {};

  // Stok ve hareket verileri
  List<Map<String, dynamic>> iplikStoklari = [];
  List<Map<String, dynamic>> filtreliStoklar = [];
  List<Map<String, dynamic>> iplikHareketleri = [];
  List<Map<String, dynamic>> tedarikciler = [];
  List<Map<String, dynamic>> iplikSiparisleri = [];

  // Yükleniyor durumu
  bool _yukleniyor = false;

  // Arama/filtreleme kontrolleri
  final stokAramaController = TextEditingController();
  final hareketAramaController = TextEditingController();
  String stokDurumFiltresi = 'tum';
  String stokSiralama = 'ad';
  String? seciliTedarikciFiltresi;
  String hareketTipiFiltresi = 'tum';
  String hareketTarihFiltresi = 'tum';
  String hareketSiralama = 'son_kayit';

  int seciliMenu =
      0; // 0: İplik Stokları, 1: İplik Hareketleri, 2: İplik Siparişi

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _successColor = Color(0xFF059669);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _surfaceColor = Color(0xFFF8FAFC);

  bool get _adminMi =>
      _kullaniciRolleri.contains('admin') ||
      _kullaniciRolleri.contains('firma_admin') ||
      _kullaniciRolleri.contains('firma_sahibi') ||
      _kullaniciRolleri.contains('depocu');

  @override
  void initState() {
    super.initState();
    _yetkiGetir();
    _verileriYukle();
  }

  @override
  void dispose() {
    stokAramaController.dispose();
    hareketAramaController.dispose();
    super.dispose();
  }

  Future<void> _yetkiGetir() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final roller = await UserRoleService.kullaniciTumRolleriniGetir(
        userId: userId,
      );
      setState(() {
        _kullaniciRolleri = roller;
        kullaniciRolu = UserRoleService.birincilRolSec(roller);
      });
    }
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);

    try {
      final firmaId = TenantManager.instance.requireFirmaId;

      List<Map<String, dynamic>> yeniTedarikciler = [];
      List<Map<String, dynamic>> yeniStoklar = [];
      List<Map<String, dynamic>> yeniHareketler = [];
      List<Map<String, dynamic>> yeniSiparisler = [];

      // Tedarikçiler önce yüklenir; stok kayıtları ekranda tedarikçi adıyla zenginleştirilir.
      try {
        final tedarikciVeri = await supabase
            .from(DbTables.tedarikciler)
            .select(
                'id, ad, sirket, telefon, tedarikci_turu, faaliyet, faaliyet_alani')
            .eq('firma_id', firmaId)
            .order('sirket');

        yeniTedarikciler = List<Map<String, dynamic>>.from(tedarikciVeri);
        debugPrint('Tedarikciler yüklendi: ${yeniTedarikciler.length} adet');
      } catch (e) {
        debugPrint('Tedarikciler tablosu bulunamadı: $e');
      }

      final tedarikciMap = {
        for (final tedarikci in yeniTedarikciler)
          if (tedarikci['id'] != null) tedarikci['id'].toString(): tedarikci,
      };

      // İplik stokları
      try {
        final stokVeri = await supabase
            .from(DbTables.iplikStoklari)
            .select('*')
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false);

        yeniStoklar = List<Map<String, dynamic>>.from(stokVeri).map((stok) {
          final tedarikci = tedarikciMap[stok['tedarikci_id']?.toString()];
          return {
            ...stok,
            'tedarikci': tedarikci,
            'tedarikci_adi': _tedarikciAdi(stok, tedarikci: tedarikci),
          };
        }).toList();

        debugPrint('İplik stokları yüklendi: ${yeniStoklar.length} adet');
      } catch (e) {
        debugPrint('İplik stokları tablosu bulunamadı: $e');
      }

      // İplik hareketleri - Join ile iplik bilgilerini de al
      try {
        final hareketVeri =
            await supabase.from(DbTables.iplikHareketleri).select('''
              *,
              iplik_stoklari!inner(
                id,
                ad,
                renk,
                lot_no,
                birim
              )
            ''').eq('firma_id', firmaId).order('created_at', ascending: false);

        // Veriyi düzenle - iplik bilgilerini doğrudan kayıt seviyesine taşı
        final duzenlenmisHareketler = hareketVeri.map((hareket) {
          final iplikBilgisi = hareket[DbTables.iplikStoklari];
          return {
            ...hareket,
            'iplik': iplikBilgisi,
          };
        }).toList();

        yeniHareketler = List<Map<String, dynamic>>.from(duzenlenmisHareketler);

        debugPrint('İplik hareketleri yüklendi: ${yeniHareketler.length} adet');
      } catch (e) {
        debugPrint('İplik hareketleri join hatası, basit sorgu deneniyor: $e');
        // Join başarısız olursa basit sorgu ile dene
        try {
          final hareketVeri = await supabase
              .from(DbTables.iplikHareketleri)
              .select('*')
              .eq('firma_id', firmaId)
              .order('created_at', ascending: false);

          yeniHareketler = List<Map<String, dynamic>>.from(hareketVeri);

          debugPrint(
              'İplik hareketleri basit sorgu ile yüklendi: ${yeniHareketler.length} adet');
        } catch (e2) {
          debugPrint('İplik hareketleri tablosu bulunamadı: $e2');
        }
      }

      // İplik siparişleri - Basit sorgu ile (join olmadan)
      try {
        final siparisVeri = await supabase
            .from(DbTables.iplikSiparisleri)
            .select('*')
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false);

        yeniSiparisler = List<Map<String, dynamic>>.from(siparisVeri);

        debugPrint('İplik siparişleri yüklendi: ${yeniSiparisler.length} adet');
      } catch (e) {
        debugPrint('İplik siparişleri tablosu bulunamadı: $e');
      }

      setState(() {
        tedarikciler = yeniTedarikciler;
        iplikStoklari = yeniStoklar;
        iplikHareketleri = yeniHareketler;
        iplikSiparisleri = yeniSiparisler;
      });
      _stokFiltrele(stokAramaController.text);
    } catch (e) {
      debugPrint('Genel veri yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Veri yükleme hatası: Lütfen Supabase tablolarının oluşturulduğundan emin olun'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  void _stokFiltrele(String arama) {
    final aramaLower = arama.trim().toLowerCase();
    final sonuc = iplikStoklari.where((stok) {
      final miktar = (stok['miktar'] as num?)?.toDouble() ?? 0.0;
      final tedarikciId = stok['tedarikci_id']?.toString();
      final metin =
          '${stok['ad']} ${stok['renk']} ${stok['lot_no']} ${stok['tedarikci_adi']}'
              .toLowerCase();
      final aramaUygun = aramaLower.isEmpty || metin.contains(aramaLower);
      final tedarikciUygun = seciliTedarikciFiltresi == null ||
          seciliTedarikciFiltresi == tedarikciId;
      final durumUygun = switch (stokDurumFiltresi) {
        'kritik' => miktar > 0 && miktar < 10,
        'yok' => miktar <= 0,
        'var' => miktar >= 10,
        _ => true,
      };
      return aramaUygun && tedarikciUygun && durumUygun;
    }).toList();

    sonuc.sort((a, b) {
      switch (stokSiralama) {
        case 'miktar_az':
          return ((a['miktar'] as num?)?.toDouble() ?? 0)
              .compareTo((b['miktar'] as num?)?.toDouble() ?? 0);
        case 'miktar_cok':
          return ((b['miktar'] as num?)?.toDouble() ?? 0)
              .compareTo((a['miktar'] as num?)?.toDouble() ?? 0);
        case 'tedarikci':
          return (a['tedarikci_adi'] ?? '')
              .toString()
              .compareTo((b['tedarikci_adi'] ?? '').toString());
        case 'tarih':
          return (b['created_at'] ?? '')
              .toString()
              .compareTo((a['created_at'] ?? '').toString());
        case 'ad':
        default:
          return (a['ad'] ?? '')
              .toString()
              .compareTo((b['ad'] ?? '').toString());
      }
    });

    setState(() => filtreliStoklar = sonuc);
  }

  List<Map<String, dynamic>> get _filtreliHareketler {
    final arama = hareketAramaController.text.trim().toLowerCase();
    final simdi = DateTime.now();
    final bugun = DateTime(simdi.year, simdi.month, simdi.day);
    final haftaBaslangic = bugun.subtract(Duration(days: bugun.weekday - 1));
    final ayBaslangic = DateTime(simdi.year, simdi.month);

    final sonuc = iplikHareketleri.where((kayit) {
      final stok = _hareketIplikBilgisi(kayit);
      final metin =
          '${stok['ad']} ${stok['renk']} ${stok['lot_no']} ${kayit['hareket_tipi']} ${kayit['aciklama']}'
              .toLowerCase();
      final aramaUygun = arama.isEmpty || metin.contains(arama);
      final tipUygun = hareketTipiFiltresi == 'tum' ||
          kayit['hareket_tipi']?.toString() == hareketTipiFiltresi;
      final tarih = DateTime.tryParse(kayit['created_at']?.toString() ?? '');
      final tarihUygun = switch (hareketTarihFiltresi) {
        'bugun' => tarih != null &&
            DateTime(tarih.year, tarih.month, tarih.day) == bugun,
        'hafta' => tarih != null && !tarih.isBefore(haftaBaslangic),
        'ay' => tarih != null && !tarih.isBefore(ayBaslangic),
        _ => true,
      };
      return aramaUygun && tipUygun && tarihUygun;
    }).toList();

    sonuc.sort((a, b) {
      final aTarih = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTarih = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final aMiktar = (a['miktar'] as num?)?.toDouble() ?? 0;
      final bMiktar = (b['miktar'] as num?)?.toDouble() ?? 0;
      switch (hareketSiralama) {
        case 'eski_kayit':
          return aTarih.compareTo(bTarih);
        case 'miktar_cok':
          return bMiktar.compareTo(aMiktar);
        case 'miktar_az':
          return aMiktar.compareTo(bMiktar);
        case 'son_kayit':
        default:
          return bTarih.compareTo(aTarih);
      }
    });

    return sonuc;
  }

  Map<String, dynamic> _hareketIplikBilgisi(Map<String, dynamic> kayit) {
    final iplik = kayit['iplik'];
    if (iplik is Map) return Map<String, dynamic>.from(iplik);
    for (final stok in iplikStoklari) {
      if (stok['id'] == kayit['iplik_id']) return stok;
    }
    return const {};
  }

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _excelCellText(excel_package.Data? value) {
    final raw = value?.value;
    if (raw == null) return '';
    final text = raw.toString().trim();
    if (text == 'null') return '';
    return text;
  }

  DateTime? _parseDateText(String value) {
    final text = value.trim();
    if (text.isEmpty || text.startsWith('[')) return null;
    for (final formatter in [
      DateFormat('dd.MM.yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('dd/MM/yyyy'),
    ]) {
      try {
        return formatter.parseStrict(text);
      } catch (_) {}
    }
    return DateTime.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: seciliMenu == 0
          ? SingleChildScrollView(
              child: Column(
                children: [
                  _buildDepoUstBar(),
                  _buildStokDepoSayfasi(),
                ],
              ),
            )
          : Column(
              children: [
                _buildDepoUstBar(),
                Expanded(child: _buildSeciliIcerik()),
              ],
            ),
      floatingActionButton: seciliMenu == 0
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: _yeniIplikGirisi,
              tooltip: 'Yeni İplik Girişi',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDepoUstBar() {
    const menuItems = [
      (0, Icons.inventory_2_outlined, 'Stok Deposu'),
      (1, Icons.timeline, 'Hareketler'),
      (2, Icons.add_shopping_cart, 'Sipariş Oluştur'),
      (3, Icons.local_shipping_outlined, 'Sipariş Takip'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.warehouse_outlined, color: _primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İplik Depo Yönetimi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    Text(
                      'Stok, hareket, tedarikçi ve sipariş takibi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
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
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: menuItems.map((item) {
                final selected = seciliMenu == item.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    avatar: Icon(
                      item.$2,
                      size: 18,
                      color: selected ? Colors.white : const Color(0xFF475569),
                    ),
                    label: Text(item.$3),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    selectedColor: _primaryColor,
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color:
                            selected ? _primaryColor : const Color(0xFFE2E8F0),
                      ),
                    ),
                    onSelected: (_) => setState(() => seciliMenu = item.$1),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeciliIcerik() {
    if (seciliMenu == 0) return _buildStokDepoSayfasi();
    if (seciliMenu == 1) return _buildHareketlerSayfasi();
    if (seciliMenu == 2) return _buildSiparisOlusturSayfasi();
    if (seciliMenu == 3) return const IplikSiparisTakipPage();
    return const Center(child: Text('Bilinmeyen sayfa'));
  }

  Widget _buildStokDepoSayfasi() {
    final toplamKg = iplikStoklari.fold<double>(
      0,
      (sum, stok) => sum + ((stok['miktar'] as num?)?.toDouble() ?? 0),
    );
    final kritikSayisi = iplikStoklari.where((stok) {
      final miktar = (stok['miktar'] as num?)?.toDouble() ?? 0;
      return miktar > 0 && miktar < 10;
    }).length;
    final bitenSayisi = iplikStoklari.where((stok) {
      final miktar = (stok['miktar'] as num?)?.toDouble() ?? 0;
      return miktar <= 0;
    }).length;
    final toplamDeger = iplikStoklari.fold<double>(
      0,
      (sum, stok) => sum + ((stok['toplam_deger'] as num?)?.toDouble() ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStokOzetAlani(
            toplamKg: toplamKg,
            kritikSayisi: kritikSayisi,
            bitenSayisi: bitenSayisi,
            toplamDeger: toplamDeger,
          ),
          const SizedBox(height: 14),
          _buildStokFiltreleri(),
          const SizedBox(height: 12),
          _buildStokListeAlani(),
          const SizedBox(height: 84),
        ],
      ),
    );
  }

  Widget _buildStokOzetAlani({
    required double toplamKg,
    required int kritikSayisi,
    required int bitenSayisi,
    required double toplamDeger,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final kartlar = [
          _buildOzetKutusu('Toplam Stok', '${toplamKg.toStringAsFixed(1)} kg',
              Icons.scale, _primaryColor),
          _buildOzetKutusu('Kalem', iplikStoklari.length.toString(),
              Icons.category_outlined, const Color(0xFF7C3AED)),
          _buildOzetKutusu('Kritik', kritikSayisi.toString(),
              Icons.warning_amber, _warningColor),
          _buildOzetKutusu('Biten', bitenSayisi.toString(),
              Icons.remove_circle_outline, _dangerColor),
          _buildOzetKutusu(
              'Değer',
              '${_getParaBirimiSembolu('TL')}${toplamDeger.toStringAsFixed(0)}',
              Icons.payments_outlined,
              _successColor),
        ];

        if (constraints.maxWidth < 520) {
          return Column(
            children: kartlar
                .map(
                  (kart) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: kart,
                  ),
                )
                .toList(),
          );
        }

        if (constraints.maxWidth < 900) {
          final kartGenisligi = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kartlar
                .map((kart) => SizedBox(width: kartGenisligi, child: kart))
                .toList(),
          );
        }

        return Row(
          children: kartlar
              .map(
                (kart) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: kart,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStokListeAlani() {
    if (_yukleniyor) return const LoadingWidget();
    if (filtreliStoklar.isEmpty) {
      return _buildBosDurum(
          'Stok bulunamadı', 'Arama veya filtreleri değiştirin.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtreliStoklar.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildMobilStokSatiri(filtreliStoklar[index]),
          );
        }
        return _buildStokTablosu();
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
                    fontWeight: FontWeight.w800,
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

  Widget _buildStokFiltreleri() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 850;
          final children = [
            SizedBox(
              width: narrow ? constraints.maxWidth : 340,
              child: TextField(
                controller: stokAramaController,
                decoration: const InputDecoration(
                  labelText: 'İplik, renk, lot veya tedarikçi ara',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _stokFiltrele,
              ),
            ),
            SizedBox(
              width: narrow ? constraints.maxWidth : 190,
              child: DropdownButtonFormField<String>(
                initialValue: stokDurumFiltresi,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Stok durumu',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'tum', child: Text('Tümü')),
                  DropdownMenuItem(value: 'var', child: Text('Yeterli')),
                  DropdownMenuItem(value: 'kritik', child: Text('Kritik')),
                  DropdownMenuItem(value: 'yok', child: Text('Biten')),
                ],
                onChanged: (value) {
                  stokDurumFiltresi = value ?? 'tum';
                  _stokFiltrele(stokAramaController.text);
                },
              ),
            ),
            SizedBox(
              width: narrow ? constraints.maxWidth : 220,
              child: DropdownButtonFormField<String?>(
                initialValue: seciliTedarikciFiltresi,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tedarikçi',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Tüm tedarikçiler')),
                  ...tedarikciler.map((tedarikci) => DropdownMenuItem<String?>(
                        value: tedarikci['id']?.toString(),
                        child: Text(
                          '${tedarikci['sirket'] ?? tedarikci['ad'] ?? 'İsimsiz'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (value) {
                  seciliTedarikciFiltresi = value;
                  _stokFiltrele(stokAramaController.text);
                },
              ),
            ),
            SizedBox(
              width: narrow ? constraints.maxWidth : 180,
              child: DropdownButtonFormField<String>(
                initialValue: stokSiralama,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sıralama',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'ad', child: Text('İplik adı')),
                  DropdownMenuItem(
                      value: 'miktar_az', child: Text('Miktar artan')),
                  DropdownMenuItem(
                      value: 'miktar_cok', child: Text('Miktar azalan')),
                  DropdownMenuItem(
                      value: 'tedarikci', child: Text('Tedarikçi')),
                  DropdownMenuItem(value: 'tarih', child: Text('Son kayıt')),
                ],
                onChanged: (value) {
                  stokSiralama = value ?? 'ad';
                  _stokFiltrele(stokAramaController.text);
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  exportToExcel(filtreliStoklar, fileName: 'Iplik_Stoklari'),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Excel'),
            ),
            if (_adminMi)
              OutlinedButton.icon(
                onPressed: _stokBirlestirmeDialogGoster,
                icon: const Icon(Icons.merge_type),
                label: const Text('Birleştir'),
              ),
          ];

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
        },
      ),
    );
  }

  Widget _buildStokTablosu() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabloGenisligi =
              constraints.maxWidth < 1180 ? 1180.0 : constraints.maxWidth;
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tabloGenisligi,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                  dataRowMinHeight: 58,
                  dataRowMaxHeight: 104,
                  columnSpacing: 22,
                  horizontalMargin: 16,
                  columns: const [
                    DataColumn(label: Text('İplik')),
                    DataColumn(label: Text('Renk')),
                    DataColumn(label: Text('Lot')),
                    DataColumn(label: Text('Miktar')),
                    DataColumn(label: Text('Durum')),
                    DataColumn(label: Text('Tedarikçi')),
                    DataColumn(label: Text('Birim Fiyat')),
                    DataColumn(label: Text('İşlem')),
                  ],
                  rows: filtreliStoklar.map((stok) {
                    final miktar = (stok['miktar'] as num?)?.toDouble() ?? 0.0;
                    final durum = _stokDurumBilgisi(miktar);
                    return DataRow(
                      cells: [
                        DataCell(_tableText(stok['ad']?.toString() ?? '-',
                            width: 240, bold: true, maxLines: 3)),
                        DataCell(_tableText(stok['renk']?.toString() ?? '-',
                            width: 240, maxLines: 3)),
                        DataCell(_tableText(stok['lot_no']?.toString() ?? '-',
                            width: 140, maxLines: 2)),
                        DataCell(Text(
                            '${miktar.toStringAsFixed(2)} ${stok['birim'] ?? 'kg'}')),
                        DataCell(_buildDurumEtiketi(durum.$1, durum.$2)),
                        DataCell(_tableText(_tedarikciAdi(stok), width: 170)),
                        DataCell(Text(_formatFiyat(stok))),
                        DataCell(_buildStokAksiyonlari(stok, compact: true)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobilStokSatiri(Map<String, dynamic> stok) {
    final miktar = (stok['miktar'] as num?)?.toDouble() ?? 0.0;
    final durum = _stokDurumBilgisi(miktar);
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
                  stok['ad']?.toString() ?? '-',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              _buildDurumEtiketi(durum.$1, durum.$2),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _miniBilgi(
                'Renk',
                stok['renk']?.toString() ?? '-',
                width: 220,
                maxLines: 3,
              ),
              _miniBilgi('Lot', stok['lot_no']?.toString() ?? '-'),
              _miniBilgi('Miktar',
                  '${miktar.toStringAsFixed(2)} ${stok['birim'] ?? 'kg'}'),
              _miniBilgi('Tedarikçi', _tedarikciAdi(stok)),
              _miniBilgi('Fiyat', _formatFiyat(stok)),
            ],
          ),
          const SizedBox(height: 10),
          _buildStokAksiyonlari(stok),
        ],
      ),
    );
  }

  Widget _buildStokAksiyonlari(Map<String, dynamic> stok,
      {bool compact = false}) {
    final aksiyonlar = [
      IconButton(
        icon: const Icon(Icons.info_outline),
        color: _primaryColor,
        onPressed: () => _iplikDetayGoster(stok),
        tooltip: 'İplik detayları',
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
      IconButton(
        icon: const Icon(Icons.call_made),
        color: _dangerColor,
        onPressed: () => _cikisModalGoster(stok),
        tooltip: 'Çıkış / sarf yap',
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
      if (_adminMi)
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          color: _primaryColor,
          onPressed: () => _stokDuzenle(stok),
          tooltip: 'Düzenle',
          visualDensity:
              compact ? VisualDensity.compact : VisualDensity.standard,
        ),
      if (_adminMi)
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: _dangerColor,
          onPressed: () => _stokSil(stok),
          tooltip: 'Sil',
          visualDensity:
              compact ? VisualDensity.compact : VisualDensity.standard,
        ),
    ];

    if (!compact) {
      return Wrap(
        spacing: 2,
        runSpacing: 2,
        children: aksiyonlar,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: aksiyonlar,
    );
  }

  Widget _buildHareketlerSayfasi() {
    final filtreliHareketler = _filtreliHareketler;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'İplik Hareketleri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _verileriYukle,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => exportToExcel(filtreliHareketler,
                      fileName: 'Iplik_Hareketleri'),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Excel'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildHareketFiltreleri(),
          const SizedBox(height: 12),
          Expanded(
            child: _yukleniyor
                ? const LoadingWidget()
                : filtreliHareketler.isEmpty
                    ? _buildBosDurum('Hareket kaydı bulunamadı',
                        'Giriş, çıkış veya sayım hareketleri burada görünür.')
                    : ListView.separated(
                        itemCount: filtreliHareketler.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _buildHareketSatiri(filtreliHareketler[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHareketFiltreleri() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 820;
          final alan = dar ? constraints.maxWidth : 190.0;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: dar ? constraints.maxWidth : 320,
                child: TextField(
                  controller: hareketAramaController,
                  decoration: const InputDecoration(
                    labelText: 'İplik, renk, lot veya açıklama ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: alan,
                child: DropdownButtonFormField<String>(
                  initialValue: hareketTipiFiltresi,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Hareket tipi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tum', child: Text('Tümü')),
                    DropdownMenuItem(value: 'giris', child: Text('Giriş')),
                    DropdownMenuItem(value: 'cikis', child: Text('Çıkış')),
                    DropdownMenuItem(
                        value: 'transfer', child: Text('Transfer')),
                    DropdownMenuItem(value: 'sayim', child: Text('Sayım')),
                  ],
                  onChanged: (value) => setState(
                    () => hareketTipiFiltresi = value ?? 'tum',
                  ),
                ),
              ),
              SizedBox(
                width: alan,
                child: DropdownButtonFormField<String>(
                  initialValue: hareketTarihFiltresi,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tarih',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tum', child: Text('Tümü')),
                    DropdownMenuItem(value: 'bugun', child: Text('Bugün')),
                    DropdownMenuItem(value: 'hafta', child: Text('Bu hafta')),
                    DropdownMenuItem(value: 'ay', child: Text('Bu ay')),
                  ],
                  onChanged: (value) => setState(
                    () => hareketTarihFiltresi = value ?? 'tum',
                  ),
                ),
              ),
              SizedBox(
                width: alan,
                child: DropdownButtonFormField<String>(
                  initialValue: hareketSiralama,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sıralama',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'son_kayit', child: Text('Son kayıt')),
                    DropdownMenuItem(
                        value: 'eski_kayit', child: Text('Eski kayıt')),
                    DropdownMenuItem(
                        value: 'miktar_cok', child: Text('Miktar azalan')),
                    DropdownMenuItem(
                        value: 'miktar_az', child: Text('Miktar artan')),
                  ],
                  onChanged: (value) => setState(
                    () => hareketSiralama = value ?? 'son_kayit',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHareketSatiri(Map<String, dynamic> kayit) {
    final iplik = kayit['iplik'] ?? {};
    Map<String, dynamic>? bulunanIplik;
    if (iplik.isEmpty && kayit['iplik_id'] != null) {
      for (final stok in iplikStoklari) {
        if (stok['id'] == kayit['iplik_id']) {
          bulunanIplik = stok;
          break;
        }
      }
    }
    final iplikAdi = iplik['ad'] ?? bulunanIplik?['ad'] ?? 'İplik';
    final iplikRenk = iplik['renk'] ?? bulunanIplik?['renk'] ?? 'Renk Yok';
    final iplikLot = iplik['lot_no'] ?? bulunanIplik?['lot_no'] ?? '-';
    final iplikBirim = iplik['birim'] ?? bulunanIplik?['birim'] ?? 'kg';
    final tarih = DateTime.tryParse(kayit['created_at']?.toString() ?? '');
    final renk = _getHareketRenk(kayit['hareket_tipi'] ?? '');

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(_getHareketIcon(kayit['hareket_tipi'] ?? ''), color: renk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$iplikAdi${iplikRenk != 'Renk Yok' ? ' - $iplikRenk' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Lot: $iplikLot | ${_getHareketBaslik(kayit['hareket_tipi'] ?? 'bilinmiyor')} | ${kayit['miktar']} $iplikBirim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                if (kayit['aciklama'] != null &&
                    kayit['aciklama'].toString().isNotEmpty)
                  Text(
                    kayit['aciklama'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            tarih != null ? DateFormat('dd.MM.yyyy HH:mm').format(tarih) : '-',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBosDurum(String baslik, String aciklama) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(aciklama, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _tableText(
    String value, {
    double width = 140,
    bool bold = false,
    int maxLines = 1,
  }) {
    return Tooltip(
      message: value,
      child: SizedBox(
        width: width,
        child: Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style:
              TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
        ),
      ),
    );
  }

  Widget _miniBilgi(
    String baslik,
    String deger, {
    double width = 140,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Tooltip(
            message: deger,
            child: Text(
              deger,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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

  (String, Color) _stokDurumBilgisi(double miktar) {
    if (miktar <= 0) return ('Biten', _dangerColor);
    if (miktar < 10) return ('Kritik', _warningColor);
    return ('Yeterli', _successColor);
  }

  String _tedarikciAdi(Map<String, dynamic> stok,
      {Map<String, dynamic>? tedarikci}) {
    final resolvedRaw = tedarikci ?? stok['tedarikci'];
    final resolved =
        resolvedRaw is Map ? Map<String, dynamic>.from(resolvedRaw) : null;
    final sirket = resolved?['sirket']?.toString().trim();
    final ad = resolved?['ad']?.toString().trim();
    final kayitAdi = stok['tedarikci_adi']?.toString().trim();
    if (sirket != null && sirket.isNotEmpty) return sirket;
    if (ad != null && ad.isNotEmpty) return ad;
    if (kayitAdi != null && kayitAdi.isNotEmpty) return kayitAdi;
    return 'Tedarikçi yok';
  }

  String _formatFiyat(Map<String, dynamic> stok) {
    final fiyat = (stok['birim_fiyat'] as num?)?.toDouble();
    if (fiyat == null) return '-';
    return '${_getParaBirimiSembolu(stok['para_birimi'])}${fiyat.toStringAsFixed(2)}';
  }

  Widget _buildSiparisOlusturSayfasi() {
    final bekleyen = iplikSiparisleri
        .where((siparis) => _siparisDurumAnahtari(siparis) == 'beklemede')
        .length;
    final geciken = iplikSiparisleri
        .where((siparis) => _siparisDurumAnahtari(siparis) == 'gecikti')
        .length;
    final toplamKg = iplikSiparisleri.fold<double>(
      0,
      (sum, siparis) => sum + _siparisNum(siparis['miktar']),
    );
    final buAy = iplikSiparisleri.where(_siparisBuAyMi).length;
    final sonSiparisler = _sonSiparisleriAl();

    return Container(
      color: _surfaceColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSiparisUstPanel(),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final dar = constraints.maxWidth < 760;
                final kartlar = [
                  _buildOzetKutusu(
                    'Tedarikçi',
                    tedarikciler.length.toString(),
                    Icons.business,
                    _primaryColor,
                  ),
                  _buildOzetKutusu(
                    'Bekleyen',
                    bekleyen.toString(),
                    Icons.pending_actions,
                    _warningColor,
                  ),
                  _buildOzetKutusu(
                    'Geciken',
                    geciken.toString(),
                    Icons.event_busy,
                    _dangerColor,
                  ),
                  _buildOzetKutusu(
                    'Bu ay',
                    buAy.toString(),
                    Icons.calendar_month,
                    _successColor,
                  ),
                  _buildOzetKutusu(
                    'Toplam kg',
                    _formatKg(toplamKg),
                    Icons.scale,
                    const Color(0xFF7C3AED),
                  ),
                ];

                if (dar) {
                  return Column(
                    children: kartlar
                        .map(
                          (kart) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: kart,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  children: kartlar
                      .map(
                        (kart) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: kart,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final dar = constraints.maxWidth < 900;
                return dar
                    ? Column(
                        children: [
                          _buildSiparisAksiyonPaneli(),
                          const SizedBox(height: 12),
                          _buildSiparisAkisPaneli(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildSiparisAksiyonPaneli(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSiparisAkisPaneli()),
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            _buildSonSiparislerPaneli(sonSiparisler),
          ],
        ),
      ),
    );
  }

  Widget _buildSiparisUstPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 680;
          final baslik = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_shopping_cart,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İplik Siparişi Oluştur',
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
                      'Tekli sipariş, toplu Excel yükleme ve şablon akışı',
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
            ],
          );

          final aksiyonlar = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: dar ? WrapAlignment.start : WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _excelSablonIndir,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Şablon'),
              ),
              ElevatedButton.icon(
                onPressed: _yeniSiparisOlustur,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Sipariş'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );

          if (dar) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                baslik,
                const SizedBox(height: 14),
                aksiyonlar,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: baslik),
              const SizedBox(width: 16),
              aksiyonlar,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSiparisAksiyonPaneli() {
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
          const Text(
            'Sipariş işlemleri',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Siparişi tekli oluşturabilir veya Excel ile toplu aktarabilirsiniz.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final dar = constraints.maxWidth < 660;
              final tiles = [
                _buildSiparisAksiyonKutusu(
                  icon: Icons.playlist_add,
                  baslik: 'Tekli Sipariş',
                  aciklama: 'Tedarikçi, iplik, renk, miktar ve termin girin.',
                  renk: _primaryColor,
                  onTap: _yeniSiparisOlustur,
                ),
                _buildSiparisAksiyonKutusu(
                  icon: Icons.upload_file,
                  baslik: 'Toplu Excel',
                  aciklama: 'Birden fazla siparişi tek dosyayla içeri alın.',
                  renk: _successColor,
                  onTap: _topluSiparisOlustur,
                ),
                _buildSiparisAksiyonKutusu(
                  icon: Icons.file_download,
                  baslik: 'Excel Şablonu',
                  aciklama: 'Toplu yükleme formatını indirip doldurun.',
                  renk: const Color(0xFF7C3AED),
                  onTap: _excelSablonIndir,
                ),
              ];

              if (dar) {
                return Column(
                  children: tiles
                      .map(
                        (tile) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: tile,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: tiles
                    .map(
                      (tile) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: tile,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSiparisAksiyonKutusu({
    required IconData icon,
    required String baslik,
    required String aciklama,
    required Color renk,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: renk.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: renk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: renk, size: 21),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: renk, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              aciklama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiparisAkisPaneli() {
    final adimlar = [
      (
        Icons.business,
        'Tedarikçi seç',
        'Firma ve sipariş bilgilerini netleştir.',
        _primaryColor,
      ),
      (
        Icons.inventory_2,
        'Kalemleri gir',
        'İplik adı, renk, miktar ve fiyatı tamamla.',
        _warningColor,
      ),
      (
        Icons.local_shipping,
        'Takibe al',
        'Teslimatları sipariş takip ekranından işle.',
        _successColor,
      ),
    ];

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
          const Text(
            'Operasyon akışı',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...adimlar.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final adim = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: adim.$4.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(adim.$1, color: adim.$4, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$index. ${adim.$2}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adim.$3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSonSiparislerPaneli(List<Map<String, dynamic>> siparisler) {
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
              const Expanded(
                child: Text(
                  'Son siparişler',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => seciliMenu = 3),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Takibe git'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (siparisler.isEmpty)
            _buildBosDurum(
              'Henüz sipariş yok',
              'Yeni sipariş oluşturduğunuzda son kayıtlar burada görünür.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 820) {
                  return Column(
                    children: siparisler
                        .map(
                          (siparis) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildMobilSiparisSatiri(siparis),
                          ),
                        )
                        .toList(),
                  );
                }
                return _buildSiparisTablosu(siparisler);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSiparisTablosu(List<Map<String, dynamic>> siparisler) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabloGenisligi =
              constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tabloGenisligi,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columnSpacing: 20,
                horizontalMargin: 14,
                columns: const [
                  DataColumn(label: Text('Sipariş')),
                  DataColumn(label: Text('İplik / Renk')),
                  DataColumn(label: Text('Tedarikçi')),
                  DataColumn(label: Text('Miktar')),
                  DataColumn(label: Text('Termin')),
                  DataColumn(label: Text('Durum')),
                ],
                rows: siparisler.map((siparis) {
                  final durum = _siparisDurumBilgisi(siparis);
                  final birim =
                      siparis['birim']?.toString().trim().isNotEmpty == true
                          ? siparis['birim'].toString()
                          : 'kg';
                  return DataRow(
                    cells: [
                      DataCell(
                        _tableText(
                          siparis['siparis_no']?.toString() ?? '-',
                          width: 125,
                          bold: true,
                        ),
                      ),
                      DataCell(
                        _tableText(
                          '${siparis['iplik_adi'] ?? '-'} / ${_siparisRengi(siparis)}',
                          width: 210,
                        ),
                      ),
                      DataCell(
                        _tableText(_siparisTedarikciAdi(siparis), width: 170),
                      ),
                      DataCell(
                        Text(
                            '${_formatKg(_siparisNum(siparis['miktar']))} $birim'),
                      ),
                      DataCell(
                          Text(_formatSiparisTarih(siparis['termin_tarihi']))),
                      DataCell(_buildDurumEtiketi(durum.$1, durum.$2)),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobilSiparisSatiri(Map<String, dynamic> siparis) {
    final durum = _siparisDurumBilgisi(siparis);
    final birim = siparis['birim']?.toString().trim().isNotEmpty == true
        ? siparis['birim'].toString()
        : 'kg';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildDurumEtiketi(durum.$1, durum.$2),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniBilgi('Renk', _siparisRengi(siparis)),
              _miniBilgi('Tedarikçi', _siparisTedarikciAdi(siparis)),
              _miniBilgi(
                'Miktar',
                '${_formatKg(_siparisNum(siparis['miktar']))} $birim',
              ),
              _miniBilgi(
                'Termin',
                _formatSiparisTarih(siparis['termin_tarihi']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _sonSiparisleriAl() {
    final siraliSiparisler = List<Map<String, dynamic>>.from(iplikSiparisleri);
    siraliSiparisler.sort((a, b) {
      final aTarih = _parseSiparisTarih(a['created_at']) ??
          _parseSiparisTarih(a['siparis_tarihi']) ??
          DateTime(1900);
      final bTarih = _parseSiparisTarih(b['created_at']) ??
          _parseSiparisTarih(b['siparis_tarihi']) ??
          DateTime(1900);
      return bTarih.compareTo(aTarih);
    });
    return siraliSiparisler.take(8).toList();
  }

  String _siparisDurumAnahtari(Map<String, dynamic> siparis) {
    final miktar = _siparisNum(siparis['miktar']);
    final teslim = _siparisNum(siparis['teslim_miktari']);
    final durum = siparis['durum']?.toString();
    final termin = _parseSiparisTarih(siparis['termin_tarihi']);
    final bugun = DateTime.now();
    final bugunTarih = DateTime(bugun.year, bugun.month, bugun.day);

    if (durum == 'iptal') return 'iptal';
    if (durum == 'tamamlandi' || durum == 'teslim_edildi') return 'tamamlandi';
    if (miktar > 0 && teslim >= miktar) return 'tamamlandi';
    if (termin != null && termin.isBefore(bugunTarih)) return 'gecikti';
    if (teslim > 0) return 'kismi';
    return 'beklemede';
  }

  (String, Color) _siparisDurumBilgisi(Map<String, dynamic> siparis) {
    switch (_siparisDurumAnahtari(siparis)) {
      case 'tamamlandi':
        return ('Tamamlandı', _successColor);
      case 'gecikti':
        return ('Geciken', _dangerColor);
      case 'kismi':
        return ('Kısmi', _primaryColor);
      case 'iptal':
        return ('İptal', const Color(0xFF64748B));
      default:
        return ('Bekleyen', _warningColor);
    }
  }

  String _siparisTedarikciAdi(Map<String, dynamic> siparis) {
    final kayitAdi = siparis['tedarikci_adi']?.toString().trim();
    if (kayitAdi != null && kayitAdi.isNotEmpty) return kayitAdi;

    final tedarikciId = siparis['tedarikci_id']?.toString();
    final tedarikci = tedarikciler
        .where((item) => item['id']?.toString() == tedarikciId)
        .firstOrNull;
    final sirket = tedarikci?['sirket']?.toString().trim();
    final ad = tedarikci?['ad']?.toString().trim();
    if (sirket != null && sirket.isNotEmpty) return sirket;
    if (ad != null && ad.isNotEmpty) return ad;
    return 'Tedarikçi yok';
  }

  String _siparisRengi(Map<String, dynamic> siparis) {
    final renk = siparis['renk']?.toString().trim();
    return renk == null || renk.isEmpty ? 'Renk yok' : renk;
  }

  bool _siparisBuAyMi(Map<String, dynamic> siparis) {
    final tarih = _parseSiparisTarih(siparis['created_at']) ??
        _parseSiparisTarih(siparis['siparis_tarihi']);
    if (tarih == null) return false;
    final simdi = DateTime.now();
    return tarih.year == simdi.year && tarih.month == simdi.month;
  }

  DateTime? _parseSiparisTarih(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _formatSiparisTarih(dynamic value) {
    final tarih = _parseSiparisTarih(value);
    if (tarih == null) return '-';
    return DateFormat('dd.MM.yyyy').format(tarih);
  }

  String _formatKg(double value) {
    final formatter = NumberFormat.decimalPattern('tr_TR');
    return formatter.format(value);
  }

  double _siparisNum(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0;
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  // ignore: unused_element
  Widget _buildSiparisOlusturSayfasiLegacy() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık kartı
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      size: 32,
                      color: Color(0xFFD2B48C),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İplik Siparişi Oluştur',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD2B48C),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tedarikçilerinize hızlı ve düzenli sipariş verin',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ana sipariş formu
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sipariş Bilgileri',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD2B48C),
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Sipariş formu burada geliştirilecek
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _yeniSiparisOlustur,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Tekli Sipariş Oluştur'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD2B48C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _topluSiparisOlustur,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Toplu Sipariş (Excel)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Excel şablon indirme
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.download,
                                  color: Color(0xFFD2B48C),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Excel Şablon İndirme',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD2B48C),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toplu sipariş oluşturmak için Excel şablonunu indirin, doldurun ve yükleyin.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _excelSablonIndir,
                              icon: const Icon(Icons.file_download),
                              label: const Text('Excel Şablon İndir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
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
            const SizedBox(height: 16),

            // Özellikler kartı
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.featured_play_list,
                          color: Color(0xFFD2B48C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sipariş Sistemi Özellikleri',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD2B48C),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildOzellikSatiri(Icons.business, 'Tedarikçi Seçimi',
                        'İplik firmalarından tedarikçi seçin'),
                    _buildOzellikSatiri(Icons.category, 'İplik Detayları',
                        'İplik türü, renk, miktar ve özellikleri'),
                    _buildOzellikSatiri(Icons.schedule, 'Termin Takibi',
                        'Teslimat tarihi belirleme ve takip'),
                    _buildOzellikSatiri(Icons.attach_money, 'Fiyat Yönetimi',
                        'Birim fiyat ve toplam tutar hesaplama'),
                    _buildOzellikSatiri(Icons.track_changes, 'Sipariş Takibi',
                        'Sipariş durumu ve süreç takibi'),
                    _buildOzellikSatiri(Icons.email, 'Bildirimler',
                        'E-posta ve SMS ile otomatik bildirim'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOzellikSatiri(IconData icon, String baslik, String aciklama) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD2B48C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFD2B48C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  aciklama,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
