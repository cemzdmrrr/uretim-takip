import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/app_logger.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Abonelik planları, firma abonelikleri ve ödeme işlemleri servisi.
class AbonelikService {
  static final _client = Supabase.instance.client;

  static String get _firmaId => TenantManager.instance.requireFirmaId;

  // ── Plan Listeleme ───────────────────────────────────────

  /// Tüm aktif planları sıralı getirir.
  static Future<List<AbonelikPlani>> planlariGetir() async {
    final response = await _client
        .from(DbTables.abonelikPlanlari)
        .select()
        .eq('aktif', true)
        .order('sira_no');

    return (response as List)
        .map((e) => AbonelikPlani.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tek bir planı getirir.
  static Future<AbonelikPlani?> planGetir(String planId) async {
    final response = await _client
        .from(DbTables.abonelikPlanlari)
        .select()
        .eq('id', planId)
        .maybeSingle();

    return response != null ? AbonelikPlani.fromJson(response) : null;
  }

  // ── Firma Abonelik Yönetimi ──────────────────────────────

  /// Firmanın aktif aboneliğini plan bilgisiyle birlikte getirir.
  static Future<FirmaAbonelik?> aktifAbonelikGetir() async {
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('*, abonelik_planlari(*)')
        .eq('firma_id', _firmaId)
        .inFilter('durum', ['aktif', 'deneme', 'odeme_bekleniyor'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response != null ? FirmaAbonelik.fromJson(response) : null;
  }

  /// Firmanın tüm abonelik geçmişini getirir.
  static Future<List<FirmaAbonelik>> abonelikGecmisiGetir() async {
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('*, abonelik_planlari(*)')
        .eq('firma_id', _firmaId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => FirmaAbonelik.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Aboneliğin geçerli olup olmadığını kontrol eder.
  static Future<bool> abonelikGecerliMi() async {
    try {
      final abonelik = await aktifAbonelikGetir();
      if (abonelik == null) return false;
      return abonelik.gecerliMi;
    } catch (e) {
      AppLogger.error('AbonelikService', 'Abonelik kontrolü hatası', e);
      return false;
    }
  }

  /// Yeni firma için deneme aboneliği başlatır.
  static Future<FirmaAbonelik> denemeSuresiBaslat(String firmaId) async {
    // Deneme planını bul
    final denemePlan = await _client
        .from(DbTables.abonelikPlanlari)
        .select()
        .eq('plan_kodu', 'deneme')
        .single();

    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .insert({
          'firma_id': firmaId,
          'plan_id': denemePlan['id'],
          'durum': 'deneme',
          'odeme_periyodu': 'aylik',
        })
        .select('*, abonelik_planlari(*)')
        .single();

    return FirmaAbonelik.fromJson(response);
  }

  /// Plan değiştirir (yükseltme / düşürme).
  static Future<FirmaAbonelik> planDegistir({
    required String yeniPlanId,
    String odemePeriyodu = 'aylik',
  }) async {
    // Mevcut aktif aboneliği iptal et
    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({'durum': 'pasif'})
        .eq('firma_id', _firmaId)
        .inFilter('durum', ['aktif', 'deneme']);

    // Yeni abonelik oluştur
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .insert({
          'firma_id': _firmaId,
          'plan_id': yeniPlanId,
          'durum': 'odeme_bekleniyor',
          'odeme_periyodu': odemePeriyodu,
        })
        .select('*, abonelik_planlari(*)')
        .single();

    return FirmaAbonelik.fromJson(response);
  }

  /// Aboneliği aktifleştirir (ödeme sonrası).
  static Future<void> abonelikAktifle(String abonelikId) async {
    final now = DateTime.now();
    await _client.from(DbTables.firmaAbonelikleri).update({
      'durum': 'aktif',
      'baslangic_tarihi': now.toIso8601String(),
      'son_odeme_tarihi': now.toIso8601String(),
      'sonraki_odeme_tarihi':
          now.add(const Duration(days: 30)).toIso8601String(),
    }).eq('id', abonelikId);
  }

  /// Aboneliği iptal eder.
  static Future<void> abonelikIptal() async {
    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({
          'durum': 'iptal',
          'iptal_tarihi': DateTime.now().toIso8601String(),
        })
        .eq('firma_id', _firmaId)
        .inFilter('durum', ['aktif', 'deneme', 'odeme_bekleniyor']);
  }

  // ── Ödeme ────────────────────────────────────────────────

  /// Ödeme kaydı oluşturur.
  static Future<AbonelikOdeme> odemeKaydet({
    required String abonelikId,
    required double tutar,
    required String odemeYontemi,
    String? odemeReferans,
  }) async {
    final response = await _client
        .from(DbTables.abonelikOdemeleri)
        .insert({
          'firma_id': _firmaId,
          'abonelik_id': abonelikId,
          'tutar': tutar,
          'odeme_yontemi': odemeYontemi,
          'odeme_referans': odemeReferans,
          'durum': 'basarili',
        })
        .select()
        .single();

    return AbonelikOdeme.fromJson(response);
  }

  /// Firmanın ödeme geçmişini getirir.
  static Future<List<AbonelikOdeme>> odemeGecmisiGetir() async {
    final response = await _client
        .from(DbTables.abonelikOdemeleri)
        .select()
        .eq('firma_id', _firmaId)
        .order('odeme_tarihi', ascending: false);

    return (response as List)
        .map((e) => AbonelikOdeme.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Modül Erişim Kontrolü ────────────────────────────────

  /// Firmanın planına göre modüle erişimi var mı kontrol eder.
  static Future<bool> modulErisimKontrol(String modulKodu) async {
    try {
      final abonelik = await aktifAbonelikGetir();
      if (abonelik == null) return false;
      if (!abonelik.gecerliMi) return false;
      final plan = abonelik.plan;
      if (plan == null) return false;
      // Enterprise ve kurumsal planlarda tüm modüller açık
      if (plan.maxModul == null) return true;
      return plan.dahilModuller.contains(modulKodu);
    } catch (e) {
      AppLogger.error('AbonelikService', 'Modül erişim kontrolü hatası', e);
      return false;
    }
  }

  /// Plan satın al - Ödeme işlemini gerçekleştir
  static Future<FirmaAbonelik> planSatinAl({
    required String planId,
    required String odemePeriyodu,
    required String kartNumarasi,
    required String kartSCT,
    required String kartCVV,
    required String kartAdSoyad,
  }) async {
    try {
      // Mevcut aktif aboneliği iptal et
      await _client
          .from(DbTables.firmaAbonelikleri)
          .update({'durum': 'pasif'})
          .eq('firma_id', _firmaId)
          .inFilter('durum', ['aktif', 'deneme']);

      // Yeni abonelik oluştur
      final response = await _client
          .from(DbTables.firmaAbonelikleri)
          .insert({
            'firma_id': _firmaId,
            'plan_id': planId,
            'durum': 'aktif',
            'odeme_periyodu': odemePeriyodu,
            'baslangic_tarihi': DateTime.now().toIso8601String(),
            'son_odeme_tarihi': DateTime.now().toIso8601String(),
            'sonraki_odeme_tarihi':
                DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          })
          .select('*, abonelik_planlari(*)')
          .single();

      final abonelik = FirmaAbonelik.fromJson(response);

      // Ödeme kaydı oluştur
      final plan = await planGetir(planId);
      if (plan != null) {
        final tutar = odemePeriyodu == 'yillik'
            ? (plan.yillikUcret ?? plan.aylikUcret * 12)
            : plan.aylikUcret;

        await odemeKaydet(
          abonelikId: abonelik.id,
          tutar: tutar,
          odemeYontemi: 'kredi_karti',
          odemeReferans: 'REF-${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      return abonelik;
    } catch (e) {
      AppLogger.error('AbonelikService', 'Plan satın alma hatası', e);
      rethrow;
    }
  }
}
