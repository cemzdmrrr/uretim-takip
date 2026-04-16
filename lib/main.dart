import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uretim_takip/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/config/secure_storage.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/providers/auth_provider.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';

import 'package:uretim_takip/pages/home/ana_sayfa.dart';
import 'package:uretim_takip/pages/auth/login_page.dart';
import 'package:uretim_takip/pages/auth/splash_screen.dart';
import 'package:uretim_takip/pages/model/model_duzenle.dart';
import 'package:uretim_takip/pages/uretim/dokuma_dashboard.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_panel.dart';
import 'package:uretim_takip/pages/uretim/kalite_kontrol_panel.dart';
import 'package:uretim_takip/pages/uretim/yikama_dashboard.dart';
import 'package:uretim_takip/pages/uretim/uretim_raporu_page.dart';
import 'package:uretim_takip/pages/uretim/nakis_dashboard.dart';
import 'package:uretim_takip/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sadece masaüstü platformlarda window_manager kullan
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await windowManager.ensureInitialized();
    windowManager.setTitle('TexPilot');
  }

  // Supabase'i initialize et (Hot restart için güvenli)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    // Yapılandırma eksikse kullanıcıya hata mesajı göster
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '$e',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }

  await SecureCredentialStorage.migrateLegacyStorage();
  final rememberMe = await SecureCredentialStorage.isRememberMeEnabled;

  if (!rememberMe && Supabase.instance.client.auth.currentSession != null) {
    await Supabase.instance.client.auth.signOut();
    await SecureCredentialStorage.clear();
  }

  final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

  // Auth provider'ı başlat
  final authProvider = AuthProvider();
  final tenantProvider = TenantProvider();
  if (isLoggedIn) {
    await authProvider.initialize();
    // Tenant başlat
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await tenantProvider.kullaniciFirmalariniYukle(userId);
    }
  }

  runApp(MyApp(
      isLoggedIn: isLoggedIn,
      authProvider: authProvider,
      tenantProvider: tenantProvider));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final AuthProvider authProvider;
  final TenantProvider tenantProvider;

  const MyApp(
      {super.key,
      required this.isLoggedIn,
      required this.authProvider,
      required this.tenantProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: tenantProvider),
      ],
      child: MaterialApp(
        title: 'TexPilot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        supportedLocales: const [
          Locale('tr'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('tr'),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => SplashScreen(isLoggedIn: isLoggedIn),
          AppRoutes.anasayfa: (context) => const AnaSayfa(),
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.dokuma: (context) => const DokumaDashboard(),
          AppRoutes.tedarikci: (context) => const TedarikciPanel(),
          AppRoutes.kalite: (context) => const KaliteKontrolPanel(),
          AppRoutes.kaliteKontrol: (context) => const KaliteKontrolPanel(),
          AppRoutes.yikama: (context) => const YikamaDashboard(),
          AppRoutes.nakis: (context) => const NakisDashboard(),
          AppRoutes.uretimRaporu: (context) => const UretimRaporuPage(),
          AppRoutes.modelDuzenle: (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            if (args != null) {
              return ModelDuzenlePage(
                modelId: args['modelId'],
                modelData: args['modelData'],
              );
            }
            return const LoginPage(); // Fallback
          },
        },
      ),
    );
  }
}
