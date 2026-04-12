import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:uretim_takip/models/izin_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class IzinService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  Future<List<IzinModel>> getIzinlerForPersonel(String personelId, {String? donem}) async {
    try {
      debugPrint('IzinService.getIzinlerForPersonel: personelId=$personelId, donem=$donem');
      // Veritabanında sadece user_id var
      var query = _client
          .from(DbTables.izinler)
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
                .gte('baslama_tarihi', baslangicTarihi.toIso8601String())
                .lte('baslama_tarihi', bitisTarihi.toIso8601String());
          }
        }
      }
      
      final response = await query.order('baslama_tarihi', ascending: false);
      debugPrint('IzinService.getIzinlerForPersonel: ${(response as List).length} kayıt bulundu');
      return response.map((e) => IzinModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('IzinService.getIzinlerForPersonel HATA: $e');
      return [];
    }
  }

  Future<String?> addIzin(IzinModel izin) async {
    try {
      debugPrint('=== IzinService.addIzin ===');
      final mapData = izin.toMap();
      mapData['firma_id'] = _firmaId;
      debugPrint('toMap() sonucu: $mapData');
      final response = await _client.from(DbTables.izinler).insert(mapData).select('id').single();
      debugPrint('Kayıt başarılı, id: ${response['id']}');
      return response['id']?.toString();
    } catch (e) {
      debugPrint('IzinService.addIzin HATA: $e');
      rethrow;
    }
  }

  Future<void> updateIzinDurum(String id, String yeniDurum, {String? onaylayanId}) async {
    await _client.from(DbTables.izinler).update({
      'onay_durumu': yeniDurum,
      if (onaylayanId != null) 'onaylayan_user_id': onaylayanId,
    }).eq('id', id);
  }

  Future<void> deleteIzin(String id) async {
    await _client.from(DbTables.izinler).delete().eq('id', id);
  }

  Future<List<IzinModel>> getTumIzinler() async {
    final response = await _client
        .from(DbTables.izinler)
        .select()
        .eq('firma_id', _firmaId)
        .order('baslama_tarihi', ascending: false); // Database column: baslama_tarihi
    return (response as List)
        .map((e) => IzinModel.fromMap(e))
        .toList();
  }

  Future<void> updateIzin(String id, Map<String, dynamic> data) async {
    await _client.from(DbTables.izinler).update(data).eq('id', id);
  }

  /// Belirli personelin onaylı yıllık izin toplam gününü döndürür
  Future<int> getKullanilanYillikIzin(String personelId) async {
    final response = await _client
        .from(DbTables.izinler)
        .select('gun_sayisi, izin_turu, onay_durumu')
        .eq('firma_id', _firmaId)
        .eq('user_id', personelId)
        .eq('izin_turu', 'Yıllık İzin')
        .eq('onay_durumu', 'onaylandi');
    final toplam = response.fold<num>(0, (sum, e) => sum + (e['gun_sayisi'] ?? 0));
    return toplam.toInt();
  }

  /// Belirli personelin onaylı ücretsiz izin toplam gününü döndürür
  Future<int> getKullanilanUcretsizIzinGun(String personelId) async {
    final response = await _client
        .from(DbTables.izinler)
        .select('gun_sayisi, izin_turu, onay_durumu')
        .eq('firma_id', _firmaId)
        .eq('user_id', personelId)
        .eq('izin_turu', 'Ücretsiz İzin')
        .eq('onay_durumu', 'onaylandi');
    final toplam = response.fold<num>(0, (sum, e) => sum + (e['gun_sayisi'] ?? 0));
    return toplam.toInt();
  }

  /// Belirli yıl için kullanılan yıllık izin gününü döndürür
  Future<int> getYillikIzinByYil(String personelId, int yil) async {
    final baslangic = DateTime(yil, 1, 1);
    final bitis = DateTime(yil, 12, 31, 23, 59, 59);
    
    final response = await _client
        .from(DbTables.izinler)
        .select('gun_sayisi')
        .eq('firma_id', _firmaId)
        .eq('user_id', personelId)
        .eq('izin_turu', 'Yıllık İzin')
        .eq('onay_durumu', 'onaylandi')
        .gte('baslama_tarihi', baslangic.toIso8601String())
        .lte('baslama_tarihi', bitis.toIso8601String());
    
    return response.fold<int>(0, (sum, e) => sum + ((e['gun_sayisi'] as int?) ?? 0));
  }

  /// Geçen yıldan devreden izin hakkını hesaplar
  /// yillikHak: Personelin yıllık izin hakkı (varsayılan 14)
  /// Devir limiti: maksimum 14 gün
  Future<int> getDevredenIzin(String personelId, int yillikHak, {int? yil}) async {
    final hesaplamaYili = yil ?? DateTime.now().year;
    final gecenYil = hesaplamaYili - 1;
    
    // Geçen yıl kullanılan izin
    final gecenYilKullanilan = await getYillikIzinByYil(personelId, gecenYil);
    
    // Geçen yıldan kalan
    final int gecenYilKalan = yillikHak - gecenYilKullanilan;
    
    // Devir limiti: maksimum 14 gün devredilebilir
    const int devirLimiti = 14;
    int devredenIzin = gecenYilKalan > 0 ? gecenYilKalan : 0;
    devredenIzin = devredenIzin > devirLimiti ? devirLimiti : devredenIzin;
    
    return devredenIzin;
  }

  /// Toplam kullanılabilir izin hakkını hesaplar (yıllık hak + devir)
  Future<Map<String, int>> getIzinOzeti(String personelId, int yillikHak) async {
    final buYil = DateTime.now().year;
    
    // Bu yıl kullanılan
    final buYilKullanilan = await getYillikIzinByYil(personelId, buYil);
    
    // Geçen yıldan devir
    final devredenIzin = await getDevredenIzin(personelId, yillikHak);
    
    // Toplam hak = yıllık hak + devir
    final toplamHak = yillikHak + devredenIzin;
    
    // Kalan = toplam hak - bu yıl kullanılan
    final kalan = toplamHak - buYilKullanilan;
    
    return {
      'yillikHak': yillikHak,
      'devredenIzin': devredenIzin,
      'toplamHak': toplamHak,
      'buYilKullanilan': buYilKullanilan,
      'kalan': kalan > 0 ? kalan : 0,
    };
  }
}
