import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class IplikLokasyonSayimService {
  IplikLokasyonSayimService._();
  static final _client = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  static Future<List<Map<String, dynamic>>> lokasyonlariGetir({
    bool sadeceAktif = false,
  }) async {
    var query = _client
        .from(DbTables.iplikLokasyonlari)
        .select('*')
        .eq('firma_id', _firmaId);
    if (sadeceAktif) query = query.eq('aktif', true);
    final rows =
        await query.order('sistem_lokasyonu', ascending: false).order('kod');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<Map<String, dynamic>> lokasyonKaydet({
    String? id,
    required String kod,
    required String ad,
    String? aciklama,
  }) async {
    final data = {
      'firma_id': _firmaId,
      'kod': kod.trim().toUpperCase(),
      'ad': ad.trim(),
      'aciklama': aciklama?.trim().isEmpty == true ? null : aciklama?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (id == null) {
      final row = await _client
          .from(DbTables.iplikLokasyonlari)
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(row);
    }
    final row = await _client
        .from(DbTables.iplikLokasyonlari)
        .update(data)
        .eq('firma_id', _firmaId)
        .eq('id', id)
        .eq('sistem_lokasyonu', false)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  static Future<void> lokasyonAktiflikDegistir(String id, bool aktif) async {
    await _client
        .from(DbTables.iplikLokasyonlari)
        .update(
            {'aktif': aktif, 'updated_at': DateTime.now().toIso8601String()})
        .eq('firma_id', _firmaId)
        .eq('id', id)
        .eq('sistem_lokasyonu', false);
  }

  static Future<List<Map<String, dynamic>>> stokDagilimlariGetir() async {
    final rows = await _client
        .from(DbTables.iplikStokLokasyonlari)
        .select('*, iplik_lokasyonlari(*), iplik_stoklari(ad, renk, lot_no)')
        .eq('firma_id', _firmaId)
        .gt('miktar', 0);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> transferEt({
    required String stokId,
    required String kaynakLokasyonId,
    required String hedefLokasyonId,
    required double miktar,
    String? aciklama,
  }) async {
    await _client.rpc('iplik_lokasyonlu_stok_hareket_kaydet', params: {
      'p_firma_id': _firmaId,
      'p_iplik_id': stokId,
      'p_hareket_tipi': 'transfer',
      'p_miktar': miktar,
      'p_aciklama': aciklama,
      'p_kaynak_lokasyon_id': kaynakLokasyonId,
      'p_hedef_lokasyon_id': hedefLokasyonId,
    });
  }

  static Future<List<Map<String, dynamic>>> sayimlariGetir() async {
    final rows = await _client
        .from(DbTables.iplikSayimOturumlari)
        .select(
            '*, iplik_sayim_oturum_lokasyonlari(lokasyon_id, iplik_lokasyonlari(kod, ad)), iplik_sayim_satirlari(id, beklenen_miktar, sayilan_miktar)')
        .eq('firma_id', _firmaId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> sayimAc({
    required List<String> lokasyonIds,
    String? aciklama,
  }) async {
    final id = await _client.rpc('iplik_sayim_oturumu_ac', params: {
      'p_firma_id': _firmaId,
      'p_aciklama': aciklama,
      'p_lokasyon_ids': lokasyonIds,
    });
    return id.toString();
  }

  static Future<List<Map<String, dynamic>>> sayimSatirlariGetir(
      String sayimId) async {
    final rows = await _client
        .from(DbTables.iplikSayimSatirlari)
        .select(
            '*, iplik_lokasyonlari(kod, ad), iplik_stoklari(ad, renk, lot_no, iplik_kalinligi, iplik_karisimi)')
        .eq('firma_id', _firmaId)
        .eq('sayim_id', sayimId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> sayimSatiriKaydet({
    required String sayimId,
    required String lokasyonId,
    required String stokId,
    required double sayilan,
  }) async {
    await _client.rpc('iplik_sayim_satiri_kaydet', params: {
      'p_firma_id': _firmaId,
      'p_sayim_id': sayimId,
      'p_lokasyon_id': lokasyonId,
      'p_stok_id': stokId,
      'p_sayilan': sayilan,
    });
  }

  static Future<void> sayimKapat(String id) => _client.rpc(
        'iplik_sayim_oturumu_kapat',
        params: {'p_firma_id': _firmaId, 'p_sayim_id': id},
      );
  static Future<void> sayimIptal(String id) => _client.rpc(
        'iplik_sayim_oturumu_iptal',
        params: {'p_firma_id': _firmaId, 'p_sayim_id': id},
      );
}
