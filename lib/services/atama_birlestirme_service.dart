import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AtamaBirlestirmeService {
  AtamaBirlestirmeService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _aktifDurumlar = {
    '',
    'bekleyen',
    'beklemede',
    'atandi',
    'onaylandi',
    'onay_bekliyor',
    'firma_onay_bekliyor',
    'kabul_edildi',
    'kontrol_bekliyor',
    'baslandi',
    'baslatildi',
    'uretimde',
    'devam_ediyor',
    'kontrolde',
    'islemde',
    'isleniyor',
    'kismi_tamamlandi',
    'sevk_ediliyor',
    'kismen_sevk',
  };

  static const _secilebilirKolonlar = [
    'id',
    'model_id',
    'durum',
    'adet',
    'talep_edilen_adet',
    'kabul_edilen_adet',
    'kontrol_edilecek_adet',
    'alinan_adet',
    'kalan_adet',
    'sevk_edilen_adet',
    'tamamlanan_adet',
    'beden_detaylari',
    'notlar',
    'tedarikci_id',
    'atanan_kullanici_id',
    'idempotency_key',
    'created_at',
  ];

  static const _varsayilanAdetKolonlari = [
    'adet',
    'talep_edilen_adet',
    'kabul_edilen_adet',
    'kontrol_edilecek_adet',
    'alinan_adet',
    'kalan_adet',
    'sevk_edilen_adet',
    'tamamlanan_adet',
  ];

  static List<Map<String, dynamic>> mergeForDisplay(
    List<Map<String, dynamic>> rows, {
    List<String> quantityFields = _varsayilanAdetKolonlari,
  }) {
    final grouped = <String, Map<String, dynamic>>{};
    final order = <String>[];

    for (final row in rows) {
      final modelId = row['model_id']?.toString();
      if (modelId == null || modelId.isEmpty) {
        final fallbackKey = 'row:${row['id'] ?? order.length}';
        grouped[fallbackKey] = Map<String, dynamic>.from(row);
        order.add(fallbackKey);
        continue;
      }

      final key = '$modelId:${_durumGrubu(row['durum'])}';
      final existing = grouped[key];
      if (existing == null) {
        final first = Map<String, dynamic>.from(row);
        first['_merged_record_ids'] = [row['id']];
        grouped[key] = first;
        order.add(key);
        continue;
      }

      final ids = List<dynamic>.from(existing['_merged_record_ids'] ?? []);
      ids.add(row['id']);
      existing['_merged_record_ids'] = ids;

      for (final field in quantityFields) {
        if (!row.containsKey(field)) continue;
        final incoming = _toInt(row[field]);
        if (incoming <= 0) continue;
        existing[field] = _toInt(existing[field]) + incoming;
      }

      final existingBeden = _parseBedenDetayi(existing['beden_detaylari']);
      final incomingBeden = _parseBedenDetayi(
        row['beden_detaylari'] ?? row['beden_dagilimi'],
      );
      if (incomingBeden.isNotEmpty) {
        final merged = <String, int>{...existingBeden};
        for (final entry in incomingBeden.entries) {
          merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
        }
        existing['beden_detaylari'] = _siraliBedenMap(merged);
      }

      final yeniNot =
          (row['notlar'] ?? row['aciklama'] ?? '').toString().trim();
      if (yeniNot.isNotEmpty) {
        final mevcutNot = (existing['notlar'] ?? existing['aciklama'] ?? '')
            .toString()
            .trim();
        final birlesikNot = mevcutNot.isEmpty || mevcutNot.contains(yeniNot)
            ? mevcutNot.isEmpty
                ? yeniNot
                : mevcutNot
            : '$mevcutNot\n$yeniNot';
        if (existing.containsKey('notlar')) {
          existing['notlar'] = birlesikNot;
        } else if (existing.containsKey('aciklama')) {
          existing['aciklama'] = birlesikNot;
        }
      }
    }

    return order.map((key) => grouped[key]!).toList();
  }

  Future<Map<String, dynamic>> insertOrMerge({
    required String tableName,
    required String firmaId,
    required dynamic modelId,
    required Map<String, dynamic> values,
    Map<String, dynamic> matchFields = const {},
    String? idempotencyKey,
    List<String> quantityFields = const [
      'adet',
      'talep_edilen_adet',
      'kabul_edilen_adet',
      'kontrol_edilecek_adet',
      'alinan_adet',
      'kalan_adet',
    ],
  }) async {
    final normalizedValues = Map<String, dynamic>.from(values);
    normalizedValues['firma_id'] = firmaId;
    normalizedValues['model_id'] = modelId;
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      normalizedValues['idempotency_key'] = idempotencyKey;
    }

    final idempotentKayit = await _idempotentKayitBul(
      tableName: tableName,
      firmaId: firmaId,
      idempotencyKey: idempotencyKey,
    );

    final mevcutKayit = idempotentKayit ??
        await _aktifModelKaydiBul(
          tableName: tableName,
          firmaId: firmaId,
          modelId: modelId,
          matchFields: matchFields,
        );

    if (mevcutKayit == null) {
      await _esnekInsert(tableName, normalizedValues);
      return {'merged': false, 'idempotent': false};
    }

    final updateData = _mergeData(
      mevcutKayit: mevcutKayit,
      incoming: normalizedValues,
      quantityFields: quantityFields,
      addQuantities: idempotentKayit == null,
    );

    await _esnekUpdate(
      tableName: tableName,
      firmaId: firmaId,
      kayitId: mevcutKayit['id'],
      values: updateData,
    );

    return {
      'merged': true,
      'idempotent': idempotentKayit != null,
      'id': mevcutKayit['id'],
    };
  }

  Future<Map<String, dynamic>?> _idempotentKayitBul({
    required String tableName,
    required String firmaId,
    required String? idempotencyKey,
  }) async {
    if (idempotencyKey == null || idempotencyKey.isEmpty) return null;
    final columns = List<String>.from(_secilebilirKolonlar);
    try {
      while (true) {
        try {
          final response = await _client
              .from(tableName)
              .select(columns.join(', '))
              .eq('firma_id', firmaId)
              .eq('idempotency_key', idempotencyKey)
              .maybeSingle();
          return response == null ? null : Map<String, dynamic>.from(response);
        } catch (e) {
          final missing = _missingColumnName(e);
          if (missing != null && columns.remove(missing)) {
            continue;
          }
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Atama idempotency araması atlandı: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _aktifModelKaydiBul({
    required String tableName,
    required String firmaId,
    required dynamic modelId,
    required Map<String, dynamic> matchFields,
  }) async {
    List<dynamic> rows;
    final columns = List<String>.from(_secilebilirKolonlar);
    final activeMatchFields = Map<String, dynamic>.from(matchFields);
    try {
      while (true) {
        try {
          var query = _client
              .from(tableName)
              .select(columns.join(', '))
              .eq('firma_id', firmaId)
              .eq('model_id', modelId);
          for (final entry in activeMatchFields.entries) {
            if (entry.value != null) {
              query = query.eq(entry.key, entry.value);
            }
          }
          rows = await query.order('created_at', ascending: true).limit(25);
          break;
        } catch (e) {
          final missing = _missingColumnName(e);
          if (missing != null && columns.remove(missing)) {
            continue;
          }
          if (missing != null && activeMatchFields.remove(missing) != null) {
            continue;
          }
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Atama birleştirme araması başarısız: $e');
      return null;
    }

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final durum = _normalize(row['durum']);
      if (_aktifDurumlar.contains(durum)) {
        return row;
      }
    }
    return null;
  }

  Map<String, dynamic> _mergeData({
    required Map<String, dynamic> mevcutKayit,
    required Map<String, dynamic> incoming,
    required List<String> quantityFields,
    required bool addQuantities,
  }) {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    for (final key in quantityFields) {
      if (!incoming.containsKey(key)) continue;
      final incomingValue = _toInt(incoming[key]);
      if (incomingValue <= 0) continue;
      final mevcutValue = _toInt(mevcutKayit[key]);
      updateData[key] =
          addQuantities ? mevcutValue + incomingValue : incomingValue;
    }

    if (!addQuantities &&
        incoming.containsKey('alinan_adet') &&
        updateData.containsKey('kalan_adet')) {
      final sevkEdilen = _toInt(mevcutKayit['sevk_edilen_adet']);
      final alinan = _toInt(incoming['alinan_adet']);
      updateData['kalan_adet'] = (alinan - sevkEdilen).clamp(0, 999999999);
    }

    final mevcutBeden = _parseBedenDetayi(mevcutKayit['beden_detaylari']);
    final yeniBeden = _parseBedenDetayi(incoming['beden_detaylari']);
    if (yeniBeden.isNotEmpty) {
      final merged = <String, int>{...mevcutBeden};
      for (final entry in yeniBeden.entries) {
        merged[entry.key] =
            (addQuantities ? (merged[entry.key] ?? 0) : 0) + entry.value;
      }
      updateData['beden_detaylari'] = _siraliBedenMap(merged);
    }

    final yeniNot = (incoming['notlar'] ?? '').toString().trim();
    if (yeniNot.isNotEmpty) {
      final mevcutNot = (mevcutKayit['notlar'] ?? '').toString().trim();
      updateData['notlar'] = mevcutNot.isEmpty || mevcutNot.contains(yeniNot)
          ? yeniNot
          : '$mevcutNot\n$yeniNot';
    }

    if (incoming.containsKey('durum') &&
        _normalize(mevcutKayit['durum']).isEmpty) {
      updateData['durum'] = incoming['durum'];
    }

    final yeniIdempotency = (incoming['idempotency_key'] ?? '').toString();
    if (yeniIdempotency.isNotEmpty &&
        yeniIdempotency != (mevcutKayit['idempotency_key'] ?? '').toString()) {
      updateData['idempotency_key'] = yeniIdempotency;
    }

    return updateData;
  }

  Future<void> _esnekInsert(
    String tableName,
    Map<String, dynamic> values,
  ) async {
    final payload = Map<String, dynamic>.from(values);
    while (true) {
      try {
        await _client.from(tableName).insert(payload);
        return;
      } catch (e) {
        final missing = _missingColumnName(e);
        if (missing != null && payload.containsKey(missing)) {
          payload.remove(missing);
          continue;
        }
        rethrow;
      }
    }
  }

  Future<void> _esnekUpdate({
    required String tableName,
    required String firmaId,
    required dynamic kayitId,
    required Map<String, dynamic> values,
  }) async {
    final payload = Map<String, dynamic>.from(values);
    while (true) {
      try {
        await _client
            .from(tableName)
            .update(payload)
            .eq('id', kayitId)
            .eq('firma_id', firmaId);
        return;
      } catch (e) {
        final missing = _missingColumnName(e);
        if (missing != null && payload.containsKey(missing)) {
          payload.remove(missing);
          continue;
        }
        rethrow;
      }
    }
  }

  static String _normalize(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('i̇', 'i')
        .replaceAll('ı', 'i')
        .replaceAll(' ', '_');
  }

  static String _durumGrubu(dynamic value) {
    final durum = _normalize(value);
    if (durum.isEmpty ||
        {
          'bekleyen',
          'beklemede',
          'atandi',
          'firma_onay_bekliyor',
          'onay_bekliyor',
          'kontrol_bekliyor',
        }.contains(durum)) {
      return 'bekleyen';
    }
    if ({'onaylandi', 'kabul_edildi'}.contains(durum)) {
      return 'onaylanan';
    }
    if ({
      'baslandi',
      'baslatildi',
      'uretimde',
      'devam_ediyor',
      'kontrolde',
      'islemde',
      'isleniyor',
      'kismi_tamamlandi',
      'sevk_ediliyor',
      'kismen_sevk',
    }.contains(durum)) {
      return 'islemde';
    }
    if (durum == 'tamamlandi') return 'tamamlanan';
    return durum;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static Map<String, int> _parseBedenDetayi(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      final result = <String, int>{};
      raw.forEach((key, value) {
        final beden = key.toString().trim();
        final adet = _toInt(value);
        if (beden.isNotEmpty && adet > 0) result[beden] = adet;
      });
      return _siraliBedenMap(result);
    }
    return {};
  }

  static Map<String, int> _siraliBedenMap(Map<String, int> input) {
    final keys = input.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final key in keys) key: input[key] ?? 0};
  }

  static String? _missingColumnName(Object e) {
    final text = e.toString();
    final patterns = [
      RegExp(r"Could not find the '([^']+)' column"),
      RegExp(r'column "?([a-zA-Z0-9_]+)"? does not exist'),
      RegExp(r'Could not find column "?([a-zA-Z0-9_]+)"?'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }
}
