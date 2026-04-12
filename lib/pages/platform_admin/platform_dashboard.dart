import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';
import 'package:uretim_takip/pages/platform_admin/firma_listesi_page.dart';
import 'package:uretim_takip/pages/platform_admin/abonelik_yonetimi_admin.dart';
import 'package:uretim_takip/pages/platform_admin/modul_yonetimi_page.dart';
import 'package:uretim_takip/pages/platform_admin/uretim_dali_yonetimi_page.dart';
import 'package:uretim_takip/pages/platform_admin/platform_raporlari.dart';
import 'package:uretim_takip/pages/platform_admin/destek_talepleri_page.dart';

/// Platform Yönetim Paneli Ana Dashboard.
///
/// Sadece platform_admin (super admin) rolündeki kullanıcılar erişebilir.
/// Genel istatistikleri gösterir ve alt yönetim sayfalarına yönlendirir.
class PlatformDashboard extends StatefulWidget {
  const PlatformDashboard({super.key});

  @override
  State<PlatformDashboard> createState() => _PlatformDashboardState();
}

class _PlatformDashboardState extends State<PlatformDashboard> {
  bool _yukleniyor = true;
  Map<String, dynamic> _istatistikler = {};
  List<Map<String, dynamic>> _populerModuller = [];
  List<Map<String, dynamic>> _populerDallar = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final sonuclar = await Future.wait([
        PlatformAdminService.platformIstatistikleri(),
        PlatformAdminService.populerModuller(),
        PlatformAdminService.populerUretimDallari(),
      ]);

      setState(() {
        _istatistikler = sonuclar[0] as Map<String, dynamic>;
        _populerModuller =
            sonuclar[1] as List<Map<String, dynamic>>;
        _populerDallar =
            sonuclar[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yükleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Yönetim Paneli'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _verileriYukle,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildIstatistikKartlari(),
                  const SizedBox(height: 24),
                  _buildYonetimMenusu(),
                  const SizedBox(height: 24),
                  _buildPopulerModuller(),
                  const SizedBox(height: 16),
                  _buildPopulerDallar(),
                ],
              ),
            ),
    );
  }

  Widget _buildIstatistikKartlari() {
    final kartlar = <_IstatistikVeri>[
      _IstatistikVeri(
        'Aktif Firma',
        _istatistikler['aktif_firma_sayisi']?.toString() ?? '0',
        Icons.business,
        const Color(0xFF2E7D32),
      ),
      _IstatistikVeri(
        'Toplam Kullanıcı',
        _istatistikler['toplam_kullanici_sayisi']?.toString() ?? '0',
        Icons.people,
        const Color(0xFF1565C0),
      ),
      _IstatistikVeri(
        'Aktif Abonelik',
        _istatistikler['aktif_abonelik_sayisi']?.toString() ?? '0',
        Icons.card_membership,
        const Color(0xFF00695C),
      ),
      _IstatistikVeri(
        'Deneme',
        _istatistikler['deneme_abonelik_sayisi']?.toString() ?? '0',
        Icons.hourglass_bottom,
        const Color(0xFFE65100),
      ),
      _IstatistikVeri(
        'Aylık Gelir (MRR)',
        '₺${_formatPara(_istatistikler['aylik_gelir'])}',
        Icons.trending_up,
        const Color(0xFF6A1B9A),
      ),
      _IstatistikVeri(
        'Açık Destek',
        _istatistikler['acik_destek_sayisi']?.toString() ?? '0',
        Icons.support_agent,
        const Color(0xFFC62828),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: kartlar.length,
      itemBuilder: (context, index) {
        final k = kartlar[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [k.renk.withAlpha(25), k.renk.withAlpha(8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(k.ikon, color: k.renk, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        k.baslik,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  k.deger,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: k.renk,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYonetimMenusu() {
    final menuler = <_MenuOgesi>[
      _MenuOgesi(
        'Firma Yönetimi',
        'Tüm firmaları listele ve yönet',
        Icons.business_center,
        const Color(0xFF1565C0),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FirmaListesiPage())),
      ),
      _MenuOgesi(
        'Abonelik Yönetimi',
        'Abonelikleri takip et ve müdahale et',
        Icons.card_membership,
        const Color(0xFF00695C),
        () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AbonelikYonetimiAdminPage())),
      ),
      _MenuOgesi(
        'Modül Yönetimi',
        'Modül tanımları ve fiyatlandırma',
        Icons.extension,
        const Color(0xFF6A1B9A),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ModulYonetimiPage())),
      ),
      _MenuOgesi(
        'Üretim Dalı Yönetimi',
        'Üretim dalı tanımlarını yönet',
        Icons.factory,
        const Color(0xFFE65100),
        () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const UretimDaliYonetimiPage())),
      ),
      _MenuOgesi(
        'Platform Raporları',
        'Gelir analizi ve istatistikler',
        Icons.analytics,
        const Color(0xFF2E7D32),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PlatformRaporlari())),
      ),
      _MenuOgesi(
        'Destek Talepleri',
        'Firma destek taleplerini yönet',
        Icons.support_agent,
        const Color(0xFFC62828),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DestekTalepleriPage())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yönetim',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: menuler.length,
          itemBuilder: (context, index) {
            final m = menuler[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: m.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: m.renk.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m.ikon, color: m.renk, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.baslik,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.aciklama,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPopulerModuller() {
    if (_populerModuller.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension, size: 20, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 8),
                Text(
                  'En Çok Kullanılan Modüller',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._populerModuller.take(5).map((m) {
              final toplam = _istatistikler['aktif_firma_sayisi'] as int? ?? 1;
              final sayi = m['firma_sayisi'] as int? ?? 0;
              final oran = toplam > 0 ? sayi / toplam : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        m['modul_kodu']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: oran,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sayi firma',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulerDallar() {
    if (_populerDallar.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.factory, size: 20, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Text(
                  'En Çok Seçilen Üretim Dalları',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._populerDallar.take(5).map((d) {
              final toplam = _istatistikler['aktif_firma_sayisi'] as int? ?? 1;
              final sayi = d['firma_sayisi'] as int? ?? 0;
              final oran = toplam > 0 ? sayi / toplam : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        d['tekstil_dali']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: oran,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sayi firma',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatPara(dynamic deger) {
    if (deger == null) return '0';
    final sayi = (deger as num).toDouble();
    if (sayi >= 1000000) {
      return '${(sayi / 1000000).toStringAsFixed(1)}M';
    } else if (sayi >= 1000) {
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
  const _MenuOgesi(this.baslik, this.aciklama, this.ikon, this.renk, this.onTap);
}
