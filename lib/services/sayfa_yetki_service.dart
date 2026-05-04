import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/user_role_service.dart';

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
    SayfaTanimi(
        kod: 'genel_uretim',
        etiket: 'Genel Üretim',
        ikon: Icons.dashboard_customize_rounded,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'dokuma',
        etiket: 'Dokuma',
        ikon: Icons.design_services,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'konfeksiyon',
        etiket: 'Konfeksiyon',
        ikon: Icons.checkroom,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'nakis',
        etiket: 'Nakış',
        ikon: Icons.brush,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'yikama',
        etiket: 'Yıkama',
        ikon: Icons.local_laundry_service,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'utu_paket',
        etiket: 'Ütü Paket',
        ikon: Icons.inventory_2,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'ilik_dugme',
        etiket: 'İlik Düğme',
        ikon: Icons.radio_button_checked,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'kalite_kontrol',
        etiket: 'Kalite Kontrol',
        ikon: Icons.verified,
        kategori: katUretimPanelleri),
    SayfaTanimi(
        kod: 'sevkiyat',
        etiket: 'Sevkiyat',
        ikon: Icons.local_shipping,
        kategori: katUretimPanelleri),

    // Üretim & Stok
    SayfaTanimi(
        kod: 'yeni_model_ekle',
        etiket: 'Yeni Model Ekle',
        ikon: Icons.add_box_rounded,
        kategori: katUretimStok),
    SayfaTanimi(
        kod: 'toplu_model_ekle',
        etiket: 'Toplu Model Ekle',
        ikon: Icons.upload_file_rounded,
        kategori: katUretimStok),
    SayfaTanimi(
        kod: 'kayitli_modeller',
        etiket: 'Kayıtlı Modeller',
        ikon: Icons.inventory_2_rounded,
        kategori: katUretimStok),
    SayfaTanimi(
        kod: 'tamamlanan_siparisler',
        etiket: 'Tamamlanan Siparişler',
        ikon: Icons.check_circle_rounded,
        kategori: katUretimStok),
    SayfaTanimi(
        kod: 'depo_yonetimi',
        etiket: 'Depo Yönetimi',
        ikon: Icons.warehouse_rounded,
        kategori: katUretimStok),

    // Raporlar & Analiz
    SayfaTanimi(
        kod: 'uretim_raporu',
        etiket: 'Üretim Raporu',
        ikon: Icons.assessment_rounded,
        kategori: katRaporlar),
    SayfaTanimi(
        kod: 'gelismis_raporlar',
        etiket: 'Gelişmiş Raporlar',
        ikon: Icons.analytics_rounded,
        kategori: katRaporlar),

    // Finansal Yönetim
    SayfaTanimi(
        kod: 'tedarikci_yonetimi',
        etiket: 'Tedarikçi Yönetimi',
        ikon: Icons.business_rounded,
        kategori: katFinans),
    SayfaTanimi(
        kod: 'faturalar',
        etiket: 'Faturalar',
        ikon: Icons.receipt_long_rounded,
        kategori: katFinans),
    SayfaTanimi(
        kod: 'kasa_banka',
        etiket: 'Kasa & Banka',
        ikon: Icons.account_balance_wallet_rounded,
        kategori: katFinans),
    SayfaTanimi(
        kod: 'kasa_banka_hareketleri',
        etiket: 'Kasa/Banka Hareketleri',
        ikon: Icons.swap_horiz_rounded,
        kategori: katFinans),
    SayfaTanimi(
        kod: 'dosya_yonetimi',
        etiket: 'Dosya Yönetimi',
        ikon: Icons.folder_rounded,
        kategori: katFinans),

    // İnsan Kaynakları
    SayfaTanimi(
        kod: 'personel_yonetimi',
        etiket: 'Personel Yönetimi',
        ikon: Icons.badge_rounded,
        kategori: katIK),
    SayfaTanimi(
        kod: 'kullanici_listesi',
        etiket: 'Kullanıcı Listesi',
        ikon: Icons.supervisor_account_rounded,
        kategori: katIK),

    // Kullanıcı & Yetki
    SayfaTanimi(
        kod: 'firma_kullanicilari',
        etiket: 'Firma Kullanıcıları',
        ikon: Icons.people_alt_rounded,
        kategori: katKullaniciYetki),
    SayfaTanimi(
        kod: 'rol_sayfa_yetkileri',
        etiket: 'Rol Bazlı Sayfa Yetkileri',
        ikon: Icons.shield_rounded,
        kategori: katKullaniciYetki),
    SayfaTanimi(
        kod: 'firma_sayfa_yetkileri',
        etiket: 'Firma Sayfa Yetkileri',
        ikon: Icons.business_center_rounded,
        kategori: katKullaniciYetki),
    SayfaTanimi(
        kod: 'sayfa_yetki_yonetimi',
        etiket: 'Kullanıcı Sayfa Yetkileri',
        ikon: Icons.lock_open_rounded,
        kategori: katKullaniciYetki),

    // Abonelik & Plan
    SayfaTanimi(
        kod: 'abonelik_yonetimi',
        etiket: 'Abonelik Yönetimi',
        ikon: Icons.card_membership_rounded,
        kategori: katAbonelik),
    SayfaTanimi(
        kod: 'plan_degistir',
        etiket: 'Plan Değiştir',
        ikon: Icons.swap_vert_circle_rounded,
        kategori: katAbonelik),

    // Platform Yönetimi
    SayfaTanimi(
        kod: 'platform_paneli',
        etiket: 'Platform Paneli',
        ikon: Icons.admin_panel_settings_rounded,
        kategori: katPlatform),
    SayfaTanimi(
        kod: 'migrasyon_durumu',
        etiket: 'Migrasyon Durumu',
        ikon: Icons.sync_alt_rounded,
        kategori: katPlatform),
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
class SayfaYetkiPaketi {
  final Set<String> goruntuleme;
  final Set<String> duzenleme;
  final Set<String> silme;

  const SayfaYetkiPaketi({
    required this.goruntuleme,
    Set<String>? duzenleme,
    Set<String>? silme,
  })  : duzenleme = duzenleme ?? const {},
        silme = silme ?? const {};

  SayfaYetkiPaketi sinirla(Set<String> izinliSayfalar) {
    if (izinliSayfalar.isEmpty) return this;
    return SayfaYetkiPaketi(
      goruntuleme: goruntuleme.intersection(izinliSayfalar),
      duzenleme: duzenleme.intersection(izinliSayfalar),
      silme: silme.intersection(izinliSayfalar),
    );
  }
}

class SayfaYetkiService {
  static final _client = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  /// Sayfa kodlarını tutarlı karşılaştırmak için normalize eder.
  /// Eski verilerde gelebilecek boşluk/büyük-küçük harf/Türkçe karakter farklarını tolere eder.
  static String normalizeSayfaKodu(String kod) {
    return kod
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  // ═══════════════════════════════════════════════
  // FİRMA SEVİYESİ SAYFA YETKİLERİ
  // ═══════════════════════════════════════════════

  /// Firma için aktif olan sayfa kodlarını getirir
  static Future<Set<String>> firmaYetkileriniGetir(String firmaId) async {
    try {
      final client = SupabaseConfig.isAdminAvailable
          ? SupabaseConfig.adminClient
          : _client;
      final response = await client
          .from(DbTables.firmaSayfaYetkileri)
          .select('sayfa_kodu')
          .eq('firma_id', firmaId)
          .eq('aktif', true);

      return (response as List)
          .map((r) => normalizeSayfaKodu((r['sayfa_kodu'] ?? '').toString()))
          .where((k) => k.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('Firma sayfa yetkileri yüklenemedi: $e');
      return {};
    }
  }

  /// Mevcut firma için aktif sayfa kodlarını getirir
  static Future<Set<String>> mevcutFirmaYetkileriniGetir() async {
    return firmaYetkileriniGetir(_firmaId);
  }

  /// Firma sayfa yetkilerini kaydet (upsert)
  static Future<void> firmaYetkileriniKaydet(
      String firmaId, Set<String> sayfaKodlari) async {
    final client =
        SupabaseConfig.isAdminAvailable ? SupabaseConfig.adminClient : _client;

    // Mevcut kayıtları sil
    await client
        .from(DbTables.firmaSayfaYetkileri)
        .delete()
        .eq('firma_id', firmaId);

    // Yeni kayıtları ekle
    if (sayfaKodlari.isNotEmpty) {
      final rows = sayfaKodlari
          .map(normalizeSayfaKodu)
          .where((k) => k.isNotEmpty)
          .toSet()
          .map((kod) => {
                'firma_id': firmaId,
                'sayfa_kodu': kod,
                'aktif': true,
              })
          .toList();

      await client.from(DbTables.firmaSayfaYetkileri).insert(rows);
    }
  }

  /// Firma belirli sayfaya erişebilir mi
  static Future<bool> firmaSayfaErisimKontrol(String sayfaKodu) async {
    final yetkiler = await mevcutFirmaYetkileriniGetir();
    if (yetkiler.isEmpty) {
      return true; // Hiç tanımlama yoksa tümüne erişim (geriye uyumluluk)
    }
    return yetkiler.contains(normalizeSayfaKodu(sayfaKodu));
  }

  // ═══════════════════════════════════════════════
  // KULLANICI SEVİYESİ SAYFA YETKİLERİ
  // ═══════════════════════════════════════════════

  /// Belirli kullanıcının erişebildiği sayfa kodlarını getirir
  static Future<Set<String>> kullaniciYetkileriniGetir(String userId) async {
    try {
      final client = SupabaseConfig.isAdminAvailable
          ? SupabaseConfig.adminClient
          : _client;

      final response = await client
          .from(DbTables.kullaniciSayfaYetkileri)
          .select('sayfa_kodu')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .eq('aktif', true);

      return (response as List)
          .map((r) => normalizeSayfaKodu((r['sayfa_kodu'] ?? '').toString()))
          .where((k) => k.isNotEmpty)
          .toSet();
    } catch (e) {
      // Tablo yoksa veya hata varsa boş set döndür
      debugPrint('Kullanıcı sayfa yetkileri yüklenemedi: $e');
      return {};
    }
  }

  static Future<SayfaYetkiPaketi> kullaniciYetkiPaketiniGetir(
      String userId) async {
    try {
      final client = SupabaseConfig.isAdminAvailable
          ? SupabaseConfig.adminClient
          : _client;

      final response = await client
          .from(DbTables.kullaniciSayfaYetkileri)
          .select('sayfa_kodu, aktif, duzenleme_yetkisi, silme_yetkisi')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId);

      final goruntuleme = <String>{};
      final duzenleme = <String>{};
      final silme = <String>{};

      for (final row in response as List) {
        final kod = normalizeSayfaKodu((row['sayfa_kodu'] ?? '').toString());
        if (kod.isEmpty) continue;
        final aktif = row['aktif'] == true;
        if (aktif) goruntuleme.add(kod);
        if (aktif && row['duzenleme_yetkisi'] == true) duzenleme.add(kod);
        if (aktif && row['silme_yetkisi'] == true) silme.add(kod);
      }

      return SayfaYetkiPaketi(
        goruntuleme: goruntuleme,
        duzenleme: duzenleme,
        silme: silme,
      );
    } catch (e) {
      debugPrint('Kullanıcı sayfa yetki paketi yüklenemedi: $e');
      try {
        final client = SupabaseConfig.isAdminAvailable
            ? SupabaseConfig.adminClient
            : _client;
        final response = await client
            .from(DbTables.kullaniciSayfaYetkileri)
            .select('sayfa_kodu')
            .eq('firma_id', _firmaId)
            .eq('user_id', userId)
            .eq('aktif', true);

        final goruntuleme = (response as List)
            .map((r) => normalizeSayfaKodu((r['sayfa_kodu'] ?? '').toString()))
            .where((k) => k.isNotEmpty)
            .toSet();
        return SayfaYetkiPaketi(goruntuleme: goruntuleme);
      } catch (_) {
        return const SayfaYetkiPaketi(goruntuleme: {});
      }
    }
  }

  /// Kullanici icin explicit sayfa yetki kaydi var mi
  ///
  /// Kayit yoksa eski davranis korunur ve rol bazli yetkilere dusulur.
  /// Kayit varsa aktif=false satirlar da kullanicinin bilincli tercihi sayilir.
  static Future<bool> kullaniciSayfaYetkiKaydiVarMi(String userId) async {
    try {
      final client = SupabaseConfig.isAdminAvailable
          ? SupabaseConfig.adminClient
          : _client;

      final response = await client
          .from(DbTables.kullaniciSayfaYetkileri)
          .select('id')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Kullanici sayfa yetki kaydi kontrol edilemedi: $e');
      return false;
    }
  }

  /// Kullanıcı belirli sayfaya erişebilir mi
  static Future<bool> sayfaErisimKontrol(
      String userId, String sayfaKodu) async {
    final yetkiler = await kullaniciYetkileriniGetir(userId);
    return yetkiler.contains(normalizeSayfaKodu(sayfaKodu));
  }

  /// Kullanıcının tüm sayfa yetkilerini kaydet (upsert)
  static Future<bool> sayfaIslemYetkisiKontrol(
    String userId,
    String sayfaKodu,
    String islem,
  ) async {
    final kod = normalizeSayfaKodu(sayfaKodu);
    final paket = await efektifSayfaYetkiPaketiniGetir(userId);
    if (islem == 'duzenleme') return paket.duzenleme.contains(kod);
    if (islem == 'silme') return paket.silme.contains(kod);
    return paket.goruntuleme.contains(kod);
  }

  static Future<void> yetkileriKaydet(
    String userId,
    Set<String> sayfaKodlari, {
    Set<String> duzenlemeYetkileri = const {},
    Set<String> silmeYetkileri = const {},
  }) async {
    final client =
        SupabaseConfig.isAdminAvailable ? SupabaseConfig.adminClient : _client;

    final seciliKodlar =
        sayfaKodlari.map(normalizeSayfaKodu).where((k) => k.isNotEmpty).toSet();
    final duzenlemeKodlari = duzenlemeYetkileri
        .map(normalizeSayfaKodu)
        .where((k) => k.isNotEmpty)
        .toSet()
        .intersection(seciliKodlar);
    final silmeKodlari = silmeYetkileri
        .map(normalizeSayfaKodu)
        .where((k) => k.isNotEmpty)
        .toSet()
        .intersection(seciliKodlar);

    // Önce mevcut kayıtları sil
    await client
        .from(DbTables.kullaniciSayfaYetkileri)
        .delete()
        .eq('firma_id', _firmaId)
        .eq('user_id', userId);

    // Tüm sayfaları aktif/pasif olarak yazarak "hiç sayfa gösterme"
    // tercihini de kalıcı hale getiriyoruz.
    final rows = SayfaRegistry.tumSayfalar
        .map((sayfa) => normalizeSayfaKodu(sayfa.kod))
        .where((k) => k.isNotEmpty)
        .toSet()
        .map((kod) => {
              'firma_id': _firmaId,
              'user_id': userId,
              'sayfa_kodu': kod,
              'aktif': seciliKodlar.contains(kod),
              'duzenleme_yetkisi': duzenlemeKodlari.contains(kod),
              'silme_yetkisi': silmeKodlari.contains(kod),
            })
        .toList();

    if (rows.isNotEmpty) {
      await client.from(DbTables.kullaniciSayfaYetkileri).insert(rows);
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

  // ═══════════════════════════════════════════════
  // ROL BAZLI SAYFA YETKİLERİ
  // ═══════════════════════════════════════════════

  /// Belirli rol için aktif olan sayfa kodlarını getirir
  static Future<Set<String>> rolYetkileriniGetir(String rol) async {
    try {
      final client = SupabaseConfig.isAdminAvailable
          ? SupabaseConfig.adminClient
          : _client;

      final response = await client
          .from(DbTables.rolSayfaYetkileri)
          .select('sayfa_kodu')
          .eq('firma_id', _firmaId)
          .eq('rol', rol)
          .eq('aktif', true);

      return (response as List)
          .map((r) => normalizeSayfaKodu((r['sayfa_kodu'] ?? '').toString()))
          .where((k) => k.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('Rol sayfa yetkileri yüklenemedi: $e');
      return {};
    }
  }

  /// Role ait sayfa yetkilerini kaydet (upsert)
  static Future<void> rolYetkileriniKaydet(
      String rol, Set<String> sayfaKodlari) async {
    final client =
        SupabaseConfig.isAdminAvailable ? SupabaseConfig.adminClient : _client;

    // Önce mevcut kayıtları sil
    await client
        .from(DbTables.rolSayfaYetkileri)
        .delete()
        .eq('firma_id', _firmaId)
        .eq('rol', rol);

    // Yeni kayıtları ekle
    if (sayfaKodlari.isNotEmpty) {
      final rows = sayfaKodlari
          .map(normalizeSayfaKodu)
          .where((k) => k.isNotEmpty)
          .toSet()
          .map((kod) => {
                'firma_id': _firmaId,
                'rol': rol,
                'sayfa_kodu': kod,
                'aktif': true,
              })
          .toList();

      await client.from(DbTables.rolSayfaYetkileri).insert(rows);
    }
  }

  /// Kullanıcının rolüne göre sayfa yetkilerini getirir
  static Future<Set<String>> kullaniciRolYetkileriniGetir(String userId) async {
    try {
      final firmaRolu = await kullaniciFirmaRolunuGetir(userId);
      if (firmaRolu == null) return {};

      if (firmaRolu == 'firma_sahibi' ||
          firmaRolu == 'firma_admin' ||
          firmaRolu == 'admin') {
        return SayfaRegistry.tumSayfalar.map((s) => s.kod).toSet();
      }

      final roller = <String>{firmaRolu};
      final operasyonRolleri =
          await UserRoleService.kullaniciOperasyonRolleriniGetir(
        userId: userId,
        firmaId: _firmaId,
      );
      roller.addAll(operasyonRolleri.where((rol) => rol != 'admin'));

      final tumYetkiler = <String>{};
      for (final rol in roller) {
        tumYetkiler.addAll(await rolYetkileriniGetir(rol));
      }
      return tumYetkiler;
    } catch (e) {
      debugPrint('Kullanıcı rol yetkileri yüklenemedi: $e');
      return {};
    }
  }

  /// Kullanıcının aktif firmadaki rolünü firma_kullanicilari tablosundan getirir.
  static Future<String?> kullaniciFirmaRolunuGetir(String userId) async {
    try {
      final response = await _client
          .from(DbTables.firmaKullanicilari)
          .select('rol')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .eq('aktif', true)
          .maybeSingle();

      return response?['rol'] as String?;
    } catch (e) {
      debugPrint('Kullanıcı firma rolü yüklenemedi: $e');
      return null;
    }
  }

  /// Ana sayfa görünürlüğü için nihai sayfa yetkilerini getirir.
  ///
  /// Öncelik:
  /// 1. Admin/firma admin/firma sahibi tüm sayfaları görür.
  /// 2. Kullanıcıya özel kayıt varsa sadece aktif kayıtlar kullanılır.
  /// 3. Kullanıcıya özel kayıt yoksa rol bazlı yetkilere düşülür.
  /// Firma seviyesinde sayfa kısıtı varsa admin dışındaki sonuç onunla kesiştirilir.
  static Future<Set<String>> efektifSayfaYetkileriniGetir(String userId) async {
    final paket = await efektifSayfaYetkiPaketiniGetir(userId);
    return paket.goruntuleme;
  }

  static Future<SayfaYetkiPaketi> efektifSayfaYetkiPaketiniGetir(
      String userId) async {
    final firmaRolu = await kullaniciFirmaRolunuGetir(userId);
    final roller = await UserRoleService.kullaniciTumRolleriniGetir(
      userId: userId,
      firmaId: _firmaId,
    );
    final adminMi = roller.contains('admin') ||
        firmaRolu == 'firma_sahibi' ||
        firmaRolu == 'firma_admin';

    if (adminMi) {
      final tumSayfalar = SayfaRegistry.tumSayfalar
          .map((s) => normalizeSayfaKodu(s.kod))
          .toSet();
      return SayfaYetkiPaketi(
        goruntuleme: tumSayfalar,
        duzenleme: tumSayfalar,
        silme: tumSayfalar,
      );
    }

    final explicitKayitVar = await kullaniciSayfaYetkiKaydiVarMi(userId);
    SayfaYetkiPaketi paket;
    if (explicitKayitVar) {
      paket = await kullaniciYetkiPaketiniGetir(userId);
    } else {
      paket = SayfaYetkiPaketi(
        goruntuleme: await kullaniciRolYetkileriniGetir(userId),
      );
    }

    final firmaYetkileri = await mevcutFirmaYetkileriniGetir();
    return paket.sinirla(firmaYetkileri);
  }

  /// Firmadaki tüm rolleri listeler
  static Future<List<String>> firmaRolleriniGetir() async {
    try {
      final response = await _client
          .from(DbTables.userRoles)
          .select('role')
          .eq('firma_id', _firmaId)
          .eq('aktif', true);

      return (response as List)
          .map((r) => (r['role'] ?? '').toString())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
    } catch (e) {
      debugPrint('Firma rolleri yüklenemedi: $e');
      return [];
    }
  }
}
