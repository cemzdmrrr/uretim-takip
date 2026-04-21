import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/app_logger.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class AbonelikService {
  static final _client = Supabase.instance.client;

  static String get _firmaId => TenantManager.instance.requireFirmaId;

  static DateTime _sonrakiOdemeTarihi(DateTime baslangic, String periyot) {
    if (periyot == 'yillik') {
      return DateTime(
        baslangic.year + 1,
        baslangic.month,
        baslangic.day,
        baslangic.hour,
        baslangic.minute,
        baslangic.second,
        baslangic.millisecond,
        baslangic.microsecond,
      );
    }

    return DateTime(
      baslangic.year,
      baslangic.month + 1,
      baslangic.day,
      baslangic.hour,
      baslangic.minute,
      baslangic.second,
      baslangic.millisecond,
      baslangic.microsecond,
    );
  }

  static Future<List<AbonelikPlani>> planlariGetir({
    bool sadeceAktif = true,
  }) async {
    var query = _client.from(DbTables.abonelikPlanlari).select();
    if (sadeceAktif) {
      query = query.eq('aktif', true);
    }

    final response = await query.order('sira_no');
    return (response as List)
        .map((e) => AbonelikPlani.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<AbonelikPlani?> planGetir(String planId) async {
    final response = await _client
        .from(DbTables.abonelikPlanlari)
        .select()
        .eq('id', planId)
        .maybeSingle();

    return response != null ? AbonelikPlani.fromJson(response) : null;
  }

  static Future<void> _planModulleriniUygula({
    required String firmaId,
    required AbonelikPlani plan,
  }) async {
    final moduller = await _client
        .from(DbTables.modulTanimlari)
        .select('id, modul_kodu')
        .eq('aktif', true);

    final tumModuller = List<Map<String, dynamic>>.from(moduller as List);
    final tumuAcik =
        plan.maxModul == null || plan.ozellikler['tum_moduller'] == true;
    final izinliKodlar = tumuAcik
        ? tumModuller.map((m) => m['modul_kodu'].toString()).toSet()
        : plan.dahilModuller.toSet();

    await _client
        .from(DbTables.firmaModulleri)
        .update({'aktif': false}).eq('firma_id', firmaId);

    final kayitlar = tumModuller
        .where((m) => izinliKodlar.contains(m['modul_kodu']?.toString()))
        .map((m) => {
              'firma_id': firmaId,
              'modul_id': m['id'],
              'aktif': true,
            })
        .toList();

    if (kayitlar.isNotEmpty) {
      await _client.from(DbTables.firmaModulleri).upsert(kayitlar);
    }
  }

  static Future<FirmaAbonelik?> aktifAbonelikGetir() async {
    final response = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('*, abonelik_planlari(*)')
        .eq('firma_id', _firmaId)
        .inFilter('durum', ['aktif', 'deneme'])
        .order('created_at', ascending: false)
        .limit(5);

    for (final item in response as List) {
      final abonelik = FirmaAbonelik.fromJson(item as Map<String, dynamic>);
      if (abonelik.gecerliMi) return abonelik;
    }
    return null;
  }

  static Future<FirmaAbonelik?> guncelAbonelikGetir() async {
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

  static Future<bool> abonelikGecerliMi() async {
    try {
      final abonelik = await aktifAbonelikGetir();
      return abonelik?.gecerliMi ?? false;
    } catch (e) {
      AppLogger.error('AbonelikService', 'Abonelik kontrol hatasi', e);
      return false;
    }
  }

  static Future<FirmaAbonelik> denemeSuresiBaslat(String firmaId) async {
    final mevcut = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('*, abonelik_planlari(*)')
        .eq('firma_id', firmaId)
        .inFilter('durum', ['aktif', 'deneme', 'odeme_bekleniyor'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (mevcut != null) {
      return FirmaAbonelik.fromJson(mevcut);
    }

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

  static Future<FirmaAbonelik> planDegistir({
    required String yeniPlanId,
    String odemePeriyodu = 'aylik',
  }) async {
    final plan = await planGetir(yeniPlanId);
    if (plan == null) {
      throw StateError('Plan bulunamadi');
    }

    if (plan.denemeMi) {
      final mevcut = await aktifAbonelikGetir();
      if (mevcut != null && mevcut.plan?.denemeMi != true) {
        throw StateError('Deneme plani yalnizca yeni firmalar icindir.');
      }
      return denemeSuresiBaslat(_firmaId);
    }

    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({
          'durum': 'pasif',
          'bitis_tarihi': DateTime.now().toIso8601String(),
        })
        .eq('firma_id', _firmaId)
        .eq('durum', 'odeme_bekleniyor');

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

  static Future<void> abonelikAktifle(String abonelikId) async {
    final now = DateTime.now();
    final abonelik = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('firma_id, odeme_periyodu, plan_id')
        .eq('id', abonelikId)
        .single();

    final firmaId = abonelik['firma_id'] as String;
    final periyot = abonelik['odeme_periyodu']?.toString() ?? 'aylik';

    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({
          'durum': 'pasif',
          'bitis_tarihi': now.toIso8601String(),
        })
        .eq('firma_id', firmaId)
        .inFilter('durum', ['aktif', 'deneme'])
        .neq('id', abonelikId);

    await _client.from(DbTables.firmaAbonelikleri).update({
      'durum': 'aktif',
      'baslangic_tarihi': now.toIso8601String(),
      'bitis_tarihi': null,
      'son_odeme_tarihi': now.toIso8601String(),
      'sonraki_odeme_tarihi':
          _sonrakiOdemeTarihi(now, periyot).toIso8601String(),
    }).eq('id', abonelikId);

    final plan = await planGetir(abonelik['plan_id'] as String);
    if (plan != null) {
      await _planModulleriniUygula(firmaId: firmaId, plan: plan);
    }
  }

  static Future<void> abonelikIptal() async {
    final now = DateTime.now();
    final aktifler = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('id, durum, deneme_bitis, sonraki_odeme_tarihi')
        .eq('firma_id', _firmaId)
        .inFilter('durum', ['aktif', 'deneme'])
        .order('created_at', ascending: false)
        .limit(1);

    if ((aktifler as List).isNotEmpty) {
      final aktif = Map<String, dynamic>.from(aktifler.first as Map);
      final durum = aktif['durum']?.toString();
      final bitisAdayi = durum == 'deneme'
          ? aktif['deneme_bitis']?.toString()
          : aktif['sonraki_odeme_tarihi']?.toString();
      final bitis = DateTime.tryParse(bitisAdayi ?? '') ?? now;

      await _client.from(DbTables.firmaAbonelikleri).update({
        'iptal_tarihi': now.toIso8601String(),
        'bitis_tarihi': bitis.toIso8601String(),
      }).eq('id', aktif['id']);
    }

    await _client
        .from(DbTables.firmaAbonelikleri)
        .update({
          'durum': 'iptal',
          'iptal_tarihi': now.toIso8601String(),
          'bitis_tarihi': now.toIso8601String(),
        })
        .eq('firma_id', _firmaId)
        .eq('durum', 'odeme_bekleniyor');
  }

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

  static Future<bool> modulErisimKontrol(String modulKodu) async {
    try {
      final abonelik = await aktifAbonelikGetir();
      if (abonelik == null || !abonelik.gecerliMi) return false;
      final plan = abonelik.plan;
      if (plan == null) return false;
      if (plan.maxModul == null) return true;
      return plan.dahilModuller.contains(modulKodu);
    } catch (e) {
      AppLogger.error('AbonelikService', 'Modul erisim kontrol hatasi', e);
      return false;
    }
  }

  static Future<FirmaAbonelik> planSatinAl({
    required String planId,
    required String odemePeriyodu,
    required String kartNumarasi,
    required String kartSCT,
    required String kartCVV,
    required String kartAdSoyad,
  }) async {
    try {
      final now = DateTime.now();

      await _client
          .from(DbTables.firmaAbonelikleri)
          .update({
            'durum': 'pasif',
            'bitis_tarihi': now.toIso8601String(),
          })
          .eq('firma_id', _firmaId)
          .inFilter('durum', ['aktif', 'deneme', 'odeme_bekleniyor']);

      final response = await _client
          .from(DbTables.firmaAbonelikleri)
          .insert({
            'firma_id': _firmaId,
            'plan_id': planId,
            'durum': 'aktif',
            'odeme_periyodu': odemePeriyodu,
            'baslangic_tarihi': now.toIso8601String(),
            'bitis_tarihi': null,
            'son_odeme_tarihi': now.toIso8601String(),
            'sonraki_odeme_tarihi':
                _sonrakiOdemeTarihi(now, odemePeriyodu).toIso8601String(),
          })
          .select('*, abonelik_planlari(*)')
          .single();

      final abonelik = FirmaAbonelik.fromJson(response);
      final plan = await planGetir(planId);
      if (plan != null) {
        await _planModulleriniUygula(firmaId: _firmaId, plan: plan);

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
      AppLogger.error('AbonelikService', 'Plan satin alma hatasi', e);
      rethrow;
    }
  }

  static Future<bool> fiyatYonetimiYetkisiVarMi() async {
    try {
      final response = await _client.rpc('abonelik_plan_fiyat_yonetebilir_mi');
      return response == true;
    } catch (_) {
      final tenant = TenantManager.instance;
      return tenant.isFirmaAdmin &&
          tenant.firmaDetay?['firma_kodu'] == 'varsayilan-firma';
    }
  }

  static Future<AbonelikPlani> planFiyatGuncelle({
    required String planId,
    required double aylikUcret,
    double? yillikUcret,
    required bool aktif,
  }) async {
    if (aylikUcret < 0 || (yillikUcret != null && yillikUcret < 0)) {
      throw ArgumentError('Plan fiyati negatif olamaz');
    }

    try {
      final response = await _client.rpc(
        'abonelik_plan_fiyat_guncelle',
        params: {
          'p_plan_id': planId,
          'p_aylik_ucret': aylikUcret,
          'p_yillik_ucret': yillikUcret,
          'p_aktif': aktif,
        },
      );
      return AbonelikPlani.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      AppLogger.error('AbonelikService', 'Plan fiyat guncelleme hatasi', e);
      rethrow;
    }
  }
}
