import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/puantaj_model.dart';

void main() {
  group('PuantajModel', () {
    final sampleMap = {
      'id': 42,
      'user_id': 'user-a',
      'ad': 'Mehmet',
      'ay': 6,
      'yil': 2025,
      'gun': 22,
      'calisma_saati': 176,
      'fazla_mesai': 12,
      'eksik_gun': 1,
      'devamsizlik': 0,
    };

    test('fromMap creates instance with all fields', () {
      final model = PuantajModel.fromMap(sampleMap);
      expect(model.id, '42');
      expect(model.personelId, 'user-a');
      expect(model.ad, 'Mehmet');
      expect(model.ay, 6);
      expect(model.yil, 2025);
      expect(model.gun, 22);
      expect(model.calismaSaati, 176);
      expect(model.fazlaMesai, 12);
      expect(model.eksikGun, 1);
      expect(model.devamsizlik, 0);
    });

    test('fromJson delegates to fromMap', () {
      final model = PuantajModel.fromJson(sampleMap);
      expect(model.personelId, 'user-a');
      expect(model.ay, 6);
    });

    test('fromMap parses string numbers', () {
      final stringMap = {
        'id': 'abc',
        'user_id': 'u1',
        'ad': 'Test',
        'ay': '3',
        'yil': '2024',
        'gun': '20',
        'calisma_saati': '160',
        'fazla_mesai': '5',
        'eksik_gun': '2',
        'devamsizlik': '1',
      };
      final model = PuantajModel.fromMap(stringMap);
      expect(model.ay, 3);
      expect(model.yil, 2024);
      expect(model.gun, 20);
      expect(model.calismaSaati, 160);
    });

    test('fromMap defaults missing values to 0', () {
      final minimal = {'id': '1', 'user_id': 'u', 'ad': 'A'};
      final model = PuantajModel.fromMap(minimal);
      expect(model.ay, 0);
      expect(model.gun, 0);
      expect(model.devamsizlik, 0);
    });

    test('toMap with sendId true includes id', () {
      final model = PuantajModel.fromMap(sampleMap);
      final map = model.toMap(sendId: true);
      expect(map.containsKey('id'), isTrue);
      expect(map['id'], '42');
    });

    test('toMap with sendId false excludes id', () {
      final model = PuantajModel.fromMap(sampleMap);
      final map = model.toMap(sendId: false);
      expect(map.containsKey('id'), isFalse);
    });

    test('toJson delegates to toMap', () {
      final model = PuantajModel.fromMap(sampleMap);
      expect(model.toJson(), model.toMap());
    });

    test('toMap excludes id when id is empty', () {
      final map = {...sampleMap, 'id': ''};
      final model = PuantajModel.fromMap(map);
      final result = model.toMap(sendId: true);
      expect(result.containsKey('id'), isFalse);
    });
  });
}
