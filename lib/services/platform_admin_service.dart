import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/app_logger.dart';

/// Platform yönetim paneli servisi (Super Admin).
///
/// Firma-bağımsız, tüm platform verilerine erişim sağlar.
/// Sadece platform_admin rolündeki kullanıcılar kullanmalıdır.
class PlatformAdminService {
  static final _client = Supabase.instance.client;

  // ── Platform İstatistikleri ────────────────────────────────

  /// Genel platform istatistiklerini getirir.
  static Future<Map<String, dynamic>> platformIstatistikleri() async {
    try {
      final response = await _client
          .from('v_platform_istatistikleri')
          .select()
          .single();
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      AppLogger.error('PlatformAdmin', 'İstatistik hatası', e);
      return {
        'aktif_firma_sayisi': 0,
        'pasif_firma_sayisi': 0,
        'toplam_firma_sayisi': 0,
        'toplam_kullanici_sayisi': 0,
        'aktif_abonelik_sayisi': 0,
        'deneme_abonelik_sayisi': 0,
        'aylik_gelir': 0.0,
        'acik_destek_sayisi': 0,
      };
    }
  }

  /// Plan bazlı abonelik dağılımını getirir.
  static Future<List<Map<String, dynamic>>> abonelikDagilimi() async {
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('durum, plan_id, abonelik_planlari(plan_adi, plan_kodu)')
        .inFilter('durum', ['aktif', 'deneme']);
    return List<Map<String, dynamic>>.from(response);
  }

  /// En çok kullanılan modülleri getirir.
  static Future<List<Map<String, dynamic>>> populerModuller() async {
    final response = await _client
        .from(DbTables.firmaModulleri)
        .select('modul_id, modul_tanimlari(modul_kodu)')
        .eq('aktif', true);

    final sayac = <String, int>{};
    for (final r in response) {
      final modulData = r['modul_tanimlari'];
      if (modulData is Map) {
        final kod = modulData['modul_kodu'] as String?;
        if (kod != null) {
          sayac[kod] = (sayac[kod] ?? 0) + 1;
        }
      }
    }

    final sirali = sayac.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sirali
        .map((e) => {'modul_kodu': e.key, 'firma_sayisi': e.value})
        .toList();
  }

  /// En çok seçilen üretim dallarını getirir.
  static Future<List<Map<String, dynamic>>> populerUretimDallari() async {
    try {
      final response = await _client
          .from(DbTables.firmaUretimModulleri)
          .select('uretim_modul_id, uretim_modulleri(tekstil_dali)')
          .eq('aktif', true);

      final sayac = <String, int>{};
      for (final r in response) {
        final uretimData = r['uretim_modulleri'];
        if (uretimData is Map) {
          final dal = uretimData['tekstil_dali']?.toString();
          if (dal != null && dal.isNotEmpty) {
            sayac[dal] = (sayac[dal] ?? 0) + 1;
          }
        }
      }

      final sirali = sayac.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sirali
          .map((e) => {'tekstil_dali': e.key, 'firma_sayisi': e.value})
          .toList();
    } catch (e) {
      AppLogger.error('PlatformAdmin', 'Popüler üretim dalları hatası', e);
      return [];
    }
  }

  // ── Firma Yönetimi ────────────────────────────────────────

  /// Tüm firmaları özet bilgileriyle getirir.
  static Future<List<Map<String, dynamic>>> firmalariGetir({
    String? arama,
    bool? sadecAktif,
  }) async {
    var query = _client
        .from(DbTables.firmalar)
        .select('id, firma_adi, firma_kodu, aktif, created_at');

    if (sadecAktif != null) {
      query = query.eq('aktif', sadecAktif);
    }

    final response = await query.order('created_at', ascending: false);
    List<Map<String, dynamic>> sonuc = List<Map<String, dynamic>>.from(response);

    if (arama != null && arama.isNotEmpty) {
      final aramaLower = arama.toLowerCase();
      sonuc = sonuc
          .where((f) =>
              (f['firma_adi']?.toString().toLowerCase() ?? '')
                  .contains(aramaLower) ||
              (f['firma_kodu']?.toString().toLowerCase() ?? '')
                  .contains(aramaLower))
          .toList();
    }

    return sonuc;
  }

  /// Firma detayını getirir.
  static Future<Map<String, dynamic>?> firmaDetayGetir(String firmaId) async {
    return await _client
        .from(DbTables.firmalar)
        .select()
        .eq('id', firmaId)
        .maybeSingle();
  }

  /// Firmanın kullanıcılarını detaylı getirir.
  static Future<List<Map<String, dynamic>>> firmaKullanicilariGetir(
      String firmaId) async {
    final response = await _client
        .rpc('firma_kullanicilari_detay', params: {'p_firma_id': firmaId});
    return List<Map<String, dynamic>>.from(response);
  }

  /// Firmanın modüllerini getirir.
  static Future<List<Map<String, dynamic>>> firmaModulleriGetir(
      String firmaId) async {
    final response = await _client
        .from(DbTables.firmaModulleri)
        .select('*, modul_tanimlari(id, modul_kodu, modul_adi, kategori, aciklama)')
        .eq('firma_id', firmaId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Firma aktif/pasif durumunu değiştirir.
  static Future<void> firmaDurumDegistir(String firmaId, bool aktif) async {
    await _client
        .from(DbTables.firmalar)
        .update({'aktif': aktif, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', firmaId);

    await _logKaydet('firma_durum_degistir', 'firmalar', firmaId, {
      'yeni_durum': aktif ? 'aktif' : 'pasif',
    });
  }

  // ── Abonelik Yönetimi ─────────────────────────────────────

  /// Tüm abonelikleri firma bilgisiyle getirir.
  static Future<List<Map<String, dynamic>>> tumAbonelikleriGetir() async {
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('*, firmalar(firma_adi, firma_kodu), abonelik_planlari(plan_adi, plan_kodu, aylik_ucret)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Abonelik durumunu günceller.
  static Future<void> abonelikDurumGuncelle(
      String abonelikId, String yeniDurum) async {
    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({'durum': yeniDurum})
        .eq('id', abonelikId);

    await _logKaydet('abonelik_durum_guncelle', 'firma_abonelikleri',
        abonelikId, {'yeni_durum': yeniDurum});
  }

  /// Firmanın abonelik planını değiştirir.
  static Future<void> abonelikPlanDegistir(
      String abonelikId, String yeniPlanId) async {
    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({'plan_id': yeniPlanId})
        .eq('id', abonelikId);

    await _logKaydet('abonelik_plan_degistir', 'firma_abonelikleri',
        abonelikId, {'yeni_plan_id': yeniPlanId});
  }

  // ── Modül Yönetimi ────────────────────────────────────────

  /// Tüm modül tanımlarını getirir.
  static Future<List<Map<String, dynamic>>> modulTanimlariGetir() async {
    final response = await _client
        .from(DbTables.modulTanimlari)
        .select()
        .order('sira_no');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Modül tanımını günceller.
  static Future<void> modulTanimGuncelle(
      String modulId, Map<String, dynamic> veri) async {
    await _client
        .from(DbTables.modulTanimlari)
        .update(veri)
        .eq('id', modulId);

    await _logKaydet('modul_guncelle', 'modul_tanimlari', modulId, veri);
  }

  /// Yeni modül tanımı ekler.
  static Future<void> modulTanimEkle(Map<String, dynamic> veri) async {
    final res = await _client
        .from(DbTables.modulTanimlari)
        .insert(veri)
        .select('id')
        .single();

    await _logKaydet(
        'modul_ekle', 'modul_tanimlari', res['id'].toString(), veri);
  }

  // ── Üretim Dalı Yönetimi ─────────────────────────────────

  /// Tüm üretim dalı tanımlarını getirir.
  static Future<List<Map<String, dynamic>>> uretimDallariGetir() async {
    final response = await _client
        .from(DbTables.uretimModulleri)
        .select()
        .order('sira_no');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Üretim dalı tanımını günceller.
  static Future<void> uretimDaliGuncelle(
      String dalId, Map<String, dynamic> veri) async {
    await _client
        .from(DbTables.uretimModulleri)
        .update(veri)
        .eq('id', dalId);

    await _logKaydet('uretim_dali_guncelle', 'uretim_modulleri', dalId, veri);
  }

  // ── Destek Talepleri ──────────────────────────────────────

  /// Tüm destek taleplerini getirir.
  static Future<List<Map<String, dynamic>>> destekTalepleriGetir({
    String? durumFiltre,
  }) async {
    var query = _client
        .from('destek_talepleri')
        .select('*, firmalar:firma_id(firma_adi)');

    if (durumFiltre != null) {
      query = query.eq('durum', durumFiltre);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Destek talebini cevaplar.
  static Future<void> destekCevapla(
      String talepId, String cevap) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('destek_talepleri').update({
      'cevap': cevap,
      'cevaplayan_id': userId,
      'cevap_tarihi': DateTime.now().toIso8601String(),
      'durum': 'cevaplandi',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', talepId);

    await _logKaydet('destek_cevapla', 'destek_talepleri', talepId, {
      'cevap_uzunluk': cevap.length,
    });
  }

  /// Destek talebini kapatır.
  static Future<void> destekKapat(String talepId) async {
    await _client.from('destek_talepleri').update({
      'durum': 'kapali',
      'kapatma_tarihi': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', talepId);

    await _logKaydet('destek_kapat', 'destek_talepleri', talepId, {});
  }

  // ── Gelir Raporları ───────────────────────────────────────

  /// Aylık gelir verilerini getirir (son 12 ay).
  static Future<List<Map<String, dynamic>>> aylikGelirRaporu() async {
    final response = await _client
        .from(DbTables.abonelikOdemeleri)
        .select('tutar, odeme_tarihi, durum')
        .eq('durum', 'basarili')
        .order('odeme_tarihi', ascending: false);

    final sonuclar = List<Map<String, dynamic>>.from(response);

    // Aylık gruplama
    final aylikGelir = <String, double>{};
    for (final odeme in sonuclar) {
      final tarih = DateTime.tryParse(odeme['odeme_tarihi']?.toString() ?? '');
      if (tarih == null) continue;
      final ayAnahtar =
          '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}';
      aylikGelir[ayAnahtar] =
          (aylikGelir[ayAnahtar] ?? 0) + (odeme['tutar'] as num).toDouble();
    }

    final sirali = aylikGelir.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sirali
        .take(12)
        .map((e) => {'ay': e.key, 'gelir': e.value})
        .toList();
  }

  /// Yeni kayıt trendini getirir (son 12 ay firma kayıt sayıları).
  static Future<List<Map<String, dynamic>>> yeniKayitTrendi() async {
    final response = await _client
        .from(DbTables.firmalar)
        .select('created_at')
        .order('created_at', ascending: false);

    final aylikKayit = <String, int>{};
    for (final firma in response) {
      final tarih = DateTime.tryParse(firma['created_at']?.toString() ?? '');
      if (tarih == null) continue;
      final ayAnahtar =
          '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}';
      aylikKayit[ayAnahtar] = (aylikKayit[ayAnahtar] ?? 0) + 1;
    }

    final sirali = aylikKayit.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sirali
        .take(12)
        .map((e) => {'ay': e.key, 'kayit_sayisi': e.value})
        .toList();
  }

  // ── Platform Logları ──────────────────────────────────────

  /// Admin işlem loglarını getirir.
  static Future<List<Map<String, dynamic>>> platformLoglariniGetir({
    int limit = 50,
  }) async {
    final response = await _client
        .from('platform_loglari')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Log kaydı oluşturur.
  static Future<void> _logKaydet(
    String islemTipi,
    String? hedefTablo,
    String? hedefId,
    Map<String, dynamic> detay,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('platform_loglari').insert({
        'admin_id': userId,
        'islem_tipi': islemTipi,
        'hedef_tablo': hedefTablo,
        'hedef_id': hedefId,
        'detay': detay,
      });
    } catch (e) {
      AppLogger.error('PlatformAdmin', 'Log kayıt hatası', e);
    }
  }
}
