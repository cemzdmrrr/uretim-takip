import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class PersonelService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  Future<List<PersonelModel>> getPersoneller({bool sadeceAktif = true}) async {
    try {
      var query = _client.from(DbTables.personel).select().eq('firma_id', _firmaId);
      
      // Varsayılan olarak sadece aktif personelleri getir
      if (sadeceAktif) {
        query = query.or('durum.eq.aktif,durum.is.null');
      }
      
      final response = await query;
      debugPrint('PersonelService.getPersoneller: ${response.length} kayıt bulundu (sadeceAktif=$sadeceAktif)');
      return (response as List).map((e) => PersonelModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('PersonelService.getPersoneller HATA: $e');
      return [];
    }
  }
  
  /// Tüm personelleri getirir (pasif olanlar dahil) - raporlama için
  Future<List<PersonelModel>> getTumPersoneller() async {
    return getPersoneller(sadeceAktif: false);
  }

  Future<void> addPersonel(PersonelModel p) async {
    await _client.from(DbTables.personel).insert({
      'firma_id': _firmaId,
      'ad': p.ad,
      'soyad': p.soyad,
      'tckn': p.tckn,
      'pozisyon': p.pozisyon,
      'departman': p.departman,
      'email': p.email,
      'telefon': p.telefon,
      'ise_baslangic': p.iseBaslangic,
      'brut_maas': p.brutMaas.isEmpty ? null : num.tryParse(p.brutMaas),
      'sgk_sicil_no': p.sgkSicilNo,
      'gunluk_calisma_saati': p.gunlukCalismaSaati.isEmpty ? null : num.tryParse(p.gunlukCalismaSaati),
      'haftalik_calisma_gunu': p.haftalikCalismaGunu.isEmpty ? null : num.tryParse(p.haftalikCalismaGunu),
      'yol_ucreti': p.yolUcreti.isEmpty ? null : num.tryParse(p.yolUcreti),
      'yemek_ucreti': p.yemekUcreti.isEmpty ? null : num.tryParse(p.yemekUcreti),
      'ekstra_prim': p.ekstraPrim.isEmpty ? null : num.tryParse(p.ekstraPrim),
      'elden_maas': (p.eldenMaas.isEmpty || num.tryParse(p.eldenMaas) == null) ? 0 : num.tryParse(p.eldenMaas),
      'banka_maas': p.bankaMaas.isEmpty ? null : num.tryParse(p.bankaMaas),
      'adres': p.adres,
      'net_maas': p.netMaas.isEmpty ? null : num.tryParse(p.netMaas),
      'yillik_izin_hakki': p.yillikIzinHakki.isEmpty ? null : int.tryParse(p.yillikIzinHakki),
      'user_id': p.userId,
    });
  }

  Future<PersonelModel?> getPersonelByTckn(String tckn) async {
    final response = await _client.from(DbTables.personel).select().eq('firma_id', _firmaId).eq('tckn', tckn).maybeSingle();
    if (response == null) return null;
    return PersonelModel.fromMap(response);
  }

  /// Personeli user_id ile getirir
  Future<PersonelModel?> getPersonelById(String userId) async {
    try {
      debugPrint('PersonelService.getPersonelById: userId=$userId');
      final response = await _client.from(DbTables.personel).select().eq('firma_id', _firmaId).eq('user_id', userId).maybeSingle();
      debugPrint('PersonelService.getPersonelById response: $response');
      if (response == null) {
        debugPrint('PersonelService.getPersonelById: Personel bulunamadı!');
        return null;
      }
      return PersonelModel.fromMap(response);
    } catch (e) {
      debugPrint('PersonelService.getPersonelById HATA: $e');
      return null;
    }
  }

  /// getPersonelById ile aynı işlevi yapar - backward compatibility için
  Future<PersonelModel?> getPersonelByUserId(String userId) => getPersonelById(userId);

  Future<void> updatePersonel(PersonelModel p) async {
    await _client.from(DbTables.personel).update({
      'ad': p.ad,
      'soyad': p.soyad,
      'pozisyon': p.pozisyon,
      'departman': p.departman,
      'email': p.email,
      'telefon': p.telefon,
      'ise_baslangic': p.iseBaslangic,
      'brut_maas': p.brutMaas.isEmpty ? null : num.tryParse(p.brutMaas),
      'sgk_sicil_no': p.sgkSicilNo,
      'gunluk_calisma_saati': p.gunlukCalismaSaati.isEmpty ? null : num.tryParse(p.gunlukCalismaSaati),
      'haftalik_calisma_gunu': p.haftalikCalismaGunu.isEmpty ? null : num.tryParse(p.haftalikCalismaGunu),
      'yol_ucreti': p.yolUcreti.isEmpty ? null : num.tryParse(p.yolUcreti),
      'yemek_ucreti': p.yemekUcreti.isEmpty ? null : num.tryParse(p.yemekUcreti),
      'ekstra_prim': p.ekstraPrim.isEmpty ? null : num.tryParse(p.ekstraPrim),
      'elden_maas': (p.eldenMaas.isEmpty || num.tryParse(p.eldenMaas) == null) ? 0 : num.tryParse(p.eldenMaas),
      'banka_maas': p.bankaMaas.isEmpty ? null : num.tryParse(p.bankaMaas),
      'adres': p.adres,
      'net_maas': p.netMaas.isEmpty ? null : num.tryParse(p.netMaas),
      'yillik_izin_hakki': p.yillikIzinHakki.isEmpty ? null : int.tryParse(p.yillikIzinHakki),
    }).eq('tckn', p.tckn);
  }

  /// Personeli pasif yapar (soft delete) - veri raporlama için kalır
  Future<void> deletePersonel(String tckn) async {
    try {
      await _client.from(DbTables.personel).update({
        'durum': 'pasif',
        'silme_tarihi': DateTime.now().toIso8601String(),
      }).eq('tckn', tckn);
      debugPrint('PersonelService.deletePersonel: TCKN=$tckn pasif yapıldı');
    } catch (e) {
      debugPrint('PersonelService.deletePersonel HATA: $e');
      rethrow;
    }
  }
  
  /// Personeli kalıcı olarak siler (hard delete) - dikkatli kullanın!
  Future<void> kaliciSil(String tckn) async {
    await _client.from(DbTables.personel).delete().eq('tckn', tckn);
    debugPrint('PersonelService.kaliciSil: TCKN=$tckn kalıcı olarak silindi');
  }
  
  /// Pasif personeli tekrar aktif yapar
  Future<void> aktifYap(String tckn) async {
    await _client.from(DbTables.personel).update({
      'durum': 'aktif',
      'silme_tarihi': null,
    }).eq('tckn', tckn);
    debugPrint('PersonelService.aktifYap: TCKN=$tckn tekrar aktif yapıldı');
  }
}
