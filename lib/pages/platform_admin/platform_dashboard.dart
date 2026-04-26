import 'package:flutter/material.dart';
import 'package:uretim_takip/pages/platform_admin/abonelik_yonetimi_admin.dart';
import 'package:uretim_takip/pages/platform_admin/destek_talepleri_page.dart';
import 'package:uretim_takip/pages/platform_admin/firma_listesi_page.dart';
import 'package:uretim_takip/pages/platform_admin/migrasyon_durumu_page.dart';
import 'package:uretim_takip/pages/platform_admin/modul_yonetimi_page.dart';
import 'package:uretim_takip/pages/platform_admin/platform_raporlari.dart';
import 'package:uretim_takip/pages/platform_admin/uretim_dali_yonetimi_page.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class PlatformDashboard extends StatefulWidget {
  const PlatformDashboard({super.key});

  @override
  State<PlatformDashboard> createState() => _PlatformDashboardState();
}

class _PlatformDashboardState extends State<PlatformDashboard> {
  bool _yukleniyor = true;
  bool _yetkiKontrolEdiliyor = true;
  bool _yetkiliMi = false;

  Map<String, dynamic> _istatistikler = {};
  List<Map<String, dynamic>> _populerModuller = [];
  List<Map<String, dynamic>> _populerDallar = [];

  @override
  void initState() {
    super.initState();
    _hazirlikYap();
  }

  Future<void> _hazirlikYap() async {
    try {
      _yetkiliMi = await PlatformAdminService.kullaniciPlatformAdminMi();
      if (_yetkiliMi) {
        await _verileriYukle();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yetki kontrolü yapılamadı: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _yetkiKontrolEdiliyor = false);
      }
    }
  }

  Future<void> _verileriYukle() async {
    if (mounted) {
      setState(() => _yukleniyor = true);
    }
    try {
      final sonuclar = await Future.wait([
        PlatformAdminService.platformIstatistikleri(),
        PlatformAdminService.populerModuller(),
        PlatformAdminService.populerUretimDallari(),
      ]);

      if (!mounted) return;
      setState(() {
        _istatistikler = sonuclar[0] as Map<String, dynamic>;
        _populerModuller = List<Map<String, dynamic>>.from(sonuclar[1] as List);
        _populerDallar = List<Map<String, dynamic>>.from(sonuclar[2] as List);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Platform Yönetim Paneli'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _hazirlikYap,
          ),
        ],
      ),
      body: _yetkiKontrolEdiliyor
          ? const Center(child: CircularProgressIndicator())
          : !_yetkiliMi
              ? _buildYetkisizDurum()
              : _yukleniyor
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _hazirlikYap,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          return ListView(
                            padding: EdgeInsets.fromLTRB(
                              width >= 1000 ? 24 : 16,
                              16,
                              width >= 1000 ? 24 : 16,
                              32,
                            ),
                            children: [
                              _buildHero(width),
                              const SizedBox(height: 20),
                              _buildIstatistikKartlari(width),
                              const SizedBox(height: 24),
                              _buildYonetimMenusu(width),
                              const SizedBox(height: 24),
                              _buildInsightGrid(width),
                            ],
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildYetkisizDurum() {
    return Center(
      child: Container(
        width: 520,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 42, color: Color(0xFFB91C1C)),
            SizedBox(height: 12),
            Text(
              'Bu alan yalnızca platform admin kullanıcılarına açıktır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Hesabınızda admin rolü yoksa platform paneli açılmaz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(double width) {
    final toplamFirma =
        _istatistikler['toplam_firma_sayisi']?.toString() ?? '0';
    final aktifAbonelik =
        _istatistikler['aktif_abonelik_sayisi']?.toString() ?? '0';

    return Container(
      padding: EdgeInsets.all(width >= 960 ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3FAE), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Merkezi Kontrol',
                  style: TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Firma, abonelik ve destek akışını tek ekranda yönetin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$toplamFirma firma ve $aktifAbonelik aktif abonelik için operasyon görünümü',
                  style: const TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroMetric(
                'Aylık Gelir',
                '₺${_formatPara(_istatistikler['aylik_gelir'])}',
                Icons.trending_up_outlined,
              ),
              _buildHeroMetric(
                'Açık Destek',
                _istatistikler['acik_destek_sayisi']?.toString() ?? '0',
                Icons.support_agent_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String title, String value, IconData icon) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIstatistikKartlari(double width) {
    final kartlar = <_IstatistikVeri>[
      _IstatistikVeri(
        'Aktif Firma',
        _istatistikler['aktif_firma_sayisi']?.toString() ?? '0',
        Icons.business_outlined,
        const Color(0xFF2E7D32),
      ),
      _IstatistikVeri(
        'Toplam Kullanıcı',
        _istatistikler['toplam_kullanici_sayisi']?.toString() ?? '0',
        Icons.people_outline,
        const Color(0xFF1565C0),
      ),
      _IstatistikVeri(
        'Aktif Abonelik',
        _istatistikler['aktif_abonelik_sayisi']?.toString() ?? '0',
        Icons.card_membership_outlined,
        const Color(0xFF00695C),
      ),
      _IstatistikVeri(
        'Deneme',
        _istatistikler['deneme_abonelik_sayisi']?.toString() ?? '0',
        Icons.hourglass_bottom_outlined,
        const Color(0xFFE65100),
      ),
      _IstatistikVeri(
        'Aylık Gelir',
        '₺${_formatPara(_istatistikler['aylik_gelir'])}',
        Icons.payments_outlined,
        const Color(0xFF6A1B9A),
      ),
      _IstatistikVeri(
        'Açık Destek',
        _istatistikler['acik_destek_sayisi']?.toString() ?? '0',
        Icons.support_agent_outlined,
        const Color(0xFFC62828),
      ),
    ];

    final itemWidth = width >= 1280
        ? (width - 48) / 3
        : width >= 760
            ? (width - 16) / 2
            : double.infinity;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: kartlar
          .map(
            (kart) => SizedBox(
              width: itemWidth,
              child: _buildStatCard(kart),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatCard(_IstatistikVeri data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.renk.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.ikon, color: data.renk),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.baslik,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.deger,
                  style: TextStyle(
                    color: data.renk,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYonetimMenusu(double width) {
    final menuler = <_MenuOgesi>[
      _MenuOgesi(
        'Firma Yönetimi',
        'Tüm firmaları listele ve yönet',
        Icons.business_center_outlined,
        const Color(0xFF1565C0),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FirmaListesiPage()),
        ),
      ),
      _MenuOgesi(
        'Abonelik Yönetimi',
        'Abonelik akışı ve müdahale adımları',
        Icons.card_membership_outlined,
        const Color(0xFF00695C),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AbonelikYonetimiAdminPage()),
        ),
      ),
      _MenuOgesi(
        'Modül Yönetimi',
        'Modül tanımları ve plan bağlantıları',
        Icons.extension_outlined,
        const Color(0xFF6A1B9A),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ModulYonetimiPage()),
        ),
      ),
      _MenuOgesi(
        'Üretim Dalı Yönetimi',
        'Üretim dalı tanımlarını yönet',
        Icons.precision_manufacturing_outlined,
        const Color(0xFFE65100),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UretimDaliYonetimiPage()),
        ),
      ),
      _MenuOgesi(
        'Platform Raporları',
        'Gelir analizi ve kayıt trendleri',
        Icons.analytics_outlined,
        const Color(0xFF2E7D32),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlatformRaporlari()),
        ),
      ),
      _MenuOgesi(
        'Destek Talepleri',
        'Firma destek taleplerini yönet',
        Icons.support_agent_outlined,
        const Color(0xFFC62828),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DestekTalepleriPage()),
        ),
      ),
      _MenuOgesi(
        'Migrasyon Durumu',
        'Tenant sağlığı, RLS ve veri bütünlüğü kontrolleri',
        Icons.rule_folder_outlined,
        const Color(0xFF0F766E),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MigrasyonDurumuPage()),
        ),
      ),
    ];

    final itemWidth = width >= 1280
        ? (width - 48) / 3
        : width >= 760
            ? (width - 16) / 2
            : double.infinity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yönetim Modülleri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: menuler
              .map(
                (menu) => SizedBox(
                  width: itemWidth,
                  child: _buildMenuCard(menu),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMenuCard(_MenuOgesi menu) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: menu.onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: menu.renk.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(menu.ikon, color: menu.renk),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.baslik,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.aciklama,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightGrid(double width) {
    final itemWidth = width >= 1180 ? (width - 16) / 2 : double.infinity;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(width: itemWidth, child: _buildPopulerModuller()),
        SizedBox(width: itemWidth, child: _buildPopulerDallar()),
      ],
    );
  }

  Widget _buildPopulerModuller() {
    return _buildInsightPanel(
      title: 'En Çok Kullanılan Modüller',
      icon: Icons.extension_outlined,
      color: const Color(0xFF6A1B9A),
      items: _populerModuller
          .take(5)
          .map(
            (modul) => _InsightItem(
              label: modul['modul_kodu']?.toString() ?? '-',
              count: modul['firma_sayisi'] as int? ?? 0,
            ),
          )
          .toList(),
    );
  }

  Widget _buildPopulerDallar() {
    return _buildInsightPanel(
      title: 'En Çok Seçilen Üretim Dalları',
      icon: Icons.precision_manufacturing_outlined,
      color: const Color(0xFFE65100),
      items: _populerDallar
          .take(5)
          .map(
            (dal) => _InsightItem(
              label: dal['tekstil_dali']?.toString() ?? '-',
              count: dal['firma_sayisi'] as int? ?? 0,
            ),
          )
          .toList(),
    );
  }

  Widget _buildInsightPanel({
    required String title,
    required IconData icon,
    required Color color,
    required List<_InsightItem> items,
  }) {
    final toplam = _istatistikler['aktif_firma_sayisi'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Veri bulunmuyor.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...items.map((item) {
              final oran = toplam > 0 ? item.count / toplam : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 132,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: oran,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.count} firma',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
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

  String _formatPara(dynamic deger) {
    if (deger == null) return '0';
    final sayi = (deger as num).toDouble();
    if (sayi >= 1000000) {
      return '${(sayi / 1000000).toStringAsFixed(1)}M';
    }
    if (sayi >= 1000) {
      return '${(sayi / 1000).toStringAsFixed(1)}K';
    }
    return sayi.toStringAsFixed(0);
  }
}

class _IstatistikVeri {
  final String baslik;
  final String deger;
  final IconData ikon;
  final Color renk;

  const _IstatistikVeri(this.baslik, this.deger, this.ikon, this.renk);
}

class _MenuOgesi {
  final String baslik;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  final VoidCallback onTap;

  const _MenuOgesi(
    this.baslik,
    this.aciklama,
    this.ikon,
    this.renk,
    this.onTap,
  );
}

class _InsightItem {
  final String label;
  final int count;

  const _InsightItem({
    required this.label,
    required this.count,
  });
}
