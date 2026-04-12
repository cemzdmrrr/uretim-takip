import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:uretim_takip/models/beden_models.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Beden bazlı üretim takip servisi
class BedenService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  // ==========================================
  // BEDEN TANIMLARI
  // ==========================================
  
  /// Tüm beden tanımlarını getirir
  Future<List<BedenTanimi>> getBedenTanimlari({bool sadeceAktif = true}) async {
    try {
      var query = _client.from(DbTables.bedenTanimlari).select();
      if (sadeceAktif) {
        query = query.eq('aktif', true);
      }
      final response = await query.order('sira_no');
      return (response as List).map((e) => BedenTanimi.fromMap(e)).toList();
    } catch (e) {
      debugPrint('BedenService.getBedenTanimlari HATA: $e');
      // Varsayılan bedenler
      return [
        BedenTanimi(id: 1, bedenKodu: 'XS', bedenAdi: 'Extra Small', siraNo: 1),
        BedenTanimi(id: 2, bedenKodu: 'S', bedenAdi: 'Small', siraNo: 2),
        BedenTanimi(id: 3, bedenKodu: 'M', bedenAdi: 'Medium', siraNo: 3),
        BedenTanimi(id: 4, bedenKodu: 'L', bedenAdi: 'Large', siraNo: 4),
        BedenTanimi(id: 5, bedenKodu: 'XL', bedenAdi: 'Extra Large', siraNo: 5),
        BedenTanimi(id: 6, bedenKodu: 'XXL', bedenAdi: '2X Large', siraNo: 6),
      ];
    }
  }

  // ==========================================
  // MODEL BEDEN DAĞILIMI
  // ==========================================

  /// Bir model için beden dağılımını getirir
  Future<List<ModelBedenDagilimi>> getModelBedenDagilimi(String modelId) async {
    try {
      final response = await _client
          .from(DbTables.modelBedenDagilimi)
          .select()
          .eq('firma_id', _firmaId)
          .eq('model_id', modelId)
          .order('beden_kodu');
      return (response as List).map((e) => ModelBedenDagilimi.fromMap(e)).toList();
    } catch (e) {
      debugPrint('BedenService.getModelBedenDagilimi HATA: $e');
      return [];
    }
  }

  /// Model için beden dağılımını kaydeder (toplu)
  Future<void> saveModelBedenDagilimi(String modelId, List<ModelBedenDagilimi> bedenler) async {
    try {
      // Önce mevcut kayıtları sil
      await _client.from(DbTables.modelBedenDagilimi).delete().eq('model_id', modelId);
      
      // Yeni kayıtları ekle
      for (final beden in bedenler) {
        if (beden.siparisAdedi > 0) {
          await _client.from(DbTables.modelBedenDagilimi).insert({
            'firma_id': _firmaId,
            'model_id': modelId,
            'beden_kodu': beden.bedenKodu,
            'siparis_adedi': beden.siparisAdedi,
          });
        }
      }
      debugPrint('BedenService: $modelId için ${bedenler.length} beden kaydedildi');
    } catch (e) {
      debugPrint('BedenService.saveModelBedenDagilimi HATA: $e');
      rethrow;
    }
  }

  /// Tek bir beden için adet güncelle
  Future<void> updateBedenAdedi(String modelId, String bedenKodu, int adet) async {
    try {
      await _client.from(DbTables.modelBedenDagilimi).upsert({
        'firma_id': _firmaId,
        'model_id': modelId,
        'beden_kodu': bedenKodu,
        'siparis_adedi': adet,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'model_id,beden_kodu');
    } catch (e) {
      debugPrint('BedenService.updateBedenAdedi HATA: $e');
      rethrow;
    }
  }

  // ==========================================
  // ÜRETİM AŞAMASI BEDEN TAKİP
  // ==========================================

  /// Belirli bir aşama için beden takip verilerini getirir
  Future<List<BedenUretimTakip>> getAsamaBedenTakip(String asama, int atamaId) async {
    try {
      final tabloAdi = '${asama}_beden_takip';
      final response = await _client
          .from(tabloAdi)
          .select()
          .eq('atama_id', atamaId);
      return (response as List).map((e) => BedenUretimTakip.fromMap(e)).toList();
    } catch (e) {
      debugPrint('BedenService.getAsamaBedenTakip HATA: $e');
      return [];
    }
  }

  /// Üretim aşamasında beden bazlı adet günceller
  Future<void> updateUretimBeden({
    required String asama, // 'dokuma', 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme'
    required int atamaId,
    required String modelId,
    required String bedenKodu,
    required int uretilenAdet,
    int fireAdet = 0,
  }) async {
    try {
      final tabloAdi = '${asama}_beden_takip';
      await _client.from(tabloAdi).upsert({
        'firma_id': _firmaId,
        'atama_id': atamaId,
        'model_id': modelId,
        'beden_kodu': bedenKodu,
        'uretilen_adet': uretilenAdet,
        'fire_adet': fireAdet,
        'guncelleme_tarihi': DateTime.now().toIso8601String(),
      }, onConflict: 'atama_id,beden_kodu');
      
      debugPrint('BedenService: $asama - $bedenKodu: $uretilenAdet adet güncellendi');
    } catch (e) {
      debugPrint('BedenService.updateUretimBeden HATA: $e');
      rethrow;
    }
  }

  /// Toplu beden güncelleme (tüm bedenleri tek seferde)
  /// bedenAdetleri: {'XS': 50, 'S': 100, ...}
  Future<void> updateUretimBedenlerToplu({
    required String asama,
    required int atamaId,
    String? modelId,
    Map<String, int>? bedenAdetleri,
    Map<String, int>? bedenFireleri,
    Map<String, Map<String, int>>? bedenVerileri, // {'XS': {'hedef_adet': 50, 'uretilen_adet': 40, 'fire_adet': 2}, ...}
  }) async {
    try {
      final tabloAdi = '${asama}_beden_takip';
      
      // Yeni format (bedenVerileri) kullanılıyorsa
      if (bedenVerileri != null) {
        for (final entry in bedenVerileri.entries) {
          final bedenKodu = entry.key;
          final veriler = entry.value;
          
          await _client.from(tabloAdi).upsert({
            'firma_id': _firmaId,
            'atama_id': atamaId,
            if (modelId != null) 'model_id': modelId,
            'beden_kodu': bedenKodu,
            'hedef_adet': veriler['hedef_adet'] ?? 0,
            'uretilen_adet': veriler['uretilen_adet'] ?? 0,
            'fire_adet': veriler['fire_adet'] ?? 0,
            'guncelleme_tarihi': DateTime.now().toIso8601String(),
          }, onConflict: 'atama_id,beden_kodu');
        }
        debugPrint('BedenService: $asama için ${bedenVerileri.length} beden güncellendi (yeni format)');
      } 
      // Eski format (bedenAdetleri) kullanılıyorsa
      else if (bedenAdetleri != null) {
        for (final entry in bedenAdetleri.entries) {
          final fireAdet = bedenFireleri?[entry.key] ?? 0;
          
          await _client.from(tabloAdi).upsert({
            'firma_id': _firmaId,
            'atama_id': atamaId,
            if (modelId != null) 'model_id': modelId,
            'beden_kodu': entry.key,
            'uretilen_adet': entry.value,
            'fire_adet': fireAdet,
            'guncelleme_tarihi': DateTime.now().toIso8601String(),
          }, onConflict: 'atama_id,beden_kodu');
        }
        debugPrint('BedenService: $asama için ${bedenAdetleri.length} beden güncellendi');
      }
    } catch (e) {
      debugPrint('BedenService.updateUretimBedenlerToplu HATA: $e');
      rethrow;
    }
  }

  // ==========================================
  // ÖZET VE RAPORLAR
  // ==========================================

  /// Model için beden bazlı özet getirir
  Future<ModelBedenOzet?> getModelBedenOzet(String modelId) async {
    try {
      final response = await _client
          .from(DbTables.modelBedenOzet)
          .select()
          .eq('model_id', modelId);
      
      if ((response as List).isEmpty) return null;
      
      final bedenler = response.map((e) => BedenDetay.fromMap(e)).toList();
      final ilk = response.first;
      
      return ModelBedenOzet(
        modelId: modelId,
        itemNo: ilk['item_no'],
        marka: ilk['marka'],
        renk: ilk['renk'],
        bedenler: bedenler,
      );
    } catch (e) {
      debugPrint('BedenService.getModelBedenOzet HATA: $e');
      return null;
    }
  }

  /// Tüm modellerin toplam adetlerini getirir
  Future<List<Map<String, dynamic>>> getModelToplamAdetler() async {
    try {
      final response = await _client.from(DbTables.modelToplamAdetler).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('BedenService.getModelToplamAdetler HATA: $e');
      return [];
    }
  }

  /// Bir model için aşama bazlı beden durumunu getirir
  Future<Map<String, List<BedenUretimTakip>>> getModelAsamaDurum(String modelId) async {
    final result = <String, List<BedenUretimTakip>>{};
    final asamalar = ['dokuma', 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme'];
    
    for (final asama in asamalar) {
      try {
        final tabloAdi = '${asama}_beden_takip';
        final response = await _client
            .from(tabloAdi)
            .select()
            .eq('model_id', modelId);
        result[asama] = (response as List).map((e) => BedenUretimTakip.fromMap(e)).toList();
      } catch (e) {
        result[asama] = [];
      }
    }
    
    return result;
  }

  // ==========================================
  // AŞAMA ARASI ADET AKTARIMI
  // ==========================================

  /// Önceki aşamadan gerçekleşen adetleri alır (üretilen - fire)
  Future<Map<String, int>> getOncekiAsamaGerceklesenAdetler(
    String modelId,
    String sonrakiAsama,
  ) async {
    try {
      debugPrint('🔍 BedenService.getOncekiAsamaGerceklesenAdetler CAGRIDI:');
      debugPrint('   - modelId: $modelId');
      debugPrint('   - sonrakiAsama: $sonrakiAsama');
      
      final response = await _client.rpc(
        'get_onceki_asama_gerceklesen_adetler',
        params: {
          'p_model_id': modelId,
          'p_sonraki_asama': sonrakiAsama,
        },
      );
      
      debugPrint('📦 RPC Response: $response');
      
      final Map<String, int> adetler = {};
      if (response != null && response is List) {
        debugPrint('✅ Response liste donusturuldu, ${response.length} item var');
        for (final item in response) {
          final bedenKodu = item['beden_kodu'] as String?;
          final adet = item['gerceklesen_adet'] as int?;
          debugPrint('   - $bedenKodu: $adet');
          if (bedenKodu != null && adet != null) {
            adetler[bedenKodu] = adet;
          }
        }
      } else {
        debugPrint('⚠️ Response null veya List degil: ${response.runtimeType}');
      }
      
      debugPrint('✅ Sonuc - Onceki asamadan gelen adetler ($sonrakiAsama): $adetler');
      return adetler;
    } catch (e) {
      debugPrint('❌ BedenService.getOncekiAsamaGerceklesenAdetler HATA: $e');
      debugPrint('   Stack trace: $e');
      return {};
    }
  }

  /// Bir sonraki aşamanın hedef adetlerini önceki aşamanın gerçekleşen adetlerine göre günceller
  /// tamamlananAsama: 'dokuma', 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme'
  /// SQL fonksiyonu otomatik olarak sonraki atama_id'yi bulur
  Future<void> updateSonrakiAsamaHedefAdetler({
    required String modelId,
    required String tamamlananAsama,
  }) async {
    try {
      debugPrint('🔄 updateSonrakiAsamaHedefAdetler cagirildi:');
      debugPrint('   - modelId: $modelId');
      debugPrint('   - tamamlananAsama: $tamamlananAsama');
      
      await _client.rpc(
        'update_sonraki_asama_hedef_adetler',
        params: {
          'p_model_id': modelId,
          'p_tamamlanan_asama': tamamlananAsama,
        },
      );
      
      debugPrint('✅ Asama tamalandigi, sonraki asama hedef adetleri guncellendi');
    } catch (e) {
      debugPrint('❌ BedenService.updateSonrakiAsamaHedefAdetler HATA: $e');
      rethrow;
    }
  }
  
  /// Sonraki aşama adını belirle

  /// Manuel olarak bir aşamanın hedef adetlerini önceki aşamadan çeker
  Future<void> hedefAdetleriOncekiAsamadanAl({
    required String modelId,
    required String asama,
    required int atamaId,
  }) async {
    try {
      // Önceki aşamadan adetleri al
      final adetler = await getOncekiAsamaGerceklesenAdetler(modelId, asama);
      
      if (adetler.isEmpty) {
        debugPrint('⚠️ Önceki aşamada henüz üretim tamamlanmamış');
        return;
      }
      
      // Her beden için hedef_adet'i güncelle
      final tabloAdi = '${asama}_beden_takip';
      for (final entry in adetler.entries) {
        await _client.from(tabloAdi).upsert({
          'firma_id': _firmaId,
          'atama_id': atamaId,
          'model_id': modelId,
          'beden_kodu': entry.key,
          'hedef_adet': entry.value,
          'guncelleme_tarihi': DateTime.now().toIso8601String(),
        }, onConflict: 'atama_id,beden_kodu');
      }
      
      debugPrint('✅ $asama aşamasının hedef adetleri önceki aşamadan güncellendi: $adetler');
    } catch (e) {
      debugPrint('BedenService.hedefAdetleriOncekiAsamadanAl HATA: $e');
      rethrow;
    }
  }
}
