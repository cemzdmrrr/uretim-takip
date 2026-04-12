import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/config/database_tables.dart';

void main() {
  group('DbTables', () {
    test('core table names are correct', () {
      expect(DbTables.modeller, 'modeller');
      expect(DbTables.tedarikciler, 'tedarikciler');
      expect(DbTables.bildirimler, 'bildirimler');
      expect(DbTables.faturalar, 'faturalar');
    });

    test('atama table names follow convention', () {
      expect(DbTables.dokumaAtamalari, 'dokuma_atamalari');
      expect(DbTables.konfeksiyonAtamalari, 'konfeksiyon_atamalari');
      expect(DbTables.yikamaAtamalari, 'yikama_atamalari');
      expect(DbTables.utuAtamalari, 'utu_atamalari');
      expect(DbTables.paketlemeAtamalari, 'paketleme_atamalari');
      expect(DbTables.ilikDugmeAtamalari, 'ilik_dugme_atamalari');
      expect(DbTables.nakisAtamalari, 'nakis_atamalari');
      expect(DbTables.kaliteKontrolAtamalari, 'kalite_kontrol_atamalari');
    });

    test('tracking and record tables', () {
      expect(DbTables.trikoTakip, 'triko_takip');
      expect(DbTables.sevkiyatKayitlari, 'sevkiyat_kayitlari');
      expect(DbTables.yuklemeKayitlari, 'yukleme_kayitlari');
    });

    test('stok and siparis tables', () {
      expect(DbTables.iplikStoklari, 'iplik_stoklari');
      expect(DbTables.iplikSiparisleri, 'iplik_siparisleri');
    });

    test('user and role tables', () {
      expect(DbTables.userRoles, 'user_roles');
      expect(DbTables.firmaKullanicilari, 'firma_kullanicilari');
    });
  });

  group('DbTables - Multi-Tenant & SaaS', () {
    test('firma tabloları doğru', () {
      expect(DbTables.firmalar, 'firmalar');
      expect(DbTables.firmaAyarlari, 'firma_ayarlari');
      expect(DbTables.kullaniciAktifFirma, 'kullanici_aktif_firma');
      expect(DbTables.firmaDavetleri, 'firma_davetleri');
    });

    test('modül tabloları doğru', () {
      expect(DbTables.modulTanimlari, 'modul_tanimlari');
      expect(DbTables.uretimModulleri, 'uretim_modulleri');
      expect(DbTables.firmaModulleri, 'firma_modulleri');
      expect(DbTables.firmaUretimModulleri, 'firma_uretim_modulleri');
    });

    test('abonelik tabloları doğru', () {
      expect(DbTables.abonelikPlanlari, 'abonelik_planlari');
      expect(DbTables.firmaAbonelikleri, 'firma_abonelikleri');
      expect(DbTables.abonelikOdemeleri, 'abonelik_odemeleri');
    });

    test('yetki tablosu doğru', () {
      expect(DbTables.yetkiTanimlari, 'yetki_tanimlari');
    });
  });

  group('DbTables - Genel Üretim (Phase 8)', () {
    test('üretim genelleştirme tabloları doğru', () {
      expect(DbTables.uretimAtamalari, 'uretim_atamalari');
      expect(DbTables.dalFormAlanlari, 'dal_form_alanlari');
      expect(DbTables.asamaTanimlari, 'asama_tanimlari');
    });
  });

  group('DbTables - Platform Admin (Phase 9)', () {
    test('platform admin tabloları doğru', () {
      expect(DbTables.destekTalepleri, 'destek_talepleri');
      expect(DbTables.platformLoglari, 'platform_loglari');
      expect(DbTables.platformDuyurulari, 'platform_duyurulari');
    });
  });

  group('DbTables - Migrasyon (Phase 10)', () {
    test('migrasyon tablosu doğru', () {
      expect(DbTables.migrasyonDurumu, 'migrasyon_durumu');
    });
  });
}
