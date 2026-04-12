import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/abonelik_model.dart';

import 'helpers/test_fixtures.dart';

void main() {
  // ════════════════════════════════════════════════════
  // AbonelikPlani
  // ════════════════════════════════════════════════════
  group('AbonelikPlani', () {
    test('fromJson doğru alanları parse eder', () {
      final plan = AbonelikPlani.fromJson(TestFixtures.abonelikPlaniJson());

      expect(plan.id, 'plan-001');
      expect(plan.planKodu, 'profesyonel');
      expect(plan.planAdi, 'Profesyonel');
      expect(plan.aylikUcret, 499.0);
      expect(plan.yillikUcret, 4990.0);
      expect(plan.maxKullanici, 10);
      expect(plan.maxModul, 5);
      expect(plan.dahilModuller, ['uretim', 'finans', 'stok']);
      expect(plan.ozellikler, {'destek': 'email'});
      expect(plan.aktif, isTrue);
      expect(plan.siraNo, 2);
    });

    test('fromJson dahil_moduller null iken boş liste', () {
      final json = TestFixtures.abonelikPlaniJson();
      json['dahil_moduller'] = null;
      final plan = AbonelikPlani.fromJson(json);
      expect(plan.dahilModuller, isEmpty);
    });

    test('fromJson ozellikler null iken boş map', () {
      final json = TestFixtures.abonelikPlaniJson();
      json['ozellikler'] = null;
      final plan = AbonelikPlani.fromJson(json);
      expect(plan.ozellikler, isEmpty);
    });

    test('enterpriseMi doğru çalışır', () {
      final enterprise = AbonelikPlani.fromJson(TestFixtures.enterprisePlaniJson());
      final profesyonel = AbonelikPlani.fromJson(TestFixtures.abonelikPlaniJson());

      expect(enterprise.enterpriseMi, isTrue);
      expect(profesyonel.enterpriseMi, isFalse);
    });

    test('denemeMi doğru çalışır', () {
      final deneme = AbonelikPlani.fromJson(TestFixtures.denemePlaniJson());
      final prof = AbonelikPlani.fromJson(TestFixtures.abonelikPlaniJson());

      expect(deneme.denemeMi, isTrue);
      expect(prof.denemeMi, isFalse);
    });

    test('yillikIndirimYuzdesi hesaplama', () {
      final plan = AbonelikPlani.fromJson(TestFixtures.abonelikPlaniJson(
        aylikUcret: 100.0,
        yillikUcret: 1000.0,
      ));
      // Normal yıllık: 100 * 12 = 1200, indirimli: 1000
      // Yüzde: (1200 - 1000) / 1200 * 100 ≈ 16.67
      expect(plan.yillikIndirimYuzdesi, closeTo(16.67, 0.01));
    });

    test('yillikIndirimYuzdesi yıllık ücret null iken 0', () {
      final plan = AbonelikPlani.fromJson(TestFixtures.abonelikPlaniJson(
        aylikUcret: 100.0,
        yillikUcret: null,
      ));
      expect(plan.yillikIndirimYuzdesi, 0);
    });

    test('yillikIndirimYuzdesi aylik 0 iken 0', () {
      final plan = AbonelikPlani.fromJson(TestFixtures.abonelikPlaniJson(
        aylikUcret: 0,
        yillikUcret: 0,
      ));
      expect(plan.yillikIndirimYuzdesi, 0);
    });
  });

  // ════════════════════════════════════════════════════
  // AbonelikDurum
  // ════════════════════════════════════════════════════
  group('AbonelikDurum', () {
    test('fromString tüm durumları doğru döner', () {
      expect(AbonelikDurum.fromString('aktif'), AbonelikDurum.aktif);
      expect(AbonelikDurum.fromString('pasif'), AbonelikDurum.pasif);
      expect(AbonelikDurum.fromString('deneme'), AbonelikDurum.deneme);
      expect(AbonelikDurum.fromString('iptal'), AbonelikDurum.iptal);
      expect(AbonelikDurum.fromString('odeme_bekleniyor'),
          AbonelikDurum.odemeBekleniyor);
    });

    test('fromString bilinmeyen değerde deneme döner', () {
      expect(AbonelikDurum.fromString('bilinmeyen'), AbonelikDurum.deneme);
      expect(AbonelikDurum.fromString(null), AbonelikDurum.deneme);
    });

    test('dpiValue doğru string döner', () {
      expect(AbonelikDurum.aktif.dpiValue, 'aktif');
      expect(AbonelikDurum.pasif.dpiValue, 'pasif');
      expect(AbonelikDurum.deneme.dpiValue, 'deneme');
      expect(AbonelikDurum.iptal.dpiValue, 'iptal');
      expect(AbonelikDurum.odemeBekleniyor.dpiValue, 'odeme_bekleniyor');
    });

    test('etiket Türkçe döner', () {
      expect(AbonelikDurum.aktif.etiket, 'Aktif');
      expect(AbonelikDurum.pasif.etiket, 'Pasif');
      expect(AbonelikDurum.deneme.etiket, 'Deneme');
      expect(AbonelikDurum.iptal.etiket, 'İptal Edildi');
      expect(AbonelikDurum.odemeBekleniyor.etiket, 'Ödeme Bekleniyor');
    });
  });

  // ════════════════════════════════════════════════════
  // FirmaAbonelik
  // ════════════════════════════════════════════════════
  group('FirmaAbonelik', () {
    test('fromJson doğru parse eder', () {
      final abonelik = FirmaAbonelik.fromJson(TestFixtures.firmaAbonelikJson());

      expect(abonelik.id, 'abone-001');
      expect(abonelik.firmaId, TestFixtures.firmaId1);
      expect(abonelik.planId, 'plan-001');
      expect(abonelik.durum, AbonelikDurum.aktif);
      expect(abonelik.odemePeriyodu, 'aylik');
      expect(abonelik.plan, isNotNull);
      expect(abonelik.plan!.planKodu, 'profesyonel');
    });

    test('fromJson abonelik_planlari null iken plan null', () {
      final json = TestFixtures.firmaAbonelikJson();
      json.remove('abonelik_planlari');
      final abonelik = FirmaAbonelik.fromJson(json);
      expect(abonelik.plan, isNull);
    });

    test('gecerliMi aktif durumda true', () {
      final abonelik =
          FirmaAbonelik.fromJson(TestFixtures.firmaAbonelikJson(durum: 'aktif'));
      expect(abonelik.gecerliMi, isTrue);
    });

    test('gecerliMi deneme + süre devam ediyor true', () {
      final gelecek =
          DateTime.now().add(const Duration(days: 10)).toIso8601String();
      final abonelik = FirmaAbonelik.fromJson(
        TestFixtures.firmaAbonelikJson(durum: 'deneme', denemeBitis: gelecek),
      );
      expect(abonelik.gecerliMi, isTrue);
    });

    test('gecerliMi deneme + süre dolmuş false', () {
      final gecmis =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final abonelik = FirmaAbonelik.fromJson(
        TestFixtures.firmaAbonelikJson(durum: 'deneme', denemeBitis: gecmis),
      );
      expect(abonelik.gecerliMi, isFalse);
    });

    test('gecerliMi pasif durumda false', () {
      final abonelik =
          FirmaAbonelik.fromJson(TestFixtures.firmaAbonelikJson(durum: 'pasif'));
      expect(abonelik.gecerliMi, isFalse);
    });

    test('gecerliMi iptal durumda false', () {
      final abonelik =
          FirmaAbonelik.fromJson(TestFixtures.firmaAbonelikJson(durum: 'iptal'));
      expect(abonelik.gecerliMi, isFalse);
    });

    test('denemeSuresiDolmusMu deneme bitince true', () {
      final gecmis =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final abonelik = FirmaAbonelik.fromJson(
        TestFixtures.firmaAbonelikJson(durum: 'deneme', denemeBitis: gecmis),
      );
      expect(abonelik.denemeSuresiDolmusMu, isTrue);
    });

    test('denemeSuresiDolmusMu deneme devam ederken false', () {
      final gelecek =
          DateTime.now().add(const Duration(days: 5)).toIso8601String();
      final abonelik = FirmaAbonelik.fromJson(
        TestFixtures.firmaAbonelikJson(durum: 'deneme', denemeBitis: gelecek),
      );
      expect(abonelik.denemeSuresiDolmusMu, isFalse);
    });

    test('denemeSuresiDolmusMu aktif durumda false', () {
      final abonelik =
          FirmaAbonelik.fromJson(TestFixtures.firmaAbonelikJson(durum: 'aktif'));
      expect(abonelik.denemeSuresiDolmusMu, isFalse);
    });

    test('kalanDenemeGunu hesaplama', () {
      final gelecek =
          DateTime.now().add(const Duration(days: 10)).toIso8601String();
      final abonelik = FirmaAbonelik.fromJson(
        TestFixtures.firmaAbonelikJson(durum: 'deneme', denemeBitis: gelecek),
      );
      // 9 veya 10 gün olabilir (saat farkından)
      expect(abonelik.kalanDenemeGunu, greaterThanOrEqualTo(9));
      expect(abonelik.kalanDenemeGunu, lessThanOrEqualTo(10));
    });

    test('kalanDenemeGunu süresi dolmuşta 0', () {
      final gecmis =
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      final abonelik = FirmaAbonelik.fromJson(
        TestFixtures.firmaAbonelikJson(durum: 'deneme', denemeBitis: gecmis),
      );
      expect(abonelik.kalanDenemeGunu, 0);
    });
  });

  // ════════════════════════════════════════════════════
  // AbonelikOdeme
  // ════════════════════════════════════════════════════
  group('AbonelikOdeme', () {
    test('fromJson doğru parse eder', () {
      final odeme = AbonelikOdeme.fromJson(TestFixtures.abonelikOdemeJson());

      expect(odeme.id, 'odeme-001');
      expect(odeme.firmaId, TestFixtures.firmaId1);
      expect(odeme.abonelikId, 'abone-001');
      expect(odeme.tutar, 499.0);
      expect(odeme.paraBirimi, 'TRY');
      expect(odeme.odemeYontemi, 'kredi_karti');
      expect(odeme.odemeReferans, 'REF-12345');
      expect(odeme.durum, 'basarili');
      expect(odeme.faturaNo, 'FTR-001');
      expect(odeme.odemeTarihi, isNotNull);
    });

    test('fromJson opsiyonel alanlar null olabilir', () {
      final json = {
        'id': 'odeme-002',
        'firma_id': TestFixtures.firmaId1,
        'abonelik_id': 'abone-001',
        'tutar': 100.0,
      };
      final odeme = AbonelikOdeme.fromJson(json);

      expect(odeme.paraBirimi, 'TRY'); // varsayılan
      expect(odeme.durum, 'basarili'); // varsayılan
      expect(odeme.odemeYontemi, isNull);
      expect(odeme.odemeReferans, isNull);
      expect(odeme.odemeTarihi, isNull);
      expect(odeme.faturaNo, isNull);
    });
  });
}
