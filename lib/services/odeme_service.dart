import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:uretim_takip/models/odeme_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class OdemeService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  Future<List<OdemeModel>> getOdemelerForPersonel(String personelId, {String? donem}) async {
    try {
      debugPrint('=== OdemeService.getOdemelerForPersonel ===');
      debugPrint('personelId: "$personelId"');
      debugPrint('donem: "$donem"');
      
      // Veritabanında sadece user_id var
      var query = _client
          .from(DbTables.odemeKayitlari)
          .select()
          .eq('firma_id', _firmaId)
          .eq('user_id', personelId);
      
      // Eğer dönem seçilmişse, o döneme ait kayıtları filtrele
      if (donem != null && donem.isNotEmpty) {
        // Dönem formatı: "2025-08" gibi
        final parts = donem.split('-');
        if (parts.length == 2) {
          final yil = int.tryParse(parts[0]);
          final ay = int.tryParse(parts[1]);
          if (yil != null && ay != null) {
            final baslangicTarihi = DateTime(yil, ay, 1);
            final bitisTarihi = DateTime(yil, ay + 1, 0, 23, 59, 59);
            debugPrint('Dönem filtresi: $baslangicTarihi - $bitisTarihi');
            query = query
                .gte('odeme_tarihi', baslangicTarihi.toIso8601String())
                .lte('odeme_tarihi', bitisTarihi.toIso8601String());
          }
        }
      }
      
      final response = await query.order('odeme_tarihi', ascending: false);
      debugPrint('Bulunan kayıt sayısı: ${(response as List).length}');
      if (response.isNotEmpty) {
        debugPrint('İlk kayıt: ${response.first}');
      }
      return response.map((e) => OdemeModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('OdemeService.getOdemelerForPersonel HATA: $e');
      return [];
    }
  }

  Future<void> addOdeme(OdemeModel odeme) async {
    debugPrint('=== OdemeService.addOdeme ===');
    debugPrint('odeme.personelId: "${odeme.personelId}"');
    debugPrint('odeme.userId: "${odeme.userId}"');
    
    final mapData = odeme.toMap();
    mapData['firma_id'] = _firmaId;
    debugPrint('toMap() sonucu: $mapData');
    debugPrint('Kaydedilecek user_id: "${mapData['user_id']}"');
    
    // personelId veya userId kontrolü
    final effectiveUserId = mapData['user_id'];
    if ((effectiveUserId ?? '').toString().trim().isEmpty) {
      throw Exception('Geçerli bir personel seçilmeden ödeme kaydı eklenemez!');
    }
    await _client.from(DbTables.odemeKayitlari).insert(mapData);
    debugPrint('Kayıt başarıyla eklendi');
  }

  Future<void> updateOdemeDurum(int id, String yeniDurum, {String? onaylayanId}) async {
    await _client.from(DbTables.odemeKayitlari).update({
      'durum': yeniDurum,
      if (onaylayanId != null) 'onaylayan_user_id': onaylayanId,
      'onay_tarihi': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteOdeme(int id) async {
    await _client.from(DbTables.odemeKayitlari).delete().eq('id', id);
  }

  Future<double> getOnayliAvansBakiyesi(String personelId) async {
    // Veritabanında sadece user_id var
    final response = await _client
        .from(DbTables.odemeKayitlari)
        .select('tutar')
        .eq('firma_id', _firmaId)
        .eq('user_id', personelId)
        .eq('odeme_turu', 'avans')
        .eq('durum', 'onaylandi');
    final toplam = (response as List)
        .map((e) => (e['tutar'] as num).toDouble())
        .fold<double>(0, (a, b) => a + b);
    return toplam;
  }

  Future<Map<String, double>> getOnayliBakiyeOzet(String personelId, {String? donem}) async {
    // Veritabanında sadece user_id var
    var query = _client
        .from(DbTables.odemeKayitlari)
        .select('odeme_turu, tur, tutar, odeme_tarihi')
        .eq('firma_id', _firmaId)
        .eq('user_id', personelId)
        .eq('durum', 'onaylandi');
    
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
              .gte('odeme_tarihi', baslangicTarihi.toIso8601String())
              .lte('odeme_tarihi', bitisTarihi.toIso8601String());
        }
      }
    }
    
    final response = await query;
    final Map<String, double> toplamlar = {
      'avans': 0,
      'prim': 0,
      DbTables.mesai: 0,
      'ikramiye': 0,
      'kesinti': 0,
    };
    for (final e in response) {
      final odemeTuru = e['odeme_turu']?.toString() ?? '';
      final tur = e['tur']?.toString() ?? '';
      final tutar = (e['tutar'] as num?)?.toDouble() ?? 0;
      
      // Avans ve prim için odeme_turu kullan
      if (odemeTuru == 'avans') {
        toplamlar['avans'] = toplamlar['avans']! + tutar;
      } else if (odemeTuru == 'prim') {
        toplamlar['prim'] = toplamlar['prim']! + tutar;
      }
      // Diğer türler için tur kolonu kullan (avans ve prim hariç)
      else if (toplamlar.containsKey(tur) && tur != 'avans' && tur != 'prim') {
        toplamlar[tur] = toplamlar[tur]! + tutar;
      }
    }
    return toplamlar;
  }

  Future<void> updateOdeme(int id, Map<String, dynamic> data) async {
    await _client.from(DbTables.odemeKayitlari).update(data).eq('id', id);
  }
}
