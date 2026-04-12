import 'package:flutter/foundation.dart';
import 'package:uretim_takip/config/database_tables.dart';
// =============================================
// KASA/BANKA HAREKETLERİ SERVİSİ
// Tarih: 27.06.2025
// Açıklama: Kasa ve banka hesaplarındaki para hareketlerini yöneten servis
// =============================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/kasa_banka_hareket_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class KasaBankaHareketService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  // =============================================
  // HAREKET CRUD İŞLEMLERİ
  // =============================================

  /// Yeni hareket ekler
  Future<KasaBankaHareket?> hareketEkle(KasaBankaHareket hareket) async {
    try {
      final data = hareket.toJson();
      // ID'yi kaldır çünkü Supabase otomatik oluşturur
      data.remove('id');
      data['firma_id'] = _firmaId;

      final response = await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .insert(data)
          .select()
          .single();

      return KasaBankaHareket.fromJson(response);
    } catch (e) {
      debugPrint('Hareket ekleme hatası: $e');
      rethrow;
    }
  }

  /// Hareket günceller
  Future<KasaBankaHareket?> hareketGuncelle(KasaBankaHareket hareket) async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .update(hareket.toJson())
          .eq('id', hareket.id)
          .select()
          .single();

      return KasaBankaHareket.fromJson(response);
    } catch (e) {
      debugPrint('Hareket güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Hareket siler
  Future<bool> hareketSil(String hareketId) async {
    try {
      await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .delete()
          .eq('id', hareketId);

      return true;
    } catch (e) {
      debugPrint('Hareket silme hatası: $e');
      return false;
    }
  }

  /// Hareket getirir
  Future<KasaBankaHareket?> hareketGetir(String hareketId) async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select()
          .eq('firma_id', _firmaId)
          .eq('id', hareketId)
          .single();

      return KasaBankaHareket.fromJson(response);
    } catch (e) {
      debugPrint('Hareket getirme hatası: $e');
      return null;
    }
  }

  // =============================================
  // HAREKET LİSTELEME İŞLEMLERİ
  // =============================================

  /// Belirli hesaba ait hareketleri getirir
  Future<List<KasaBankaHareket>> hesapHareketleriGetir(
    String kasaBankaId, {
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    String? hareketTipi,
    String? kategori,
    bool? onaylilar,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select()
          .eq('firma_id', _firmaId)
          .eq('kasa_banka_id', kasaBankaId);

      // Filtreler
      if (baslangicTarihi != null) {
        queryBuilder = queryBuilder.gte('islem_tarihi', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        queryBuilder = queryBuilder.lte('islem_tarihi', bitisTarihi.toIso8601String());
      }
      if (hareketTipi != null) {
        queryBuilder = queryBuilder.eq('hareket_tipi', hareketTipi);
      }
      if (kategori != null) {
        queryBuilder = queryBuilder.eq('kategori', kategori);
      }
      if (onaylilar != null) {
        queryBuilder = queryBuilder.eq('onaylanmis_mi', onaylilar);
      }

      final response = await queryBuilder
          .order('islem_tarihi', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((item) => KasaBankaHareket.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Hesap hareketleri getirme hatası: $e');
      return [];
    }
  }

  /// Tüm hareketleri getirir
  Future<List<KasaBankaHareket>> tumHareketleriGetir({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    String? hareketTipi,
    String? kategori,
    bool? onaylilar,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select()
          .eq('firma_id', _firmaId);

      // Filtreler
      if (baslangicTarihi != null) {
        queryBuilder = queryBuilder.gte('islem_tarihi', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        queryBuilder = queryBuilder.lte('islem_tarihi', bitisTarihi.toIso8601String());
      }
      if (hareketTipi != null) {
        queryBuilder = queryBuilder.eq('hareket_tipi', hareketTipi);
      }
      if (kategori != null) {
        queryBuilder = queryBuilder.eq('kategori', kategori);
      }
      if (onaylilar != null) {
        queryBuilder = queryBuilder.eq('onaylanmis_mi', onaylilar);
      }

      final response = await queryBuilder
          .order('islem_tarihi', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((item) => KasaBankaHareket.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Tüm hareketleri getirme hatası: $e');
      return [];
    }
  }

  // =============================================
  // TRANSFER İŞLEMLERİ
  // =============================================

  /// Transfer işlemi yapar (çıkış ve giriş hareketlerini birlikte oluşturur)
  Future<List<KasaBankaHareket>> transferYap(TransferIslemi transfer) async {
    try {
      final cikisHareket = KasaBankaHareket(
        id: '',
        kasaBankaId: transfer.cikanHesapId,
        hareketTipi: 'transfer_giden',
        tutar: transfer.tutar,
        paraBirimi: transfer.paraBirimi,
        aciklama: transfer.aciklama,
        kategori: 'bank_transfer',
        transferKasaBankaId: transfer.girenHesapId,
        referansNo: transfer.referansNo,
        islemTarihi: transfer.islemTarihi,
        olusturmaTarihi: DateTime.now(),
        olusturanKullanici: _supabase.auth.currentUser?.email ?? 'sistem',
      );

      final girisHareket = KasaBankaHareket(
        id: '',
        kasaBankaId: transfer.girenHesapId,
        hareketTipi: 'transfer_gelen',
        tutar: transfer.tutar,
        paraBirimi: transfer.paraBirimi,
        aciklama: transfer.aciklama,
        kategori: 'bank_transfer',
        transferKasaBankaId: transfer.cikanHesapId,
        referansNo: transfer.referansNo,
        islemTarihi: transfer.islemTarihi,
        olusturmaTarihi: DateTime.now(),
        olusturanKullanici: _supabase.auth.currentUser?.email ?? 'sistem',
      );

      final cikisData = cikisHareket.toJson();
      final girisData = girisHareket.toJson();
      cikisData.remove('id');
      girisData.remove('id');
      cikisData['firma_id'] = _firmaId;
      girisData['firma_id'] = _firmaId;

      final response = await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .insert([cikisData, girisData])
          .select();

      return response.map((item) => KasaBankaHareket.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Transfer işlemi hatası: $e');
      rethrow;
    }
  }

  // =============================================
  // FATURA ÖDEMESİ İŞLEMLERİ
  // =============================================

  /// Fatura ödemesi kaydeder
  Future<KasaBankaHareket?> faturaOdemesiKaydet({
    required String kasaBankaId,
    required String faturaId,
    required double tutar,
    required String paraBirimi,
    String? aciklama,
    String? referansNo,
    DateTime? islemTarihi,
  }) async {
    try {
      final hareket = KasaBankaHareket(
        id: '',
        kasaBankaId: kasaBankaId,
        hareketTipi: 'cikis',
        tutar: tutar,
        paraBirimi: paraBirimi,
        aciklama: aciklama ?? 'Fatura ödemesi',
        kategori: 'fatura_odeme',
        faturaId: faturaId,
        referansNo: referansNo,
        islemTarihi: islemTarihi ?? DateTime.now(),
        olusturmaTarihi: DateTime.now(),
        olusturanKullanici: _supabase.auth.currentUser?.email ?? 'sistem',
      );

      return await hareketEkle(hareket);
    } catch (e) {
      debugPrint('Fatura ödemesi kaydetme hatası: $e');
      rethrow;
    }
  }

  /// Faturaya ait ödemeleri getirir
  Future<List<KasaBankaHareket>> faturaOdemeleriniGetir(String faturaId) async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select()
          .eq('fatura_id', faturaId)
          .eq('kategori', 'fatura_odeme')
          .order('islem_tarihi', ascending: false);

      return response.map((item) => KasaBankaHareket.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Fatura ödemeleri getirme hatası: $e');
      return [];
    }
  }

  // =============================================
  // ONAY İŞLEMLERİ
  // =============================================

  /// Hareket onaylar
  Future<KasaBankaHareket?> hareketOnayla(String hareketId) async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .update({
            'onaylanmis_mi': true,
            'onaylayan_kullanici': _supabase.auth.currentUser?.email ?? 'sistem',
            'onaylama_tarihi': DateTime.now().toIso8601String(),
          })
          .eq('id', hareketId)
          .select()
          .single();

      return KasaBankaHareket.fromJson(response);
    } catch (e) {
      debugPrint('Hareket onaylama hatası: $e');
      rethrow;
    }
  }

  /// Hareket onayını kaldır
  Future<KasaBankaHareket?> hareketOnayiKaldir(String hareketId) async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHareketleri)
          .update({
            'onaylanmis_mi': false,
            'onaylayan_kullanici': null,
            'onaylama_tarihi': null,
          })
          .eq('id', hareketId)
          .select()
          .single();

      return KasaBankaHareket.fromJson(response);
    } catch (e) {
      debugPrint('Hareket onayını kaldırma hatası: $e');
      rethrow;
    }
  }

  // =============================================
  // RAPOR VE İSTATİSTİK İŞLEMLERİ
  // =============================================

  /// Hesap özeti getirir
  Future<HareketOzeti?> hesapOzetiGetir(
    String kasaBankaId, {
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      var queryBuilder = _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select('hareket_tipi, tutar, para_birimi')
          .eq('kasa_banka_id', kasaBankaId)
          .eq('onaylanmis_mi', true);

      if (baslangicTarihi != null) {
        queryBuilder = queryBuilder.gte('islem_tarihi', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        queryBuilder = queryBuilder.lte('islem_tarihi', bitisTarihi.toIso8601String());
      }

      final response = await queryBuilder;

      double toplamGiris = 0;
      double toplamCikis = 0;
      final int islemSayisi = response.length;
      String paraBirimi = 'TRY';

      for (final item in response) {
        final tutar = (item['tutar'] ?? 0).toDouble();
        final hareketTipi = item['hareket_tipi'] ?? '';
        
        if (paraBirimi == 'TRY' && item['para_birimi'] != null) {
          paraBirimi = item['para_birimi'];
        }

        if (hareketTipi == 'giris' || hareketTipi == 'transfer_gelen') {
          toplamGiris += tutar;
        } else if (hareketTipi == 'cikis' || hareketTipi == 'transfer_giden') {
          toplamCikis += tutar;
        }
      }

      return HareketOzeti(
        toplamGiris: toplamGiris,
        toplamCikis: toplamCikis,
        bakiye: toplamGiris - toplamCikis,
        islemSayisi: islemSayisi,
        paraBirimi: paraBirimi,
      );
    } catch (e) {
      debugPrint('Hesap özeti getirme hatası: $e');
      return null;
    }
  }

  /// Kategori bazlı hareket özetini getirir
  Future<Map<String, double>> kategoriBazliOzet(
    String kasaBankaId, {
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      var queryBuilder = _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select('kategori, hareket_tipi, tutar')
          .eq('kasa_banka_id', kasaBankaId)
          .eq('onaylanmis_mi', true);

      if (baslangicTarihi != null) {
        queryBuilder = queryBuilder.gte('islem_tarihi', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        queryBuilder = queryBuilder.lte('islem_tarihi', bitisTarihi.toIso8601String());
      }

      final response = await queryBuilder;

      final Map<String, double> kategoriOzeti = {};

      for (final item in response) {
        final kategori = item['kategori'] ?? 'belirtilmemis';
        final tutar = (item['tutar'] ?? 0).toDouble();
        final hareketTipi = item['hareket_tipi'] ?? '';

        if (hareketTipi == 'cikis' || hareketTipi == 'transfer_giden') {
          kategoriOzeti[kategori] = (kategoriOzeti[kategori] ?? 0) + tutar;
        }
      }

      return kategoriOzeti;
    } catch (e) {
      debugPrint('Kategori bazlı özet getirme hatası: $e');
      return {};
    }
  }

  /// Günlük hareket özetini getirir
  Future<List<Map<String, dynamic>>> gunlukHareketOzeti(
    String kasaBankaId, {
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      var queryBuilder = _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select('islem_tarihi, hareket_tipi, tutar')
          .eq('kasa_banka_id', kasaBankaId)
          .eq('onaylanmis_mi', true);

      if (baslangicTarihi != null) {
        queryBuilder = queryBuilder.gte('islem_tarihi', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        queryBuilder = queryBuilder.lte('islem_tarihi', bitisTarihi.toIso8601String());
      }

      final response = await queryBuilder.order('islem_tarihi');

      final Map<String, Map<String, double>> gunlukOzet = {};

      for (final item in response) {
        final tarih = DateTime.parse(item['islem_tarihi']).toIso8601String().substring(0, 10);
        final tutar = (item['tutar'] ?? 0).toDouble();
        final hareketTipi = item['hareket_tipi'] ?? '';

        if (!gunlukOzet.containsKey(tarih)) {
          gunlukOzet[tarih] = {'giris': 0, 'cikis': 0};
        }

        if (hareketTipi == 'giris' || hareketTipi == 'transfer_gelen') {
          gunlukOzet[tarih]!['giris'] = gunlukOzet[tarih]!['giris']! + tutar;
        } else if (hareketTipi == 'cikis' || hareketTipi == 'transfer_giden') {
          gunlukOzet[tarih]!['cikis'] = gunlukOzet[tarih]!['cikis']! + tutar;
        }
      }

      return gunlukOzet.entries.map((entry) => {
        'tarih': entry.key,
        'giris': entry.value['giris'],
        'cikis': entry.value['cikis'],
        'net': entry.value['giris']! - entry.value['cikis']!,
      }).toList();
    } catch (e) {
      debugPrint('Günlük hareket özeti getirme hatası: $e');
      return [];
    }
  }

  // =============================================
  // YARDIMCI METODLAR
  // =============================================

  /// Referans numarası oluşturur
  String generateReferansNo() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    return 'REF${timestamp.substring(timestamp.length - 8)}';
  }

  /// Para birimi kontrolü yapar
  bool isValidParaBirimi(String paraBirimi) {
    const validCurrencies = ['TRY', 'USD', 'EUR', 'GBP'];
    return validCurrencies.contains(paraBirimi);
  }

  /// Hareket tipi kontrolü yapar
  bool isValidHareketTipi(String hareketTipi) {
    const validTypes = ['giris', 'cikis', 'transfer_giden', 'transfer_gelen'];
    return validTypes.contains(hareketTipi);
  }

  /// Kategori kontrolü yapar
  bool isValidKategori(String kategori) {
    const validCategories = ['fatura_odeme', 'nakit_giris', 'bank_transfer', 'operasyonel', 'diger'];
    return validCategories.contains(kategori);
  }
}
