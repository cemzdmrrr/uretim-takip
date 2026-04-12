import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/kasa_banka_model.dart';

void main() {
  final sampleJson = {
    'id': 1,
    'ad': 'Ana Kasa',
    'tip': 'KASA',
    'banka_adi': null,
    'hesap_no': null,
    'iban': null,
    'bakiye': 15000.50,
    'doviz_turu': 'TRY',
    'durumu': 'AKTIF',
    'aciklama': 'Peşin işlemler',
    'olusturma_tarihi': '2025-01-15T10:00:00Z',
    'guncelleme_tarihi': '2025-03-01T08:30:00Z',
  };

  group('KasaBankaModel.fromJson', () {
    test('creates model from JSON correctly', () {
      final model = KasaBankaModel.fromJson(sampleJson);
      expect(model.id, 1);
      expect(model.ad, 'Ana Kasa');
      expect(model.tip, 'KASA');
      expect(model.bakiye, 15000.50);
      expect(model.dovizTuru, 'TRY');
      expect(model.durumu, 'AKTIF');
      expect(model.aciklama, 'Peşin işlemler');
    });

    test('handles missing optional fields', () {
      final model = KasaBankaModel.fromJson({
        'ad': 'Test',
        'tip': 'BANKA',
        'olusturma_tarihi': '2025-01-01T00:00:00Z',
        'guncelleme_tarihi': '2025-01-01T00:00:00Z',
      });
      expect(model.bankaAdi, isNull);
      expect(model.hesapNo, isNull);
      expect(model.iban, isNull);
      expect(model.bakiye, 0.0);
    });

    test('handles null ad defaults to empty string', () {
      final model = KasaBankaModel.fromJson({
        'olusturma_tarihi': '2025-01-01T00:00:00Z',
        'guncelleme_tarihi': '2025-01-01T00:00:00Z',
      });
      expect(model.ad, '');
      expect(model.tip, 'KASA');
    });
  });

  group('KasaBankaModel.toJson', () {
    test('serializes correctly', () {
      final model = KasaBankaModel.fromJson(sampleJson);
      final json = model.toJson();
      expect(json['ad'], 'Ana Kasa');
      expect(json['tip'], 'KASA');
      expect(json['bakiye'], 15000.50);
      expect(json['doviz_turu'], 'TRY');
    });

    test('omits null optional fields', () {
      final model = KasaBankaModel.fromJson(sampleJson);
      final json = model.toJson();
      expect(json.containsKey('banka_adi'), isFalse);
      expect(json.containsKey('hesap_no'), isFalse);
      expect(json.containsKey('iban'), isFalse);
    });

    test('includes id when present', () {
      final model = KasaBankaModel.fromJson(sampleJson);
      expect(model.toJson()['id'], 1);
    });
  });

  group('KasaBankaModel getters', () {
    test('tipText returns Turkish display name', () {
      expect(KasaBankaModel.fromJson({...sampleJson, 'tip': 'KASA'}).tipText, 'Kasa');
      expect(KasaBankaModel.fromJson({...sampleJson, 'tip': 'BANKA'}).tipText, 'Banka');
      expect(KasaBankaModel.fromJson({...sampleJson, 'tip': 'KREDI_KARTI'}).tipText, 'Kredi Kartı');
      expect(KasaBankaModel.fromJson({...sampleJson, 'tip': 'CEK_HESABI'}).tipText, 'Çek Hesabı');
    });

    test('tipColor returns correct colors', () {
      expect(KasaBankaModel.fromJson({...sampleJson, 'tip': 'KASA'}).tipColor, Colors.brown);
      expect(KasaBankaModel.fromJson({...sampleJson, 'tip': 'BANKA'}).tipColor, Colors.blue);
      expect(KasaBankaModel.fromJson({...sampleJson, 'tip': 'KREDI_KARTI'}).tipColor, Colors.purple);
    });

    test('aktif returns true when AKTIF', () {
      expect(KasaBankaModel.fromJson(sampleJson).aktif, isTrue);
    });

    test('aktif returns false when PASIF', () {
      expect(KasaBankaModel.fromJson({...sampleJson, 'durumu': 'PASIF'}).aktif, isFalse);
    });

    test('formattedBakiye includes currency', () {
      final model = KasaBankaModel.fromJson(sampleJson);
      expect(model.formattedBakiye, '15000.50 TRY');
    });

    test('hesapAdi returns ad', () {
      expect(KasaBankaModel.fromJson(sampleJson).hesapAdi, 'Ana Kasa');
    });
  });

  group('KasaBankaModel.toMap', () {
    test('toMap is alias for toJson', () {
      final model = KasaBankaModel.fromJson(sampleJson);
      expect(model.toMap(), model.toJson());
    });
  });
}
