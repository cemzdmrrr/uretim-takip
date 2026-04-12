import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/mesai_model.dart';

void main() {
  group('MesaiModel', () {
    final sampleMap = {
      'id': 'mesai-1',
      'user_id': 'user-abc',
      'tarih': '2025-06-15',
      'baslangic_saati': '18:00',
      'bitis_saati': '22:00',
      'mesai_turu': 'normal',
      'onay_durumu': 'onaylandi',
      'saat': 4.0,
      'onaylayan_user_id': 'admin-1',
      'mesai_ucret': 250.0,
      'yemek_ucreti': 75.0,
      'carpan': 1.5,
    };

    test('fromMap creates instance with all fields', () {
      final model = MesaiModel.fromMap(sampleMap);
      expect(model.id, 'mesai-1');
      expect(model.personelId, 'user-abc');
      expect(model.userId, 'user-abc');
      expect(model.tarih, DateTime(2025, 6, 15));
      expect(model.baslangicSaati, '18:00');
      expect(model.bitisSaati, '22:00');
      expect(model.mesaiTuru, 'normal');
      expect(model.onayDurumu, 'onaylandi');
      expect(model.saat, 4.0);
      expect(model.onaylayanId, 'admin-1');
      expect(model.mesaiUcret, 250.0);
      expect(model.yemekUcreti, 75.0);
      expect(model.carpan, 1.5);
    });

    test('fromJson delegates to fromMap', () {
      final model = MesaiModel.fromJson(sampleMap);
      expect(model.personelId, 'user-abc');
      expect(model.mesaiTuru, 'normal');
    });

    test('fromMap handles string numeric values', () {
      final map = {
        ...sampleMap,
        'saat': '3.5',
        'mesai_ucret': '200',
        'carpan': '2',
      };
      final model = MesaiModel.fromMap(map);
      expect(model.saat, 3.5);
      expect(model.mesaiUcret, 200.0);
      expect(model.carpan, 2.0);
    });

    test('fromMap uses defaults for missing optional fields', () {
      final minimal = {
        'user_id': 'u1',
        'tarih': '2025-01-01',
        'baslangic_saati': '08:00',
        'bitis_saati': '17:00',
        'mesai_turu': 'normal',
        'onay_durumu': 'beklemede',
      };
      final model = MesaiModel.fromMap(minimal);
      expect(model.saat, isNull);
      expect(model.onaylayanId, isNull);
      expect(model.mesaiUcret, isNull);
      expect(model.carpan, isNull);
    });

    test('toMap produces correct fields', () {
      final model = MesaiModel.fromMap(sampleMap);
      final map = model.toMap();
      expect(map['user_id'], 'user-abc');
      expect(map['mesai_turu'], 'normal');
      expect(map['mesai_ucret'], 250.0);
      expect(map['onaylayan_user_id'], 'admin-1');
      expect(map.containsKey('saat'), isTrue);
    });

    test('toMap excludes onaylayan_user_id when null', () {
      final model = MesaiModel(
        personelId: 'u1',
        tarih: DateTime(2025, 1, 1),
        baslangicSaati: '08:00',
        bitisSaati: '17:00',
        mesaiTuru: 'normal',
        onayDurumu: 'beklemede',
      );
      final map = model.toMap();
      expect(map.containsKey('onaylayan_user_id'), isFalse);
    });

    test('toJson delegates to toMap', () {
      final model = MesaiModel.fromMap(sampleMap);
      expect(model.toJson(), model.toMap());
    });
  });
}
