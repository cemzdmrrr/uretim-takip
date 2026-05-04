import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uretim_takip/pages/model/model_ekle.dart';
import 'package:uretim_takip/pages/model/toplu_model_ekle.dart';
import 'package:uretim_takip/pages/model/model_listele.dart';
import 'package:uretim_takip/pages/raporlar/gelismis_raporlar_page.dart';
import 'package:uretim_takip/pages/auth/login_page.dart';
import 'package:uretim_takip/pages/ayarlar/kullanici_listesi.dart';
import 'package:uretim_takip/pages/stok/stok_yonetimi.dart';
import 'package:uretim_takip/pages/sevkiyat/tamamlanan_siparisler_page.dart';
import 'package:uretim_takip/pages/personel/personel_anasayfa.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_hareket_listesi_page.dart';
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
import 'package:uretim_takip/widgets/bildirim_popup.dart';

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
import 'package:uretim_takip/services/user_role_service.dart';
import 'package:uretim_takip/utils/role_utils.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/pages/ayarlar/sayfa_yetki_yonetimi_page.dart';
import 'package:uretim_takip/config/asama_registry.dart';

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
          .select('id, tamamlandi, termin_tarihi')
          .eq('firma_id', _firmaId);

      final int toplam = modeller.length;
      int tamamlanan = 0;
      int geciken = 0;

      for (final m in modeller) {
        if (m['tamamlandi'] == true) {
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
            'devam_eden': toplam - tamamlanan,
            'tamamlanan': tamamlanan,
            'geciken': geciken,
          };
        });
      }
    } catch (e) {
      debugPrint('Dashboard veri hatası: $e');
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              const Spacer(),
              Icon(Icons.trending_flat,
                  color: color.withValues(alpha: 0.45), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: intValue),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) => Text(
              '$val',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
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
                        if (_modulAktif('uretim')) ...[
                          _buildStatsRow(),
                          const SizedBox(height: 14),
                          _buildFocusPanel(),
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
              const Text(
                'Operasyon Merkezi',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
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
                    '$modulSayisi sayfa',
                    const Color(0xFF5C6BC0),
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

  // --- Yardımcı build metotları ---

  Widget _buildStatsRow() {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            'Üretim Özeti',
            Icons.insert_chart,
            const Color(0xFF1565C0),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 920
                  ? 4
                  : constraints.maxWidth >= 520
                      ? 2
                      : 1;
              final stats = [
                _buildStatCard(
                    'Toplam Model',
                    '${_dashboardStats['toplam_model']}',
                    Icons.layers,
                    const Color(0xFF1565C0)),
                _buildStatCard('Devam Eden', '${_dashboardStats['devam_eden']}',
                    Icons.autorenew, const Color(0xFFF57C00)),
                _buildStatCard('Tamamlanan', '${_dashboardStats['tamamlanan']}',
                    Icons.check_circle, const Color(0xFF2E7D32)),
                _buildStatCard('Geciken', '${_dashboardStats['geciken']}',
                    Icons.warning_amber, const Color(0xFFD32F2F)),
              ];

              return GridView.builder(
                itemCount: stats.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 132,
                ),
                itemBuilder: (context, index) => stats[index],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusPanel() {
    final toplam = _dashboardStats['toplam_model'] ?? 0;
    final tamamlanan = _dashboardStats['tamamlanan'] ?? 0;
    final devamEden = _dashboardStats['devam_eden'] ?? 0;
    final geciken = _dashboardStats['geciken'] ?? 0;
    final oran = toplam == 0 ? 0 : ((tamamlanan / toplam) * 100).round();

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            'Bugün İzlenecekler',
            Icons.assignment_turned_in,
            const Color(0xFF0F766E),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final items = [
                _buildFocusItem(
                  Icons.priority_high,
                  'Geciken',
                  geciken == 0 ? 'Yok' : '$geciken model',
                  geciken == 0
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD32F2F),
                ),
                _buildFocusItem(
                  Icons.sync,
                  'Devam Eden',
                  '$devamEden model',
                  const Color(0xFFF57C00),
                ),
                _buildFocusItem(
                  Icons.pie_chart,
                  'Tamamlanma',
                  '%$oran',
                  const Color(0xFF1565C0),
                ),
              ];

              if (narrow) {
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      items[i],
                      if (i < items.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    Expanded(child: items[i]),
                    if (i < items.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusItem(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasQuickActions() {
    return _sayfaErisimVar('uretim_raporu') ||
        _sayfaErisimVar('yeni_model_ekle') ||
        _sayfaErisimVar('kayitli_modeller');
  }

  Widget _buildQuickActionsRow() {
    final actions = <Widget>[];
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
    if (uretimStok.isNotEmpty) kategoriler['Üretim & Stok'] = uretimStok;

    // 3. Raporlar & Analiz
    if (raporAktif) {
      const rc = Color(0xFF00695C);
      final raporlar = <Map<String, dynamic>>[];
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
      }
      if (_sayfaErisimVar('dosya_yonetimi')) {
        finansItems.add({
          'text': 'Dosya Yönetimi',
          'icon': Icons.folder,
          'color': fc,
          'onPressed': () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const DosyalarPage()))
        });
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
            await Navigator.push(context,
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
