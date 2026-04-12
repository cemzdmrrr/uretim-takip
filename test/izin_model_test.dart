import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/izin_model.dart';

void main() {
  group('IzinModel', () {
    final sampleMap = {
      'id': 'izin-1',
      'user_id': 'user-abc',
      'izin_turu': 'yillik',
      'baslama_tarihi': '2025-07-01T00:00:00.000',
      'bitis_tarihi': '2025-07-05T00:00:00.000',
      'aciklama': 'Tatil',
      'onay_durumu': 'onaylandi',
      'onaylayan_user_id': 'admin-1',
      'gun_sayisi': 5,
    };

    test('fromMap creates instance with all fields', () {
      final model = IzinModel.fromMap(sampleMap);
      expect(model.id, 'izin-1');
      expect(model.personelId, 'user-abc');
      expect(model.userId, 'user-abc');
      expect(model.izinTuru, 'yillik');
      expect(model.baslangic, DateTime(2025, 7, 1));
      expect(model.bitis, DateTime(2025, 7, 5));
      expect(model.aciklama, 'Tatil');
      expect(model.onayDurumu, 'onaylandi');
      expect(model.onaylayanId, 'admin-1');
      expect(model.gunSayisi, 5);
    });

    test('fromJson delegates to fromMap', () {
      final model = IzinModel.fromJson(sampleMap);
      expect(model.izinTuru, 'yillik');
      expect(model.gunSayisi, 5);
    });

    test('fromMap handles string gun_sayisi', () {
      final map = {...sampleMap, 'gun_sayisi': '3'};
      final model = IzinModel.fromMap(map);
      expect(model.gunSayisi, 3);
    });

    test('fromMap uses bitis fallback for bitis_tarihi', () {
      final map = Map<String, dynamic>.from(sampleMap);
      map.remove('bitis_tarihi');
      map['bitis'] = '2025-07-10T00:00:00.000';
      final model = IzinModel.fromMap(map);
      expect(model.bitis, DateTime(2025, 7, 10));
    });

    test('fromMap uses defaults for missing optional fields', () {
      final minimal = {
        'user_id': 'u1',
        'izin_turu': 'hastalik',
        'baslama_tarihi': '2025-01-01T00:00:00.000',
        'bitis_tarihi': '2025-01-02T00:00:00.000',
      };
      final model = IzinModel.fromMap(minimal);
      expect(model.aciklama, '');
      expect(model.onayDurumu, 'beklemede');
      expect(model.onaylayanId, isNull);
      expect(model.gunSayisi, 0);
    });

    test('toMap produces correct keys', () {
      final model = IzinModel.fromMap(sampleMap);
      final map = model.toMap();
      expect(map['user_id'], 'user-abc');
      expect(map['izin_turu'], 'yillik');
      expect(map['baslama_tarihi'], isNotNull);
      expect(map['bitis_tarihi'], isNotNull);
      expect(map['gun_sayisi'], 5);
      expect(map['onaylayan_user_id'], 'admin-1');
    });

    test('toMap excludes onaylayan_user_id when null', () {
      final model = IzinModel(
        personelId: 'u1',
        izinTuru: 'yillik',
        baslangic: DateTime(2025, 1, 1),
        bitis: DateTime(2025, 1, 5),
        aciklama: '',
        onayDurumu: 'beklemede',
        gunSayisi: 5,
      );
      final map = model.toMap();
      expect(map.containsKey('onaylayan_user_id'), isFalse);
    });

    test('toJson delegates to toMap', () {
      final model = IzinModel.fromMap(sampleMap);
      expect(model.toJson(), model.toMap());
    });
  });
}
