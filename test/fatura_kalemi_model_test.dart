import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/fatura_kalemi_model.dart';

void main() {
  group('FaturaKalemiModel', () {
    final sampleJson = {
      'kalem_id': 1,
      'fatura_id': 10,
      'sira_no': 1,
      'urun_kodu': 'PRD-001',
      'urun_adi': 'T-Shirt',
      'aciklama': 'Beyaz XL',
      'miktar': 100.0,
      'birim': 'adet',
      'birim_fiyat': 50.0,
      'iskonto': 10.0,
      'iskonto_tutar': 500.0,
      'kdv_orani': 20.0,
      'kdv_tutar': 900.0,
      'satir_tutar': 5400.0,
      'model_id': 5,
      'stok_id': 20,
      'olusturma_tarihi': '2025-06-15T00:00:00.000',
    };

    test('fromJson creates instance with all fields', () {
      final model = FaturaKalemiModel.fromJson(sampleJson);
      expect(model.kalemId, 1);
      expect(model.faturaId, 10);
      expect(model.urunAdi, 'T-Shirt');
      expect(model.miktar, 100.0);
      expect(model.birimFiyat, 50.0);
      expect(model.iskonto, 10.0);
      expect(model.kdvOrani, 20.0);
      expect(model.satirTutar, 5400.0);
      expect(model.modelId, 5);
    });

    test('fromJson uses defaults for missing fields', () {
      final minimal = {
        'urun_adi': 'X',
        'birim_fiyat': 10.0,
        'kdv_tutar': 2.0,
        'satir_tutar': 12.0,
      };
      final model = FaturaKalemiModel.fromJson(minimal);
      expect(model.faturaId, 0);
      expect(model.siraNo, 1);
      expect(model.birim, 'adet');
      expect(model.iskonto, 0.0);
      expect(model.kdvOrani, 20.0);
    });

    test('toJson produces correct keys', () {
      final model = FaturaKalemiModel.fromJson(sampleJson);
      final json = model.toJson();
      expect(json['kalem_id'], 1);
      expect(json['fatura_id'], 10);
      expect(json['urun_adi'], 'T-Shirt');
      expect(json['miktar'], 100.0);
    });

    test('toJson excludes null optional fields', () {
      final model = FaturaKalemiModel(
        faturaId: 1,
        siraNo: 1,
        urunAdi: 'Item',
        miktar: 1,
        birimFiyat: 10,
        kdvTutar: 2,
        satirTutar: 12,
        olusturmaTarihi: DateTime(2025, 1, 1),
      );
      final json = model.toJson();
      expect(json.containsKey('kalem_id'), isFalse);
      expect(json.containsKey('urun_kodu'), isFalse);
      expect(json.containsKey('model_id'), isFalse);
      expect(json.containsKey('stok_id'), isFalse);
    });

    test('hesaplaKdvHaricTutar calculates correctly', () {
      // 100 adet * 50 TL = 5000, %10 iskonto = 500, net = 4500
      final result = FaturaKalemiModel.hesaplaKdvHaricTutar(100, 50, 10);
      expect(result, 4500.0);
    });

    test('hesaplaKdvTutar calculates correctly', () {
      // 4500 * %20 = 900
      final result = FaturaKalemiModel.hesaplaKdvTutar(4500, 20);
      expect(result, 900.0);
    });

    test('hesaplaSatirTutar computes full total', () {
      // 100 * 50 = 5000, -10% = 4500, +20% KDV = 5400
      final result = FaturaKalemiModel.hesaplaSatirTutar(100, 50, 10, 20);
      expect(result, 5400.0);
    });

    test('getter araToplamTutar computes correctly', () {
      final model = FaturaKalemiModel.fromJson(sampleJson);
      // (100 * 50) - 500 = 4500
      expect(model.araToplamTutar, 4500.0);
    });

    test('formattedMiktar shows integer for whole numbers', () {
      final model = FaturaKalemiModel.fromJson({...sampleJson, 'miktar': 50.0});
      expect(model.formattedMiktar, '50');
    });

    test('formattedMiktar shows decimals for fractions', () {
      final model = FaturaKalemiModel.fromJson({...sampleJson, 'miktar': 50.5});
      expect(model.formattedMiktar, '50.50');
    });
  });
}
