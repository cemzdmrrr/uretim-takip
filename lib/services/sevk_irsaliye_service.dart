import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';

class SevkIrsaliyeService {
  SevkIrsaliyeService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> olusturVeOnayla({
    required String firmaId,
    required String kaynakAsama,
    required String hedefAsama,
    required String kaynakTablo,
    required dynamic kaynakKayitId,
    required dynamic modelId,
    required int sevkAdedi,
    int? hedefTedarikciId,
    String? notlar,
    String? olusturanId,
    String? idempotencyKey,
    List<Map<String, dynamic>> detayKalemleri = const [],
  }) async {
    if (sevkAdedi <= 0) {
      throw Exception('Irsaliye olusturulamadi: sevk adedi 0 veya negatif olamaz.');
    }

    final normalizedIdempotency = (idempotencyKey ?? '').trim();
    if (normalizedIdempotency.isNotEmpty) {
      final mevcut = await _mevcutIrsaliyeBul(
        firmaId: firmaId,
        idempotencyKey: normalizedIdempotency,
      );
      if (mevcut != null) {
        return mevcut;
      }
    }

    final now = DateTime.now().toIso8601String();

    for (var attempt = 0; attempt < 3; attempt++) {
      final irsaliyeNo = await _sonrakiIrsaliyeNo(firmaId);
      final header = <String, dynamic>{
        'firma_id': firmaId,
        'irsaliye_no': irsaliyeNo,
        'kaynak_asama': kaynakAsama,
        'hedef_asama': hedefAsama,
        'kaynak_tablo': kaynakTablo,
        'kaynak_kayit_id': _toNullableString(kaynakKayitId),
        'model_id': _toRequiredString(modelId, fieldName: 'model_id'),
        'sevk_adedi': sevkAdedi,
        'hedef_tedarikci_id': hedefTedarikciId,
        'sevk_tarihi': now,
        'durum': 'onaylandi',
        'notlar': notlar,
        'created_by': olusturanId,
        'onaylayan_id': olusturanId,
        'onay_tarihi': now,
      };

      if (normalizedIdempotency.isNotEmpty) {
        header['idempotency_key'] = normalizedIdempotency;
      }

      try {
        final created = await _supabase
            .from(DbTables.sevkIrsaliyeleri)
            .insert(header)
            .select('id, irsaliye_no, model_id, sevk_adedi')
            .single();

        final irsaliyeId = created['id'];
        final kalemler = detayKalemleri.isEmpty
            ? <Map<String, dynamic>>[
                {
                  'model_id': modelId,
                  'adet': sevkAdedi,
                  'birim': 'adet',
                }
              ]
            : detayKalemleri;

        final kalemInsert = kalemler
            .map(
              (kalem) => <String, dynamic>{
                'irsaliye_id': irsaliyeId,
                'firma_id': firmaId,
                'model_id': _toRequiredString(
                  kalem['model_id'] ?? modelId,
                  fieldName: 'kalem.model_id',
                ),
                'beden_kodu': kalem['beden_kodu'],
                'koli_adedi': kalem['koli_adedi'],
                'adet': _toInt(kalem['adet']) > 0 ? _toInt(kalem['adet']) : sevkAdedi,
                'birim': (kalem['birim'] ?? 'adet').toString(),
                'aciklama': kalem['aciklama'],
              },
            )
            .toList();

        await _supabase.from(DbTables.sevkIrsaliyeKalemleri).insert(kalemInsert);

        return Map<String, dynamic>.from(created);
      } on PostgrestException catch (e) {
        final message =
            '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
        final duplicateError =
            message.contains('duplicate') || message.contains('unique');

        if (message.contains('invalid input syntax for type bigint')) {
          throw Exception(
            'Sevk irsaliye tablosunda ID tip uyumsuzlugu var (UUID -> bigint). '
            'Lutfen sql/sevk_irsaliye_schema.sql dosyasini tekrar calistirip '
            'model_id ve kaynak_kayit_id kolonlarini text tipine guncelleyin.',
          );
        }

        if (duplicateError && attempt < 2) {
          continue;
        }

        rethrow;
      }
    }

    throw Exception('Irsaliye numarasi olusturulamadi, tekrar deneyin.');
  }

  Future<Map<String, dynamic>?> _mevcutIrsaliyeBul({
    required String firmaId,
    required String idempotencyKey,
  }) async {
    try {
      final data = await _supabase
          .from(DbTables.sevkIrsaliyeleri)
          .select('id, irsaliye_no, model_id, sevk_adedi')
          .eq('firma_id', firmaId)
          .eq('idempotency_key', idempotencyKey)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Future<String> _sonrakiIrsaliyeNo(String firmaId) async {
    final year = DateTime.now().year;
    final prefix = 'IRS-$year-';

    try {
      final last = await _supabase
          .from(DbTables.sevkIrsaliyeleri)
          .select('irsaliye_no')
          .eq('firma_id', firmaId)
          .like('irsaliye_no', '$prefix%')
          .order('irsaliye_no', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastNo = (last?['irsaliye_no'] ?? '').toString();
      final match = RegExp(r'^IRS-(\d{4})-(\d+)$').firstMatch(lastNo);
      final seq = match == null ? 0 : int.tryParse(match.group(2) ?? '0') ?? 0;
      final next = seq + 1;
      return '$prefix${next.toString().padLeft(6, '0')}';
    } catch (_) {
      return '$prefix${'1'.padLeft(6, '0')}';
    }
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _toRequiredString(dynamic value, {required String fieldName}) {
    final text = _toNullableString(value);
    if (text == null) {
      throw Exception('Gerekli alan bos: $fieldName');
    }
    return text;
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
