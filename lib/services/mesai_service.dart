import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/mesai_model.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class MesaiService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  Future<List<MesaiModel>> getMesailerForPersonel(String personelId,
      {String? donem}) async {
    try {
      debugPrint(
          'MesaiService.getMesailerForPersonel: personelId=$personelId, donem=$donem');
      var query = _client
          .from(DbTables.mesai)
          .select()
          .eq('firma_id', _firmaId)
          .eq('user_id', personelId);

      // Eğer dönem seçilmişse, o döneme ait kayıtları filtrele
      if (donem != null && donem.isNotEmpty) {
        final parts = donem.split('-');
        if (parts.length == 2) {
          final yil = int.tryParse(parts[0]);
          final ay = int.tryParse(parts[1]);
          if (yil != null && ay != null) {
            final baslangicTarihi = DateTime(yil, ay, 1);
            final sonrakiDonemBaslangici = DateTime(yil, ay + 1, 1);
            query = query
                .gte('tarih', baslangicTarihi.toIso8601String().split('T')[0])
                .lt('tarih',
                    sonrakiDonemBaslangici.toIso8601String().split('T')[0]);
          }
        }
      }

      final response = await query.order('tarih', ascending: false);
      debugPrint(
          'MesaiService.getMesailerForPersonel: ${(response as List).length} kayıt bulundu');
      return _mesaiListesiOlustur(response);
    } catch (e) {
      debugPrint('MesaiService.getMesailerForPersonel HATA: $e');
      return [];
    }
  }

  List<MesaiModel> _mesaiListesiOlustur(List<dynamic> response) {
    final mesailer = <MesaiModel>[];
    for (final row in response) {
      try {
        mesailer.add(MesaiModel.fromMap(Map<String, dynamic>.from(row as Map)));
      } catch (e) {
        debugPrint('MesaiService satır parse edilemedi: $e, row=$row');
      }
    }
    return mesailer;
  }

  Future<void> addMesai(MesaiModel mesai) async {
    final mesaiData = mesai.toMap();
    mesaiData['firma_id'] = _firmaId;
    final response = await _client
        .from(DbTables.mesai)
        .insert(mesaiData)
        .select('id')
        .single();
    final mesaiId = response['id']?.toString();
    if (mesaiId != null && mesaiId.isNotEmpty) {
      await BildirimService().mesaiTalebiBildir(
        mesaiId: mesaiId,
        personelId: (mesai.userId ?? '').trim().isNotEmpty
            ? mesai.userId!
            : mesai.personelId,
        mesaiTuru: mesai.mesaiTuru,
        tarih: mesai.tarih.toIso8601String().split('T').first,
        saat: mesai.saat ?? 0,
      );
    }
  }

  Future<void> addMesaiRaw(Map<String, dynamic> data) async {
    debugPrint('=== MesaiService.addMesaiRaw ===');
    debugPrint('Gelen data: $data');

    // baslangic_saati ve bitis_saati alanlarını sadece saat:dk formatında gönder
    if (data['baslangic_saati'] is DateTime) {
      final dt = data['baslangic_saati'] as DateTime;
      data['baslangic_saati'] =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['baslangic_saati'] is String &&
        data['baslangic_saati'].contains('T')) {
      // Eğer yanlışlıkla string DateTime gelirse
      final t = DateTime.tryParse(data['baslangic_saati']);
      if (t != null) {
        data['baslangic_saati'] =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    }
    if (data['bitis_saati'] is DateTime) {
      final dt = data['bitis_saati'] as DateTime;
      data['bitis_saati'] =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['bitis_saati'] is String &&
        data['bitis_saati'].contains('T')) {
      final t = DateTime.tryParse(data['bitis_saati']);
      if (t != null) {
        data['bitis_saati'] =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    }
    // Saat hesapla ve ekle
    if (data['baslangic_saati'] != null && data['bitis_saati'] != null) {
      final bas = data['baslangic_saati'];
      final bit = data['bitis_saati'];
      int bSaat = 0, bDak = 0, eSaat = 0, eDak = 0;
      if (bas is String && bas.contains(':')) {
        final parts = bas.split(':');
        bSaat = int.tryParse(parts[0]) ?? 0;
        bDak = int.tryParse(parts[1]) ?? 0;
      }
      if (bit is String && bit.contains(':')) {
        final parts = bit.split(':');
        eSaat = int.tryParse(parts[0]) ?? 0;
        eDak = int.tryParse(parts[1]) ?? 0;
      }
      final diff = _mesaiDakikasiHesapla(
        baslangicSaat: bSaat,
        baslangicDakika: bDak,
        bitisSaat: eSaat,
        bitisDakika: eDak,
      );
      data['saat'] = double.parse((diff / 60).toStringAsFixed(2));
    }

    // carpan alanını double olarak gönder (veritabanı tipi numeric/decimal olmalı)
    if (data['carpan'] != null) {
      data['carpan'] = (data['carpan'] is num)
          ? data['carpan'].toDouble()
          : double.tryParse(data['carpan'].toString()) ?? 1.0;
    }

    // mesai_ucret ve yemek_ucreti de double olmalı
    if (data['mesai_ucret'] != null) {
      data['mesai_ucret'] = (data['mesai_ucret'] is num)
          ? data['mesai_ucret'].toDouble()
          : double.tryParse(data['mesai_ucret'].toString()) ?? 0.0;
    }
    if (data['yemek_ucreti'] != null) {
      data['yemek_ucreti'] = (data['yemek_ucreti'] is num)
          ? data['yemek_ucreti'].toDouble()
          : double.tryParse(data['yemek_ucreti'].toString()) ?? 0.0;
    }

    data['firma_id'] = _firmaId;
    debugPrint('Insert edilecek data: $data');
    try {
      final response =
          await _client.from(DbTables.mesai).insert(data).select('id').single();
      final mesaiId = response['id']?.toString();
      if (mesaiId != null && mesaiId.isNotEmpty) {
        await BildirimService().mesaiTalebiBildir(
          mesaiId: mesaiId,
          personelId: data['user_id']?.toString() ?? '',
          mesaiTuru: data['mesai_turu']?.toString() ?? '',
          tarih: data['tarih']?.toString() ?? '',
          saat: (data['saat'] is num)
              ? (data['saat'] as num).toDouble()
              : double.tryParse(data['saat']?.toString() ?? '0') ?? 0,
        );
      }
      debugPrint('Mesai insert başarılı');
    } catch (e) {
      debugPrint('Mesai insert hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteMesai(String? id) async {
    if (id == null) return;
    await _client.from(DbTables.mesai).delete().eq('id', id);
  }

  Future<void> updateMesai(String id, Map<String, dynamic> data) async {
    // baslangic_saati ve bitis_saati alanlarını sadece saat:dk formatında gönder
    if (data['baslangic_saati'] is DateTime) {
      final dt = data['baslangic_saati'] as DateTime;
      data['baslangic_saati'] =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['baslangic_saati'] is String &&
        data['baslangic_saati'].contains('T')) {
      final t = DateTime.tryParse(data['baslangic_saati']);
      if (t != null) {
        data['baslangic_saati'] =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    }
    if (data['bitis_saati'] is DateTime) {
      final dt = data['bitis_saati'] as DateTime;
      data['bitis_saati'] =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['bitis_saati'] is String &&
        data['bitis_saati'].contains('T')) {
      final t = DateTime.tryParse(data['bitis_saati']);
      if (t != null) {
        data['bitis_saati'] =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    }
    // Saat hesapla ve ekle
    if (data['baslangic_saati'] != null && data['bitis_saati'] != null) {
      final bas = data['baslangic_saati'];
      final bit = data['bitis_saati'];
      int bSaat = 0, bDak = 0, eSaat = 0, eDak = 0;
      if (bas is String && bas.contains(':')) {
        final parts = bas.split(':');
        bSaat = int.tryParse(parts[0]) ?? 0;
        bDak = int.tryParse(parts[1]) ?? 0;
      }
      if (bit is String && bit.contains(':')) {
        final parts = bit.split(':');
        eSaat = int.tryParse(parts[0]) ?? 0;
        eDak = int.tryParse(parts[1]) ?? 0;
      }
      final diff = _mesaiDakikasiHesapla(
        baslangicSaat: bSaat,
        baslangicDakika: bDak,
        bitisSaat: eSaat,
        bitisDakika: eDak,
      );
      data['saat'] = double.parse((diff / 60).toStringAsFixed(2));
    }
    await _client.from(DbTables.mesai).update(data).eq('id', id);
  }

  /// Belirli personelin belirtilen yıl ve ay için toplam onaylı fazla mesai saatini döndürür
  Future<double> getAylikFazlaMesaiSaati(
      String personelId, int yil, int ay) async {
    final response = await _client
        .from(DbTables.mesai)
        .select('saat, tarih, onay_durumu')
        .eq('user_id', personelId)
        .eq('onay_durumu', 'onaylandi');
    return response.where((e) {
      final t = DateTime.tryParse(e['tarih'] ?? '');
      return t != null && t.year == yil && t.month == ay;
    }).fold<double>(
        0,
        (sum, e) =>
            sum +
            ((e['saat'] is num)
                ? e['saat']
                : double.tryParse(e['saat']?.toString() ?? '0') ?? 0));
  }

  /// Belirli personelin belirtilen yıl için toplam onaylı fazla mesai saatini döndürür
  Future<double> getYillikFazlaMesaiSaati(String personelId, int yil) async {
    final response = await _client
        .from(DbTables.mesai)
        .select('saat, tarih, onay_durumu')
        .eq('user_id', personelId)
        .eq('onay_durumu', 'onaylandi');
    return response.where((e) {
      final t = DateTime.tryParse(e['tarih'] ?? '');
      return t != null && t.year == yil;
    }).fold<double>(
        0,
        (sum, e) =>
            sum +
            ((e['saat'] is num)
                ? e['saat']
                : double.tryParse(e['saat']?.toString() ?? '0') ?? 0));
  }

  /// Aynı gün ve saat aralığında çakışan mesai var mı kontrolü
  Future<bool> mesaiCakisiyorMu(String personelId, DateTime tarih,
      String baslangicSaati, String bitisSaati,
      {String? excludeId}) async {
    final response = await _client
        .from(DbTables.mesai)
        .select('id, baslangic_saati, bitis_saati, tarih')
        .eq('user_id', personelId)
        .eq('tarih', tarih.toIso8601String().substring(0, 10));
    for (final e in response) {
      if (excludeId != null && e['id'].toString() == excludeId) continue;
      final bas = e['baslangic_saati'];
      final bit = e['bitis_saati'];
      if (bas == null || bit == null) continue;
      final aralik1 = _saatAraligi(baslangicSaati, bitisSaati);
      final aralik2 = _saatAraligi(bas.toString(), bit.toString());
      if (aralik1 == null || aralik2 == null) continue;
      if (_araliklarCakisiyor(aralik1, aralik2)) {
        return true;
      }
    }
    return false;
  }

  /// Mesai onay/red ve onaylayan kişi güncelleme
  Future<void> updateMesaiOnay(String id, String yeniDurum,
      {String? onaylayanId}) async {
    await _client.from(DbTables.mesai).update({
      'onay_durumu': yeniDurum,
      if (onaylayanId != null) 'onaylayan_user_id': onaylayanId,
    }).eq('id', id);
  }

  /// Mesai ücreti otomatik hesaplama
  double hesaplaMesaiUcreti(
      {required double saatlikUcret,
      required double mesaiSaati,
      double zamOrani = 1.5}) {
    return double.parse(
        (saatlikUcret * mesaiSaati * zamOrani).toStringAsFixed(2));
  }

  int _mesaiDakikasiHesapla({
    required int baslangicSaat,
    required int baslangicDakika,
    required int bitisSaat,
    required int bitisDakika,
  }) {
    final start = baslangicSaat * 60 + baslangicDakika;
    var end = bitisSaat * 60 + bitisDakika;
    if (end <= start) {
      end += const Duration(days: 1).inMinutes;
    }
    return end - start;
  }

  ({int start, int end})? _saatAraligi(String baslangic, String bitis) {
    final start = _parseSaatToMinute(baslangic);
    final endRaw = _parseSaatToMinute(bitis);
    if (start == null || endRaw == null) return null;
    var end = endRaw;
    if (end <= start) {
      end += const Duration(days: 1).inMinutes;
    }
    return (start: start, end: end);
  }

  bool _araliklarCakisiyor(
    ({int start, int end}) first,
    ({int start, int end}) second,
  ) {
    return first.start < second.end && second.start < first.end;
  }

  int? _parseSaatToMinute(String s) {
    if (!s.contains(':')) return null;
    final parts = s.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
