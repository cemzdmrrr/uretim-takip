import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';

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
import 'package:uretim_takip/widgets/animated_counter.dart';
import 'package:uretim_takip/widgets/activity_timeline.dart';
import 'package:uretim_takip/widgets/sidebar_layout.dart';

import 'package:provider/provider.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:uretim_takip/providers/theme_provider.dart';
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
import 'package:uretim_takip/pages/ayarlar/firma_sayfa_yetki_yonetimi_page.dart';

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
  bool _yetkilerYuklendi = false;
  Set<String> _firmaSayfaYetkileri = {};
  bool _firmaYetkileriYuklendi = false;
  String _selectedSidebarKey = 'anasayfa';
  
  // Staggered animation controller
  late AnimationController _staggerController;
  
  // Canlı dashboard verileri
  Map<String, int> _dashboardStats = {
    'toplam_model': 0,
    'devam_eden': 0,
    'tamamlanan': 0,
    'geciken': 0,
  };
  
  // Son aktiviteler
  List<AktiviteItem> _sonAktiviteler = [];
  
  // Haftalık üretim verileri (son 7 gün)
  List<double> _haftalikUretim = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      
      // Firma sayfa yetkilerini yükle
      await _firmaSayfaYetkileriniYukle();
      
      // Dashboard verilerini yükle
      if (_isBackofficeUser) {
        await _dashboardVerileriniYukle();
        await _sonAktiviteleriYukle();
        await _haftalikUretimYukle();
        _startAutoRefresh();
      }
      
      setState(() => yukleniyor = false);
      _staggerController.forward();
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
    _staggerController.dispose();
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

  Future<void> _sonAktiviteleriYukle() async {
    try {
      final supabase = Supabase.instance.client;
      final modeller = await supabase
          .from(DbTables.trikoTakip)
          .select('model_kodu, durum, tamamlandi, created_at, updated_at')
          .eq('firma_id', _firmaId)
          .order('updated_at', ascending: false)
          .limit(8);

      final aktiviteler = <AktiviteItem>[];
      for (final m in modeller) {
        final durum = m['durum']?.toString() ?? 'Bilinmiyor';
        final tamamlandi = m['tamamlandi'] == true;
        final modelKodu = m['model_kodu']?.toString() ?? '-';
        final tarihStr = m['updated_at']?.toString() ?? m['created_at']?.toString();
        final tarih = tarihStr != null ? DateTime.tryParse(tarihStr) ?? DateTime.now() : DateTime.now();

        IconData icon;
        Color renk;
        String aciklama;

        if (tamamlandi) {
          icon = Icons.check_circle_rounded;
          renk = const Color(0xFF4CAF50);
          aciklama = 'Sipariş tamamlandı';
        } else if (durum == 'Üretim') {
          icon = Icons.precision_manufacturing_rounded;
          renk = const Color(0xFF9C27B0);
          aciklama = 'Üretimde';
        } else if (durum == 'Beklemede') {
          icon = Icons.hourglass_empty_rounded;
          renk = const Color(0xFFFF9800);
          aciklama = 'Beklemede';
        } else {
          icon = Icons.update_rounded;
          renk = const Color(0xFF2196F3);
          aciklama = durum;
        }

        aktiviteler.add(AktiviteItem(
          baslik: modelKodu,
          aciklama: aciklama,
          icon: icon,
          renk: renk,
          tarih: tarih,
        ));
      }

      if (mounted) {
        setState(() => _sonAktiviteler = aktiviteler);
      }
    } catch (e) {
      debugPrint('Aktivite yükleme hatası: $e');
    }
  }

  Future<void> _haftalikUretimYukle() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final yediGunOnce = now.subtract(const Duration(days: 7));
      
      final modeller = await supabase
          .from(DbTables.trikoTakip)
          .select('created_at')
          .eq('firma_id', _firmaId)
          .gte('created_at', yediGunOnce.toIso8601String());

      final List<double> gunlukSayilar = List.filled(7, 0);
      for (final m in modeller) {
        final tarih = DateTime.tryParse(m['created_at']?.toString() ?? '');
        if (tarih != null) {
          final gunFarki = now.difference(tarih).inDays;
          if (gunFarki >= 0 && gunFarki < 7) {
            gunlukSayilar[6 - gunFarki] += 1;
          }
        }
      }

      if (mounted) {
        setState(() => _haftalikUretim = gunlukSayilar);
      }
    } catch (e) {
      debugPrint('Haftalık üretim hatası: $e');
    }
  }

  String _selamlamaMetni() {
    final saat = DateTime.now().hour;
    if (saat < 6) return 'İyi Geceler';
    if (saat < 12) return 'Günaydın';
    if (saat < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  // --- UI Bileşenleri (Yeni Tasarım) ---

  Widget _buildStaggeredChild(int index, Widget child) {
    final begin = (index * 0.1).clamp(0.0, 0.6);
    final end = (begin + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildGlassStatCard(String title, int value, IconData icon, Color color, int animIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.06) : color.withValues(alpha: 0.06);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.10) : color.withValues(alpha: 0.12);

    return _buildStaggeredChild(
      animIndex,
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.06 : 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const Spacer(),
                    // Mini sparkline indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, color: color, size: 12),
                          const SizedBox(width: 2),
                          Text('Canlı', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedCounter(
                  value: value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String text, IconData icon, Color color, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [color.withValues(alpha: 0.25), color.withValues(alpha: 0.15)]
                  : [color, color.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.15 : 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${butonlar.length}',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
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
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2A2A3C) : Colors.white;
    final borderClr = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderClr),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- Mini Haftalık Grafik ---
  Widget _buildMiniChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2A2A3C) : Colors.white;
    final gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final now = DateTime.now();
    final baslangicGunu = now.weekday; // 1=Pzt
    // Reorder to show last 7 days ending today
    final labels = List.generate(7, (i) {
      final idx = (baslangicGunu - 7 + i) % 7;
      return gunler[idx.clamp(0, 6)];
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: const Color(0xFF1976D2), size: 18),
              const SizedBox(width: 8),
              Text(
                'Son 7 Gün Üretim',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_haftalikUretim.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            labels[idx],
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[500]),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _haftalikUretim[i],
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tamamlanma Oranı Pie Chart ---
  Widget _buildCompletionPie() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2A2A3C) : Colors.white;
    final toplam = _dashboardStats['toplam_model'] ?? 0;
    final tamamlanan = _dashboardStats['tamamlanan'] ?? 0;
    final devamEden = _dashboardStats['devam_eden'] ?? 0;
    final geciken = _dashboardStats['geciken'] ?? 0;
    final oran = toplam > 0 ? (tamamlanan / toplam * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: const Color(0xFF4CAF50), size: 18),
              const SizedBox(width: 8),
              Text(
                'Tamamlanma Oranı',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      sections: [
                        PieChartSectionData(
                          value: tamamlanan.toDouble(),
                          color: const Color(0xFF4CAF50),
                          title: '',
                          radius: 22,
                        ),
                        PieChartSectionData(
                          value: (devamEden - geciken).toDouble().clamp(0, double.infinity),
                          color: const Color(0xFF2196F3),
                          title: '',
                          radius: 22,
                        ),
                        PieChartSectionData(
                          value: geciken.toDouble(),
                          color: const Color(0xFFF44336),
                          title: '',
                          radius: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '%${oran.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPieLegend('Tamamlanan', const Color(0xFF4CAF50), isDark),
                    const SizedBox(height: 4),
                    _buildPieLegend('Devam Eden', const Color(0xFF2196F3), isDark),
                    const SizedBox(height: 4),
                    _buildPieLegend('Geciken', const Color(0xFFF44336), isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegend(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF1976D2)),
                const SizedBox(height: 16),
                Text('Yükleniyor...', style: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : const Color(0xFF546E7A))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 768;

    // Sidebar items
    final sidebarItems = <SidebarItem>[
      const SidebarItem(label: 'Ana Sayfa', icon: Icons.home_rounded, key: 'anasayfa', color: Color(0xFF1976D2)),
      if (_modulAktif('uretim'))
        const SidebarItem(label: 'Üretim', icon: Icons.precision_manufacturing_rounded, key: 'uretim', color: Color(0xFF2E7D32)),
      if (_modulAktif('rapor'))
        const SidebarItem(label: 'Raporlar', icon: Icons.analytics_rounded, key: 'raporlar', color: Color(0xFF00695C)),
      if (_modulAktif('finans') || _modulAktif('tedarik'))
        const SidebarItem(label: 'Finans', icon: Icons.account_balance_rounded, key: 'finans', color: Color(0xFF1565C0)),
      if (_modulAktif('ik'))
        const SidebarItem(label: 'İK', icon: Icons.people_rounded, key: 'ik', color: Color(0xFF7B1FA2)),
    ];

    Widget dashboardBody = _buildDashboardContent(
      kategoriler: kategoriler,
      email: email,
      firmaAdi: firmaAdi,
      isDark: isDark,
      tenant: tenant,
      isWideScreen: isWideScreen,
    );

    // Web/tablet: sidebar layout, Mobil: body only
    if (isWideScreen) {
      return SidebarLayout(
        body: dashboardBody,
        items: sidebarItems,
        selectedKey: _selectedSidebarKey,
        onItemTap: (key) {
          setState(() => _selectedSidebarKey = key);
          // Sidebar'dan sayfa scroll hedefleri buraya eklenebilir
        },
        title: 'TexPilot',
        subtitle: firmaAdi.isNotEmpty ? firmaAdi : null,
        header: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              if (tenant.cokluFirma)
                _buildSidebarActionButton(Icons.swap_horiz_rounded, 'Firma', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmaSecimPage()));
                }),
              const Spacer(),
              _buildSidebarActionButton(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                isDark ? 'Açık' : 'Koyu',
                () => context.read<ThemeProvider>().toggleTheme(),
              ),
            ],
          ),
        ),
      );
    }

    return dashboardBody;
  }

  Widget _buildSidebarActionButton(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isDark ? Colors.white60 : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildDashboardContent({
    required Map<String, List<Map<String, dynamic>>> kategoriler,
    required String email,
    required String firmaAdi,
    required bool isDark,
    required TenantProvider tenant,
    required bool isWideScreen,
  }) {
    final scaffoldBg = isDark ? const Color(0xFF16161E) : const Color(0xFFF0F2F5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          await _dashboardVerileriniYukle();
          await _sonAktiviteleriYukle();
          await _haftalikUretimYukle();
        },
        child: CustomScrollView(
          slivers: [
            // --- Yeni Modern AppBar ---
            SliverAppBar(
              expandedHeight: isWideScreen ? 90 : 100,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF1565C0),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                          )
                        : const LinearGradient(
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
                          // Logo
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.precision_manufacturing_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (!isWideScreen)
                                      const Text(
                                        'TexPilot',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    if (!isWideScreen && firmaAdi.isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          firmaAdi,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    if (isWideScreen)
                                      Text(
                                        '${_selamlamaMetni()}, ${email.split('@').first}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isWideScreen
                                      ? 'Üretim takip sisteminize hoş geldiniz'
                                      : (email.isNotEmpty ? email : 'Üretim Takip Sistemi'),
                                  style: TextStyle(
                                    fontSize: 12,
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
                // Mobilde tema toggle
                if (!isWideScreen)
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: isDark ? 'Açık Tema' : 'Koyu Tema',
                    onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                  ),
                if (!isWideScreen && tenant.cokluFirma)
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                    tooltip: 'Firma Değiştir',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmaSecimPage()));
                    },
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI İstatistik Kartları (Glassmorphism)
                    if (_modulAktif('uretim')) ...[
                      _buildGlassStatsRow(),
                      const SizedBox(height: 20),
                    ],

                    // Grafikler (yan yana: bar chart + pie chart)
                    if (_isBackofficeUser && _modulAktif('uretim')) ...[
                      _buildStaggeredChild(5, _buildChartsRow(isWideScreen)),
                      const SizedBox(height: 20),
                    ],

                    // Hızlı Erişim (Dinamik kısayollar)
                    if (_isBackofficeUser && _modulAktif('uretim')) ...[
                      _buildStaggeredChild(6, _buildQuickAccessSection(isDark)),
                      const SizedBox(height: 8),
                    ],

                    // Kategoriler
                    ...kategoriler.entries.map((entry) {
                      final meta = _categoryMeta(entry.key);
                      return _buildCategorySection(entry.key, meta['icon'] as IconData, meta['color'] as Color, entry.value);
                    }),

                    // Son Aktiviteler
                    if (_isBackofficeUser && _sonAktiviteler.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildStaggeredChild(8, _buildActivitiesSection(isDark)),
                    ],

                    const SizedBox(height: 24),
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

  Widget _buildGlassStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final stats = [
          _buildGlassStatCard('Toplam Model', _dashboardStats['toplam_model'] ?? 0, Icons.layers_rounded, const Color(0xFF1976D2), 0),
          _buildGlassStatCard('Devam Eden', _dashboardStats['devam_eden'] ?? 0, Icons.autorenew_rounded, const Color(0xFFF57C00), 1),
          _buildGlassStatCard('Tamamlanan', _dashboardStats['tamamlanan'] ?? 0, Icons.check_circle_rounded, const Color(0xFF2E7D32), 2),
          _buildGlassStatCard('Geciken', _dashboardStats['geciken'] ?? 0, Icons.warning_amber_rounded, const Color(0xFFD32F2F), 3),
        ];

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: stats,
          );
        }
        return Row(
          children: stats.map((s) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: s))).toList(),
        );
      },
    );
  }

  Widget _buildChartsRow(bool isWideScreen) {
    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildMiniChart()),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildCompletionPie()),
        ],
      );
    }
    return Column(
      children: [
        _buildMiniChart(),
        const SizedBox(height: 16),
        _buildCompletionPie(),
      ],
    );
  }

  Widget _buildQuickAccessSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, color: const Color(0xFFF57C00), size: 20),
            const SizedBox(width: 8),
            Text(
              'Hızlı Erişim',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickActionsRow(),
      ],
    );
  }

  Widget _buildActivitiesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline_rounded, color: const Color(0xFF7B1FA2), size: 20),
            const SizedBox(width: 8),
            Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ActivityTimeline(aktiviteler: _sonAktiviteler),
      ],
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

  Future<void> _firmaSayfaYetkileriniYukle() async {
    try {
      final yetkiler = await SayfaYetkiService.mevcutFirmaYetkileriniGetir();
      setState(() {
        _firmaSayfaYetkileri = yetkiler;
        _firmaYetkileriYuklendi = true;
      });
    } catch (e) {
      debugPrint('Firma sayfa yetkileri yüklenemedi: $e');
      setState(() => _firmaYetkileriYuklendi = true);
    }
  }

  /// Kullanıcının belirli sayfaya erişimi var mı?
  /// Önce firma seviyesi kontrol edilir, sonra kullanıcı seviyesi.
  /// Admin her zaman erişebilir. Yetki tanımlanmamışsa (boş set) tüm sayfaları göster (geriye uyumluluk).
  bool _sayfaErisimVar(String sayfaKodu) {
    // 1. Firma seviyesi kontrol
    if (_firmaYetkileriYuklendi && _firmaSayfaYetkileri.isNotEmpty) {
      if (!_firmaSayfaYetkileri.contains(sayfaKodu)) return false;
    }
    // 2. Platform admin her zaman erişebilir
    if (RoleUtils.isAdmin(kullaniciRolu)) return true;
    // 3. Kullanıcı seviyesi kontrol
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
        {'text': 'Firma Sayfa Yetkileri', 'icon': Icons.business_center_rounded, 'color': yc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmaSayfaYetkiYonetimiPage()))},
        {'text': 'Kullanıcı Sayfa Yetkileri', 'icon': Icons.lock_open_rounded, 'color': yc, 'onPressed': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SayfaYetkiYonetimiPage()))},
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
