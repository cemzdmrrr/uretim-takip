import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/services/yetki_service.dart';

void main() {
  group('YetkiService - rol sabitleri', () {
    test('firmaRolleri doğru tanımlı', () {
      expect(YetkiService.firmaRolleri, [
        'firma_sahibi',
        'firma_admin',
        'yonetici',
        'kullanici',
        'personel',
      ]);
    });

    test('ozelRoller doğru tanımlı', () {
      expect(YetkiService.ozelRoller, contains('dokumaci'));
      expect(YetkiService.ozelRoller, contains('konfeksiyoncu'));
      expect(YetkiService.ozelRoller, contains('kalite_kontrol'));
      expect(YetkiService.ozelRoller, contains('sofor'));
      expect(YetkiService.ozelRoller, contains('muhasebeci'));
      expect(YetkiService.ozelRoller, contains('depocu'));
    });

    test('tumRoller firma + özel rolleri birleştirir', () {
      final tumRoller = YetkiService.tumRoller;
      expect(tumRoller, containsAll(YetkiService.firmaRolleri));
      expect(tumRoller, containsAll(YetkiService.ozelRoller));
      expect(
        tumRoller.length,
        YetkiService.firmaRolleri.length + YetkiService.ozelRoller.length,
      );
    });

    test('rolEtiketleri tüm firma rolleri için tanımlı', () {
      for (final rol in YetkiService.firmaRolleri) {
        expect(YetkiService.rolEtiketleri.containsKey(rol), isTrue,
            reason: '$rol için etiket tanımlı olmalı');
      }
    });

    test('rolEtiketleri tüm özel roller için tanımlı', () {
      for (final rol in YetkiService.ozelRoller) {
        expect(YetkiService.rolEtiketleri.containsKey(rol), isTrue,
            reason: '$rol için etiket tanımlı olmalı');
      }
    });

    test('yetkiTurleri doğru tanımlı', () {
      expect(YetkiService.yetkiTurleri,
          ['okuma', 'yazma', 'silme', 'yonetim', 'export']);
    });
  });

  group('YetkiService.yetkiVarMi', () {
    test('joker (*) ile her yetki true', () {
      expect(YetkiService.yetkiVarMi(['*'], 'uretim', 'okuma'), isTrue);
      expect(YetkiService.yetkiVarMi(['*'], 'finans', 'silme'), isTrue);
      expect(YetkiService.yetkiVarMi(['*'], 'stok', 'yonetim'), isTrue);
    });

    test('spesifik yetki eşleşir', () {
      final yetkiler = ['uretim:okuma', 'uretim:yazma', 'finans:okuma'];
      expect(YetkiService.yetkiVarMi(yetkiler, 'uretim', 'okuma'), isTrue);
      expect(YetkiService.yetkiVarMi(yetkiler, 'uretim', 'yazma'), isTrue);
      expect(YetkiService.yetkiVarMi(yetkiler, 'finans', 'okuma'), isTrue);
    });

    test('eşleşmeyen yetki false', () {
      final yetkiler = ['uretim:okuma'];
      expect(YetkiService.yetkiVarMi(yetkiler, 'uretim', 'yazma'), isFalse);
      expect(YetkiService.yetkiVarMi(yetkiler, 'finans', 'okuma'), isFalse);
    });

    test('boş yetki listesiyle false', () {
      expect(YetkiService.yetkiVarMi([], 'uretim', 'okuma'), isFalse);
    });
  });

  group('YetkiService.modulErisimVarMi', () {
    test('okuma yetkisi varsa true', () {
      expect(
        YetkiService.modulErisimVarMi(['uretim:okuma'], 'uretim'),
        isTrue,
      );
    });

    test('sadece yazma yetkisi varsa false (okuma gerekli)', () {
      expect(
        YetkiService.modulErisimVarMi(['uretim:yazma'], 'uretim'),
        isFalse,
      );
    });

    test('joker ile true', () {
      expect(YetkiService.modulErisimVarMi(['*'], 'herhangi'), isTrue);
    });
  });

  group('YetkiService.yazmaYetkisiVarMi', () {
    test('yazma yetkisi varsa true', () {
      expect(
        YetkiService.yazmaYetkisiVarMi(['uretim:yazma'], 'uretim'),
        isTrue,
      );
    });

    test('sadece okuma yetkisi varsa false', () {
      expect(
        YetkiService.yazmaYetkisiVarMi(['uretim:okuma'], 'uretim'),
        isFalse,
      );
    });

    test('joker ile true', () {
      expect(YetkiService.yazmaYetkisiVarMi(['*'], 'stok'), isTrue);
    });
  });

  group('YetkiService.yonetimYetkisiVarMi', () {
    test('yonetim yetkisi varsa true', () {
      expect(
        YetkiService.yonetimYetkisiVarMi(['uretim:yonetim'], 'uretim'),
        isTrue,
      );
    });

    test('sadece yazma yetkisi varsa false', () {
      expect(
        YetkiService.yonetimYetkisiVarMi(['uretim:yazma'], 'uretim'),
        isFalse,
      );
    });

    test('joker ile true', () {
      expect(YetkiService.yonetimYetkisiVarMi(['*'], 'finans'), isTrue);
    });
  });

  group('YetkiService - çapraz modül izolasyonu', () {
    test('farklı modül yetkileri birbirine karışmaz', () {
      final yetkiler = ['uretim:okuma', 'finans:yazma'];

      expect(YetkiService.yetkiVarMi(yetkiler, 'uretim', 'okuma'), isTrue);
      expect(YetkiService.yetkiVarMi(yetkiler, 'uretim', 'yazma'), isFalse);
      expect(YetkiService.yetkiVarMi(yetkiler, 'finans', 'yazma'), isTrue);
      expect(YetkiService.yetkiVarMi(yetkiler, 'finans', 'okuma'), isFalse);
    });

    test('aynı modülde birden fazla yetki', () {
      final yetkiler = [
        'uretim:okuma',
        'uretim:yazma',
        'uretim:silme',
        'uretim:yonetim',
        'uretim:export',
      ];

      for (final tur in YetkiService.yetkiTurleri) {
        expect(YetkiService.yetkiVarMi(yetkiler, 'uretim', tur), isTrue);
      }
      // Başka modülde yetki yok
      expect(YetkiService.yetkiVarMi(yetkiler, 'finans', 'okuma'), isFalse);
    });
  });
}
