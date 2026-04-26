import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/app_logger.dart';
import 'package:uretim_takip/services/edge_function_service.dart';

/// Platform yÃ¶netim paneli servisi (Super Admin).
///
/// Firma-baÄŸÄ±msÄ±z, tÃ¼m platform verilerine eriÅŸim saÄŸlar.
/// Sadece platform_admin rolÃ¼ndeki kullanÄ±cÄ±lar kullanmalÄ±dÄ±r.
class PlatformAdminService {
  static final _client = Supabase.instance.client;

  static Future<bool> kullaniciPlatformAdminMi() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return false;
    }

    final kayit = await _client
        .from(DbTables.userRoles)
        .select('role')
        .eq('user_id', userId)
        .eq('role', 'admin')
        .maybeSingle();

    return kayit != null;
  }

  static bool _isMissingPlatformLogTable(Object error) {
    return error is PostgrestException &&
        error.code == 'PGRST205' &&
        (error.message.contains('platform_loglari') ||
            error.message.contains(DbTables.platformLoglari));
  }

  // â”€â”€ Platform Ä°statistikleri â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Genel platform istatistiklerini getirir.
  static Future<Map<String, dynamic>> platformIstatistikleri() async {
    try {
      final response =
          await _client.from('v_platform_istatistikleri').select().single();
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      AppLogger.error('PlatformAdmin', 'Ä°statistik hatasÄ±', e);
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

  /// Plan bazlÄ± abonelik daÄŸÄ±lÄ±mÄ±nÄ± getirir.
  static Future<List<Map<String, dynamic>>> abonelikDagilimi() async {
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('durum, plan_id, abonelik_planlari(plan_adi, plan_kodu)')
        .inFilter('durum', ['aktif', 'deneme']);
    return List<Map<String, dynamic>>.from(response);
  }

  /// En Ã§ok kullanÄ±lan modÃ¼lleri getirir.
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

  /// En Ã§ok seÃ§ilen Ã¼retim dallarÄ±nÄ± getirir.
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
      AppLogger.error('PlatformAdmin', 'PopÃ¼ler Ã¼retim dallarÄ± hatasÄ±', e);
      return [];
    }
  }

  // â”€â”€ Firma YÃ¶netimi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// TÃ¼m firmalarÄ± Ã¶zet bilgileriyle getirir.
  static Future<List<Map<String, dynamic>>> firmalariGetir({
    String? arama,
    bool? sadecAktif,
  }) async {
    var firmaQuery = _client
        .from(DbTables.firmalar)
        .select('id, firma_adi, firma_kodu, aktif, created_at');

    if (sadecAktif != null) {
      firmaQuery = firmaQuery.eq('aktif', sadecAktif);
    }

    final firmaResponse =
        await firmaQuery.order('created_at', ascending: false);
    List<Map<String, dynamic>> firmalar =
        List<Map<String, dynamic>>.from(firmaResponse);

    if (arama != null && arama.isNotEmpty) {
      final aramaLower = arama.toLowerCase();
      firmalar = firmalar
          .where((f) =>
              (f['firma_adi']?.toString().toLowerCase() ?? '')
                  .contains(aramaLower) ||
              (f['firma_kodu']?.toString().toLowerCase() ?? '')
                  .contains(aramaLower))
          .toList();
    }

    if (firmalar.isEmpty) {
      return [];
    }

    final firmaIdleri = firmalar
        .map((firma) => firma['id']?.toString())
        .whereType<String>()
        .toList();

    final sonuclar = await Future.wait([
      _client
          .from(DbTables.firmaAbonelikleri)
          .select(
              'firma_id, durum, created_at, abonelik_planlari(plan_adi, plan_kodu)')
          .inFilter('firma_id', firmaIdleri)
          .order('created_at', ascending: false),
      _client
          .from(DbTables.firmaKullanicilari)
          .select('firma_id, user_id, aktif')
          .inFilter('firma_id', firmaIdleri),
      _client
          .from(DbTables.firmaModulleri)
          .select('firma_id, aktif')
          .inFilter('firma_id', firmaIdleri),
    ]);

    final abonelikler = List<Map<String, dynamic>>.from(sonuclar[0]);
    final firmaKullanicilari = List<Map<String, dynamic>>.from(sonuclar[1]);
    final firmaModulleri = List<Map<String, dynamic>>.from(sonuclar[2]);

    final kullaniciSayilari = <String, int>{};
    for (final kayit in firmaKullanicilari) {
      final firmaId = kayit['firma_id']?.toString();
      if (firmaId == null || firmaId.isEmpty) continue;
      kullaniciSayilari[firmaId] = (kullaniciSayilari[firmaId] ?? 0) + 1;
    }

    final aktifModulSayilari = <String, int>{};
    for (final kayit in firmaModulleri) {
      final firmaId = kayit['firma_id']?.toString();
      if (firmaId == null || firmaId.isEmpty) continue;
      if (kayit['aktif'] == true) {
        aktifModulSayilari[firmaId] = (aktifModulSayilari[firmaId] ?? 0) + 1;
      }
    }

    final sonAbonelikler = <String, Map<String, dynamic>>{};
    for (final abonelik in abonelikler) {
      final firmaId = abonelik['firma_id']?.toString();
      if (firmaId == null || firmaId.isEmpty) continue;

      final mevcut = sonAbonelikler[firmaId];
      final durum = abonelik['durum']?.toString();
      final oncelikli = durum == 'aktif' || durum == 'deneme';

      if (mevcut == null) {
        sonAbonelikler[firmaId] = abonelik;
        continue;
      }

      final mevcutDurum = mevcut['durum']?.toString();
      final mevcutOncelikli = mevcutDurum == 'aktif' || mevcutDurum == 'deneme';

      if (oncelikli && !mevcutOncelikli) {
        sonAbonelikler[firmaId] = abonelik;
      }
    }

    return firmalar.map((firma) {
      final firmaId = firma['id']?.toString() ?? '';
      final abonelik = sonAbonelikler[firmaId];
      final planData = abonelik?['abonelik_planlari'];

      return {
        ...firma,
        'abonelik_durumu': abonelik?['durum']?.toString() ?? '-',
        'plan_adi':
            planData is Map ? planData['plan_adi']?.toString() ?? '-' : '-',
        'plan_kodu':
            planData is Map ? planData['plan_kodu']?.toString() ?? '-' : '-',
        'kullanici_sayisi': kullaniciSayilari[firmaId] ?? 0,
        'modul_sayisi': aktifModulSayilari[firmaId] ?? 0,
      };
    }).toList();
  }

  /// Firma detayÄ±nÄ± getirir.
  static Future<Map<String, dynamic>?> firmaDetayGetir(String firmaId) async {
    return await _client
        .from(DbTables.firmalar)
        .select()
        .eq('id', firmaId)
        .maybeSingle();
  }

  /// FirmanÄ±n kullanÄ±cÄ±larÄ±nÄ± detaylÄ± getirir.
  static Future<List<Map<String, dynamic>>> firmaKullanicilariGetir(
      String firmaId) async {
    final response = await _client
        .rpc('firma_kullanicilari_detay', params: {'p_firma_id': firmaId});
    return List<Map<String, dynamic>>.from(response);
  }

  /// FirmanÄ±n modÃ¼llerini getirir.
  static Future<List<Map<String, dynamic>>> firmaModulleriGetir(
      String firmaId) async {
    final response = await _client
        .from(DbTables.firmaModulleri)
        .select(
            '*, modul_tanimlari(id, modul_kodu, modul_adi, kategori, aciklama)')
        .eq('firma_id', firmaId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Firma aktif/pasif durumunu deÄŸiÅŸtirir.
  static Future<void> firmaDurumDegistir(String firmaId, bool aktif) async {
    await _client.from(DbTables.firmalar).update({
      'aktif': aktif,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', firmaId);

    await _logKaydet('firma_durum_degistir', 'firmalar', firmaId, {
      'yeni_durum': aktif ? 'aktif' : 'pasif',
    });
  }

  static Future<Map<String, dynamic>> firmaSil(String firmaId) async {
    final response = await EdgeFunctionService.instance.firmaSil(
      firmaId: firmaId,
    );

    await _logKaydet('firma_sil', 'firmalar', firmaId, {
      'silinen_firma_id': firmaId,
      'ozet': response,
    });

    return response;
  }

  // â”€â”€ Abonelik YÃ¶netimi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// TÃ¼m abonelikleri firma bilgisiyle getirir.
  static Future<List<Map<String, dynamic>>> tumAbonelikleriGetir() async {
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .select(
            '*, firmalar(firma_adi, firma_kodu), abonelik_planlari(plan_adi, plan_kodu, aylik_ucret)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Abonelik durumunu gÃ¼nceller.
  static Future<void> abonelikDurumGuncelle(
      String abonelikId, String yeniDurum) async {
    final now = DateTime.now();
    final update = <String, dynamic>{
      'durum': yeniDurum,
      'updated_at': now.toIso8601String(),
    };

    if (yeniDurum == 'aktif') {
      final abonelik = await _client
          .from(DbTables.firmaAbonelikleri)
          .select('firma_id, odeme_periyodu')
          .eq('id', abonelikId)
          .single();
      final firmaId = abonelik['firma_id'] as String;
      final periyot = abonelik['odeme_periyodu']?.toString() ?? 'aylik';
      final sonraki = periyot == 'yillik'
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day);

      await _client
          .from(DbTables.firmaAbonelikleri)
          .update({
            'durum': 'pasif',
            'bitis_tarihi': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('firma_id', firmaId)
          .inFilter('durum', ['aktif', 'deneme'])
          .neq('id', abonelikId);

      update.addAll({
        'baslangic_tarihi': now.toIso8601String(),
        'bitis_tarihi': null,
        'son_odeme_tarihi': now.toIso8601String(),
        'sonraki_odeme_tarihi': sonraki.toIso8601String(),
      });
    }

    if (yeniDurum == 'iptal' || yeniDurum == 'pasif') {
      update.addAll({
        'bitis_tarihi': now.toIso8601String(),
        if (yeniDurum == 'iptal') 'iptal_tarihi': now.toIso8601String(),
      });
    }

    await _client
        .from(DbTables.firmaAbonelikleri)
        .update(update)
        .eq('id', abonelikId);

    await _logKaydet('abonelik_durum_guncelle', 'firma_abonelikleri',
        abonelikId, {'yeni_durum': yeniDurum});
  }

  /// FirmanÄ±n abonelik planÄ±nÄ± deÄŸiÅŸtirir.
  static Future<void> abonelikPlanDegistir(
      String abonelikId, String yeniPlanId) async {
    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({'plan_id': yeniPlanId}).eq('id', abonelikId);

    await _logKaydet('abonelik_plan_degistir', 'firma_abonelikleri', abonelikId,
        {'yeni_plan_id': yeniPlanId});
  }

  // â”€â”€ ModÃ¼l YÃ¶netimi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// TÃ¼m modÃ¼l tanÄ±mlarÄ±nÄ± getirir.
  static Future<List<Map<String, dynamic>>> modulTanimlariGetir() async {
    final response =
        await _client.from(DbTables.modulTanimlari).select().order('sira_no');
    return List<Map<String, dynamic>>.from(response);
  }

  /// ModÃ¼l tanÄ±mÄ±nÄ± gÃ¼nceller.
  static Future<void> modulTanimGuncelle(
      String modulId, Map<String, dynamic> veri) async {
    await _client.from(DbTables.modulTanimlari).update(veri).eq('id', modulId);

    await _logKaydet('modul_guncelle', 'modul_tanimlari', modulId, veri);
  }

  /// Yeni modÃ¼l tanÄ±mÄ± ekler.
  static Future<void> modulTanimEkle(Map<String, dynamic> veri) async {
    final res = await _client
        .from(DbTables.modulTanimlari)
        .insert(veri)
        .select('id')
        .single();

    await _logKaydet(
        'modul_ekle', 'modul_tanimlari', res['id'].toString(), veri);
  }

  // â”€â”€ Ãœretim DalÄ± YÃ¶netimi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// TÃ¼m Ã¼retim dalÄ± tanÄ±mlarÄ±nÄ± getirir.
  static Future<List<Map<String, dynamic>>> uretimDallariGetir() async {
    final response =
        await _client.from(DbTables.uretimModulleri).select().order('sira_no');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ãœretim dalÄ± tanÄ±mÄ±nÄ± gÃ¼nceller.
  static Future<void> uretimDaliGuncelle(
      String dalId, Map<String, dynamic> veri) async {
    await _client.from(DbTables.uretimModulleri).update(veri).eq('id', dalId);

    await _logKaydet('uretim_dali_guncelle', 'uretim_modulleri', dalId, veri);
  }

  // â”€â”€ Destek Talepleri â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// TÃ¼m destek taleplerini getirir.
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
  static Future<void> destekCevapla(String talepId, String cevap) async {
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

  /// Destek talebini kapatÄ±r.
  static Future<void> destekKapat(String talepId) async {
    await _client.from('destek_talepleri').update({
      'durum': 'kapali',
      'kapatma_tarihi': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', talepId);

    await _logKaydet('destek_kapat', 'destek_talepleri', talepId, {});
  }

  // â”€â”€ Gelir RaporlarÄ± â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// AylÄ±k gelir verilerini getirir (son 12 ay).
  static Future<List<Map<String, dynamic>>> aylikGelirRaporu() async {
    final response = await _client
        .from(DbTables.abonelikOdemeleri)
        .select('tutar, odeme_tarihi, durum')
        .eq('durum', 'basarili')
        .order('odeme_tarihi', ascending: false);

    final sonuclar = List<Map<String, dynamic>>.from(response);

    // AylÄ±k gruplama
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

    return sirali.take(12).map((e) => {'ay': e.key, 'gelir': e.value}).toList();
  }

  /// Yeni kayÄ±t trendini getirir (son 12 ay firma kayÄ±t sayÄ±larÄ±).
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

  // â”€â”€ Platform LoglarÄ± â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Admin iÅŸlem loglarÄ±nÄ± getirir.
  static Future<List<Map<String, dynamic>>> platformLoglariniGetir({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('platform_loglari')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (_isMissingPlatformLogTable(e)) {
        return [];
      }
      rethrow;
    }
  }

  /// Log kaydÄ± oluÅŸturur.
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
      if (_isMissingPlatformLogTable(e)) {
        return;
      }
      AppLogger.error('PlatformAdmin', 'Log kayÄ±t hatasÄ±', e);
    }
  }
}
