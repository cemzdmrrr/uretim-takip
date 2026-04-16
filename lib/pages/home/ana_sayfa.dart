import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:uretim_takip/pages/model/model_ekle.dart';
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
import 'package:uretim_takip/pages/muhasebe/fatura_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_listesi_page.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_hareket_listesi_page.dart';
import 'package:uretim_takip/pages/ayarlar/dosyalar_page.dart';
import 'package:uretim_takip/pages/uretim/dokuma_dashboard.dart';
import 'package:uretim_takip/pages/uretim/konfeksiyon_dashboard.dart';
import 'package:uretim_takip/pages/uretim/yikama_dashboard.dart';
import 'package:uretim_takip/pages/uretim/ilik_dugme_dashboard.dart';
import 'package:uretim_takip/pages/uretim/kalite_kontrol_dashboard.dart';
import 'package:uretim_takip/pages/uretim/utu_paket_dashboard.dart';
import 'package:uretim_takip/pages/sevkiyat/sevkiyat_panel.dart';
import 'package:uretim_takip/pages/uretim/uretim_raporu_page.dart';
import 'package:uretim_takip/widgets/bildirim_popup.dart';

import 'package:provider/provider.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:uretim_takip/pages/auth/firma_secim_page.dart';
import 'package:uretim_takip/pages/abonelik/abonelik_yonetimi_page.dart';
import 'package:uretim_takip/pages/abonelik/plan_secim_page.dart';
import 'package:uretim_takip/pages/ayarlar/firma_kullanici_yonetimi_page.dart';
import 'package:uretim_takip/pages/ayarlar/rol_yetki_yonetimi_page.dart';
import 'package:uretim_takip/pages/uretim/genel_uretim_dashboard.dart';
import 'package:uretim_takip/pages/platform_admin/platform_dashboard.dart';
import 'package:uretim_takip/pages/platform_admin/migrasyon_durumu_page.dart';
import 'package:uretim_takip/providers/auth_provider.dart';
import 'package:uretim_takip/utils/role_utils.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/pages/ayarlar/sayfa_yetki_yonetimi_page.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  String kullaniciRolu = RoleUtils.standardUserRole;
  bool yukleniyor = true;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  Timer? _refreshTimer;
  Set<String> _sayfaYetkileri = {};
  bool _yetkilerYuklendi = false;
  
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

      final response = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select('role, aktif')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        if (response != null && response['aktif'] == true) {
          kullaniciRolu =
              RoleUtils.normalizeDashboardRole(response['role']?.toString()) ??
                  RoleUtils.standardUserRole;
        } else {
          kullaniciRolu = RoleUtils.standardUserRole;
        }
      });
      
      debugPrint('✅ Kullanıcı rolü alındı: $kullaniciRolu (RLS kapalı)');
      
      // Sayfa yetkilerini yükle (admin değilse)
      if (!RoleUtils.isAdmin(kullaniciRolu)) {
        await _sayfaYetkileriniYukle(user.id);
      }
      
      // Dashboard verilerini yükle
      if (_isBackofficeUser) {
        await _dashboardVerileriniYukle();
        _startAutoRefresh();
      }
      
      setState(() => yukleniyor = false);
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _dashboardVerileriniYukle();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, IconData icon, Color color, List<Map<String, dynamic>> butonlar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            int cols;
            if (kIsWeb) {
              if (w > 1100) { cols = 4; }
              else if (w > 800) { cols = 3; }
              else if (w > 500) { cols = 2; }
              else { cols = 1; }
            } else {
              if (w > 700) { cols = 3; }
              else if (w > 450) { cols = 2; }
              else { cols = 1; }
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: cols == 1 ? 5.0 : 3.5,
              ),
              itemCount: butonlar.length,
              itemBuilder: (context, index) {
                final b = butonlar[index];
                return _buildModulCard(b['text'], b['icon'], b['onPressed'], color: b['color']);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildModulCard(String text, IconData icon, VoidCallback onPressed, {Color color = const Color(0xFF455A64)}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return Scaffold(
        body: Container(
          color: const Color(0xFFF8F9FA),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF1976D2)),
                SizedBox(height: 16),
                Text('Yükleniyor...', style: TextStyle(fontSize: 16, color: Color(0xFF546E7A))),
              ],
            ),
          ),
        ),
      );
    }

    // Rol bazlı yönlendirmeler
    if (_dashboardRoleIs(DbTables.personel)) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı.')));
      }
      return FutureBuilder<PersonelModel?>(
        future: PersonelService().getPersonelByUserId(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Scaffold(body: Center(child: Text('Personel kaydı bulunamadı.')));
          }
          return PersonelDetayPage(id: snapshot.data!.userId);
        },
      );
    }
    if (_dashboardRoleIs('dokuma')) return const DokumaDashboard();
    if (_dashboardRoleIs('konfeksiyon')) return const KonfeksiyonDashboard();
    if (_dashboardRoleIs('yikama')) return const YikamaDashboard();
    if (_dashboardRoleIs('utu_paket')) return const UtuPaketDashboard();
    if (_dashboardRoleIs('ilik_dugme')) return const IlikDugmeDashboard();
    if (_dashboardRoleIs('kalite_kontrol')) return const KaliteKontrolDashboard();
    if (_dashboardRoleIs('depo')) return const StokYonetimiPage();

    // Kategori butonları
    final kategoriler = _buildKategoriler();
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final tenant = context.watch<TenantProvider>();
    final firmaAdi = tenant.firmaAdi;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _dashboardVerileriniYukle,
        child: CustomScrollView(
          slivers: [
            // --- Modern AppBar ---
            SliverAppBar(
              expandedHeight: 80,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF1565C0),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          // Logo ve başlık
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.precision_manufacturing_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'TexPilot',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (firmaAdi.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          firmaAdi,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email.isNotEmpty ? email : 'Üretim Takip Sistemi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (tenant.cokluFirma)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                      tooltip: 'Firma Değiştir',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FirmaSecimPage()),
                        );
                      },
                    ),
                  ),
                const BildirimPopup(),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                    tooltip: 'Çıkış Yap',
                    onPressed: cikisYap,
                  ),
                ),
              ],
            ),

            // --- İçerik ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI İstatistik Kartları (üretim modülü aktifse)
                    if (_modulAktif('uretim')) ...[
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                    ],

                    // Hızlı Erişim (üretim modülü aktifse)
                    if (_isBackofficeUser && _modulAktif('uretim')) ...[
                      Text(
                        'Hızlı Erişim',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionsRow(),
                      const SizedBox(height: 8),
                    ],

                    // Kategoriler
                    ...kategoriler.entries.map((entry) {
                      final meta = _categoryMeta(entry.key);
                      return _buildCategorySection(entry.key, meta['icon'] as IconData, meta['color'] as Color, entry.value);
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Yardımcı build metotları ---

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final stats = [
          _buildStatCard('Toplam Model', '${_dashboardStats['toplam_model']}', Icons.layers_rounded, const Color(0xFF1976D2)),
          _buildStatCard('Devam Eden', '${_dashboardStats['devam_eden']}', Icons.autorenew_rounded, const Color(0xFFF57C00)),
          _buildStatCard('Tamamlanan', '${_dashboardStats['tamamlanan']}', Icons.check_circle_rounded, const Color(0xFF2E7D32)),
          _buildStatCard('Geciken', '${_dashboardStats['geciken']}', Icons.warning_amber_rounded, const Color(0xFFD32F2F)),
        ];

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: stats,
          );
        }
        return Row(
          children: stats.map((s) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: s))).toList(),
        );
      },
    );
  }

  Widget _buildQuickActionsRow() {
    final actions = <Widget>[];
    if (_sayfaErisimVar('uretim_raporu')) {
      actions.add(_buildQuickAction(
        'Üretim Raporu',
        Icons.assessment_rounded,
        const Color(0xFF00695C),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UretimRaporuPage())),
      ));
    }
    if (_sayfaErisimVar('yeni_model_ekle')) {
      actions.add(_buildQuickAction(
        'Yeni Model Ekle',
        Icons.add_box_rounded,
        const Color(0xFF2E7D32),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelEkle())),
      ));
    }
    if (_sayfaErisimVar('kayitli_modeller')) {
      actions.add(_buildQuickAction(
        'Kayıtlı Modeller',
        Icons.inventory_2_rounded,
        const Color(0xFF1565C0),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelListele())),
      ));
    }
    if (actions.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                SizedBox(width: double.infinity, child: actions[i]),
                if (i < actions.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(child: actions[i]),
              if (i < actions.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  bool get _isBackofficeUser =>
      RoleUtils.isAdmin(kullaniciRolu) ||
      RoleUtils.isStandardUser(kullaniciRolu);

  Future<void> _sayfaYetkileriniYukle(String userId) async {
    try {
      final yetkiler = await SayfaYetkiService.kullaniciYetkileriniGetir(userId);
      setState(() {
        _sayfaYetkileri = yetkiler;
        _yetkilerYuklendi = true;
      });
    } catch (e) {
      debugPrint('Sayfa yetkileri yüklenemedi: $e');
      setState(() => _yetkilerYuklendi = true);
    }
  }

  /// Kullanıcının belirli sayfaya erişimi var mı?
  /// Admin her zaman erişebilir. Yetki tanımlanmamışsa (boş set) tüm sayfaları göster (geriye uyumluluk).
  /// Yetki tablosu henüz yüklenmediyse veya hata varsa tüm sayfaları göster.
  bool _sayfaErisimVar(String sayfaKodu) {
    if (RoleUtils.isAdmin(kullaniciRolu)) return true;
    if (!_yetkilerYuklendi) return true; // Henüz yüklenmediyse göster
    if (_sayfaYetkileri.isEmpty) return true; // Hiç yetki tanımlanmamışsa tümünü göster
    return _sayfaYetkileri.contains(sayfaKodu);
  }

  bool _dashboardRoleIs(String role) =>
      RoleUtils.sameDashboardRole(kullaniciRolu, role);

  Map<String, dynamic> _categoryMeta(String key) {
    switch (key) {
      case 'Üretim Panelleri':
        return {'color': const Color(0xFF1976D2), 'icon': Icons.dashboard_rounded};
      case 'Üretim & Stok':
        return {'color': const Color(0xFF2E7D32), 'icon': Icons.precision_manufacturing_rounded};
      case 'Raporlar & Analiz':
        return {'color': const Color(0xFF00695C), 'icon': Icons.analytics_rounded};
      case 'Finansal Yönetim':
        return {'color': const Color(0xFF1565C0), 'icon': Icons.account_balance_rounded};
      case 'İnsan Kaynakları':
        return {'color': const Color(0xFF7B1FA2), 'icon': Icons.people_rounded};
      case 'Kullanıcı & Yetki':
        return {'color': const Color(0xFF5C6BC0), 'icon': Icons.security_rounded};
      case 'Abonelik & Plan':
        return {'color': const Color(0xFF00838F), 'icon': Icons.card_membership_rounded};
      case 'Platform Yönetimi':
        return {'color': const Color(0xFF1A237E), 'icon': Icons.admin_panel_settings_rounded};
      default:
        return {'color': const Color(0xFF455A64), 'icon': Icons.dashboard_rounded};
    }
  }

  /// Modül aktif mi kontrol et (tenant modül listesi)
  bool _modulAktif(String modulKodu) {
    final tenant = context.read<TenantProvider>();
    // Modül listesi boşsa tüm modülleri göster (geriye uyumluluk)
    if (tenant.aktifModuller.isEmpty) return true;
    return tenant.modulAktifMi(modulKodu);
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

    // 1. Üretim Panelleri (admin + üretim modülü aktifse)
    if (RoleUtils.isAdmin(kullaniciRolu) && uretimAktif) {
      const c = Color(0xFF1976D2);
      final paneller = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('genel_uretim')) paneller.add({'text': 'Genel Üretim', 'icon': Icons.dashboard_customize_rounded, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenelUretimDashboard()))});
      if (_sayfaErisimVar('dokuma')) paneller.add({'text': 'Dokuma', 'icon': Icons.design_services, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DokumaDashboard()))});
      if (_sayfaErisimVar('konfeksiyon')) paneller.add({'text': 'Konfeksiyon', 'icon': Icons.checkroom, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KonfeksiyonDashboard()))});
      if (_sayfaErisimVar('yikama')) paneller.add({'text': 'Yıkama', 'icon': Icons.local_laundry_service, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YikamaDashboard()))});
      if (_sayfaErisimVar('utu_paket')) paneller.add({'text': 'Ütü Paket', 'icon': Icons.inventory_2, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UtuPaketDashboard()))});
      if (_sayfaErisimVar('ilik_dugme')) paneller.add({'text': 'İlik Düğme', 'icon': Icons.radio_button_checked, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IlikDugmeDashboard()))});
      if (kaliteAktif && _sayfaErisimVar('kalite_kontrol')) {
        paneller.add({'text': 'Kalite Kontrol', 'icon': Icons.verified, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KaliteKontrolDashboard()))});
      }
      if (sevkiyatAktif && _sayfaErisimVar('sevkiyat')) {
        paneller.add({'text': 'Sevkiyat', 'icon': Icons.local_shipping, 'color': c, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SevkiyatPanel()))});
      }
      if (paneller.isNotEmpty) kategoriler['Üretim Panelleri'] = paneller;
    }

    // 2. Üretim & Stok
    final List<Map<String, dynamic>> uretimStok = [];
    const usc = Color(0xFF2E7D32);
    if (_isBackofficeUser && uretimAktif) {
      if (_sayfaErisimVar('yeni_model_ekle')) {
        uretimStok.add({'text': 'Yeni Model Ekle', 'icon': Icons.add_box_rounded, 'color': usc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelEkle()))});
      }
      if (_sayfaErisimVar('toplu_model_ekle')) {
        uretimStok.add({'text': 'Toplu Model Ekle', 'icon': Icons.upload_file_rounded, 'color': usc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopluModelEkle()))});
      }
    }
    if (uretimAktif &&
        (RoleUtils.isAdmin(kullaniciRolu) || !_dashboardRoleIs('depo'))) {
      if (_sayfaErisimVar('kayitli_modeller')) {
        uretimStok.add({'text': 'Kayıtlı Modeller', 'icon': Icons.inventory_2_rounded, 'color': usc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelListele()))});
      }
      if (_sayfaErisimVar('tamamlanan_siparisler')) {
        uretimStok.add({'text': 'Tamamlanan Siparişler', 'icon': Icons.check_circle_rounded, 'color': usc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TamamlananSiparislerPage()))});
      }
    }
    if (stokAktif &&
        (RoleUtils.isAdmin(kullaniciRolu) ||
            _dashboardRoleIs('depo') ||
            RoleUtils.isStandardUser(kullaniciRolu))) {
      if (_sayfaErisimVar('depo_yonetimi')) {
        uretimStok.add({'text': 'Depo Yönetimi', 'icon': Icons.warehouse_rounded, 'color': usc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StokYonetimiPage()))});
      }
    }
    if (uretimStok.isNotEmpty) kategoriler['Üretim & Stok'] = uretimStok;

    // 3. Raporlar & Analiz
    if (raporAktif && _isBackofficeUser) {
      const rc = Color(0xFF00695C);
      final raporlar = <Map<String, dynamic>>[];
      if (uretimAktif && _sayfaErisimVar('uretim_raporu')) {
        raporlar.add({'text': 'Üretim Raporu', 'icon': Icons.assessment_rounded, 'color': rc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UretimRaporuPage()))});
      }
      if (_sayfaErisimVar('gelismis_raporlar')) {
        raporlar.add({'text': 'Gelişmiş Raporlar', 'icon': Icons.analytics_rounded, 'color': rc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GelismisRaporlarPage()))});
      }
      if (raporlar.isNotEmpty) kategoriler['Raporlar & Analiz'] = raporlar;
    }

    // 4. Finansal Yönetim
    if ((finansAktif || tedarikAktif) && _isBackofficeUser) {
      const fc = Color(0xFF1565C0);
      final finansItems = <Map<String, dynamic>>[];
      if (tedarikAktif && _sayfaErisimVar('tedarikci_yonetimi')) {
        finansItems.add({'text': 'Tedarikçi Yönetimi', 'icon': Icons.business_rounded, 'color': fc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TedarikciListesiPage()))});
      }
      if (finansAktif) {
        if (_sayfaErisimVar('faturalar')) {
          finansItems.add({'text': 'Faturalar', 'icon': Icons.receipt_long_rounded, 'color': fc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaturaListesiPage()))});
        }
        if (_sayfaErisimVar('kasa_banka')) {
          finansItems.add({'text': 'Kasa & Banka', 'icon': Icons.account_balance_wallet_rounded, 'color': fc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KasaBankaListesiPage()))});
        }
        if (_sayfaErisimVar('kasa_banka_hareketleri')) {
          finansItems.add({'text': 'Kasa/Banka Hareketleri', 'icon': Icons.swap_horiz_rounded, 'color': fc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KasaBankaHareketListesiPage()))});
        }
      }
      if (_sayfaErisimVar('dosya_yonetimi')) {
        finansItems.add({'text': 'Dosya Yönetimi', 'icon': Icons.folder_rounded, 'color': fc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DosyalarPage()))});
      }
      if (finansItems.isNotEmpty) kategoriler['Finansal Yönetim'] = finansItems;
    }

    // 5. İnsan Kaynakları
    if (ikAktif && _isBackofficeUser) {
      const ic = Color(0xFF7B1FA2);
      final ikItems = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('personel_yonetimi')) {
        ikItems.add({'text': 'Personel Yönetimi', 'icon': Icons.badge_rounded, 'color': ic, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonelAnaSayfa(kullaniciRolu: kullaniciRolu)))});
      }
      if (_sayfaErisimVar('kullanici_listesi')) {
        ikItems.add({'text': 'Kullanıcı Listesi', 'icon': Icons.supervisor_account_rounded, 'color': ic, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KullaniciListesiPage()))});
      }
      if (ikItems.isNotEmpty) kategoriler['İnsan Kaynakları'] = ikItems;
    }

    // 7. Kullanıcı & Yetki Yönetimi (firma admin)
    if (RoleUtils.isAdmin(kullaniciRolu)) {
      const yc = Color(0xFF5C6BC0);
      kategoriler['Kullanıcı & Yetki'] = [
        {'text': 'Firma Kullanıcıları', 'icon': Icons.people_alt_rounded, 'color': yc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmaKullaniciYonetimiPage()))},
        {'text': 'Rol & Yetki Yönetimi', 'icon': Icons.security_rounded, 'color': yc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolYetkiYonetimiPage()))},
        {'text': 'Sayfa Yetki Yönetimi', 'icon': Icons.lock_open_rounded, 'color': yc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SayfaYetkiYonetimiPage()))},
      ];
    }

    // 7. Abonelik & Plan Yönetimi
    if (RoleUtils.isAdmin(kullaniciRolu)) {
      const ac = Color(0xFF00838F);
      final abonelikItems = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('abonelik_yonetimi')) {
        abonelikItems.add({'text': 'Abonelik Yönetimi', 'icon': Icons.card_membership_rounded, 'color': ac, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbonelikYonetimiPage()))});
      }
      if (_sayfaErisimVar('plan_degistir')) {
        abonelikItems.add({'text': 'Plan Değiştir', 'icon': Icons.swap_vert_circle_rounded, 'color': ac, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanSecimPage()))});
      }
      if (abonelikItems.isNotEmpty) kategoriler['Abonelik & Plan'] = abonelikItems;
    }

    // 8. Platform Yönetimi (Super Admin)
    if (RoleUtils.isAdmin(kullaniciRolu)) {
      const pc = Color(0xFF1A237E);
      final platformItems = <Map<String, dynamic>>[];
      if (_sayfaErisimVar('platform_paneli')) {
        platformItems.add({'text': 'Platform Paneli', 'icon': Icons.admin_panel_settings_rounded, 'color': pc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlatformDashboard()))});
      }
      if (_sayfaErisimVar('migrasyon_durumu')) {
        platformItems.add({'text': 'Migrasyon Durumu', 'icon': Icons.sync_alt_rounded, 'color': pc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MigrasyonDurumuPage()))});
      }
      if (platformItems.isNotEmpty) kategoriler['Platform Yönetimi'] = platformItems;
    }

    return kategoriler;
  }
}
