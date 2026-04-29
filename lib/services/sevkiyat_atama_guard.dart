import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';

class SevkiyatAtamaGuard {
  SevkiyatAtamaGuard({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static bool sevkGerektirir(String asama) {
    final normalized = _normalize(asama);
    return normalized == 'utu' ||
        normalized == 'paketleme' ||
        normalized == 'utu_paket';
  }

  static String normalizeHedefAsama(String asama) {
    final normalized = _normalize(asama);
    if (normalized == 'utu_paket') return 'utu';
    return normalized;
  }

  Future<bool> hedefAsamayaSevkVarMi({
    required String modelId,
    required String hedefAsama,
    required String firmaId,
  }) async {
    final hedefAliaslari = _hedefAliaslari(hedefAsama);

    if (await _sevkiyatKaydindaVarMi(
      modelId: modelId,
      firmaId: firmaId,
      hedefAliaslari: hedefAliaslari,
    )) {
      return true;
    }

    for (final table in _kaynakAtamaTablolari) {
      if (await _kaynakAtamadaVarMi(
        table: table,
        modelId: modelId,
        firmaId: firmaId,
        hedefAliaslari: hedefAliaslari,
      )) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _sevkiyatKaydindaVarMi({
    required String modelId,
    required String firmaId,
    required Set<String> hedefAliaslari,
  }) async {
    try {
      final records = await _client
          .from(DbTables.sevkiyatKayitlari)
          .select('id, durum, hedef_asama')
          .eq('firma_id', firmaId)
          .eq('model_id', modelId)
          .limit(100);

      return _kayitlardaHedefVarMi(records, hedefAliaslari);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _kaynakAtamadaVarMi({
    required String table,
    required String modelId,
    required String firmaId,
    required Set<String> hedefAliaslari,
  }) async {
    try {
      final records = await _client
          .from(table)
          .select('id, durum, hedef_asama')
          .eq('firma_id', firmaId)
          .eq('model_id', modelId)
          .limit(100);

      return _kayitlardaHedefVarMi(records, hedefAliaslari);
    } catch (_) {
      return false;
    }
  }

  bool _kayitlardaHedefVarMi(
    List<dynamic> records,
    Set<String> hedefAliaslari,
  ) {
    for (final rawRecord in records) {
      if (rawRecord is! Map) continue;

      final hedef =
          normalizeHedefAsama(rawRecord['hedef_asama']?.toString() ?? '');
      if (!hedefAliaslari.contains(hedef)) continue;

      final durum = _normalize(rawRecord['durum']?.toString() ?? '');
      if (_iptalDurumlari.contains(durum)) continue;

      return true;
    }
    return false;
  }

  static Set<String> _hedefAliaslari(String hedefAsama) {
    final normalized = normalizeHedefAsama(hedefAsama);
    if (normalized == 'utu' || normalized == 'paketleme') {
      return {'utu', 'paketleme', 'utu_paket'};
    }
    return {normalized};
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static const Set<String> _iptalDurumlari = {
    'iptal',
    'iptal_edildi',
    'silindi',
    'pasif',
  };

  static const List<String> _kaynakAtamaTablolari = [
    DbTables.dokumaAtamalari,
    DbTables.konfeksiyonAtamalari,
    DbTables.nakisAtamalari,
    DbTables.yikamaAtamalari,
    DbTables.ilikDugmeAtamalari,
    DbTables.kaliteKontrolAtamalari,
  ];
}
