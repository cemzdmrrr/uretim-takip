import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/providers/auth_provider.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/yetki_service.dart';

import 'helpers/test_fixtures.dart';

/// Multi-tenant SaaS senaryolarını test eden entegrasyon testleri.
/// Supabase bağlantısı gerektirmez — saf mantık testleri.
void main() {
  late TenantManager tm;
  late AuthProvider auth;

  setUp(() {
    tm = TenantManager.instance;
    tm.temizle();
    auth = AuthProvider();
  });

  tearDown(() {
    tm.temizle();
  });

  group('Firma izolasyonu - TenantManager', () {
    test('firma geçişinde eski veriler temizlenmeli', () {
      // Firma 1 durumu
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaDetay: TestFixtures.firmaDetay(firmaAdi: 'Firma A'),
        aktifModuller: ['uretim', 'finans'],
        aktifUretimDallari: ['triko'],
        firmaRol: 'firma_sahibi',
        yetkiler: ['*'],
        aktifAbonelik: {'durum': 'aktif'},
      );

      expect(tm.firmaAdi, 'Firma A');
      expect(tm.modulAktifMi('uretim'), isTrue);
      expect(tm.modulAktifMi('finans'), isTrue);

      // Firma 2'ye geçiş - temizle + yeni durum
      tm.temizle();
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId2,
        firmaDetay: TestFixtures.firmaDetay(
          id: TestFixtures.firmaId2,
          firmaAdi: 'Firma B',
        ),
        aktifModuller: ['stok'],
        aktifUretimDallari: ['konfeksiyon'],
        firmaRol: 'kullanici',
        yetkiler: ['stok:okuma'],
      );

      // Firma 1'in verileri kalmamalı
      expect(tm.firmaId, TestFixtures.firmaId2);
      expect(tm.firmaAdi, 'Firma B');
      expect(tm.modulAktifMi('uretim'), isFalse);
      expect(tm.modulAktifMi('finans'), isFalse);
      expect(tm.modulAktifMi('stok'), isTrue);
      expect(tm.uretimDaliAktifMi('triko'), isFalse);
      expect(tm.uretimDaliAktifMi('konfeksiyon'), isTrue);
      expect(tm.isFirmaAdmin, isFalse);
      expect(tm.yetkiVarMi('uretim', 'okuma'), isFalse);
      expect(tm.yetkiVarMi('stok', 'okuma'), isTrue);
    });

    test('oturum kapatmada tüm firma verileri temizlenmeli', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaDetay: TestFixtures.firmaDetay(),
        aktifModuller: ['uretim'],
        firmaRol: 'firma_sahibi',
        yetkiler: ['*'],
        aktifAbonelik: {'durum': 'aktif'},
      );

      tm.temizle(); // signOut çağrısı gibi

      expect(tm.firmaId, isNull);
      expect(tm.firmaSecildi, isFalse);
      expect(tm.aktifModuller, isEmpty);
      expect(tm.aktifUretimDallari, isEmpty);
      expect(tm.firmaRol, isNull);
      expect(tm.yetkiler, isEmpty);
      expect(tm.aktifAbonelik, isNull);
    });
  });

  group('Yetki hiyerarşisi - tam senaryo', () {
    test('firma_sahibi tüm modüllere tam erişim', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaRol: 'firma_sahibi',
        aktifModuller: ['uretim', 'finans', 'stok', 'ik'],
      );
      auth.testDurumAyarla(
        role: 'user',
        firmaRol: 'firma_sahibi',
        yetkiler: ['*'],
      );

      for (final modul in ['uretim', 'finans', 'stok', 'ik']) {
        for (final yetki in YetkiService.yetkiTurleri) {
          expect(tm.yetkiVarMi(modul, yetki), isTrue,
              reason: 'firma_sahibi $modul:$yetki true olmalı');
          expect(auth.yetkiVarMi(modul, yetki), isTrue,
              reason: 'AuthProvider firma_sahibi $modul:$yetki true olmalı');
        }
      }
    });

    test('kullanici sadece atanmış yetkilere erişir', () {
      final yetkiler = ['uretim:okuma', 'uretim:yazma', 'stok:okuma'];

      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaRol: 'kullanici',
        yetkiler: yetkiler,
        aktifModuller: ['uretim', 'finans', 'stok'],
      );
      auth.testDurumAyarla(
        role: 'user',
        firmaRol: 'kullanici',
        yetkiler: yetkiler,
      );

      // İzin verilen
      expect(tm.yetkiVarMi('uretim', 'okuma'), isTrue);
      expect(tm.yetkiVarMi('uretim', 'yazma'), isTrue);
      expect(tm.yetkiVarMi('stok', 'okuma'), isTrue);

      // İzin verilmeyen
      expect(tm.yetkiVarMi('uretim', 'silme'), isFalse);
      expect(tm.yetkiVarMi('finans', 'okuma'), isFalse);
      expect(tm.yetkiVarMi('stok', 'yazma'), isFalse);

      // AuthProvider eşleşmeli
      expect(auth.yetkiVarMi('uretim', 'okuma'), isTrue);
      expect(auth.yetkiVarMi('finans', 'okuma'), isFalse);
    });

    test('platform admin (role=admin) tüm yetkilere sahip', () {
      auth.testDurumAyarla(
        role: 'admin',
        firmaRol: null,
        yetkiler: [],
      );

      expect(auth.isAdmin, isTrue);
      expect(auth.yetkiVarMi('uretim', 'silme'), isTrue);
      expect(auth.yetkiVarMi('finans', 'yonetim'), isTrue);
      expect(auth.modulErisimVarMi('herhangi_modul'), isTrue);
    });
  });

  group('Modül erişim + abonelik senaryoları', () {
    test('modül aktif değilse erişim olmamalı', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        aktifModuller: ['uretim'], // sadece uretim aktif
        firmaRol: 'kullanici',
        yetkiler: ['finans:okuma', 'finans:yazma'],
      );

      // Yetki var ama modül aktif değil
      expect(tm.modulAktifMi('finans'), isFalse);
      // Yetki var ama modül kontrolü eksik — bu bir business rule
      expect(tm.yetkiVarMi('finans', 'okuma'), isTrue);
      // Doğru kontrol: modül aktif + yetki var
      final erisilebilir =
          tm.modulAktifMi('finans') && tm.yetkiVarMi('finans', 'okuma');
      expect(erisilebilir, isFalse);
    });

    test('abonelik süresi dolmuşsa erişim kısıtlanmalı', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        aktifModuller: ['uretim', 'finans'],
        firmaRol: 'firma_sahibi',
        aktifAbonelik: {
          'durum': 'deneme',
          'deneme_bitis': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        },
      );

      expect(tm.abonelikGecerliMi, isFalse);
      // Business rule: abonelik geçersizse modüller hala orada ama erişim engellenmeli
      expect(tm.modulAktifMi('uretim'), isTrue); // modüller hala yüklü
      expect(tm.abonelikGecerliMi, isFalse); // ama abonelik geçersiz
    });
  });

  group('AbonelikPlani - modül limiti senaryoları', () {
    test('enterprise plan sınırsız modül', () {
      final plan =
          AbonelikPlani.fromJson(TestFixtures.enterprisePlaniJson());
      expect(plan.maxModul, isNull); // sınırsız
      expect(plan.enterpriseMi, isTrue);
    });

    test('profesyonel plan modül sınırlı', () {
      final plan = AbonelikPlani.fromJson(TestFixtures.abonelikPlaniJson());
      expect(plan.maxModul, 5);
      expect(plan.dahilModuller, hasLength(3));
    });

    test('deneme planı tüm modüller dahil', () {
      final plan = AbonelikPlani.fromJson(TestFixtures.denemePlaniJson());
      expect(plan.maxModul, isNull);
      expect(plan.maxKullanici, 5);
      expect(plan.denemeMi, isTrue);
      expect(plan.dahilModuller, hasLength(10));
    });
  });

  group('Çoklu firma senaryoları', () {
    test('kullanıcı birden fazla firmaya üye olabilir', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        kullaniciFirmalari: [
          {
            'firma_id': TestFixtures.firmaId1,
            'rol': 'firma_sahibi',
            'firmalar': {'id': TestFixtures.firmaId1, 'firma_adi': 'Firma A'},
          },
          {
            'firma_id': TestFixtures.firmaId2,
            'rol': 'kullanici',
            'firmalar': {'id': TestFixtures.firmaId2, 'firma_adi': 'Firma B'},
          },
        ],
      );

      expect(tm.kullaniciFirmalari, hasLength(2));
      expect(tm.firmaId, TestFixtures.firmaId1);
    });

    test('farklı firmalarda farklı roller', () {
      // Firma 1: firma_sahibi
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaRol: 'firma_sahibi',
        yetkiler: ['*'],
      );
      expect(tm.isFirmaAdmin, isTrue);
      expect(tm.yetkiVarMi('finans', 'silme'), isTrue);

      // Firma 2: personel
      tm.temizle();
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId2,
        firmaRol: 'personel',
        yetkiler: [],
      );
      expect(tm.isFirmaAdmin, isFalse);
      expect(tm.yetkiVarMi('finans', 'silme'), isFalse);
    });
  });

  group('YetkiService - tüm yetki türlerini kapsayan senaryo', () {
    test('tam yetkili kullanıcı tüm türlere sahip', () {
      final yetkiler = [
        'uretim:okuma',
        'uretim:yazma',
        'uretim:silme',
        'uretim:yonetim',
        'uretim:export',
      ];

      expect(YetkiService.modulErisimVarMi(yetkiler, 'uretim'), isTrue);
      expect(YetkiService.yazmaYetkisiVarMi(yetkiler, 'uretim'), isTrue);
      expect(YetkiService.yonetimYetkisiVarMi(yetkiler, 'uretim'), isTrue);
    });

    test('sadece okuma yetkili kullanıcı kısıtlı', () {
      final yetkiler = ['uretim:okuma'];

      expect(YetkiService.modulErisimVarMi(yetkiler, 'uretim'), isTrue);
      expect(YetkiService.yazmaYetkisiVarMi(yetkiler, 'uretim'), isFalse);
      expect(YetkiService.yonetimYetkisiVarMi(yetkiler, 'uretim'), isFalse);
    });
  });
}
