import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/beden_models.dart';

void main() {
  group('BedenTanimi', () {
    test('fromMap creates instance correctly', () {
      final map = {
        'id': 1,
        'beden_kodu': 'M',
        'beden_adi': 'Medium',
        'sira_no': 2,
        'aktif': true,
      };

      final beden = BedenTanimi.fromMap(map);

      expect(beden.id, 1);
      expect(beden.bedenKodu, 'M');
      expect(beden.bedenAdi, 'Medium');
      expect(beden.siraNo, 2);
      expect(beden.aktif, isTrue);
    });

    test('fromMap handles null values with defaults', () {
      final map = <String, dynamic>{
        'id': null,
        'beden_kodu': null,
      };

      final beden = BedenTanimi.fromMap(map);

      expect(beden.id, 0);
      expect(beden.bedenKodu, '');
      expect(beden.bedenAdi, isNull);
      expect(beden.siraNo, 0);
      expect(beden.aktif, isTrue);
    });
  });

  group('ModelBedenDagilimi', () {
    test('fromMap creates instance correctly', () {
      final map = {
        'id': 10,
        'model_id': 'abc-123',
        'beden_kodu': 'L',
        'siparis_adedi': 500,
      };

      final dagilim = ModelBedenDagilimi.fromMap(map);

      expect(dagilim.id, 10);
      expect(dagilim.modelId, 'abc-123');
      expect(dagilim.bedenKodu, 'L');
      expect(dagilim.siparisAdedi, 500);
    });

    test('toMap returns correct data', () {
      final dagilim = ModelBedenDagilimi(
        modelId: 'test-id',
        bedenKodu: 'XL',
        siparisAdedi: 250,
      );

      final map = dagilim.toMap();

      expect(map['model_id'], 'test-id');
      expect(map['beden_kodu'], 'XL');
      expect(map['siparis_adedi'], 250);
    });
  });

  group('BedenUretimTakip', () {
    test('fromMap creates instance correctly', () {
      final map = {
        'id': 5,
        'atama_id': 100,
        'model_id': 'model-1',
        'beden_kodu': 'S',
        'hedef_adet': 1000,
        'uretilen_adet': 750,
        'kabul_edilen_adet': 700,
        'fire_adet': 50,
        'kayit_tarihi': '2025-06-01T10:00:00',
      };

      final takip = BedenUretimTakip.fromMap(map);

      expect(takip.id, 5);
      expect(takip.atamaId, 100);
      expect(takip.hedefAdet, 1000);
      expect(takip.uretilenAdet, 750);
      expect(takip.fireAdet, 50);
    });

    test('kalanAdet is calculated correctly', () {
      final takip = BedenUretimTakip(
        atamaId: 1,
        modelId: 'm1',
        bedenKodu: 'M',
        hedefAdet: 1000,
        uretilenAdet: 750,
      );

      expect(takip.kalanAdet, 250);
    });

    test('tamamlanmaOrani is calculated correctly', () {
      final takip = BedenUretimTakip(
        atamaId: 1,
        modelId: 'm1',
        bedenKodu: 'M',
        hedefAdet: 200,
        uretilenAdet: 100,
      );

      expect(takip.tamamlanmaOrani, 50.0);
    });

    test('tamamlanmaOrani returns 0 when hedefAdet is 0', () {
      final takip = BedenUretimTakip(
        atamaId: 1,
        modelId: 'm1',
        bedenKodu: 'M',
        hedefAdet: 0,
        uretilenAdet: 0,
      );

      expect(takip.tamamlanmaOrani, 0);
    });

    test('toMap returns correct data', () {
      final takip = BedenUretimTakip(
        atamaId: 5,
        modelId: 'model-x',
        bedenKodu: 'L',
        hedefAdet: 500,
        uretilenAdet: 300,
        kabulEdilenAdet: 280,
        fireAdet: 20,
      );

      final map = takip.toMap();

      expect(map['atama_id'], 5);
      expect(map['model_id'], 'model-x');
      expect(map['beden_kodu'], 'L');
      expect(map['hedef_adet'], 500);
      expect(map['uretilen_adet'], 300);
      expect(map['kabul_edilen_adet'], 280);
      expect(map['fire_adet'], 20);
    });
  });
}
