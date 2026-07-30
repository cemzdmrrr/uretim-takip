import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class IplikModelTahsisService {
  IplikModelTahsisService._();

  static final _client = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  static Future<List<Map<String, dynamic>>> modelleriGetir() async {
    final response = await _client
        .from(DbTables.trikoTakip)
        .select('id, marka, item_no')
        .eq('firma_id', _firmaId)
        .order('marka');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> stokTahsisleriGetir(
    String stokId,
  ) async {
    final response = await _client
        .from(DbTables.iplikStokModelTahsisleri)
        .select('*, triko_takip(id, marka, item_no)')
        .eq('firma_id', _firmaId)
        .eq('stok_id', stokId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> siparisTahsisleriGetir(
    String siparisId,
  ) async {
    final response = await _client
        .from(DbTables.iplikSiparisModelTahsisleri)
        .select('*, triko_takip(id, marka, item_no)')
        .eq('firma_id', _firmaId)
        .eq('siparis_id', siparisId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> stokTahsisleriniKaydet(
    String stokId,
    List<Map<String, dynamic>> tahsisler,
  ) async {
    await _client.rpc('iplik_model_tahsisleri_kaydet', params: {
      'p_firma_id': _firmaId,
      'p_kaynak_tipi': 'stok',
      'p_kaynak_id': stokId,
      'p_tahsisler': tahsisler,
    });
  }

  static Future<void> siparisTahsisleriniKaydet(
    String siparisId,
    List<Map<String, dynamic>> tahsisler,
  ) async {
    await _client.rpc('iplik_model_tahsisleri_kaydet', params: {
      'p_firma_id': _firmaId,
      'p_kaynak_tipi': 'siparis',
      'p_kaynak_id': siparisId,
      'p_tahsisler': tahsisler,
    });
  }

  static double toplamTahsis(Iterable<Map<String, dynamic>> tahsisler) =>
      tahsisler.fold(0, (toplam, item) {
        final value = item['tahsis_miktari'];
        return toplam + (value is num ? value.toDouble() : 0);
      });
}
