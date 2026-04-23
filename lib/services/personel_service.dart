import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/edge_function_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class PersonelService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  String? _dateOrNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('.') && trimmed.length == 10) {
      final parts = trimmed.split('.');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    }

    return trimmed;
  }

  Future<List<PersonelModel>> getPersoneller({
    bool sadeceAktif = true,
    List<String>? durumlar,
  }) async {
    try {
      var query = _client.from(DbTables.personel).select().eq('firma_id', _firmaId);

      if (durumlar != null && durumlar.isNotEmpty) {
        final orFilter = durumlar.map((durum) => 'durum.eq.$durum').join(',');
        query = query.or(orFilter);
      } else if (sadeceAktif) {
        query = query.or('durum.eq.aktif,durum.is.null');
      }

      final response = await query.order('ad');
      debugPrint(
        'PersonelService.getPersoneller: ${response.length} kayit bulundu '
        '(sadeceAktif=$sadeceAktif, durumlar=$durumlar)',
      );
      return (response as List).map((e) => PersonelModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('PersonelService.getPersoneller HATA: $e');
      return [];
    }
  }

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
      'ise_baslangic': _dateOrNull(p.iseBaslangic),
      'brut_maas': p.brutMaas.isEmpty ? null : num.tryParse(p.brutMaas),
      'sgk_sicil_no': p.sgkSicilNo,
      'gunluk_calisma_saati':
          p.gunlukCalismaSaati.isEmpty ? null : num.tryParse(p.gunlukCalismaSaati),
      'haftalik_calisma_gunu':
          p.haftalikCalismaGunu.isEmpty ? null : num.tryParse(p.haftalikCalismaGunu),
      'yol_ucreti': p.yolUcreti.isEmpty ? null : num.tryParse(p.yolUcreti),
      'yemek_ucreti': p.yemekUcreti.isEmpty ? null : num.tryParse(p.yemekUcreti),
      'ekstra_prim': p.ekstraPrim.isEmpty ? null : num.tryParse(p.ekstraPrim),
      'elden_maas':
          (p.eldenMaas.isEmpty || num.tryParse(p.eldenMaas) == null) ? 0 : num.tryParse(p.eldenMaas),
      'banka_maas': p.bankaMaas.isEmpty ? null : num.tryParse(p.bankaMaas),
      'adres': p.adres,
      'net_maas': p.netMaas.isEmpty ? null : num.tryParse(p.netMaas),
      'yillik_izin_hakki':
          p.yillikIzinHakki.isEmpty ? null : int.tryParse(p.yillikIzinHakki),
      'user_id': p.userId,
    });
  }

  Future<PersonelModel?> getPersonelByTckn(String tckn) async {
    final response = await _client
        .from(DbTables.personel)
        .select()
        .eq('firma_id', _firmaId)
        .eq('tckn', tckn)
        .maybeSingle();
    if (response == null) return null;
    return PersonelModel.fromMap(response);
  }

  Future<PersonelModel?> getPersonelById(String userId) async {
    try {
      final response = await _client
          .from(DbTables.personel)
          .select()
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) {
        debugPrint('PersonelService.getPersonelById: Personel bulunamadi');
        return null;
      }
      return PersonelModel.fromMap(response);
    } catch (e) {
      debugPrint('PersonelService.getPersonelById HATA: $e');
      return null;
    }
  }

  Future<PersonelModel?> getPersonelByUserId(String userId) => getPersonelById(userId);

  Future<void> updatePersonel(PersonelModel p) async {
    await _client
        .from(DbTables.personel)
        .update({
          'ad': p.ad,
          'soyad': p.soyad,
          'pozisyon': p.pozisyon,
          'departman': p.departman,
          'email': p.email,
          'telefon': p.telefon,
          'ise_baslangic': _dateOrNull(p.iseBaslangic),
          'brut_maas': p.brutMaas.isEmpty ? null : num.tryParse(p.brutMaas),
          'sgk_sicil_no': p.sgkSicilNo,
          'gunluk_calisma_saati':
              p.gunlukCalismaSaati.isEmpty ? null : num.tryParse(p.gunlukCalismaSaati),
          'haftalik_calisma_gunu':
              p.haftalikCalismaGunu.isEmpty ? null : num.tryParse(p.haftalikCalismaGunu),
          'yol_ucreti': p.yolUcreti.isEmpty ? null : num.tryParse(p.yolUcreti),
          'yemek_ucreti': p.yemekUcreti.isEmpty ? null : num.tryParse(p.yemekUcreti),
          'ekstra_prim': p.ekstraPrim.isEmpty ? null : num.tryParse(p.ekstraPrim),
          'elden_maas': (p.eldenMaas.isEmpty || num.tryParse(p.eldenMaas) == null)
              ? 0
              : num.tryParse(p.eldenMaas),
          'banka_maas': p.bankaMaas.isEmpty ? null : num.tryParse(p.bankaMaas),
          'adres': p.adres,
          'net_maas': p.netMaas.isEmpty ? null : num.tryParse(p.netMaas),
          'yillik_izin_hakki':
              p.yillikIzinHakki.isEmpty ? null : int.tryParse(p.yillikIzinHakki),
        })
        .eq('firma_id', _firmaId)
        .eq('tckn', p.tckn);
  }

  Future<void> deletePersonel(String tckn) async {
    try {
      await _client
          .from(DbTables.personel)
          .update({
            'durum': 'pasif',
          })
          .eq('firma_id', _firmaId)
          .eq('tckn', tckn);
    } catch (e) {
      debugPrint('PersonelService.deletePersonel HATA: $e');
      rethrow;
    }
  }

  Future<void> kaliciSil(String tckn) async {
    await _client.from(DbTables.personel).delete().eq('firma_id', _firmaId).eq('tckn', tckn);
  }

  Future<void> aktifYap(String tckn) async {
    await _client
        .from(DbTables.personel)
        .update({
          'durum': 'aktif',
        })
        .eq('firma_id', _firmaId)
        .eq('tckn', tckn);
  }

  Future<void> istenCikar({
    required String userId,
    required String tckn,
    required String neden,
    String? cikisTarihi,
  }) async {
    await EdgeFunctionService.instance.personelYonet(
      action: 'isten_cikar',
      firmaId: _firmaId,
      userId: userId,
      tckn: tckn,
      neden: neden,
      cikisTarihi: cikisTarihi,
    );
  }

  Future<void> personelAktifYap({
    required String userId,
    required String tckn,
  }) async {
    await EdgeFunctionService.instance.personelYonet(
      action: 'aktif_yap',
      firmaId: _firmaId,
      userId: userId,
      tckn: tckn,
    );
  }

  Future<void> personeliKaliciSil({
    required String userId,
    required String tckn,
  }) async {
    await EdgeFunctionService.instance.personelYonet(
      action: 'kalici_sil',
      firmaId: _firmaId,
      userId: userId,
      tckn: tckn,
    );
  }
}
