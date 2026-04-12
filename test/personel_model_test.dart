import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/personel_model.dart';

void main() {
  group('PersonelModel', () {
    final sampleMap = {
      'user_id': 'abc-123',
      'ad': 'Ali',
      'soyad': 'Yılmaz',
      'tckn': '12345678901',
      'pozisyon': 'Usta',
      'departman': 'Üretim',
      'email': 'ali@test.com',
      'telefon': '5551234567',
      'ise_baslangic': '2024-01-15',
      'brut_maas': 30000,
      'sgk_sicil_no': 'SGK123',
      'gunluk_calisma_saati': 8,
      'haftalik_calisma_gunu': 5,
      'yol_ucreti': 500,
      'yemek_ucreti': 400,
      'ekstra_prim': 1000,
      'elden_maas': 0,
      'banka_maas': 25000,
      'adres': 'İstanbul',
      'net_maas': 25000,
      'yillik_izin_hakki': 14,
    };

    test('fromMap creates instance with all fields', () {
      final model = PersonelModel.fromMap(sampleMap);
      expect(model.userId, 'abc-123');
      expect(model.ad, 'Ali');
      expect(model.soyad, 'Yılmaz');
      expect(model.tckn, '12345678901');
      expect(model.pozisyon, 'Usta');
      expect(model.departman, 'Üretim');
      expect(model.email, 'ali@test.com');
      expect(model.telefon, '5551234567');
      expect(model.brutMaas, '30000');
      expect(model.yillikIzinHakki, '14');
    });

    test('fromJson delegates to fromMap', () {
      final model = PersonelModel.fromJson(sampleMap);
      expect(model.userId, 'abc-123');
      expect(model.ad, 'Ali');
    });

    test('fromMap handles legacy id field', () {
      final map = {...sampleMap};
      map.remove('user_id');
      map['id'] = 999;
      final model = PersonelModel.fromMap(map);
      expect(model.userId, '999');
    });

    test('fromMap handles legacy tc_kimlik_no field', () {
      final map = {...sampleMap};
      map.remove('tckn');
      map['tc_kimlik_no'] = '99988877766';
      final model = PersonelModel.fromMap(map);
      expect(model.tckn, '99988877766');
    });

    test('fromMap uses defaults for missing optional fields', () {
      final minimal = {
        'user_id': 'u1',
        'ad': 'Test',
        'soyad': 'User',
        'tckn': '111',
        'pozisyon': 'Dev',
        'departman': 'IT',
        'email': 'test@t.com',
        'telefon': '555',
      };
      final model = PersonelModel.fromMap(minimal);
      expect(model.iseBaslangic, '');
      expect(model.brutMaas, '');
      expect(model.yillikIzinHakki, '14');
    });

    test('toMap produces correct keys', () {
      final model = PersonelModel.fromMap(sampleMap);
      final map = model.toMap();
      expect(map['user_id'], 'abc-123');
      expect(map['ad'], 'Ali');
      expect(map['soyad'], 'Yılmaz');
      expect(map['tckn'], '12345678901');
      expect(map['brut_maas'], '30000');
    });

    test('toJson delegates to toMap', () {
      final model = PersonelModel.fromMap(sampleMap);
      expect(model.toJson(), model.toMap());
    });

    test('round-trip fromMap/toMap preserves data', () {
      final model = PersonelModel.fromMap(sampleMap);
      final map = model.toMap();
      final restored = PersonelModel.fromMap(map);
      expect(restored.userId, model.userId);
      expect(restored.ad, model.ad);
      expect(restored.email, model.email);
    });
  });
}
