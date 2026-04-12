import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/tedarikci_model.dart';

void main() {
  group('TedarikciModel Tests', () {
    test('should create TedarikciModel from JSON correctly', () {
      // Test data that matches our simplified database schema
      final jsonData = {
        'id': 1,
        'ad': 'Test',
        'soyad': 'Tedarikçi',
        'sirket': 'Test Şirket A.Ş.',
        'telefon': '0212 123 4567',
        'email': 'test@example.com',
        'tedarikci_tipi': 'Üretici',
        'faaliyet': 'Tekstil',
        'durum': 'aktif',
        'vergi_no': '1234567890',
        'tc_kimlik': '12345678901',
        'iban_no': 'TR33 0006 1005 1978 6457 8413 26',
        'kayit_tarihi': '2025-01-27T10:00:00.000Z',
        'guncelleme_tarihi': null,
      };

      // Create TedarikciModel from JSON
      final tedarikci = TedarikciModel.fromJson(jsonData);

      // Verify all fields are correctly mapped
      expect(tedarikci.id, equals(1));
      expect(tedarikci.ad, equals('Test'));
      expect(tedarikci.soyad, equals('Tedarikçi'));
      expect(tedarikci.sirket, equals('Test Şirket A.Ş.'));
      expect(tedarikci.telefon, equals('0212 123 4567'));
      expect(tedarikci.email, equals('test@example.com'));
      expect(tedarikci.tedarikciTipi, equals('Üretici'));
      expect(tedarikci.faaliyet, equals('Tekstil'));
      expect(tedarikci.durum, equals('aktif'));
      expect(tedarikci.vergiNo, equals('1234567890'));
      expect(tedarikci.tcKimlik, equals('12345678901'));
      expect(tedarikci.ibanNo, equals('TR33 0006 1005 1978 6457 8413 26'));
      expect(tedarikci.guncellemeTarihi, isNull);
    });

    test('should convert TedarikciModel to JSON correctly', () {
      // Create TedarikciModel instance
      final tedarikci = TedarikciModel(
        id: 1,
        ad: 'Test',
        soyad: 'Tedarikçi',
        sirket: 'Test Şirket A.Ş.',
        telefon: '0212 123 4567',
        email: 'test@example.com',
        tedarikciTipi: 'Üretici',
        faaliyet: 'Tekstil',
        durum: 'aktif',
        vergiNo: '1234567890',
        tcKimlik: '12345678901',
        ibanNo: 'TR33 0006 1005 1978 6457 8413 26',
        kayitTarihi: DateTime.parse('2025-01-27T10:00:00.000Z'),
        guncellemeTarihi: null,
      );

      // Convert to JSON
      final json = tedarikci.toJson();

      // Verify all database column names are correctly mapped
      expect(json['id'], equals(1));
      expect(json['ad'], equals('Test'));
      expect(json['soyad'], equals('Tedarikçi'));
      expect(json['sirket'], equals('Test Şirket A.Ş.'));
      expect(json['telefon'], equals('0212 123 4567'));
      expect(json['email'], equals('test@example.com'));
      expect(json['tedarikci_tipi'], equals('Üretici'));
      expect(json['faaliyet'], equals('Tekstil'));
      expect(json['durum'], equals('aktif'));
      expect(json['vergi_no'], equals('1234567890'));
      expect(json['tc_kimlik'], equals('12345678901'));
      expect(json['iban_no'], equals('TR33 0006 1005 1978 6457 8413 26'));
      expect(json['kayit_tarihi'], equals('2025-01-27T10:00:00.000Z'));
      expect(json['guncelleme_tarihi'], isNull);
    });

    test('should handle nullable fields correctly', () {
      final jsonData = {
        'id': 1,
        'ad': 'Test Ad',
        'telefon': '0212 123 4567',
        'tedarikci_tipi': 'Üretici',
        'durum': 'aktif',
        'kayit_tarihi': '2025-01-27T10:00:00.000Z',
      };

      final tedarikci = TedarikciModel.fromJson(jsonData);

      expect(tedarikci.soyad, isNull);
      expect(tedarikci.sirket, isNull);
      expect(tedarikci.email, isNull);
      expect(tedarikci.faaliyet, isNull);
      expect(tedarikci.vergiNo, isNull);
      expect(tedarikci.tcKimlik, isNull);
      expect(tedarikci.ibanNo, isNull);
      expect(tedarikci.guncellemeTarihi, isNull);
    });

    test('should provide correct display name', () {
      // Test with company name
      final tedarikciWithCompany = TedarikciModel(
        ad: 'John',
        soyad: 'Doe',
        sirket: 'Test Company',
        telefon: '123456789',
        tedarikciTipi: 'Üretici',
        durum: 'aktif',
        kayitTarihi: DateTime.now(),
      );

      expect(tedarikciWithCompany.goruntulemeAdi, equals('Test Company'));

      // Test without company name
      final tedarikciWithoutCompany = TedarikciModel(
        ad: 'John',
        soyad: 'Doe',
        telefon: '123456789',
        tedarikciTipi: 'Üretici',
        durum: 'aktif',
        kayitTarihi: DateTime.now(),
      );

      expect(tedarikciWithoutCompany.goruntulemeAdi, equals('John Doe'));

      // Test without surname
      final tedarikciWithoutSurname = TedarikciModel(
        ad: 'John',
        telefon: '123456789',
        tedarikciTipi: 'Üretici',
        durum: 'aktif',
        kayitTarihi: DateTime.now(),
      );

      expect(tedarikciWithoutSurname.goruntulemeAdi, equals('John'));
    });

    test('should handle null values correctly', () {
      final tedarikci = TedarikciModel(
        ad: 'Test Tedarikçi',
        telefon: '0212 123 4567',
        tedarikciTipi: 'Üretici',
        durum: 'aktif',
        kayitTarihi: DateTime.now(),
      );

      final json = tedarikci.toJson();

      // Null fields should be properly handled
      expect(json['soyad'], isNull);
      expect(json['sirket'], isNull);
      expect(json['email'], isNull);
      expect(json['faaliyet'], isNull);
      expect(json['vergi_no'], isNull);
      expect(json['tc_kimlik'], isNull);
      expect(json['iban_no'], isNull);
      expect(json['guncelleme_tarihi'], isNull);
    });
  });
}
