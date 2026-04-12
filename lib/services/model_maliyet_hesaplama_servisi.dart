import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Model Maliyet Hesaplama Servisi
/// Model tamamlandığında maliyetleri hesaplar ve raporlara kaydeder
class ModelMaliyetHesaplamaServisi {
  static final ModelMaliyetHesaplamaServisi _instance =
      ModelMaliyetHesaplamaServisi._internal();
  
  factory ModelMaliyetHesaplamaServisi() => _instance;
  ModelMaliyetHesaplamaServisi._internal();

  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  /// Model tamamlandığında maliyetleri hesapla ve kaydet
  Future<Map<String, dynamic>?> modelTamamlandiMaliyetiHesapla({
    required String modelId,
    required int tamamlananAdet,
  }) async {
    try {
      // 1. Model detay verilerini getir
      final modelResponse = await _supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('id', modelId)
          .maybeSingle();

      if (modelResponse == null) {
        return null;
      }

      // 2. Tüm maliyetleri hesapla
      final maliyetBilgisi = await _tumMaliyetleriHesapla(modelResponse, tamamlananAdet);

      // 3. Maliyet hesaplama tablosuna kaydet
      await _maliyetiKaydet(modelId, maliyetBilgisi);

      return maliyetBilgisi;
    } catch (e) {
      return null;
    }
  }

  /// Tüm maliyetleri hesapla
  Future<Map<String, dynamic>> _tumMaliyetleriHesapla(
    Map<String, dynamic> model,
    int tamamlananAdet,
  ) async {
    try {
      final maliyet = <String, dynamic>{};

      // İplik Maliyetleri
      maliyet['iplik_kg_fiyati'] = model['iplik_kg_fiyati'] ?? 0;
      maliyet['iplik_maliyeti'] = model['iplik_maliyeti'] ?? 0;

      // Makina (Örgü) Maliyetleri
      final makinalikis = model['makina_cikis_suresi'] ?? 0;
      final makinaveri = model['makina_dk_fiyati'] ?? 0;
      maliyet['makina_maliyeti'] = (makinalikis * makinaveri);

      // Konfeksiyon Maliyetleri
      final konfeksiyonBirimi = model['konfeksiyon_birim_fiyati'] ?? 0;
      maliyet['konfeksiyon_maliyeti'] = konfeksiyonBirimi;

      // Naksş Maliyeti
      final nakisBirimi = model['nakis_birim_fiyati'] ?? 0;
      maliyet['nakis_maliyeti'] = nakisBirimi;

      // Yıkama Maliyeti
      final yikamaBirimi = model['yikama_birim_fiyati'] ?? 0;
      maliyet['yikama_maliyeti'] = yikamaBirimi;

      // Ütü Maliyeti
      final utuBirimi = model['utu_birim_fiyati'] ?? 0;
      maliyet['utu_maliyeti'] = utuBirimi;

      // İlik-Düğme Maliyeti
      final ilikBirimi = model['ilik_dugme_birim_fiyati'] ?? 0;
      maliyet['ilik_dugme_maliyeti'] = ilikBirimi;

      // Paketleme Maliyeti
      final paketlemeBirimi = model['paketleme_birim_fiyati'] ?? 0;
      maliyet['paketleme_maliyeti'] = paketlemeBirimi;

      // Genel Giderler (Toplam maliyetin %5-10'u)
      double altMaliyetToplami = 0;
      maliyet.forEach((key, value) {
        if (key != 'iplik_kg_fiyati' && value is num) {
          altMaliyetToplami += (value).toDouble();
        }
      });
      maliyet['genel_giderler'] = altMaliyetToplami * 0.08; // %8

      // Toplam Maliyet (Birim başına)
      double toplamMaliyetBirimi = 0;
      maliyet.forEach((key, value) {
        if (value is num && key != 'iplik_kg_fiyati') {
          toplamMaliyetBirimi += (value).toDouble();
        }
      });
      maliyet['toplam_maliyet_birimi'] = toplamMaliyetBirimi;

      // Toplam Maliyet (Tamamlanan adet için)
      maliyet['toplam_maliyet'] = toplamMaliyetBirimi * tamamlananAdet;

      // Birim Başına Kar Marjı (modelden al, yoksa %20 varsayılan)
      final karMarji = (model['kar_marji'] as num?)?.toDouble() ?? 20.0;
      maliyet['kar_marji_yuzde'] = karMarji;
      final birimsatisNoktasi = toplamMaliyetBirimi * (1 + karMarji / 100);
      maliyet['birim_satis_noktas'] = birimsatisNoktasi;

      // Tamamlanan Adet
      maliyet['tamamlanan_adet'] = tamamlananAdet;

      // Toplam Satış Geliri
      maliyet['toplam_satis_geliri'] = birimsatisNoktasi * tamamlananAdet;

      // Kâr/Zarar
      maliyet['toplam_kar_zarar'] = (birimsatisNoktasi * tamamlananAdet) - (toplamMaliyetBirimi * tamamlananAdet);

      return maliyet;
    } catch (e) {
      return {};
    }
  }

  /// Maliyeti veritabanına kaydet
  Future<void> _maliyetiKaydet(
    String modelId,
    Map<String, dynamic> maliyet,
  ) async {
    try {
      // Aynı model için daha önceki kaydı kontrol et
      final oncekiKayit = await _supabase
          .from(DbTables.maliyetHesaplama)
          .select('id')
          .eq('firma_id', _firmaId)
          .eq('model_id', modelId)
          .maybeSingle();

      if (oncekiKayit != null) {
        // Güncelle
        await _supabase
            .from(DbTables.maliyetHesaplama)
            .update({
              ...maliyet,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('model_id', modelId);
      } else {
        // Yeni kayıt
        await _supabase.from(DbTables.maliyetHesaplama).insert({
          'firma_id': _firmaId,
          'model_id': modelId,
          ...maliyet,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Modelin maliyet raporunu getir
  Future<Map<String, dynamic>?> getMaliyetRaporu(String modelId) async {
    try {
      final response = await _supabase
          .from(DbTables.maliyetHesaplama)
          .select('*')
          .eq('model_id', modelId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Tüm modellerin maliyet raporunu getir (dashboard için)
  Future<List<Map<String, dynamic>>> getTumMaliyetRaporlari() async {
    try {
      final response = await _supabase
          .from(DbTables.maliyetHesaplama)
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Karlılık raporu (kar/zarar analizi)
  Future<Map<String, dynamic>> getKarlilikRaporu() async {
    try {
      final raporlar = await getTumMaliyetRaporlari();

      if (raporlar.isEmpty) {
        return {
          'toplam_maliyet': 0,
          'toplam_satis_geliri': 0,
          'toplam_kar_zarar': 0,
          'kar_orani_yuzde': 0,
          'rapor_sayisi': 0,
        };
      }

      double toplamMaliyet = 0;
      double toplamSatisGeliri = 0;
      double toplamKarZarar = 0;

      for (var rapor in raporlar) {
        toplamMaliyet += (rapor['toplam_maliyet'] as num? ?? 0).toDouble();
        toplamSatisGeliri += (rapor['toplam_satis_geliri'] as num? ?? 0).toDouble();
        toplamKarZarar += (rapor['toplam_kar_zarar'] as num? ?? 0).toDouble();
      }

      final karOrani = toplamSatisGeliri > 0
          ? ((toplamKarZarar / toplamSatisGeliri) * 100)
          : 0;

      return {
        'toplam_maliyet': toplamMaliyet,
        'toplam_satis_geliri': toplamSatisGeliri,
        'toplam_kar_zarar': toplamKarZarar,
        'kar_orani_yuzde': karOrani,
        'rapor_sayisi': raporlar.length,
        'ortalama_kar_birimi': toplamKarZarar / raporlar.length,
      };
    } catch (e) {
      return {};
    }
  }

  /// Maliyete göre karşılaştırmalı rapor
  Future<List<Map<String, dynamic>>> getMaliyetKarsilasmasiRaporu() async {
    try {
      final raporlar = await getTumMaliyetRaporlari();

      if (raporlar.isEmpty) return [];

      // Kar/zarar oranına göre sırala
      raporlar.sort((a, b) {
        final karA = (a['toplam_kar_zarar'] as num? ?? 0).toDouble();
        final karB = (b['toplam_kar_zarar'] as num? ?? 0).toDouble();
        return karB.compareTo(karA);
      });

      return raporlar;
    } catch (e) {
      return [];
    }
  }
}
