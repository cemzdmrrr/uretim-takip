import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

import 'helpers/test_fixtures.dart';

void main() {
  late TenantManager tm;

  setUp(() {
    tm = TenantManager.instance;
    tm.temizle();
  });

  tearDown(() {
    tm.temizle();
  });

  group('TenantManager - başlangıç durumu', () {
    test('temiz başlangıçta firmaId null', () {
      expect(tm.firmaId, isNull);
    });

    test('temiz başlangıçta firmaSecildi false', () {
      expect(tm.firmaSecildi, isFalse);
    });

    test('temiz başlangıçta firmaAdi boş döner', () {
      expect(tm.firmaAdi, '');
    });

    test('temiz başlangıçta aktifModuller boş', () {
      expect(tm.aktifModuller, isEmpty);
    });

    test('temiz başlangıçta aktifUretimDallari boş', () {
      expect(tm.aktifUretimDallari, isEmpty);
    });

    test('temiz başlangıçta yetkiler boş', () {
      expect(tm.yetkiler, isEmpty);
    });

    test('temiz başlangıçta firmaRol null', () {
      expect(tm.firmaRol, isNull);
    });

    test('temiz başlangıçta aktifAbonelik null', () {
      expect(tm.aktifAbonelik, isNull);
    });
  });

  group('TenantManager - requireFirmaId', () {
    test('firma seçilmemişken StateError fırlatır', () {
      expect(() => tm.requireFirmaId, throwsStateError);
    });

    test('firma seçilmişken ID döner', () {
      tm.testDurumAyarla(firmaId: TestFixtures.firmaId1);
      expect(tm.requireFirmaId, TestFixtures.firmaId1);
    });
  });

  group('TenantManager - firmaSecildi', () {
    test('firma seçilmemişken false', () {
      expect(tm.firmaSecildi, isFalse);
    });

    test('firma seçilmişken true', () {
      tm.testDurumAyarla(firmaId: TestFixtures.firmaId1);
      expect(tm.firmaSecildi, isTrue);
    });
  });

  group('TenantManager - firmaAdi', () {
    test('firmaDetay null iken boş string', () {
      expect(tm.firmaAdi, '');
    });

    test('firmaDetay varsa firma_adi döner', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaDetay: TestFixtures.firmaDetay(firmaAdi: 'Acme Tekstil'),
      );
      expect(tm.firmaAdi, 'Acme Tekstil');
    });
  });

  group('TenantManager - isFirmaAdmin', () {
    test('firmaRol null iken false', () {
      expect(tm.isFirmaAdmin, isFalse);
    });

    test('firma_sahibi true', () {
      tm.testDurumAyarla(firmaRol: 'firma_sahibi');
      expect(tm.isFirmaAdmin, isTrue);
    });

    test('firma_admin true', () {
      tm.testDurumAyarla(firmaRol: 'firma_admin');
      expect(tm.isFirmaAdmin, isTrue);
    });

    test('kullanici false', () {
      tm.testDurumAyarla(firmaRol: 'kullanici');
      expect(tm.isFirmaAdmin, isFalse);
    });

    test('personel false', () {
      tm.testDurumAyarla(firmaRol: 'personel');
      expect(tm.isFirmaAdmin, isFalse);
    });
  });

  group('TenantManager - yetkiVarMi', () {
    test('firma_sahibi her zaman true', () {
      tm.testDurumAyarla(firmaRol: 'firma_sahibi');
      expect(tm.yetkiVarMi('uretim', 'yazma'), isTrue);
      expect(tm.yetkiVarMi('finans', 'silme'), isTrue);
    });

    test('firma_admin her zaman true', () {
      tm.testDurumAyarla(firmaRol: 'firma_admin');
      expect(tm.yetkiVarMi('stok', 'okuma'), isTrue);
    });

    test('joker yetki (*) her zaman true', () {
      tm.testDurumAyarla(
        firmaRol: 'kullanici',
        yetkiler: ['*'],
      );
      expect(tm.yetkiVarMi('herhangi', 'yetki'), isTrue);
    });

    test('spesifik yetki eşleşirse true', () {
      tm.testDurumAyarla(
        firmaRol: 'kullanici',
        yetkiler: ['uretim:okuma', 'uretim:yazma', 'finans:okuma'],
      );
      expect(tm.yetkiVarMi('uretim', 'okuma'), isTrue);
      expect(tm.yetkiVarMi('uretim', 'yazma'), isTrue);
      expect(tm.yetkiVarMi('finans', 'okuma'), isTrue);
    });

    test('spesifik yetki yoksa false', () {
      tm.testDurumAyarla(
        firmaRol: 'kullanici',
        yetkiler: ['uretim:okuma'],
      );
      expect(tm.yetkiVarMi('uretim', 'silme'), isFalse);
      expect(tm.yetkiVarMi('finans', 'okuma'), isFalse);
    });

    test('boş yetkilerle false', () {
      tm.testDurumAyarla(firmaRol: 'personel', yetkiler: []);
      expect(tm.yetkiVarMi('uretim', 'okuma'), isFalse);
    });
  });

  group('TenantManager - modulErisimVarMi', () {
    test('okuma yetkisi varsa true', () {
      tm.testDurumAyarla(
        firmaRol: 'kullanici',
        yetkiler: ['uretim:okuma'],
      );
      expect(tm.modulErisimVarMi('uretim'), isTrue);
    });

    test('başka yetki varsa ama okuma yoksa false', () {
      tm.testDurumAyarla(
        firmaRol: 'kullanici',
        yetkiler: ['uretim:yazma'],
      );
      expect(tm.modulErisimVarMi('uretim'), isFalse);
    });
  });

  group('TenantManager - modulAktifMi', () {
    test('modül listede varsa true', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        aktifModuller: ['uretim', 'finans', 'stok'],
      );
      expect(tm.modulAktifMi('uretim'), isTrue);
      expect(tm.modulAktifMi('finans'), isTrue);
    });

    test('modül listede yoksa false', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        aktifModuller: ['uretim'],
      );
      expect(tm.modulAktifMi('finans'), isFalse);
    });

    test('boş listeyle false', () {
      expect(tm.modulAktifMi('uretim'), isFalse);
    });
  });

  group('TenantManager - uretimDaliAktifMi', () {
    test('dal listede varsa true', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        aktifUretimDallari: ['triko', 'dokuma'],
      );
      expect(tm.uretimDaliAktifMi('triko'), isTrue);
      expect(tm.uretimDaliAktifMi('dokuma'), isTrue);
    });

    test('dal listede yoksa false', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        aktifUretimDallari: ['triko'],
      );
      expect(tm.uretimDaliAktifMi('konfeksiyon'), isFalse);
    });
  });

  group('TenantManager - abonelikGecerliMi', () {
    test('abonelik null iken false', () {
      expect(tm.abonelikGecerliMi, isFalse);
    });

    test('aktif abonelik true', () {
      tm.testDurumAyarla(
        aktifAbonelik: {'durum': 'aktif'},
      );
      expect(tm.abonelikGecerliMi, isTrue);
    });

    test('deneme süresi devam ediyor true', () {
      tm.testDurumAyarla(
        aktifAbonelik: {
          'durum': 'deneme',
          'deneme_bitis':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        },
      );
      expect(tm.abonelikGecerliMi, isTrue);
    });

    test('deneme süresi dolmuş false', () {
      tm.testDurumAyarla(
        aktifAbonelik: {
          'durum': 'deneme',
          'deneme_bitis':
              DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      );
      expect(tm.abonelikGecerliMi, isFalse);
    });

    test('deneme_bitis null iken false', () {
      tm.testDurumAyarla(
        aktifAbonelik: {'durum': 'deneme', 'deneme_bitis': null},
      );
      expect(tm.abonelikGecerliMi, isFalse);
    });

    test('pasif abonelik false', () {
      tm.testDurumAyarla(
        aktifAbonelik: {'durum': 'pasif'},
      );
      expect(tm.abonelikGecerliMi, isFalse);
    });

    test('iptal abonelik false', () {
      tm.testDurumAyarla(
        aktifAbonelik: {'durum': 'iptal'},
      );
      expect(tm.abonelikGecerliMi, isFalse);
    });

    test('odeme_bekleniyor false', () {
      tm.testDurumAyarla(
        aktifAbonelik: {'durum': 'odeme_bekleniyor'},
      );
      expect(tm.abonelikGecerliMi, isFalse);
    });
  });

  group('TenantManager - temizle', () {
    test('tüm durumu sıfırlar', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaDetay: TestFixtures.firmaDetay(),
        kullaniciFirmalari: [
          {'firma_id': TestFixtures.firmaId1}
        ],
        aktifModuller: ['uretim', 'finans'],
        aktifUretimDallari: ['triko'],
        aktifAbonelik: {'durum': 'aktif'},
        firmaRol: 'firma_sahibi',
        yetkiler: ['*'],
      );

      // Temizle öncesi kontrol
      expect(tm.firmaSecildi, isTrue);
      expect(tm.aktifModuller, isNotEmpty);

      tm.temizle();

      // Temizle sonrası kontrol
      expect(tm.firmaId, isNull);
      expect(tm.firmaDetay, isNull);
      expect(tm.firmaSecildi, isFalse);
      expect(tm.aktifModuller, isEmpty);
      expect(tm.aktifUretimDallari, isEmpty);
      expect(tm.aktifAbonelik, isNull);
      expect(tm.firmaRol, isNull);
      expect(tm.yetkiler, isEmpty);
    });
  });

  group('TenantManager - kullaniciFirmalari', () {
    test('unmodifiable liste döner', () {
      tm.testDurumAyarla(
        kullaniciFirmalari: [
          {'firma_id': TestFixtures.firmaId1, 'rol': 'firma_sahibi'},
          {'firma_id': TestFixtures.firmaId2, 'rol': 'kullanici'},
        ],
      );
      expect(tm.kullaniciFirmalari, hasLength(2));
      expect(
        () => (tm.kullaniciFirmalari as List).add({'test': 'test'}),
        throwsUnsupportedError,
      );
    });
  });

  group('TenantManager - firma geçişi senaryoları', () {
    test('firma 1 den firma 2 ye geçiş', () {
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId1,
        firmaDetay: TestFixtures.firmaDetay(firmaAdi: 'Firma 1'),
        aktifModuller: ['uretim'],
        firmaRol: 'firma_sahibi',
      );
      expect(tm.firmaAdi, 'Firma 1');
      expect(tm.modulAktifMi('uretim'), isTrue);

      // Firma 2'ye geçiş
      tm.testDurumAyarla(
        firmaId: TestFixtures.firmaId2,
        firmaDetay: TestFixtures.firmaDetay(
          id: TestFixtures.firmaId2,
          firmaAdi: 'Firma 2',
        ),
        aktifModuller: ['finans', 'stok'],
        firmaRol: 'kullanici',
        yetkiler: ['finans:okuma'],
      );

      expect(tm.firmaId, TestFixtures.firmaId2);
      expect(tm.firmaAdi, 'Firma 2');
      expect(tm.modulAktifMi('uretim'), isFalse);
      expect(tm.modulAktifMi('finans'), isTrue);
      expect(tm.isFirmaAdmin, isFalse);
      expect(tm.yetkiVarMi('finans', 'okuma'), isTrue);
      expect(tm.yetkiVarMi('finans', 'yazma'), isFalse);
    });
  });
}
