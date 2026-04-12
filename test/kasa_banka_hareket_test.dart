import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/kasa_banka_hareket_model.dart';

void main() {
  final sampleJson = {
    'id': 'abc-123',
    'kasa_banka_id': 'kb-001',
    'hareket_tipi': 'giris',
    'tutar': 5000.75,
    'doviz_turu': 'TRY',
    'aciklama': 'Nakit tahsilat',
    'kategori': 'nakit_giris',
    'fatura_id': null,
    'hedef_kasa_banka_id': null,
    'referans_no': 'REF-2025-001',
    'islem_tarihi': '2025-06-15T14:30:00Z',
    'created_at': '2025-06-15T14:30:00Z',
    'created_by': 'user-001',
    'onaylanmis_mi': true,
    'onaylayan_kullanici': 'admin-001',
    'onaylama_tarihi': '2025-06-15T15:00:00Z',
    'notlar': 'Test notu',
  };

  group('KasaBankaHareket.fromJson', () {
    test('creates model from full JSON', () {
      final h = KasaBankaHareket.fromJson(sampleJson);
      expect(h.id, 'abc-123');
      expect(h.kasaBankaId, 'kb-001');
      expect(h.hareketTipi, 'giris');
      expect(h.tutar, 5000.75);
      expect(h.paraBirimi, 'TRY');
      expect(h.aciklama, 'Nakit tahsilat');
      expect(h.kategori, 'nakit_giris');
      expect(h.referansNo, 'REF-2025-001');
      expect(h.onaylanmisMi, isTrue);
      expect(h.onaylayanKullanici, 'admin-001');
      expect(h.notlar, 'Test notu');
    });

    test('handles missing optional fields', () {
      final h = KasaBankaHareket.fromJson({
        'id': 'x',
        'kasa_banka_id': 'y',
        'hareket_tipi': 'cikis',
        'tutar': 100,
        'islem_tarihi': '2025-01-01T00:00:00Z',
        'created_at': '2025-01-01T00:00:00Z',
      });
      expect(h.aciklama, isNull);
      expect(h.kategori, isNull);
      expect(h.faturaId, isNull);
      expect(h.transferKasaBankaId, isNull);
      expect(h.referansNo, isNull);
      expect(h.onaylanmisMi, isFalse);
      expect(h.paraBirimi, 'TRY');
    });

    test('converts tutar to double', () {
      final h = KasaBankaHareket.fromJson({
        ...sampleJson,
        'tutar': 100, // int, not double
      });
      expect(h.tutar, isA<double>());
      expect(h.tutar, 100.0);
    });
  });

  group('KasaBankaHareket.toJson', () {
    test('round-trips required fields', () {
      final h = KasaBankaHareket.fromJson(sampleJson);
      final json = h.toJson();
      expect(json['id'], 'abc-123');
      expect(json['kasa_banka_id'], 'kb-001');
      expect(json['hareket_tipi'], 'giris');
      expect(json['tutar'], 5000.75);
      expect(json['doviz_turu'], 'TRY');
    });

    test('does not include display-only fields', () {
      final h = KasaBankaHareket.fromJson({
        ...sampleJson,
        'kasa_banka_adi': 'Ana Kasa',
        'musteri_adi': 'Test Müşteri',
      });
      final json = h.toJson();
      expect(json.containsKey('kasa_banka_adi'), isFalse);
      expect(json.containsKey('musteri_adi'), isFalse);
    });
  });

  group('hareketTipiDisplay', () {
    test('giris maps to Giriş', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'giris'});
      expect(h.hareketTipiDisplay, 'Giriş');
    });

    test('cikis maps to Çıkış', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'cikis'});
      expect(h.hareketTipiDisplay, 'Çıkış');
    });

    test('transfer_giden maps to Transfer (Giden)', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'transfer_giden'});
      expect(h.hareketTipiDisplay, 'Transfer (Giden)');
    });

    test('transfer_gelen maps to Transfer (Gelen)', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'transfer_gelen'});
      expect(h.hareketTipiDisplay, 'Transfer (Gelen)');
    });

    test('unknown type returns raw value', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'bilinmeyen'});
      expect(h.hareketTipiDisplay, 'bilinmeyen');
    });
  });

  group('kategoriDisplay', () {
    test('fatura_odeme maps correctly', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'kategori': 'fatura_odeme'});
      expect(h.kategoriDisplay, 'Fatura Ödemesi');
    });

    test('nakit_giris maps correctly', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'kategori': 'nakit_giris'});
      expect(h.kategoriDisplay, 'Nakit Giriş');
    });

    test('bank_transfer maps correctly', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'kategori': 'bank_transfer'});
      expect(h.kategoriDisplay, 'Banka Transferi');
    });

    test('operasyonel maps correctly', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'kategori': 'operasyonel'});
      expect(h.kategoriDisplay, 'Operasyonel');
    });

    test('null returns Belirtilmemiş', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'kategori': null});
      expect(h.kategoriDisplay, 'Belirtilmemiş');
    });
  });

  group('isGiris / isCikis', () {
    test('giris is isGiris=true, isCikis=false', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'giris'});
      expect(h.isGiris, isTrue);
      expect(h.isCikis, isFalse);
    });

    test('cikis is isCikis=true, isGiris=false', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'cikis'});
      expect(h.isCikis, isTrue);
      expect(h.isGiris, isFalse);
    });

    test('transfer_gelen is isGiris=true', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'transfer_gelen'});
      expect(h.isGiris, isTrue);
      expect(h.isCikis, isFalse);
    });

    test('transfer_giden is isCikis=true', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'hareket_tipi': 'transfer_giden'});
      expect(h.isCikis, isTrue);
      expect(h.isGiris, isFalse);
    });
  });

  group('formattedTutar', () {
    test('TRY uses ₺ symbol', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'tutar': 1234.5, 'doviz_turu': 'TRY'});
      expect(h.formattedTutar, '1234.50 ₺');
    });

    test('USD uses \$ symbol', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'tutar': 99.0, 'doviz_turu': 'USD'});
      expect(h.formattedTutar, '99.00 \$');
    });

    test('EUR uses € symbol', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'tutar': 50.0, 'doviz_turu': 'EUR'});
      expect(h.formattedTutar, '50.00 €');
    });

    test('GBP uses £ symbol', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'tutar': 75.0, 'doviz_turu': 'GBP'});
      expect(h.formattedTutar, '75.00 £');
    });

    test('unknown currency uses raw code', () {
      final h = KasaBankaHareket.fromJson({...sampleJson, 'tutar': 10.0, 'doviz_turu': 'JPY'});
      expect(h.formattedTutar, '10.00 JPY');
    });
  });

  group('copyWith', () {
    test('copies with changed fields', () {
      final original = KasaBankaHareket.fromJson(sampleJson);
      final copy = original.copyWith(tutar: 9999.99, hareketTipi: 'cikis');
      expect(copy.tutar, 9999.99);
      expect(copy.hareketTipi, 'cikis');
      expect(copy.id, original.id); // unchanged
      expect(copy.kasaBankaId, original.kasaBankaId); // unchanged
    });
  });
}
