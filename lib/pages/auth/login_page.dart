import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/config/secure_storage.dart';
import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:uretim_takip/pages/auth/firma_secim_page.dart';
import 'package:uretim_takip/pages/onboarding/firma_kayit_page.dart';
import 'package:uretim_takip/pages/home/ana_sayfa.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_panel.dart';
import 'package:uretim_takip/pages/uretim/kalite_kontrol_panel.dart';
import 'package:uretim_takip/pages/sevkiyat/sofor_panel.dart';
import 'package:uretim_takip/pages/sevkiyat/sevkiyat_panel.dart';
import 'package:uretim_takip/pages/uretim/dokuma_dashboard.dart';
import 'package:uretim_takip/pages/uretim/konfeksiyon_dashboard.dart';
import 'package:uretim_takip/pages/uretim/yikama_dashboard.dart';
import 'package:uretim_takip/pages/uretim/utu_paket_dashboard.dart';
import 'package:uretim_takip/pages/uretim/ilik_dugme_dashboard.dart';
import 'package:uretim_takip/pages/uretim/nakis_dashboard.dart';
import 'package:uretim_takip/pages/abonelik/plan_secim_page.dart';
import 'package:provider/provider.dart';
import 'package:uretim_takip/providers/auth_provider.dart';
import 'package:uretim_takip/utils/role_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool rememberMe = false;
  bool loading = false;
  bool showPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    await SecureCredentialStorage.migrateLegacyStorage();
    final savedRemember = await SecureCredentialStorage.isRememberMeEnabled;
    final savedEmail = await SecureCredentialStorage.savedEmail;

    if (savedEmail != null) {
      emailController.text = savedEmail;
    }

    if (savedRemember) {
      setState(() => rememberMe = true);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (rememberMe) {
          await SecureCredentialStorage.save(email: email);
        } else {
          await SecureCredentialStorage.clear();
        }

        // AuthProvider'ı başlat (merkezi kullanıcı durumu)
        if (mounted) {
          await context.read<AuthProvider>().initialize();
        }

        // Tenant'a yükle
        if (mounted) {
          final tenantProvider = context.read<TenantProvider>();
          await tenantProvider.kullaniciFirmalariniYukle(response.user!.id);
          // Çoklu firma varsa seçim ekranına yönlendir
          if (tenantProvider.kullaniciFirmalari.length > 1 &&
              !tenantProvider.firmaSecildi) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FirmaSecimPage()),
              );
            }
            return;
          }
          // Hiç firma yoksa: tedarikci/personel/rol kontrolü yap
          if (tenantProvider.kullaniciFirmalari.isEmpty) {
            bool hasExistingAccess = false;
            
            if (SupabaseConfig.isAdminAvailable) {
              try {
                final adminClient = SupabaseConfig.adminClient;

                // 1. firma_kullanicilari kontrolü (adminClient ile RLS bypass)
                final firmaKullaniciCheck = await adminClient
                    .from(DbTables.firmaKullanicilari)
                    .select('firma_id, rol')
                    .eq('user_id', response.user!.id)
                    .eq('aktif', true);
                
                if (firmaKullaniciCheck.isNotEmpty) {
                  debugPrint('✅ firma_kullanicilari kaydı bulundu (adminClient)');
                  await tenantProvider.kullaniciFirmalariniYukle(response.user!.id);
                  hasExistingAccess = true;
                }

                // 2. Tedarikci kontrolü (adminClient ile RLS bypass)
                if (!hasExistingAccess) {
                  final tedarikciCheck = await adminClient
                      .from(DbTables.tedarikciler)
                      .select('id, firma_id')
                      .eq('email', email)
                      .maybeSingle();
                  if (tedarikciCheck != null) {
                    hasExistingAccess = true;
                    // Eksik firma_kullanicilari kaydını oluştur
                    String? firmaId = tedarikciCheck['firma_id']?.toString();
                    // firma_id yoksa varsayılan firmayı kullan
                    if (firmaId == null) {
                      final varsayilanFirma = await adminClient
                          .from(DbTables.firmalar)
                          .select('id')
                          .eq('firma_kodu', 'varsayilan-firma')
                          .maybeSingle();
                      firmaId = varsayilanFirma?['id']?.toString();
                    }
                    if (firmaId != null) {
                      await adminClient.from(DbTables.firmaKullanicilari).upsert({
                        'firma_id': firmaId,
                        'user_id': response.user!.id,
                        'rol': 'kullanici',
                        'aktif': true,
                      }, onConflict: 'firma_id,user_id');
                      await tenantProvider.kullaniciFirmalariniYukle(response.user!.id);
                    }
                  }
                }

                // 3. User roles kontrolü (adminClient ile RLS bypass)
                if (!hasExistingAccess) {
                  final rolesCheck = await adminClient
                      .from(DbTables.userRoles)
                      .select('role')
                      .eq('user_id', response.user!.id);
                  if (rolesCheck.isNotEmpty) {
                    hasExistingAccess = true;
                    // Personel tablosundan firma_id bul
                    String? firmaId;
                    final personelCheck = await adminClient
                        .from(DbTables.personel)
                        .select('firma_id')
                        .eq('email', email)
                        .maybeSingle();
                    firmaId = personelCheck?['firma_id']?.toString();
                    
                    // firma_id bulunamadıysa varsayılan firmayı kullan
                    if (firmaId == null) {
                      final varsayilanFirma = await adminClient
                          .from(DbTables.firmalar)
                          .select('id')
                          .eq('firma_kodu', 'varsayilan-firma')
                          .maybeSingle();
                      firmaId = varsayilanFirma?['id']?.toString();
                      debugPrint('🏢 Varsayılan firma kullanılıyor: $firmaId');
                    }

                    if (firmaId != null) {
                      await adminClient.from(DbTables.firmaKullanicilari).upsert({
                        'firma_id': firmaId,
                        'user_id': response.user!.id,
                        'rol': 'kullanici',
                        'aktif': true,
                      }, onConflict: 'firma_id,user_id');
                      await tenantProvider.kullaniciFirmalariniYukle(response.user!.id);
                    }
                  }
                }
              } catch (e) {
                debugPrint('⚠️ Erişim kontrolü hatası: $e');
              }
            }

            if (!hasExistingAccess) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FirmaKayitPage()),
                );
              }
              return;
            }
            // hasExistingAccess true ise aşağıda normal yönlendirme yapılacak
          }
        }

        // Kullanıcı tipini kontrol et
        String targetRoute = AppRoutes.anasayfa; // Varsayılan admin paneli

        try {
          // AdminClient kullan (RLS bypass) - yoksa normal client ile devam et
          final dbClient = SupabaseConfig.isAdminAvailable
              ? SupabaseConfig.adminClient
              : Supabase.instance.client;

          // ÖNCE kullanıcı rollerini kontrol et (admin kontrolü)
          final userRoleCheck = await dbClient
              .from(DbTables.userRoles)
              .select('role')
              .eq('user_id', response.user!.id)
              .maybeSingle();

          // Rolü küçük harfe çevir (büyük/küçük harf duyarsız karşılaştırma)
          final userRole = RoleUtils.normalizeDashboardRole(
              userRoleCheck?['role']?.toString());
          debugPrint(
              '🔍 Kullanıcı rolü: $userRole (orijinal: ${userRoleCheck?['role']})');

          if (userRole == 'admin') {
            // Admin kullanıcısı - direkt ana sayfaya git
            targetRoute = AppRoutes.anasayfa;
            debugPrint('👤 Admin girişi: $email');
          } else if (userRole == 'kalite_kontrol') {
            targetRoute = AppRoutes.kalite;
            debugPrint('🔍 Kalite personeli girişi: $email');
          } else if (userRole == 'sofor') {
            targetRoute = '/sofor';
            debugPrint('🚗 Şoför girişi: $email');
          } else if (userRole == 'sevkiyat') {
            targetRoute = '/sevkiyat';
            debugPrint('📦 Sevkiyat personeli girişi: $email');
          } else {
            // Tedarikciler tablosunda bu email var mı kontrol et
            final tedarikciCheck = await dbClient
                .from(DbTables.tedarikciler)
                .select('id, sirket, faaliyet')
                .eq('email', email)
                .maybeSingle();

            if (tedarikciCheck != null) {
              // Bu bir tedarikci hesabı - faaliyete göre yönlendir
              final faaliyet =
                  (tedarikciCheck['faaliyet'] ?? '').toString().toLowerCase();
              if (faaliyet.contains('dokuma') ||
                  faaliyet.contains('örme') ||
                  faaliyet.contains('orgu')) {
                targetRoute = AppRoutes.dokuma;
              } else if (faaliyet.contains('konfeksiyon') ||
                  faaliyet.contains('dikim')) {
                targetRoute = '/konfeksiyon';
              } else if (faaliyet.contains('yıkama') ||
                  faaliyet.contains('yikama')) {
                targetRoute = AppRoutes.yikama;
              } else if (faaliyet.contains('nakış') ||
                  faaliyet.contains('nakis')) {
                targetRoute = AppRoutes.nakis;
              } else if (faaliyet.contains('ütü') || faaliyet.contains('utu')) {
                targetRoute = '/utu';
              } else if (faaliyet.contains('ilik') ||
                  faaliyet.contains('düğme') ||
                  faaliyet.contains('dugme')) {
                targetRoute = '/ilik_dugme';
              } else {
                targetRoute = AppRoutes.tedarikci;
              }
              debugPrint(
                  '🏢 Tedarikci girişi: ${tedarikciCheck['sirket']} (${tedarikciCheck['faaliyet']}) -> $targetRoute');
            } else {
              // Normal kullanıcı hesabı
              targetRoute = AppRoutes.anasayfa;
              debugPrint('👤 Kullanıcı girişi: $email');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Kullanıcı tipi kontrolü hatası: $e');
          // Hata durumunda varsayılan rotaya git
        }

        if (mounted) {
          Widget targetWidget;
          switch (targetRoute) {
            case AppRoutes.tedarikci:
              targetWidget = const TedarikciPanel();
              break;
            case AppRoutes.kalite:
              targetWidget = const KaliteKontrolPanel();
              break;
            case '/sofor':
              targetWidget = const SoforPanel();
              break;
            case '/sevkiyat':
              targetWidget = const SevkiyatPanel();
              break;
            case AppRoutes.dokuma:
              targetWidget = const DokumaDashboard();
              break;
            case '/konfeksiyon':
              targetWidget = const KonfeksiyonDashboard();
              break;
            case AppRoutes.yikama:
              targetWidget = const YikamaDashboard();
              break;
            case AppRoutes.nakis:
              targetWidget = const NakisDashboard();
              break;
            case '/utu':
              targetWidget = const UtuPaketDashboard();
              break;
            case '/ilik_dugme':
              targetWidget = const IlikDugmeDashboard();
              break;
            default:
              targetWidget = const AnaSayfa();
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => targetWidget),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Giriş Hatası', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF0d47a1),
              Color(0xFF01579b),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : (isTablet ? 32 : 20),
                vertical: isDesktop ? 20 : (isTablet ? 16 : 12),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: isDesktop
                      ? _buildDesktopLayout(size)
                      : isTablet
                          ? _buildTabletLayout(size)
                          : _buildMobileLayout(size),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Size size) {
    final cardHeight = size.height * 0.75 > 600 ? 600.0 : size.height * 0.75;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: size.width > 1200 ? 1100 : 950),
          child: Card(
            elevation: 20,
            shadowColor: Colors.black26,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                // Sol taraf - Görsel
                Expanded(
                  flex: 5,
                  child: Container(
                    height: cardHeight,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1565C0),
                          Color(0xFF0D47A1),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(size.width > 1200 ? 32 : 24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.precision_manufacturing_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'TexPilot',
                              style: TextStyle(
                                fontSize: size.width > 1200 ? 36 : 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tekstil üretim süreçlerinizi\ntek bir platformdan yönetin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildFeatureItem(
                                Icons.inventory_2_rounded, 'Sipariş Yönetimi'),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                                Icons.analytics_rounded, 'Detaylı Raporlama'),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                                Icons.groups_rounded, 'Tedarikçi Takibi'),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                                Icons.timeline_rounded, 'Üretim Aşamaları'),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                                Icons.warehouse_rounded, 'Stok Yönetimi'),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                                Icons.people_alt_rounded, 'Personel Takibi'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Sağ taraf - Form
                Expanded(
                  flex: 4,
                  child: Container(
                    height: cardHeight,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width > 1200 ? 48 : 32,
                      vertical: 24,
                    ),
                    child: SingleChildScrollView(
                      child: _buildLoginForm(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPlanBanner(),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withValues(alpha: 0.1),
            const Color(0xFF0D47A1).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildCompactFeatureItem(
              Icons.inventory_2_rounded, 'Sipariş Yönetimi'),
          const SizedBox(height: 8),
          _buildCompactFeatureItem(Icons.warehouse_rounded, 'Stok Yönetimi'),
          const SizedBox(height: 8),
          _buildCompactFeatureItem(Icons.people_alt_rounded, 'Personel Takibi'),
          const SizedBox(height: 8),
          _buildCompactFeatureItem(Icons.timeline_rounded, 'Üretim Aşamaları'),
          const SizedBox(height: 8),
          _buildCompactFeatureItem(
              Icons.analytics_rounded, 'Detaylı Raporlama'),
          const SizedBox(height: 8),
          _buildCompactFeatureItem(Icons.groups_rounded, 'Tedarikçi Takibi'),
        ],
      ),
    );
  }

  Widget _buildCompactFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1a237e),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Icon(
          Icons.check_circle,
          color: const Color(0xFF1565C0).withValues(alpha: 0.6),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildTabletLayout(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            elevation: 16,
            shadowColor: Colors.black26,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo ve Özellikler Yan Yana
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sol - Logo
                      Expanded(
                        flex: 2,
                        child: _buildCompactLogoSection(size),
                      ),
                      const SizedBox(width: 24),
                      // Sağ - Özellikler
                      Expanded(
                        flex: 3,
                        child: _buildCompactFeaturesList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ),
        _buildPlanBanner(),
      ],
    );
  }

  Widget _buildMobileLayout(Size size) {
    final isSmallMobile = size.width < 360;
    final isTinyMobile = size.width < 340;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: size.width > 450 ? 450 : size.width * 0.95),
          child: Card(
            elevation: 12,
            shadowColor: Colors.black26,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(isSmallMobile ? 20 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo ve Özellikler Yan Yana
                  isTinyMobile
                      ? Column(
                          children: [
                            _buildCompactLogoSection(size),
                            const SizedBox(height: 16),
                            _buildCompactFeaturesList(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sol - Logo
                            Expanded(
                              flex: 2,
                              child: _buildCompactLogoSection(size),
                            ),
                            SizedBox(width: isSmallMobile ? 12 : 16),
                            // Sağ - Özellikler
                            Expanded(
                              flex: 3,
                              child: _buildCompactFeaturesList(),
                            ),
                          ],
                        ),
                  SizedBox(height: isSmallMobile ? 20 : 28),
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ),
        _buildPlanBanner(),
      ],
    );
  }

  Widget _buildCompactLogoSection(Size size) {
    final isSmallMobile = size.width < 360;
    final isTablet = size.width > 600;
    final iconSize = isTablet ? 36.0 : (isSmallMobile ? 28.0 : 32.0);
    final titleSize = isTablet ? 20.0 : (isSmallMobile ? 16.0 : 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1565C0),
                Color(0xFF0D47A1),
              ],
            ),
            borderRadius: BorderRadius.circular(isSmallMobile ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.precision_manufacturing_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallMobile ? 8 : 12),
        Text(
          'TexPilot',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1a237e),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 14 gün ücretsiz deneme bilgisi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.card_giftcard, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    '14 gün ücretsiz deneme — tüm modüller dahil!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PlanSecimPage(sadeceBilgi: true)),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Planları Gör',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kIsWeb || MediaQuery.of(context).size.width > 900) ...[
            const Text(
              'Hoş Geldiniz',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a237e),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Devam etmek için giriş yapın',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
          ],
          // E-posta alanı
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@email.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF1565C0), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'E-posta gerekli';
              }
              if (!value.contains('@')) {
                return 'Geçerli bir e-posta girin';
              }
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 20),
          // Şifre alanı
          TextFormField(
            controller: passwordController,
            obscureText: !showPassword,
            decoration: InputDecoration(
              labelText: 'Şifre',
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(() => showPassword = !showPassword),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF1565C0), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalı';
              }
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 16),
          // Beni hatırla
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (value) =>
                      setState(() => rememberMe = value ?? false),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  activeColor: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Beni hatırla',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Giriş butonu
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor:
                    const Color(0xFF1565C0).withValues(alpha: 0.6),
              ),
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          // Alt bilgi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Güvenli bağlantı',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
