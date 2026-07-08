import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uretim_takip/pages/model/model_ekle.dart';
import 'package:uretim_takip/pages/model/model_detay.dart';
import 'package:uretim_takip/pages/model/toplu_model_ekle.dart';
import 'package:uretim_takip/pages/model/model_listele.dart';
import 'package:uretim_takip/pages/raporlar/gelismis_raporlar_page.dart';
import 'package:uretim_takip/pages/auth/login_page.dart';
import 'package:uretim_takip/pages/ayarlar/kullanici_listesi.dart';
import 'package:uretim_takip/pages/stok/stok_yonetimi.dart';
import 'package:uretim_takip/pages/sevkiyat/tamamlanan_siparisler_page.dart';
import 'package:uretim_takip/pages/personel/personel_anasayfa.dart';
import 'package:uretim_takip/pages/personel/personel_detay_page.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_listesi_page.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_detay_page.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_hareket_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/sevk_irsaliye_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/yapilacak_odemeler_page.dart';
import 'package:uretim_takip/pages/ayarlar/dosyalar_page.dart';
import 'package:uretim_takip/pages/uretim/dokuma_dashboard.dart';
import 'package:uretim_takip/pages/uretim/konfeksiyon_dashboard.dart';
import 'package:uretim_takip/pages/uretim/nakis_dashboard.dart';
import 'package:uretim_takip/pages/uretim/yikama_dashboard.dart';
import 'package:uretim_takip/pages/uretim/ilik_dugme_dashboard.dart';
import 'package:uretim_takip/pages/uretim/kalite_kontrol_dashboard.dart';
import 'package:uretim_takip/pages/uretim/utu_paket_dashboard.dart';
import 'package:uretim_takip/pages/sevkiyat/sevkiyat_panel.dart';
import 'package:uretim_takip/pages/uretim/uretim_raporu_page.dart';
import 'package:uretim_takip/pages/raporlar/uretim_plani_page.dart';
import 'package:uretim_takip/widgets/bildirim_popup.dart';
import 'package:uretim_takip/widgets/yapilacaklar_popup.dart';

import 'package:provider/provider.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:uretim_takip/pages/auth/firma_secim_page.dart';
import 'package:uretim_takip/pages/abonelik/abonelik_yonetimi_page.dart';
import 'package:uretim_takip/pages/abonelik/plan_secim_page.dart';
import 'package:uretim_takip/pages/ayarlar/firma_kullanici_yonetimi_page.dart';
import 'package:uretim_takip/pages/uretim/genel_uretim_dashboard.dart';
import 'package:uretim_takip/pages/platform_admin/platform_dashboard.dart';
import 'package:uretim_takip/pages/platform_admin/migrasyon_durumu_page.dart';
import 'package:uretim_takip/providers/auth_provider.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/yapilacak_service.dart';
import 'package:uretim_takip/services/user_role_service.dart';
import 'package:uretim_takip/utils/role_utils.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/pages/ayarlar/sayfa_yetki_yonetimi_page.dart';
import 'package:uretim_takip/config/asama_registry.dart';

class _AktifUretimAsamaGrubu {
  const _AktifUretimAsamaGrubu({
    required this.ad,
    required this.tablolar,
    required this.durumlar,
  });

  final String ad;
  final List<String> tablolar;
  final List<String> durumlar;
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with TickerProviderStateMixin {
  String kullaniciRolu = RoleUtils.standardUserRole;
  bool yukleniyor = true;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  Timer? _refreshTimer;
  Set<String> _sayfaYetkileri = {};

  // Animasyon
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Canlı dashboard verileri
  Map<String, int> _dashboardStats = {
    'toplam_model': 0,
    'devam_eden': 0,
    'tamamlanan': 0,
    'geciken': 0,
    'toplam_adet': 0,
    'yuklenen_adet': 0,
    'kalan_adet': 0,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    kullaniciRolunuGetir();
  }

  Future<void> kullaniciRolunuGetir() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          kullaniciRolu = 'misafir';
          yukleniyor = false;
        });
        return;
      }

      final birincilRol = await UserRoleService.kullaniciBirincilRolunuGetir(
        userId: user.id,
        firmaId: _firmaId,
      );

      setState(() {
        kullaniciRolu = RoleUtils.normalizeDashboardRole(birincilRol) ??
            RoleUtils.standardUserRole;
      });

      debugPrint('✅ Kullanıcı rolü alındı: $kullaniciRolu (RLS kapalı)');

      // Sayfa yetkilerini her kullanıcı için yükle
      await _sayfaYetkileriniYukle(user.id);

      // Dashboard verilerini yükle
      await _dashboardVerileriniYukle();
      if (RoleUtils.isAdmin(kullaniciRolu)) {
        await BildirimService().terminKontrolEt();
      }
      _startAutoRefresh();

      setState(() => yukleniyor = false);
      _animController.forward();
    } catch (e) {
      debugPrint('❌ Rol alma hatası: $e');
      setState(() {
        kullaniciRolu = RoleUtils.standardUserRole;
        yukleniyor = false;
      });
    }
  }

  Future<void> _dashboardVerileriniYukle() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      final modeller = await supabase
          .from(DbTables.trikoTakip)
          .select(
              'id, tamamlandi, termin_tarihi, toplam_adet, adet, yuklenen_adet')
          .eq('firma_id', _firmaId);

      final int toplam = modeller.length;
      int tamamlanan = 0;
      int geciken = 0;
      int toplamAdet = 0;
      int toplamYuklenenAdet = 0;
      final modelIds = <String>[];
      final modelToplamAdetleri = <String, int>{};
      final modelFallbackYuklenenAdetleri = <String, int>{};
      final aktifUretim = await _aktifUretimModelSayisi(supabase);

      for (final m in List<Map<String, dynamic>>.from(modeller)) {
        final modelId = m['id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        final modelAdet = _intDeger(m['toplam_adet'] ?? m['adet']);
        modelIds.add(modelId);
        modelToplamAdetleri[modelId] = modelAdet;
        modelFallbackYuklenenAdetleri[modelId] = _intDeger(m['yuklenen_adet']);
        toplamAdet += modelAdet;
      }

      final yuklenenByModel = await _yuklenenAdetleriGetir(supabase, modelIds);

      for (final m in List<Map<String, dynamic>>.from(modeller)) {
        final modelId = m['id']?.toString();
        final modelYuklenenAdet = yuklenenByModel[modelId] ??
            modelFallbackYuklenenAdetleri[modelId] ??
            0;
        toplamYuklenenAdet += modelYuklenenAdet;

        if (modelYuklenenAdet > 0) {
          tamamlanan++;
        } else {
          final terminStr = m['termin_tarihi']?.toString();
          if (terminStr != null && terminStr.isNotEmpty) {
            final termin = DateTime.tryParse(terminStr);
            if (termin != null && termin.isBefore(now)) {
              geciken++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _dashboardStats = {
            'toplam_model': toplam,
            'devam_eden': aktifUretim,
            'tamamlanan': tamamlanan,
            'geciken': geciken,
            'toplam_adet': toplamAdet,
            'yuklenen_adet': toplamYuklenenAdet,
            'kalan_adet':
                (toplamAdet - toplamYuklenenAdet).clamp(0, toplamAdet).toInt(),
          };
        });
      }
      await YapilacakService().hatirlaticilariKontrolEt();
    } catch (e) {
      debugPrint('Dashboard veri hatası: $e');
    }
  }

  Future<Map<String, int>> _yuklenenAdetleriGetir(
    SupabaseClient supabase,
    List<String> modelIds,
  ) async {
    if (modelIds.isEmpty) return {};

    try {
      final yuklemeler = await supabase
          .from(DbTables.yuklemeKayitlari)
          .select('model_id, adet')
          .eq('firma_id', _firmaId)
          .inFilter('model_id', modelIds);
      final sonuc = <String, int>{};
      for (final yukleme in List<Map<String, dynamic>>.from(yuklemeler)) {
        final modelId = yukleme['model_id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        sonuc[modelId] = (sonuc[modelId] ?? 0) + _intDeger(yukleme['adet']);
      }
      return sonuc;
    } catch (e) {
      debugPrint('Ana sayfa yÃ¼kleme adetleri okunamadÄ±: $e');
      return {};
    }
  }

  int _intDeger(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _aramaDialoguGoster() async {
    final controller = TextEditingController();
    var loading = false;
    var arama = '';
    var sonuclar = <Map<String, dynamic>>[];

    Future<void> ara(StateSetter setDialogState) async {
      final q = controller.text.trim();
      setDialogState(() {
        arama = q;
        loading = true;
      });

      try {
        sonuclar = q.length < 2 ? [] : await _genelAramaSonuclari(q);
      } finally {
        if (mounted) setDialogState(() => loading = false);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF1565C0)),
                  SizedBox(width: 10),
                  Text('Genel Arama'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width < 720
                    ? MediaQuery.of(context).size.width * 0.92
                    : 680,
                height: MediaQuery.of(context).size.height * 0.64,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText:
                            'Model, personel, stok, fatura, tedarikçi ara',
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF1565C0)),
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  controller.clear();
                                  setDialogState(() {
                                    arama = '';
                                    sonuclar = [];
                                  });
                                },
                              ),
                      ),
                      onChanged: (_) => ara(setDialogState),
                      onSubmitted: (_) => ara(setDialogState),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : _aramaSonucListesi(
                              arama: arama,
                              sonuclar: sonuclar,
                              dialogContext: dialogContext,
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Kapat'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Widget _aramaSonucListesi({
    required String arama,
    required List<Map<String, dynamic>> sonuclar,
    required BuildContext dialogContext,
  }) {
    if (arama.trim().length < 2) {
      return const Center(
        child: Text('Arama yapmak için en az 2 karakter yazın.'),
      );
    }

    if (sonuclar.isEmpty) {
      return const Center(child: Text('Eşleşen kayıt bulunamadı.'));
    }

    return ListView.separated(
      itemCount: sonuclar.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final sonuc = sonuclar[index];
        final icon = sonuc['icon'] as IconData? ?? Icons.search;
        final color = sonuc['color'] as Color? ?? const Color(0xFF1565C0);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          title: Text(
            sonuc['baslik']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              sonuc['tip']?.toString() ?? '',
              sonuc['altBaslik']?.toString() ?? '',
            ].where((e) => e.trim().isNotEmpty).join(' / '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _aramaSonucunaGit(dialogContext, sonuc),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _genelAramaSonuclari(String q) async {
    final arama = q.toLowerCase();
    final sonucGruplari = await Future.wait([
      _modelAramaSonuclari(arama),
      _personelAramaSonuclari(arama),
      _tedarikciAramaSonuclari(arama),
      _faturaAramaSonuclari(arama),
      _sevkIrsaliyeAramaSonuclari(arama),
      _iplikStokAramaSonuclari(arama),
      _aksesuarAramaSonuclari(arama),
      _yapilacakOdemeAramaSonuclari(arama),
    ]);

    return sonucGruplari.expand((liste) => liste).take(80).toList();
  }

  Future<List<Map<String, dynamic>>> _tabloAra({
    required String tablo,
    required String arama,
    required String tip,
    required IconData icon,
    required Color color,
    required String route,
    required String Function(Map<String, dynamic>) baslik,
    required String Function(Map<String, dynamic>) altBaslik,
    String? idAlan,
    int limit = 300,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from(tablo)
          .select('*')
          .eq('firma_id', _firmaId)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response)
          .where((row) => _rowAramaMetni(row).contains(arama))
          .take(20)
          .map((row) {
        return {
          'tip': tip,
          'icon': icon,
          'color': color,
          'route': route,
          'id':
              idAlan == null ? row['id']?.toString() : row[idAlan]?.toString(),
          'baslik': baslik(row),
          'altBaslik': altBaslik(row),
          'data': row,
        };
      }).toList();
    } catch (e) {
      debugPrint('$tip arama atlandı: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _modelAramaSonuclari(String arama) {
    return _tabloAra(
      tablo: DbTables.trikoTakip,
      arama: arama,
      tip: 'Model',
      icon: Icons.inventory_2,
      color: const Color(0xFF1565C0),
      route: 'model',
      baslik: (row) => [
        row['marka']?.toString() ?? '',
        row['item_no']?.toString() ?? '',
      ].where((e) => e.trim().isNotEmpty).join(' - '),
      altBaslik: (row) => [
        row['model_adi']?.toString() ?? '',
        _modelRenkMetni(row),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  Future<List<Map<String, dynamic>>> _personelAramaSonuclari(String arama) {
    return _tabloAra(
      tablo: DbTables.personel,
      arama: arama,
      tip: 'Personel',
      icon: Icons.person,
      color: const Color(0xFF7C3AED),
      route: 'personel',
      baslik: (row) => _ilkDolu(row, ['tam_ad', 'ad_soyad', 'ad', 'isim']),
      altBaslik: (row) => [
        _ilkDolu(row, ['departman']),
        _ilkDolu(row, ['pozisyon', 'gorev']),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  Future<List<Map<String, dynamic>>> _tedarikciAramaSonuclari(String arama) {
    return _tabloAra(
      tablo: DbTables.tedarikciler,
      arama: arama,
      tip: 'Tedarikçi',
      icon: Icons.business,
      color: const Color(0xFF0F766E),
      route: 'tedarikci',
      baslik: (row) => _ilkDolu(row, ['ad', 'sirket', 'firma_adi']),
      altBaslik: (row) => [
        _ilkDolu(row, ['telefon']),
        _ilkDolu(row, ['email']),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  Future<List<Map<String, dynamic>>> _faturaAramaSonuclari(String arama) {
    return _tabloAra(
      tablo: DbTables.faturalar,
      arama: arama,
      tip: 'Fatura',
      icon: Icons.receipt_long,
      color: const Color(0xFF2563EB),
      route: 'faturalar',
      baslik: (row) => _ilkDolu(row, ['fatura_no', 'belge_no', 'id']),
      altBaslik: (row) => [
        _ilkDolu(row, ['cari_unvan', 'musteri_adi', 'tedarikci_adi']),
        _ilkDolu(row, ['toplam_tutar', 'genel_toplam']),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  Future<List<Map<String, dynamic>>> _sevkIrsaliyeAramaSonuclari(
    String arama,
  ) {
    return _tabloAra(
      tablo: DbTables.sevkIrsaliyeleri,
      arama: arama,
      tip: 'Sevk İrsaliyesi',
      icon: Icons.local_shipping,
      color: const Color(0xFFEA580C),
      route: 'sevk_irsaliyeleri',
      baslik: (row) => _ilkDolu(row, ['irsaliye_no', 'sevk_no', 'id']),
      altBaslik: (row) => [
        _ilkDolu(row, ['hedef_asama', 'durum']),
        _ilkDolu(row, ['toplam_adet', 'adet']),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  Future<List<Map<String, dynamic>>> _iplikStokAramaSonuclari(String arama) {
    return _tabloAra(
      tablo: DbTables.iplikStoklari,
      arama: arama,
      tip: 'İplik Stok',
      icon: Icons.layers,
      color: const Color(0xFF0891B2),
      route: 'stok',
      baslik: (row) => _ilkDolu(row, ['iplik_adi', 'iplik_cinsi', 'ad', 'kod']),
      altBaslik: (row) => [
        _ilkDolu(row, ['renk_kodu', 'renk']),
        _ilkDolu(row, ['lot_no', 'lot']),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  Future<List<Map<String, dynamic>>> _aksesuarAramaSonuclari(String arama) {
    return _tabloAra(
      tablo: DbTables.aksesuarlar,
      arama: arama,
      tip: 'Aksesuar',
      icon: Icons.category,
      color: const Color(0xFF9333EA),
      route: 'stok',
      baslik: (row) => _ilkDolu(row, ['ad', 'aksesuar_adi', 'sku', 'kod']),
      altBaslik: (row) => [
        _ilkDolu(row, ['kategori', 'tip']),
        _ilkDolu(row, ['renk']),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  Future<List<Map<String, dynamic>>> _yapilacakOdemeAramaSonuclari(
    String arama,
  ) {
    return _tabloAra(
      tablo: DbTables.yapilacakOdemeler,
      arama: arama,
      tip: 'Yapılacak Ödeme',
      icon: Icons.payments,
      color: const Color(0xFF16A34A),
      route: 'yapilacak_odemeler',
      baslik: (row) => _ilkDolu(row, ['baslik', 'odeme_adi', 'aciklama']),
      altBaslik: (row) => [
        _ilkDolu(row, ['tutar', 'odeme_tutari']),
        _ilkDolu(row, ['odeme_tarihi', 'vade_tarihi']),
      ].where((e) => e.trim().isNotEmpty).join(' / '),
    );
  }

  String _modelRenkMetni(Map<String, dynamic> model) {
    final renk = model['renk'];
    if (renk is List) return renk.join(', ');
    final renkText = renk?.toString() ?? '';
    if (renkText.trim().isNotEmpty) return renkText;
    final anaRenkler = model['ana_renkler'];
    if (anaRenkler is List) return anaRenkler.join(', ');
    return anaRenkler?.toString() ?? '';
  }

  String _rowAramaMetni(Map<String, dynamic> row) {
    return row.values
        .map((value) => value?.toString().toLowerCase() ?? '')
        .join(' ');
  }

  String _ilkDolu(Map<String, dynamic> row, List<String> alanlar) {
    for (final alan in alanlar) {
      final value = row[alan]?.toString() ?? '';
      if (value.trim().isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  void _aramaSonucunaGit(
    BuildContext dialogContext,
    Map<String, dynamic> sonuc,
  ) {
    Navigator.pop(dialogContext);

    final route = sonuc['route']?.toString();
    final id = sonuc['id']?.toString();
    final data = sonuc['data'];

    Widget? page;
    switch (route) {
      case 'model':
        if (id != null && id.isNotEmpty) page = ModelDetay(modelId: id);
        break;
      case 'personel':
        if (id != null && id.isNotEmpty) page = PersonelDetayPage(id: id);
        break;
      case 'tedarikci':
        final tedarikciId = int.tryParse(id ?? '');
        if (tedarikciId != null) {
          page = TedarikciDetayPage(tedarikciId: tedarikciId);
        }
        break;
      case 'faturalar':
        page = const FaturaListesiPage();
        break;
      case 'sevk_irsaliyeleri':
        page = const SevkIrsaliyeListesiPage();
        break;
      case 'stok':
        page = const StokYonetimiPage();
        break;
      case 'yapilacak_odemeler':
        page = const YapilacakOdemelerPage();
        break;
    }

    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          data is Map
              ? 'Bu sonuç için detay ekranı bulunamadı.'
              : 'Sonuç açılamadı.',
        ),
      ),
    );
  }

  Future<int> _aktifUretimModelSayisi(SupabaseClient supabase) async {
    const uretimIslemdeDurumlari = <String>[
      'devam_ediyor',
      'uretimde',
      'baslatildi',
      'baslandi',
      'kismi_tamamlandi',
    ];
    const sevkiyatIslemdeDurumlari = <String>[
      'kismen_sevk',
      'baslandi',
      'uretimde',
      'sevk_ediliyor',
    ];

    final asamaGruplari = <_AktifUretimAsamaGrubu>[
      const _AktifUretimAsamaGrubu(
        ad: 'dokuma',
        tablolar: [DbTables.dokumaAtamalari],
        durumlar: uretimIslemdeDurumlari,
      ),
      const _AktifUretimAsamaGrubu(
        ad: 'konfeksiyon',
        tablolar: [DbTables.konfeksiyonAtamalari],
        durumlar: uretimIslemdeDurumlari,
      ),
      const _AktifUretimAsamaGrubu(
        ad: 'kalite',
        tablolar: [DbTables.kaliteKontrolAtamalari],
        durumlar: uretimIslemdeDurumlari,
      ),
      const _AktifUretimAsamaGrubu(
        ad: 'sevkiyat',
        tablolar: [DbTables.sevkiyatKayitlari],
        durumlar: sevkiyatIslemdeDurumlari,
      ),
      const _AktifUretimAsamaGrubu(
        ad: 'nakış',
        tablolar: [DbTables.nakisAtamalari],
        durumlar: uretimIslemdeDurumlari,
      ),
      const _AktifUretimAsamaGrubu(
        ad: 'ilik düğme',
        tablolar: [DbTables.ilikDugmeAtamalari],
        durumlar: uretimIslemdeDurumlari,
      ),
      const _AktifUretimAsamaGrubu(
        ad: 'yıkama',
        tablolar: [DbTables.yikamaAtamalari],
        durumlar: uretimIslemdeDurumlari,
      ),
      const _AktifUretimAsamaGrubu(
        ad: 'ütü paket',
        tablolar: [DbTables.utuAtamalari, DbTables.paketlemeAtamalari],
        durumlar: uretimIslemdeDurumlari,
      ),
    ];

    var toplam = 0;
    for (final grup in asamaGruplari) {
      toplam += await _asamaIslemdeModelKoduSayisi(supabase, grup);
    }
    return toplam;
  }

  Future<int> _asamaIslemdeModelKoduSayisi(
    SupabaseClient supabase,
    _AktifUretimAsamaGrubu grup,
  ) async {
    final modelIds = <String>{};

    for (final tablo in grup.tablolar) {
      try {
        final rows = await supabase
            .from(tablo)
            .select('model_id,durum')
            .eq('firma_id', _firmaId)
            .inFilter('durum', grup.durumlar);
        for (final row in List<Map<String, dynamic>>.from(rows)) {
          final modelId = row['model_id']?.toString().trim();
          if (modelId != null && modelId.isNotEmpty) modelIds.add(modelId);
        }
      } catch (e) {
        debugPrint('Aktif üretim sayımı atlandı (${grup.ad}/$tablo): $e');
      }
    }

    return _modelKodlariniSay(supabase, modelIds);
  }

  Future<int> _modelKodlariniSay(
    SupabaseClient supabase,
    Set<String> modelIds,
  ) async {
    if (modelIds.isEmpty) return 0;

    try {
      final modeller = await supabase
          .from(DbTables.trikoTakip)
          .select('id,item_no')
          .inFilter('id', modelIds.toList());
      final modelKodlari = <String>{};

      for (final model in List<Map<String, dynamic>>.from(modeller)) {
        final modelKodu = (model['item_no'] ?? '').toString().trim();
        final fallbackId = (model['id'] ?? '').toString().trim();
        if (modelKodu.isNotEmpty) {
          modelKodlari.add(modelKodu);
        } else if (fallbackId.isNotEmpty) {
          modelKodlari.add(fallbackId);
        }
      }

      return modelKodlari.length;
    } catch (e) {
      debugPrint('Aktif üretim model kodu sayımı yapılamadı: $e');
      return modelIds.length;
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) await _sayfaYetkileriniYukle(user.id);
      if (mounted) _dashboardVerileriniYukle();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> cikisYap() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) context.read<TenantProvider>().temizle();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // --- UI Bileşenleri ---

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

  Widget _buildPanelHeader(String title, IconData icon, Color color,
      {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final intValue = int.tryParse(value) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: intValue),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) => Text(
                    '$val',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: color.withValues(alpha: 0.75), size: 18),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF243447),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: color.withValues(alpha: 0.75), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, IconData icon, Color color,
      List<Map<String, dynamic>> butonlar) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_fadeAnim),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPanelHeader(title, icon, color,
                    trailing: '${butonlar.length} sayfa'),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w >= 1120
                        ? 4
                        : w >= 820
                            ? 3
                            : w >= 540
                                ? 2
                                : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 66,
                      ),
                      itemCount: butonlar.length,
                      itemBuilder: (context, index) {
                        final b = butonlar[index];
                        return _buildModulCard(
                          b['text'],
                          b['icon'],
                          b['onPressed'],
                          color: b['color'],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModulCard(String text, IconData icon, VoidCallback onPressed,
      {Color color = const Color(0xFF455A64)}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5EAF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF243447),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right,
                  color: color.withValues(alpha: 0.65), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F8FB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1565C0)),
              SizedBox(height: 16),
              Text('Yükleniyor...',
                  style: TextStyle(fontSize: 16, color: Color(0xFF546E7A))),
            ],
          ),
        ),
      );
    }

    final kategoriler = _buildKategoriler();
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final tenant = context.watch<TenantProvider>();
    final firmaAdi = tenant.firmaAdi;
    final modulSayisi =
        kategoriler.values.fold<int>(0, (total, items) => total + items.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TexPilot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    firmaAdi.isNotEmpty ? firmaAdi : 'Üretim Takip Sistemi',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (tenant.cokluFirma)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 22),
              tooltip: 'Firma Değiştir',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FirmaSecimPage()),
                );
              },
            ),
          Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 24),
              tooltip: 'Ara',
              onPressed: _aramaDialoguGoster,
            ),
          ),
          const YapilacaklarPopup(),
          const BildirimPopup(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            tooltip: 'Çıkış Yap',
            onPressed: cikisYap,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _dashboardVerileriniYukle,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 900 ? 24.0 : 12.0;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWorkspaceHeader(
                          firmaAdi: firmaAdi,
                          email: email,
                          modulSayisi: modulSayisi,
                        ),
                        const SizedBox(height: 14),
                        if (_modulAktif('uretim') &&
                            RoleUtils.isAdmin(kullaniciRolu)) ...[
                          _buildStatsRow(),
                          const SizedBox(height: 14),
                        ],
                        _buildQuickActionsRow(),
                        if (_hasQuickActions()) const SizedBox(height: 14),
                        if (kategoriler.isEmpty)
                          _buildEmptyHomeState()
                        else
                          ...kategoriler.entries.map((entry) {
                            final meta = _categoryMeta(entry.key);
                            return _buildCategorySection(
                              entry.key,
                              meta['icon'] as IconData,
                              meta['color'] as Color,
                              entry.value,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkspaceHeader({
    required String firmaAdi,
    required String email,
    required int modulSayisi,
  }) {
    return _buildPanel(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: const Icon(Icons.business,
                        color: Color(0xFF0F766E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ERP Operasyon Paneli',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Üretim, sevkiyat ve finans modülleri için günlük takip',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.business,
                    firmaAdi.isNotEmpty ? firmaAdi : 'Firma seçili değil',
                    const Color(0xFF1565C0),
                  ),
                  _buildInfoChip(
                    Icons.verified_user,
                    kullaniciRolu,
                    const Color(0xFF2E7D32),
                  ),
                  _buildInfoChip(
                    Icons.apps,
                    '$modulSayisi yetkili modül',
                    const Color(0xFF5C6BC0),
                  ),
                  _buildInfoChip(
                    Icons.calendar_today,
                    _bugunMetni(),
                    const Color(0xFF455A64),
                  ),
                ],
              ),
            ],
          );

          final userBlock = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: narrow ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle,
                    color: Color(0xFF64748B), size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    email.isNotEmpty ? email : 'Kullanıcı',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                userBlock,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: userBlock,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _bugunMetni() {
    final now = DateTime.now();
    final gun = now.day.toString().padLeft(2, '0');
    final ay = now.month.toString().padLeft(2, '0');
    return '$gun.$ay.${now.year}';
  }

  // --- Yardımcı build metotları ---

  Widget _buildStatsRow() {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            'İş Emri Durum Özeti',
            Icons.dashboard,
            const Color(0xFF1565C0),
            trailing: 'Canlı veri',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1040
                  ? 4
                  : constraints.maxWidth >= 700
                      ? 3
                      : constraints.maxWidth >= 480
                          ? 2
                          : 1;
              final stats = [
                _buildStatCard(
                    'Açık Model Kartı',
                    '${_dashboardStats['toplam_model']}',
                    Icons.layers,
                    const Color(0xFF1565C0)),
                _buildStatCard(
                    'Üretime Başlayan',
                    '${_dashboardStats['devam_eden']}',
                    Icons.play_arrow,
                    const Color(0xFFF57C00)),
                _buildStatCard('Kapanan İş', '${_dashboardStats['tamamlanan']}',
                    Icons.fact_check, const Color(0xFF2E7D32)),
                _buildStatCard('Termin Riski', '${_dashboardStats['geciken']}',
                    Icons.warning, const Color(0xFFD32F2F)),
                _buildStatCard(
                    'Toplam Adet',
                    '${_dashboardStats['toplam_adet']}',
                    Icons.format_list_numbered,
                    const Color(0xFF5C6BC0)),
                _buildStatCard(
                    'YÃ¼klenen Adet',
                    '${_dashboardStats['yuklenen_adet']}',
                    Icons.local_shipping,
                    const Color(0xFF0F766E)),
                _buildStatCard('Kalan Adet', '${_dashboardStats['kalan_adet']}',
                    Icons.pending_actions, const Color(0xFF8E24AA)),
              ];

              return GridView.builder(
                itemCount: stats.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 70,
                ),
                itemBuilder: (context, index) => stats[index],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _hasQuickActions() {
    return _sayfaErisimVar('uretim_plani') ||
        _sayfaErisimVar('uretim_raporu') ||
        _sayfaErisimVar('yeni_model_ekle') ||
        _sayfaErisimVar('kayitli_modeller');
  }

  Widget _buildQuickActionsRow() {
    final actions = <Widget>[];
    if (_sayfaErisimVar('uretim_plani') || _sayfaErisimVar('uretim_raporu')) {
      actions.add(_buildQuickAction(
        'Üretim Planı',
        Icons.event_note,
        const Color(0xFF455A64),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UretimPlaniPage())),
      ));
    }
    if (_sayfaErisimVar('uretim_raporu')) {
      actions.add(_buildQuickAction(
        'Üretim Raporu',
        Icons.assessment,
        const Color(0xFF00695C),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UretimRaporuPage())),
      ));
    }
    if (_sayfaErisimVar('yeni_model_ekle')) {
      actions.add(_buildQuickAction(
        'Yeni Model Ekle',
        Icons.add_box,
        const Color(0xFF2E7D32),
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ModelEkle())),
      ));
    }
    if (_sayfaErisimVar('kayitli_modeller')) {
      actions.add(_buildQuickAction(
        'Kayıtlı Modeller',
        Icons.inventory,
        const Color(0xFF1565C0),
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ModelListele())),
      ));
    }
    if (actions.isEmpty) return const SizedBox.shrink();

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            'Hızlı İşlemler',
            Icons.flash_on,
            const Color(0xFF5C6BC0),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return Column(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      SizedBox(width: double.infinity, child: actions[i]),
                      if (i < actions.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    Expanded(child: actions[i]),
                    if (i < actions.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHomeState() {
    return _buildPanel(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 42),
            SizedBox(height: 10),
            Text(
              'Görüntülenebilir sayfa bulunamadı',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sayfaYetkileriniYukle(String userId) async {
    try {
      final yetkiler =
          await SayfaYetkiService.efektifSayfaYetkileriniGetir(userId);
      debugPrint('✅ Efektif sayfa yetkileri: $yetkiler');

      setState(() {
        _sayfaYetkileri = yetkiler;
      });
    } catch (e) {
      debugPrint('Sayfa yetkileri yüklenemedi: $e');
    }
  }

  /// Kullanıcının belirli sayfaya erişimi var mı?
  bool _sayfaErisimVar(String sayfaKodu) {
    // 2. Birleşik yetkileri kontrol et (kullanıcı + rol yetkileri)
    // Normalleştirilmiş sayfa kodu ile kontrol
    final normalized = SayfaYetkiService.normalizeSayfaKodu(sayfaKodu);
    return _sayfaYetkileri.contains(normalized);
  }

  Map<String, dynamic> _categoryMeta(String key) {
    switch (key) {
      case 'Üretim Panelleri':
        return {'color': const Color(0xFF1976D2), 'icon': Icons.dashboard};
      case 'Üretim & Stok':
        return {'color': const Color(0xFF2E7D32), 'icon': Icons.build};
      case 'Raporlar & Analiz':
        return {'color': const Color(0xFF00695C), 'icon': Icons.analytics};
      case 'Finansal Yönetim':
        return {
          'color': const Color(0xFF1565C0),
          'icon': Icons.account_balance
        };
      case 'İnsan Kaynakları':
        return {'color': const Color(0xFF7B1FA2), 'icon': Icons.people};
      case 'Kullanıcı & Yetki':
        return {'color': const Color(0xFF5C6BC0), 'icon': Icons.security};
      case 'Abonelik & Plan':
        return {
          'color': const Color(0xFF00838F),
          'icon': Icons.card_membership
        };
      case 'Platform Yönetimi':
        return {
          'color': const Color(0xFF1A237E),
          'icon': Icons.admin_panel_settings
        };
      default:
        return {'color': const Color(0xFF455A64), 'icon': Icons.dashboard};
    }
  }

  /// Modül aktif mi kontrol et (tenant modül listesi)
  bool _modulAktif(String modulKodu) {
    final tenant = context.read<TenantProvider>();
    // Modül listesi boşsa tüm modülleri göster (geriye uyumluluk)
    if (tenant.aktifModuller.isEmpty) return true;
    return tenant.modulAktifMi(modulKodu);
  }

  List<Map<String, dynamic>> _buildUretimPanelleri({
    required bool kaliteAktif,
    required bool sevkiyatAktif,
  }) {
    const panelRengi = Color(0xFF1976D2);
    final paneller = <Map<String, dynamic>>[];

    if (_sayfaErisimVar('genel_uretim')) {
      paneller.add({
        'text': 'Genel Üretim',
        'icon': Icons.dashboard,
        'color': panelRengi,
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GenelUretimDashboard()),
            ),
      });
    }

    final tenant = context.read<TenantProvider>();
    final aktifDallar = tenant.aktifUretimDallari.isEmpty
        ? TenantManager.instance.aktifUretimDallari
        : tenant.aktifUretimDallari;

    const panelSirasi = <String>[
      'dokuma',
      'konfeksiyon',
      'nakis',
      'yikama',
      'utu',
      'ilik_dugme',
      'kalite_kontrol',
    ];

    final bulunanAsamalar = <String, AsamaTanim>{};
    for (final dal in aktifDallar) {
      for (final asama in AsamaRegistry.dashboardAsamalari(dal)) {
        final kod = asama.asamaKodu;
        if (kod == 'paketleme' || kod == 'sevkiyat') {
          continue;
        }
        if (panelSirasi.contains(kod) && !bulunanAsamalar.containsKey(kod)) {
          bulunanAsamalar[kod] = asama;
        }
      }
    }

    for (final kod in panelSirasi) {
      final asama = bulunanAsamalar[kod];
      if (asama == null) continue;

      final sayfaKodu = kod == 'utu' ? 'utu_paket' : kod;
      if (!_sayfaErisimVar(sayfaKodu)) continue;
      if (kod == 'kalite_kontrol' && !kaliteAktif) continue;

      final panel = _buildUretimPanelTanimi(asama, panelRengi);
      if (panel != null) {
        paneller.add(panel);
      }
    }

    if (sevkiyatAktif && _sayfaErisimVar('sevkiyat')) {
      paneller.add({
        'text': 'Sevkiyat',
        'icon': Icons.local_shipping,
        'color': panelRengi,
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SevkiyatPanel()),
            ),
      });
    }

    return paneller;
  }

  Map<String, dynamic>? _buildUretimPanelTanimi(
    AsamaTanim asama,
    Color panelRengi,
  ) {
    switch (asama.asamaKodu) {
      case 'dokuma':
        return {
          'text': 'Dokuma',
          'icon': Icons.build,
          'color': panelRengi,
          'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DokumaDashboard()),
              ),
        };
      case 'konfeksiyon':
        return {
          'text': 'Konfeksiyon',
          'icon': Icons.style,
          'color': panelRengi,
          'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KonfeksiyonDashboard()),
              ),
        };
      case 'nakis':
        return {
          'text': 'Nakış',
          'icon': Icons.brush,
          'color': panelRengi,
          'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NakisDashboard()),
              ),
        };
      case 'yikama':
        return {
          'text': 'Yıkama',
          'icon': Icons.local_laundry_service,
          'color': panelRengi,
          'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const YikamaDashboard()),
              ),
        };
      case 'utu':
        return {
          'text': 'Ütü Paket',
          'icon': Icons.inventory,
          'color': panelRengi,
          'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UtuPaketDashboard()),
              ),
        };
      case 'ilik_dugme':
        return {
          'text': 'İlik Düğme',
          'icon': Icons.radio_button_checked,
          'color': panelRengi,
          'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IlikDugmeDashboard()),
              ),
        };
      case 'kalite_kontrol':
        return {
          'text': 'Kalite Kontrol',
          'icon': Icons.verified,
          'color': panelRengi,
          'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KaliteKontrolDashboard(),
                ),
              ),
        };
      default:
        return null;
    }
  }

  Map<String, List<Map<String, dynamic>>> _buildKategoriler() {
    final Map<String, List<Map<String, dynamic>>> kategoriler = {};

    final bool uretimAktif = _modulAktif('uretim');
    final bool stokAktif = _modulAktif('stok');
    final bool finansAktif = _modulAktif('finans');
    final bool tedarikAktif = _modulAktif('tedarik');
    final bool raporAktif = _modulAktif('rapor');
    final bool ikAktif = _modulAktif('ik');
    final bool kaliteAktif = _modulAktif('kalite');
    final bool sevkiyatAktif = _modulAktif('sevkiyat');

    final uretimPanelleri = _buildUretimPanelleri(
      kaliteAktif: kaliteAktif,
      sevkiyatAktif: sevkiyatAktif,
    );
    if (uretimPanelleri.isNotEmpty) {
      kategoriler['Üretim Panelleri'] = uretimPanelleri;
    }

    // 2. Üretim & Stok
    final List<Map<String, dynamic>> uretimStok = [];
    const usc = Color(0xFF2E7D32);
    if (uretimAktif) {
      if (_sayfaErisimVar('yeni_model_ekle')) {
        uretimStok.add({
          'text': 'Yeni Model Ekle',
          'icon': Icons.add_box,
          'color': usc,
          'onPressed': () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ModelEkle()))
        });
      }
      if (_sayfaErisimVar('toplu_model_ekle')) {
        uretimStok.add({
          'text': 'Toplu Model Ekle',
          'icon': Icons.file_upload,
          'color': usc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TopluModelEkle()))
        });
      }
    }
    if (uretimAktif) {
      if (_sayfaErisimVar('kayitli_modeller')) {
        uretimStok.add({
          'text': 'Kayıtlı Modeller',
          'icon': Icons.inventory,
          'color': usc,
          'onPressed': () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ModelListele()))
        });
      }
      if (_sayfaErisimVar('tamamlanan_siparisler')) {
        uretimStok.add({
          'text': 'Tamamlanan Siparişler',
          'icon': Icons.check_circle,
          'color': usc,
          'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TamamlananSiparislerPage()))
        });
      }
    }
    if (stokAktif) {
      if (_sayfaErisimVar('depo_yonetimi')) {
        uretimStok.add({
          'text': 'Depo Yönetimi',
          'icon': Icons.store,
          'color': usc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StokYonetimiPage()))
        });
      }
    }
    if ((uretimAktif || stokAktif) && _sayfaErisimVar('dosya_yonetimi')) {
      uretimStok.add({
        'text': 'Dosya Yönetimi',
        'icon': Icons.folder,
        'color': usc,
        'onPressed': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DosyalarPage()))
      });
    }
    if (uretimStok.isNotEmpty) kategoriler['Üretim & Stok'] = uretimStok;

    // 3. Raporlar & Analiz
    if (raporAktif) {
      const rc = Color(0xFF00695C);
      final raporlar = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('uretim_plani') || _sayfaErisimVar('uretim_raporu')) {
        raporlar.add({
          'text': 'Üretim Planı',
          'icon': Icons.event_note,
          'color': rc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UretimPlaniPage()))
        });
      }
      if (uretimAktif && _sayfaErisimVar('uretim_raporu')) {
        raporlar.add({
          'text': 'Üretim Raporu',
          'icon': Icons.assessment,
          'color': rc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UretimRaporuPage()))
        });
      }
      if (_sayfaErisimVar('gelismis_raporlar')) {
        raporlar.add({
          'text': 'Gelişmiş Raporlar',
          'icon': Icons.analytics,
          'color': rc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GelismisRaporlarPage()))
        });
      }
      if (raporlar.isNotEmpty) kategoriler['Raporlar & Analiz'] = raporlar;
    }

    // 4. Finansal Yönetim
    if (finansAktif || tedarikAktif) {
      const fc = Color(0xFF1565C0);
      final finansItems = <Map<String, dynamic>>[];
      if (tedarikAktif && _sayfaErisimVar('tedarikci_yonetimi')) {
        finansItems.add({
          'text': 'Tedarikçi Yönetimi',
          'icon': Icons.business,
          'color': fc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TedarikciListesiPage()))
        });
      }
      if (finansAktif) {
        if (_sayfaErisimVar('faturalar')) {
          finansItems.add({
            'text': 'Faturalar',
            'icon': Icons.receipt_long,
            'color': fc,
            'onPressed': () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FaturaListesiPage()))
          });
        }
        if (_sayfaErisimVar('kasa_banka')) {
          finansItems.add({
            'text': 'Kasa & Banka',
            'icon': Icons.account_balance_wallet,
            'color': fc,
            'onPressed': () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KasaBankaListesiPage()))
          });
        }
        if (_sayfaErisimVar('kasa_banka_hareketleri')) {
          finansItems.add({
            'text': 'Kasa/Banka Hareketleri',
            'icon': Icons.swap_horiz,
            'color': fc,
            'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const KasaBankaHareketListesiPage()))
          });
        }
        if (_sayfaErisimVar('yapilacak_odemeler')) {
          finansItems.add({
            'text': 'Yapılacak Ödemeler',
            'icon': Icons.event_available,
            'color': fc,
            'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const YapilacakOdemelerPage()))
          });
        }
        if (_sayfaErisimVar('sevk_irsaliyeleri') ||
            _sayfaErisimVar('faturalar') ||
            _sayfaErisimVar('sevkiyat')) {
          finansItems.add({
            'text': 'Sevk İrsaliyeleri',
            'icon': Icons.receipt_long,
            'color': fc,
            'onPressed': () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SevkIrsaliyeListesiPage()))
          });
        }
      }
      if (finansItems.isNotEmpty) kategoriler['Finansal Yönetim'] = finansItems;
    }

    // 5. İnsan Kaynakları
    if (ikAktif) {
      const ic = Color(0xFF7B1FA2);
      final ikItems = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('personel_yonetimi')) {
        ikItems.add({
          'text': 'Personel Yönetimi',
          'icon': Icons.perm_identity,
          'color': ic,
          'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      PersonelAnaSayfa(kullaniciRolu: kullaniciRolu)))
        });
      }
      if (_sayfaErisimVar('kullanici_listesi')) {
        ikItems.add({
          'text': 'Kullanıcı Listesi',
          'icon': Icons.supervisor_account,
          'color': ic,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const KullaniciListesiPage()))
        });
      }
      if (ikItems.isNotEmpty) kategoriler['İnsan Kaynakları'] = ikItems;
    }

    // 7. Kullanıcı & Yetki Yönetimi
    {
      const yc = Color(0xFF5C6BC0);
      final yetkiItems = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('firma_kullanicilari')) {
        yetkiItems.add({
          'text': 'Firma Kullanıcıları',
          'icon': Icons.people_alt,
          'color': yc,
          'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const FirmaKullaniciYonetimiPage()))
        });
      }
      if (_sayfaErisimVar('sayfa_yetki_yonetimi') ||
          _sayfaErisimVar('rol_sayfa_yetkileri')) {
        yetkiItems.add({
          'text': 'Kullanıcı Yetkileri',
          'icon': Icons.lock_open,
          'color': yc,
          'onPressed': () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SayfaYetkiYonetimiPage()));
            if (!mounted) return;
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) await _sayfaYetkileriniYukle(user.id);
          }
        });
      }
      if (yetkiItems.isNotEmpty) kategoriler['Kullanıcı & Yetki'] = yetkiItems;
    }

    // 7. Abonelik & Plan Yönetimi
    {
      const ac = Color(0xFF00838F);
      final abonelikItems = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('abonelik_yonetimi')) {
        abonelikItems.add({
          'text': 'Abonelik Yönetimi',
          'icon': Icons.card_membership,
          'color': ac,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AbonelikYonetimiPage()))
        });
      }
      if (_sayfaErisimVar('plan_degistir')) {
        abonelikItems.add({
          'text': 'Plan Değiştir',
          'icon': Icons.swap_vert,
          'color': ac,
          'onPressed': () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PlanSecimPage()))
        });
      }
      if (abonelikItems.isNotEmpty) {
        kategoriler['Abonelik & Plan'] = abonelikItems;
      }
    }

    // 8. Platform Yönetimi
    {
      const pc = Color(0xFF1A237E);
      final platformItems = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('platform_paneli')) {
        platformItems.add({
          'text': 'Platform Paneli',
          'icon': Icons.admin_panel_settings,
          'color': pc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PlatformDashboard()))
        });
      }
      if (_sayfaErisimVar('migrasyon_durumu')) {
        platformItems.add({
          'text': 'Migrasyon Durumu',
          'icon': Icons.sync,
          'color': pc,
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MigrasyonDurumuPage()))
        });
      }
      if (platformItems.isNotEmpty) {
        kategoriler['Platform Yönetimi'] = platformItems;
      }
    }

    return kategoriler;
  }
}
