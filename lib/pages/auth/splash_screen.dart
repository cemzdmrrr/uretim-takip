import 'dart:async';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:uretim_takip/pages/auth/firma_secim_page.dart';
import 'package:uretim_takip/pages/onboarding/firma_kayit_page.dart';
import 'package:uretim_takip/pages/home/ana_sayfa.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_panel.dart';
import 'package:uretim_takip/pages/uretim/kalite_kontrol_panel.dart';
import 'package:uretim_takip/pages/sevkiyat/sofor_panel.dart';
import 'package:uretim_takip/pages/sevkiyat/sevkiyat_panel.dart';
import 'package:uretim_takip/pages/uretim/yikama_dashboard.dart';
import 'package:uretim_takip/pages/uretim/dokuma_dashboard.dart';
import 'package:uretim_takip/pages/uretim/konfeksiyon_dashboard.dart';
import 'package:uretim_takip/pages/uretim/utu_paket_dashboard.dart';
import 'package:uretim_takip/pages/uretim/ilik_dugme_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      try {
        if (widget.isLoggedIn) {
          // Tenant kontrolü
          final tenantProvider = context.read<TenantProvider>();
          if (!tenantProvider.firmaSecildi) {
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              await tenantProvider.kullaniciFirmalariniYukle(userId);
            }
          }
          // Çoklu firma varsa seçim ekranına yönlendir
          if (tenantProvider.kullaniciFirmalari.length > 1 && !tenantProvider.firmaSecildi) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const FirmaSecimPage()),
              );
            }
            return;
          }
          // Hiç firma yoksa onboarding'e yönlendir
          if (tenantProvider.kullaniciFirmalari.isEmpty) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const FirmaKayitPage()),
              );
            }
            return;
          }
          await _navigateToCorrectPanel();
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } catch (e) {
        debugPrint('❌ SplashScreen hata: $e');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  Future<void> _navigateToCorrectPanel() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.email == null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      debugPrint('🔍 Kullanıcı tipi belirleniyor: ${currentUser!.email}');

      // Önce admin kontrolü
      final adminCheck = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id)
          .eq('role', 'admin')
          .maybeSingle();

      if (adminCheck != null) {
        debugPrint('👤 Admin yönlendirme: ${currentUser.email}');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AnaSayfa()),
          );
        }
        return;
      }

      // Sonra tedarikci kontrolü
      final tedarikciCheck = await Supabase.instance.client
          .from(DbTables.tedarikciler)
          .select('id, sirket, faaliyet')
          .eq('email', currentUser.email!)
          .maybeSingle();

      if (tedarikciCheck != null) {
        final faaliyet = (tedarikciCheck['faaliyet'] ?? '').toString().toLowerCase();
        debugPrint('🏢 Tedarikci yönlendirme: ${tedarikciCheck['sirket']} - Faaliyet: $faaliyet');
        
        Widget targetWidget;
        if (faaliyet.contains('yıkama') || faaliyet.contains('yikama')) {
          targetWidget = const YikamaDashboard();
        } else if (faaliyet.contains('dokuma') || faaliyet.contains('örme') || faaliyet.contains('orgu')) {
          targetWidget = const DokumaDashboard();
        } else if (faaliyet.contains('konfeksiyon') || faaliyet.contains('dikim')) {
          targetWidget = const KonfeksiyonDashboard();
        } else if (faaliyet.contains('ütü') || faaliyet.contains('utu')) {
          targetWidget = const UtuPaketDashboard();
        } else if (faaliyet.contains('ilik') || faaliyet.contains('düğme') || faaliyet.contains('dugme')) {
          targetWidget = const IlikDugmeDashboard();
        } else {
          targetWidget = const TedarikciPanel();
        }
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => targetWidget),
          );
        }
        return;
      }

      // Kullanıcı rollerini kontrol et (birden fazla rol olabilir)
      final userRoles = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id);

      debugPrint('📋 Kullanıcı rolleri: $userRoles');

      if (userRoles.isNotEmpty) {
        // Rolleri listele
        final roles = (userRoles as List).map((r) => r['role'].toString().toLowerCase().trim()).toList();
        debugPrint('📋 Bulunan roller: $roles');
        
        // Sevkiyat kontrolü (öncelikli)
        if (roles.contains('sevkiyat')) {
          debugPrint('📦 Sevkiyat personeli yönlendirme: ${currentUser.email}');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SevkiyatPanel()),
            );
          }
          return;
        }
        
        // Kalite kontrol
        if (roles.contains('kalite_kontrol')) {
          debugPrint('🔍 Kalite personeli yönlendirme: ${currentUser.email}');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const KaliteKontrolPanel()),
            );
          }
          return;
        }
        
        // Şoför
        if (roles.contains('sofor')) {
          debugPrint('🚗 Şoför yönlendirme: ${currentUser.email}');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SoforPanel()),
            );
          }
          return;
        }
      }

      // Varsayılan admin/user paneli
      debugPrint('👤 Admin/User yönlendirme: ${currentUser.email}');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AnaSayfa()),
        );
      }

    } catch (e) {
      debugPrint('❌ Kullanıcı tipi kontrol hatası: $e');
      // Hata durumunda login'e yönlendir
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını al
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Logo boyutunu ekran boyutuna göre hesapla
    // Genişlik veya yüksekliğin küçük olanının %40'ı
    final logoSize = (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.5;
    
    // Minimum ve maksimum sınırlar
    final constrainedLogoSize = logoSize.clamp(120.0, 700.0);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: constrainedLogoSize * 0.4,
              height: constrainedLogoSize * 0.4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(constrainedLogoSize * 0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.precision_manufacturing_rounded,
                size: constrainedLogoSize * 0.22,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'TexPilot',
              style: TextStyle(
                fontSize: constrainedLogoSize * 0.12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a237e),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tekstil ERP',
              style: TextStyle(
                fontSize: constrainedLogoSize * 0.05,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
