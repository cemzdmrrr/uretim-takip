import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/mesai_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class MesaiService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  Future<List<MesaiModel>> getMesailerForPersonel(String personelId, {String? donem}) async {
    try {
      debugPrint('MesaiService.getMesailerForPersonel: personelId=$personelId, donem=$donem');
      // Veritabanında sadece user_id var
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
            final bitisTarihi = DateTime(yil, ay + 1, 0, 23, 59, 59);
            query = query
                .gte('tarih', baslangicTarihi.toIso8601String().split('T')[0])
                .lte('tarih', bitisTarihi.toIso8601String().split('T')[0]);
          }
        }
      }
      
      final response = await query.order('tarih', ascending: false);
      debugPrint('MesaiService.getMesailerForPersonel: ${(response as List).length} kayıt bulundu');
      return response.map((e) => MesaiModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('MesaiService.getMesailerForPersonel HATA: $e');
      return [];
    }
  }

  Future<void> addMesai(MesaiModel mesai) async {
    final mesaiData = mesai.toMap();
    mesaiData['firma_id'] = _firmaId;
    await _client.from(DbTables.mesai).insert(mesaiData);
  }

  Future<void> addMesaiRaw(Map<String, dynamic> data) async {
    debugPrint('=== MesaiService.addMesaiRaw ===');
    debugPrint('Gelen data: $data');
    
    // baslangic_saati ve bitis_saati alanlarını sadece saat:dk formatında gönder
    if (data['baslangic_saati'] is DateTime) {
      final dt = data['baslangic_saati'] as DateTime;
      data['baslangic_saati'] = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['baslangic_saati'] is String && data['baslangic_saati'].contains('T')) {
      // Eğer yanlışlıkla string DateTime gelirse
      final t = DateTime.tryParse(data['baslangic_saati']);
      if (t != null) {
        data['baslangic_saati'] = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    }
    if (data['bitis_saati'] is DateTime) {
      final dt = data['bitis_saati'] as DateTime;
      data['bitis_saati'] = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['bitis_saati'] is String && data['bitis_saati'].contains('T')) {
      final t = DateTime.tryParse(data['bitis_saati']);
      if (t != null) {
        data['bitis_saati'] = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
      final start = Duration(hours: bSaat, minutes: bDak);
      final end = Duration(hours: eSaat, minutes: eDak);
      final diff = end.inMinutes - start.inMinutes;
      if (diff > 0) {
        // saat alanını double olarak gönder (string değil)
        data['saat'] = double.parse((diff / 60).toStringAsFixed(2));
      }
    }
    
    // carpan alanını double olarak gönder (veritabanı tipi numeric/decimal olmalı)
    if (data['carpan'] != null) {
      data['carpan'] = (data['carpan'] is num) ? data['carpan'].toDouble() : double.tryParse(data['carpan'].toString()) ?? 1.0;
    }
    
    // mesai_ucret ve yemek_ucreti de double olmalı
    if (data['mesai_ucret'] != null) {
      data['mesai_ucret'] = (data['mesai_ucret'] is num) ? data['mesai_ucret'].toDouble() : double.tryParse(data['mesai_ucret'].toString()) ?? 0.0;
    }
    if (data['yemek_ucreti'] != null) {
      data['yemek_ucreti'] = (data['yemek_ucreti'] is num) ? data['yemek_ucreti'].toDouble() : double.tryParse(data['yemek_ucreti'].toString()) ?? 0.0;
    }
    
    data['firma_id'] = _firmaId;
    debugPrint('Insert edilecek data: $data');
    try {
      await _client.from(DbTables.mesai).insert(data);
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
      data['baslangic_saati'] = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['baslangic_saati'] is String && data['baslangic_saati'].contains('T')) {
      final t = DateTime.tryParse(data['baslangic_saati']);
      if (t != null) {
        data['baslangic_saati'] = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    }
    if (data['bitis_saati'] is DateTime) {
      final dt = data['bitis_saati'] as DateTime;
      data['bitis_saati'] = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (data['bitis_saati'] is String && data['bitis_saati'].contains('T')) {
      final t = DateTime.tryParse(data['bitis_saati']);
      if (t != null) {
        data['bitis_saati'] = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
      final start = Duration(hours: bSaat, minutes: bDak);
      final end = Duration(hours: eSaat, minutes: eDak);
      final diff = end.inMinutes - start.inMinutes;
      if (diff > 0) {
        data['saat'] = (diff / 60).toStringAsFixed(2);
      }
    }
    await _client.from(DbTables.mesai).update(data).eq('id', id);
  }

  /// Belirli personelin belirtilen yıl ve ay için toplam onaylı fazla mesai saatini döndürür
  Future<double> getAylikFazlaMesaiSaati(String personelId, int yil, int ay) async {
    final response = await _client
        .from(DbTables.mesai)
        .select('saat, tarih, onay_durumu')
        .eq('user_id', personelId)
        .eq('onay_durumu', 'onaylandi');
    return response.where((e) {
      final t = DateTime.tryParse(e['tarih'] ?? '');
      return t != null && t.year == yil && t.month == ay;
    }).fold<double>(0, (sum, e) => sum + ((e['saat'] is num) ? e['saat'] : double.tryParse(e['saat']?.toString() ?? '0') ?? 0));
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
    }).fold<double>(0, (sum, e) => sum + ((e['saat'] is num) ? e['saat'] : double.tryParse(e['saat']?.toString() ?? '0') ?? 0));
  }

  /// Aynı gün ve saat aralığında çakışan mesai var mı kontrolü
  Future<bool> mesaiCakisiyorMu(String personelId, DateTime tarih, String baslangicSaati, String bitisSaati, {String? excludeId}) async {
    final response = await _client
        .from(DbTables.mesai)
        .select('id, baslangic_saati, bitis_saati, tarih')
        .eq('user_id', personelId)
        .eq('tarih', tarih.toIso8601String().substring(0,10));
    for (final e in response) {
      if (excludeId != null && e['id'].toString() == excludeId) continue;
      final bas = e['baslangic_saati'];
      final bit = e['bitis_saati'];
      if (bas == null || bit == null) continue;
      final b1 = _parseSaatToDuration(baslangicSaati);
      final e1 = _parseSaatToDuration(bitisSaati);
      final b2 = _parseSaatToDuration(bas);
      final e2 = _parseSaatToDuration(bit);
      if (b1 == null || e1 == null || b2 == null || e2 == null) continue;
      // Çakışma kontrolü: iki aralık tamamen ayrık değilse çakışır
      if (!(e1 <= b2 || b1 >= e2)) {
        return true;
      }
    }
    return false;
  }

  /// Mesai onay/red ve onaylayan kişi güncelleme
  Future<void> updateMesaiOnay(String id, String yeniDurum, {String? onaylayanId}) async {
    await _client.from(DbTables.mesai).update({
      'onay_durumu': yeniDurum,
      if (onaylayanId != null) 'onaylayan_user_id': onaylayanId,
    }).eq('id', id);
  }

  /// Mesai ücreti otomatik hesaplama
  double hesaplaMesaiUcreti({required double saatlikUcret, required double mesaiSaati, double zamOrani = 1.5}) {
    return double.parse((saatlikUcret * mesaiSaati * zamOrani).toStringAsFixed(2));
  }

  /// Saat stringini Duration olarak döndürür (servis katmanında TimeOfDay kullanılmaz)
  Duration? _parseSaatToDuration(String s) {
    if (!s.contains(':')) return null;
    final parts = s.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return Duration(hours: h, minutes: m);
  }
}
