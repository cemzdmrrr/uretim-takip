import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/config/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('splash route is /', () {
      expect(AppRoutes.splash, '/');
    });

    test('temel rotalar doğru', () {
      expect(AppRoutes.anasayfa, '/anasayfa');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.firmaSecim, '/firma_secim');
    });

    test('all routes start with /', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.anasayfa,
        AppRoutes.login,
        AppRoutes.firmaSecim,
        AppRoutes.dokuma,
        AppRoutes.tedarikci,
        AppRoutes.kalite,
        AppRoutes.kaliteKontrol,
        AppRoutes.yikama,
        AppRoutes.nakis,
        AppRoutes.uretimRaporu,
        AppRoutes.modelDuzenle,
        AppRoutes.firmaKayit,
        AppRoutes.firmaBilgileri,
        AppRoutes.tekstilDaliSecim,
        AppRoutes.modulSecim,
        AppRoutes.firmaKurulumOzet,
        AppRoutes.davetKatil,
        AppRoutes.planSecim,
        AppRoutes.abonelikYonetimi,
        AppRoutes.firmaKullaniciYonetimi,
        AppRoutes.rolYetkiYonetimi,
        AppRoutes.genelUretimDashboard,
        AppRoutes.platformDashboard,
        AppRoutes.platformFirmalar,
        AppRoutes.platformAbonelikler,
        AppRoutes.platformModuller,
        AppRoutes.platformUretimDallari,
        AppRoutes.platformRaporlar,
        AppRoutes.platformDestek,
        AppRoutes.platformMigrasyon,
      ];

      for (final route in routes) {
        expect(route.startsWith('/'), isTrue,
            reason: 'Route "$route" should start with /');
      }
    });

    test('all routes are unique', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.anasayfa,
        AppRoutes.login,
        AppRoutes.firmaSecim,
        AppRoutes.dokuma,
        AppRoutes.tedarikci,
        AppRoutes.kalite,
        AppRoutes.kaliteKontrol,
        AppRoutes.yikama,
        AppRoutes.nakis,
        AppRoutes.uretimRaporu,
        AppRoutes.modelDuzenle,
        AppRoutes.firmaKayit,
        AppRoutes.firmaBilgileri,
        AppRoutes.tekstilDaliSecim,
        AppRoutes.modulSecim,
        AppRoutes.firmaKurulumOzet,
        AppRoutes.davetKatil,
        AppRoutes.planSecim,
        AppRoutes.abonelikYonetimi,
        AppRoutes.firmaKullaniciYonetimi,
        AppRoutes.rolYetkiYonetimi,
        AppRoutes.genelUretimDashboard,
        AppRoutes.platformDashboard,
        AppRoutes.platformFirmalar,
        AppRoutes.platformAbonelikler,
        AppRoutes.platformModuller,
        AppRoutes.platformUretimDallari,
        AppRoutes.platformRaporlar,
        AppRoutes.platformDestek,
        AppRoutes.platformMigrasyon,
      ];

      expect(routes.toSet().length, routes.length);
    });
  });

  group('AppRoutes - Onboarding', () {
    test('onboarding rotaları /onboarding/ ile başlar', () {
      final onboardingRoutes = [
        AppRoutes.firmaKayit,
        AppRoutes.firmaBilgileri,
        AppRoutes.tekstilDaliSecim,
        AppRoutes.modulSecim,
        AppRoutes.firmaKurulumOzet,
        AppRoutes.davetKatil,
      ];

      for (final route in onboardingRoutes) {
        expect(route.startsWith('/onboarding/'), isTrue,
            reason: 'Onboarding route "$route" should start with /onboarding/');
      }
    });
  });

  group('AppRoutes - Abonelik', () {
    test('abonelik rotaları /abonelik/ ile başlar', () {
      final abonelikRoutes = [
        AppRoutes.planSecim,
        AppRoutes.abonelikYonetimi,
      ];

      for (final route in abonelikRoutes) {
        expect(route.startsWith('/abonelik/'), isTrue,
            reason: 'Abonelik route "$route" should start with /abonelik/');
      }
    });
  });

  group('AppRoutes - Platform Admin', () {
    test('platform rotaları /platform/ ile başlar', () {
      final platformRoutes = [
        AppRoutes.platformDashboard,
        AppRoutes.platformFirmalar,
        AppRoutes.platformAbonelikler,
        AppRoutes.platformModuller,
        AppRoutes.platformUretimDallari,
        AppRoutes.platformRaporlar,
        AppRoutes.platformDestek,
        AppRoutes.platformMigrasyon,
      ];

      for (final route in platformRoutes) {
        expect(route.startsWith('/platform/'), isTrue,
            reason: 'Platform route "$route" should start with /platform/');
      }
    });
  });
}
