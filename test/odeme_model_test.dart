import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/odeme_model.dart';

void main() {
  group('OdemeModel', () {
    final now = DateTime(2025, 6, 15, 10, 30);
    final sampleMap = {
      'id': 1,
      'user_id': 'user-abc',
      'odeme_turu': 'prim',
      'tutar': 5000.50,
      'aciklama': 'Performans primi',
      'odeme_tarihi': '2025-06-15T10:30:00.000',
      'durum': 'onaylandi',
      'onaylayan_user_id': 'admin-xyz',
    };

    test('fromMap creates instance with all fields', () {
      final model = OdemeModel.fromMap(sampleMap);
      expect(model.id, 1);
      expect(model.userId, 'user-abc');
      expect(model.personelId, 'user-abc'); // mirrors userId
      expect(model.tur, 'prim');
      expect(model.tutar, 5000.50);
      expect(model.aciklama, 'Performans primi');
      expect(model.durum, 'onaylandi');
      expect(model.onaylayanId, 'admin-xyz');
    });

    test('fromJson delegates to fromMap', () {
      final model = OdemeModel.fromJson(sampleMap);
      expect(model.userId, 'user-abc');
      expect(model.tur, 'prim');
    });

    test('fromMap uses defaults for missing fields', () {
      final minimal = {
        'user_id': 'u1',
        'tutar': 100,
        'odeme_tarihi': '2025-01-01T00:00:00.000',
      };
      final model = OdemeModel.fromMap(minimal);
      expect(model.tur, 'avans');
      expect(model.aciklama, '');
      expect(model.durum, 'beklemede');
      expect(model.onaylayanId, isNull);
    });

    test('toMap produces correct keys with personelId priority', () {
      final model = OdemeModel(
        personelId: 'personel-1',
        userId: 'user-2',
        tutar: 1000.0,
        tarih: now,
      );
      final map = model.toMap();
      // personelId is prioritized for user_id
      expect(map['user_id'], 'personel-1');
      expect(map['odeme_turu'], 'avans');
      expect(map['tutar'], 1000.0);
      expect(map['durum'], 'beklemede');
    });

    test('toJson delegates to toMap', () {
      final model = OdemeModel.fromMap(sampleMap);
      expect(model.toJson(), model.toMap());
    });

    test('copyWith creates modified copy', () {
      final model = OdemeModel.fromMap(sampleMap);
      final copy = model.copyWith(tutar: 9999.0, durum: 'red');
      expect(copy.tutar, 9999.0);
      expect(copy.durum, 'red');
      expect(copy.tur, model.tur); // unchanged
      expect(copy.userId, model.userId); // unchanged
    });

    test('toMap falls back to userId when personelId is empty', () {
      final model = OdemeModel(
        personelId: '',
        userId: 'fallback-user',
        tutar: 500.0,
        tarih: now,
      );
      final map = model.toMap();
      expect(map['user_id'], 'fallback-user');
    });
  });
}
