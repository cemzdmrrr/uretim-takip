import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/fatura_model.dart';

void main() {
  group('FaturaModel', () {
    final now = DateTime(2025, 6, 15);
    final sampleJson = {
      'fatura_id': 1,
      'fatura_no': 'FTR-2025-001',
      'fatura_turu': 'satis',
      'fatura_tarihi': '2025-06-15T00:00:00.000',
      'musteri_id': 10,
      'tedarikci_id': null,
      'fatura_adres': 'İstanbul, Türkiye',
      'vergi_dairesi': 'Beyoğlu',
      'vergi_no': '1234567890',
      'ara_toplam_tutar': 1000.0,
      'kdv_tutari': 200.0,
      'toplam_tutar': 1200.0,
      'durum': 'onaylandi',
      'aciklama': 'Test fatura',
      'vade_tarihi': '2025-07-15T00:00:00.000',
      'odeme_durumu': 'odenmedi',
      'odenen_tutar': 0.0,
      'kur': 'TRY',
      'kur_orani': 1.0,
      'olusturma_tarihi': '2025-06-15T00:00:00.000',
      'olusturan_kullanici': 'admin',
    };

    test('fromJson creates instance with all fields', () {
      final model = FaturaModel.fromJson(sampleJson);
      expect(model.faturaId, 1);
      expect(model.faturaNo, 'FTR-2025-001');
      expect(model.faturaTuru, 'satis');
      expect(model.faturaTarihi, now);
      expect(model.musteriId, 10);
      expect(model.tedarikciId, isNull);
      expect(model.araToplamTutar, 1000.0);
      expect(model.kdvTutari, 200.0);
      expect(model.toplamTutar, 1200.0);
      expect(model.durum, 'onaylandi');
      expect(model.odemeDurumu, 'odenmedi');
      expect(model.kur, 'TRY');
    });

    test('fromJson uses defaults for missing fields', () {
      final minimal = {
        'fatura_no': 'F1',
        'fatura_adres': 'Addr',
        'olusturan_kullanici': 'u1',
      };
      final model = FaturaModel.fromJson(minimal);
      expect(model.faturaTuru, 'satis');
      expect(model.araToplamTutar, 0.0);
      expect(model.durum, 'taslak');
      expect(model.odemeDurumu, 'odenmedi');
      expect(model.kur, 'TRY');
      expect(model.kurOrani, 1.0);
    });

    test('toJson produces correct keys', () {
      final model = FaturaModel.fromJson(sampleJson);
      final json = model.toJson();
      expect(json['fatura_id'], 1);
      expect(json['fatura_no'], 'FTR-2025-001');
      expect(json['toplam_tutar'], 1200.0);
      expect(json['durum'], 'onaylandi');
      expect(json['olusturan_kullanici'], 'admin');
    });

    test('toJson excludes null optional fields', () {
      final model = FaturaModel(
        faturaNo: 'F1',
        faturaTuru: 'satis',
        faturaTarihi: now,
        faturaAdres: 'Addr',
        araToplamTutar: 100,
        kdvTutari: 20,
        toplamTutar: 120,
        olusturmaTarihi: now,
        olusturanKullanici: 'u1',
      );
      final json = model.toJson();
      expect(json.containsKey('fatura_id'), isFalse);
      expect(json.containsKey('musteri_id'), isFalse);
      expect(json.containsKey('tedarikci_id'), isFalse);
      expect(json.containsKey('aciklama'), isFalse);
      expect(json.containsKey('vade_tarihi'), isFalse);
    });

    test('toMap delegates to toJson', () {
      final model = FaturaModel.fromJson(sampleJson);
      expect(model.toMap(), model.toJson());
    });

    test('durumText returns localized status', () {
      expect(
        FaturaModel(
          faturaNo: 'F1', faturaTuru: 'satis', faturaTarihi: now,
          faturaAdres: '', araToplamTutar: 0, kdvTutari: 0, toplamTutar: 0,
          durum: 'taslak', olusturmaTarihi: now, olusturanKullanici: '',
        ).durumText,
        'Taslak',
      );
      expect(
        FaturaModel(
          faturaNo: 'F1', faturaTuru: 'satis', faturaTarihi: now,
          faturaAdres: '', araToplamTutar: 0, kdvTutari: 0, toplamTutar: 0,
          durum: 'onaylandi', olusturmaTarihi: now, olusturanKullanici: '',
        ).durumText,
        'Onaylandı',
      );
    });

    test('odemeDurumuText returns localized payment status', () {
      expect(
        FaturaModel(
          faturaNo: 'F1', faturaTuru: 'satis', faturaTarihi: now,
          faturaAdres: '', araToplamTutar: 0, kdvTutari: 0, toplamTutar: 0,
          odemeDurumu: 'odendi', olusturmaTarihi: now, olusturanKullanici: '',
        ).odemeDurumuText,
        'Ödendi',
      );
    });

    test('formattedTutar includes currency symbol', () {
      final model = FaturaModel.fromJson(sampleJson);
      expect(model.formattedTutar, '1200.00 TRY');
    });

    test('formattedTarih uses dd.MM.yyyy format', () {
      final model = FaturaModel.fromJson(sampleJson);
      expect(model.formattedTarih, '15.06.2025');
    });
  });
}
