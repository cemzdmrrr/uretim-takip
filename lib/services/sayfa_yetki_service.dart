import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Tüm sayfaların kayıt defteri — sayfa kodu → etiket + ikon + kategori
class SayfaTanimi {
  final String kod;
  final String etiket;
  final IconData ikon;
  final String kategori;

  const SayfaTanimi({
    required this.kod,
    required this.etiket,
    required this.ikon,
    required this.kategori,
  });
}

class SayfaRegistry {
  SayfaRegistry._();

  static const String katUretimPanelleri = 'Üretim Panelleri';
  static const String katUretimStok = 'Üretim & Stok';
  static const String katRaporlar = 'Raporlar & Analiz';
  static const String katFinans = 'Finansal Yönetim';
  static const String katIK = 'İnsan Kaynakları';
  static const String katKullaniciYetki = 'Kullanıcı & Yetki';
  static const String katAbonelik = 'Abonelik & Plan';
  static const String katPlatform = 'Platform Yönetimi';

  static const List<SayfaTanimi> tumSayfalar = [
    // Üretim Panelleri
    SayfaTanimi(kod: 'genel_uretim', etiket: 'Genel Üretim', ikon: Icons.dashboard_customize_rounded, kategori: katUretimPanelleri),
    SayfaTanimi(kod: 'dokuma', etiket: 'Dokuma', ikon: Icons.design_services, kategori: katUretimPanelleri),
    SayfaTanimi(kod: 'konfeksiyon', etiket: 'Konfeksiyon', ikon: Icons.checkroom, kategori: katUretimPanelleri),
    SayfaTanimi(kod: 'yikama', etiket: 'Yıkama', ikon: Icons.local_laundry_service, kategori: katUretimPanelleri),
    SayfaTanimi(kod: 'utu_paket', etiket: 'Ütü Paket', ikon: Icons.inventory_2, kategori: katUretimPanelleri),
    SayfaTanimi(kod: 'ilik_dugme', etiket: 'İlik Düğme', ikon: Icons.radio_button_checked, kategori: katUretimPanelleri),
    SayfaTanimi(kod: 'kalite_kontrol', etiket: 'Kalite Kontrol', ikon: Icons.verified, kategori: katUretimPanelleri),
    SayfaTanimi(kod: 'sevkiyat', etiket: 'Sevkiyat', ikon: Icons.local_shipping, kategori: katUretimPanelleri),

    // Üretim & Stok
    SayfaTanimi(kod: 'yeni_model_ekle', etiket: 'Yeni Model Ekle', ikon: Icons.add_box_rounded, kategori: katUretimStok),
    SayfaTanimi(kod: 'toplu_model_ekle', etiket: 'Toplu Model Ekle', ikon: Icons.upload_file_rounded, kategori: katUretimStok),
    SayfaTanimi(kod: 'kayitli_modeller', etiket: 'Kayıtlı Modeller', ikon: Icons.inventory_2_rounded, kategori: katUretimStok),
    SayfaTanimi(kod: 'tamamlanan_siparisler', etiket: 'Tamamlanan Siparişler', ikon: Icons.check_circle_rounded, kategori: katUretimStok),
    SayfaTanimi(kod: 'depo_yonetimi', etiket: 'Depo Yönetimi', ikon: Icons.warehouse_rounded, kategori: katUretimStok),

    // Raporlar & Analiz
    SayfaTanimi(kod: 'uretim_raporu', etiket: 'Üretim Raporu', ikon: Icons.assessment_rounded, kategori: katRaporlar),
    SayfaTanimi(kod: 'gelismis_raporlar', etiket: 'Gelişmiş Raporlar', ikon: Icons.analytics_rounded, kategori: katRaporlar),

    // Finansal Yönetim
    SayfaTanimi(kod: 'tedarikci_yonetimi', etiket: 'Tedarikçi Yönetimi', ikon: Icons.business_rounded, kategori: katFinans),
    SayfaTanimi(kod: 'faturalar', etiket: 'Faturalar', ikon: Icons.receipt_long_rounded, kategori: katFinans),
    SayfaTanimi(kod: 'kasa_banka', etiket: 'Kasa & Banka', ikon: Icons.account_balance_wallet_rounded, kategori: katFinans),
    SayfaTanimi(kod: 'kasa_banka_hareketleri', etiket: 'Kasa/Banka Hareketleri', ikon: Icons.swap_horiz_rounded, kategori: katFinans),
    SayfaTanimi(kod: 'dosya_yonetimi', etiket: 'Dosya Yönetimi', ikon: Icons.folder_rounded, kategori: katFinans),

    // İnsan Kaynakları
    SayfaTanimi(kod: 'personel_yonetimi', etiket: 'Personel Yönetimi', ikon: Icons.badge_rounded, kategori: katIK),
    SayfaTanimi(kod: 'kullanici_listesi', etiket: 'Kullanıcı Listesi', ikon: Icons.supervisor_account_rounded, kategori: katIK),

    // Kullanıcı & Yetki
    SayfaTanimi(kod: 'firma_kullanicilari', etiket: 'Firma Kullanıcıları', ikon: Icons.people_alt_rounded, kategori: katKullaniciYetki),
    SayfaTanimi(kod: 'rol_yetki_yonetimi', etiket: 'Rol & Yetki Yönetimi', ikon: Icons.security_rounded, kategori: katKullaniciYetki),
    SayfaTanimi(kod: 'sayfa_yetki_yonetimi', etiket: 'Sayfa Yetki Yönetimi', ikon: Icons.lock_open_rounded, kategori: katKullaniciYetki),

    // Abonelik & Plan
    SayfaTanimi(kod: 'abonelik_yonetimi', etiket: 'Abonelik Yönetimi', ikon: Icons.card_membership_rounded, kategori: katAbonelik),
    SayfaTanimi(kod: 'plan_degistir', etiket: 'Plan Değiştir', ikon: Icons.swap_vert_circle_rounded, kategori: katAbonelik),

    // Platform Yönetimi
    SayfaTanimi(kod: 'platform_paneli', etiket: 'Platform Paneli', ikon: Icons.admin_panel_settings_rounded, kategori: katPlatform),
    SayfaTanimi(kod: 'migrasyon_durumu', etiket: 'Migrasyon Durumu', ikon: Icons.sync_alt_rounded, kategori: katPlatform),
  ];

  static SayfaTanimi? bul(String kod) {
    try {
      return tumSayfalar.firstWhere((s) => s.kod == kod);
    } catch (_) {
      return null;
    }
  }

  static List<SayfaTanimi> kategoriyeGore(String kategori) {
    return tumSayfalar.where((s) => s.kategori == kategori).toList();
  }

  static List<String> get tumKategoriler {
    return tumSayfalar.map((s) => s.kategori).toSet().toList();
  }
}

/// Kullanıcı bazlı sayfa yetki servisi
class SayfaYetkiService {
  static final _client = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  /// Belirli kullanıcının erişebildiği sayfa kodlarını getirir
  static Future<Set<String>> kullaniciYetkileriniGetir(String userId) async {
    try {
      final response = await _client
          .from(DbTables.kullaniciSayfaYetkileri)
          .select('sayfa_kodu')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .eq('aktif', true);

      return (response as List).map((r) => r['sayfa_kodu'] as String).toSet();
    } catch (e) {
      // Tablo yoksa veya hata varsa boş set döndür
      return {};
    }
  }

  /// Kullanıcı belirli sayfaya erişebilir mi?
  static Future<bool> sayfaErisimKontrol(String userId, String sayfaKodu) async {
    final yetkiler = await kullaniciYetkileriniGetir(userId);
    return yetkiler.contains(sayfaKodu);
  }

  /// Kullanıcının tüm sayfa yetkilerini kaydet (upsert)
  static Future<void> yetkileriKaydet(String userId, Set<String> sayfaKodlari) async {
    // Önce mevcut kayıtları sil
    await _client
        .from(DbTables.kullaniciSayfaYetkileri)
        .delete()
        .eq('firma_id', _firmaId)
        .eq('user_id', userId);

    // Yeni kayıtları ekle
    if (sayfaKodlari.isNotEmpty) {
      final rows = sayfaKodlari.map((kod) => {
        'firma_id': _firmaId,
        'user_id': userId,
        'sayfa_kodu': kod,
        'aktif': true,
      }).toList();

      await _client.from(DbTables.kullaniciSayfaYetkileri).insert(rows);
    }
  }

  /// Firma kullanıcı listesini getirir (admin için)
  static Future<List<Map<String, dynamic>>> firmaKullanicilariniGetir() async {
    try {
      final response = await _client
          .rpc('firma_kullanicilari_detay', params: {'p_firma_id': _firmaId});

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
