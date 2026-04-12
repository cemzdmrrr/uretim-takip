import 'package:flutter/foundation.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class DonemService {
  static final SupabaseClient _client = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  // Tüm dönemleri getir
  static Future<List<Map<String, dynamic>>> getTumDonemler() async {
    try {
      // Önce yeni yapıyı dene
      try {
        final response = await _client
            .from(DbTables.donemler)
            .select('*')
            .eq('firma_id', _firmaId)
            .order('yil', ascending: false)
            .order('ay', ascending: false);
        
        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Yeni dönem yapısı bulunamadı: $e');
        
        // Eski yapıyı dene
        try {
          final response = await _client
              .from(DbTables.donemler)
              .select('*')
              .eq('firma_id', _firmaId)
              .order('baslangic_tarihi', ascending: false);
          
          return List<Map<String, dynamic>>.from(response);
        } catch (e2) {
          debugPrint('Eski dönem yapısı da bulunamadı: $e2');
          return [];
        }
      }
    } catch (e) {
      debugPrint('Dönem listesi getirme hatası: $e');
      return [];
    }
  }

  // Aktif dönemi getir
  static Future<Map<String, dynamic>?> getAktifDonem() async {
    try {
      // Yeni yapıyı dene
      try {
        final response = await _client
            .from(DbTables.donemler)
            .select('*')
            .eq('firma_id', _firmaId)
            .eq('durum', 'aktif')
            .single();
        
        return response;
      } catch (e) {
        debugPrint('Yeni yapıda aktif dönem bulunamadı: $e');
        
        // Eski yapıyı dene
        try {
          final response = await _client
              .from(DbTables.donemler)
              .select('*')
              .eq('firma_id', _firmaId)
              .eq('aktif', true)
              .single();
          
          return response;
        } catch (e2) {
          debugPrint('Eski yapıda da aktif dönem bulunamadı: $e2');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Aktif dönem getirme hatası: $e');
      return null;
    }
  }

  // Yeni dönem ekle
  static Future<Map<String, dynamic>> yeniDonemEkle({
    required int yil,
    required int ay,
    required String kullaniciId,
  }) async {
    try {
      // Önce aynı dönem var mı kontrol et
      final mevcutDonem = await _client
          .from(DbTables.donemler)
          .select('id')
          .eq('firma_id', _firmaId)
          .eq('yil', yil)
          .eq('ay', ay)
          .maybeSingle();

      if (mevcutDonem != null) {
        return {
          'success': false,
          'message': 'Bu dönem zaten mevcut!',
        };
      }

      // Dönem adını oluştur
      final donemAdi = '$yil-${ay.toString().padLeft(2, '0')}';

      // Mevcut aktif dönemi pasif yap
      await _client
          .from(DbTables.donemler)
          .update({'durum': 'tamamlandi'})
          .eq('firma_id', _firmaId)
          .eq('durum', 'aktif');

      // Yeni dönem ekle
      final response = await _client
          .from(DbTables.donemler)
          .insert({
            'firma_id': _firmaId,
            'yil': yil,
            'ay': ay,
            'donem_adi': donemAdi,
            'durum': 'aktif',
            'olusturan_kullanici_id': kullaniciId,
            'olusturulma_tarihi': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Tüm personel için yeni dönem kayıtları oluştur
      await _personelDonemKayitlariOlustur(response['id']);

      return {
        'success': true,
        'message': 'Yeni dönem başarıyla oluşturuldu!',
        'donem': response,
      };

    } catch (e) {
      debugPrint('Dönem ekleme hatası: $e');
      return {
        'success': false,
        'message': 'Dönem eklenirken hata oluştu: $e',
      };
    }
  }

  // Personel için dönem kayıtları oluştur
  static Future<void> _personelDonemKayitlariOlustur(int donemId) async {
    try {
      // Tüm aktif personeli getir
      final personelListesi = await _client
          .from(DbTables.personel)
          .select('user_id, yillik_izin_hakki')
          .eq('firma_id', _firmaId);

      // Her personel için dönem kaydı oluştur (avans, mesai, izin sıfırlanır)
      final List<Map<String, dynamic>> personelDonemKayitlari = [];
      
      for (final personel in personelListesi) {
        // Yıllık izin kalan hesapla (toplam hak - kullanılan izin)
        final yillikIzinHakki = personel['yillik_izin_hakki'] ?? 0;
        final kullanilanIzin = await _getKullanilanYillikIzin(personel['user_id']);
        final kalanIzin = yillikIzinHakki - kullanilanIzin;
        
        personelDonemKayitlari.add({
          'firma_id': _firmaId,
          'donem_id': donemId,
          'user_id': personel['user_id'],
          'toplam_mesai_saati': 0,
          'toplam_izin_gunu': 0,
          'toplam_avans': 0.0,
          'kalan_yillik_izin': kalanIzin > 0 ? kalanIzin : 0,
          'bordro_durumu': 'beklemede',
          'olusturulma_tarihi': DateTime.now().toIso8601String(),
        });
      }

      if (personelDonemKayitlari.isNotEmpty) {
        await _client
            .from(DbTables.personelDonem)
            .insert(personelDonemKayitlari);
        
        debugPrint('${personelDonemKayitlari.length} personel için yeni dönem kayıtları oluşturuldu (avans/mesai/izin sıfırlandı)');
      }

    } catch (e) {
      debugPrint('Personel dönem kayıtları oluşturma hatası: $e');
    }
  }

  // Personelin kullandığı yıllık izin günlerini hesapla
  static Future<int> _getKullanilanYillikIzin(String personelId) async {
    try {
      // Bu yıl içinde kullanılan yıllık izinleri topla
      final currentYear = DateTime.now().year;
      final response = await _client
          .from(DbTables.izinler)
          .select('gun_sayisi')
          .eq('firma_id', _firmaId)
          .eq('user_id', personelId)
          .eq('izin_turu', 'Yıllık İzin')
          .gte('baslama_tarihi', '$currentYear-01-01')
          .lte('baslama_tarihi', '$currentYear-12-31');

      int toplamKullanilanIzin = 0;
      for (final izin in response) {
        toplamKullanilanIzin += (izin['gun_sayisi'] as int? ?? 0);
      }

      return toplamKullanilanIzin;
    } catch (e) {
      debugPrint('Kullanılan yıllık izin hesaplama hatası: $e');
      return 0;
    }
  }

  // Dönem silme (sadece admin)
  static Future<Map<String, dynamic>> donemSil(int donemId) async {
    try {
      // Önce bu döneme ait verilerin olup olmadığını kontrol et
      final mesaiSayisi = await _client
          .from(DbTables.mesai)
          .select('id')
          .eq('donem_id', donemId);

      final izinSayisi = await _client
          .from(DbTables.izinler)
          .select('id')
          .eq('donem_id', donemId);

      if (mesaiSayisi.isNotEmpty || izinSayisi.isNotEmpty) {
        return {
          'success': false,
          'message': 'Bu döneme ait kayıtlar mevcut, silinemez!',
        };
      }

      // Personel dönem kayıtlarını sil
      await _client
          .from(DbTables.personelDonem)
          .delete()
          .eq('donem_id', donemId);

      // Dönemi sil
      await _client
          .from(DbTables.donemler)
          .delete()
          .eq('id', donemId);

      return {
        'success': true,
        'message': 'Dönem başarıyla silindi!',
      };

    } catch (e) {
      debugPrint('Dönem silme hatası: $e');
      return {
        'success': false,
        'message': 'Dönem silinirken hata oluştu: $e',
      };
    }
  }

  // Dönem durumunu güncelle
  static Future<Map<String, dynamic>> donemDurumuGuncelle(
    int donemId, 
    String yeniDurum
  ) async {
    try {
      if (yeniDurum == 'aktif') {
        // Önce diğer tüm dönemleri pasif yap
        await _client
            .from(DbTables.donemler)
            .update({'durum': 'tamamlandi'})
            .neq('id', donemId);
      }

      await _client
          .from(DbTables.donemler)
          .update({'durum': yeniDurum})
          .eq('id', donemId);

      return {
        'success': true,
        'message': 'Dönem durumu güncellendi!',
      };

    } catch (e) {
      debugPrint('Dönem durumu güncelleme hatası: $e');
      return {
        'success': false,
        'message': 'Dönem durumu güncellenirken hata oluştu: $e',
      };
    }
  }

  // Dönem istatistikleri
  static Future<Map<String, dynamic>> getDonemIstatistikleri(int donemId) async {
    try {
      final donemBilgisi = await _client
          .from(DbTables.donemler)
          .select('*')
          .eq('id', donemId)
          .single();

      final yil = donemBilgisi['yil'];
      final ay = donemBilgisi['ay'];
      
      // Bu dönemdeki veriler
      final mesaiSayisi = await _client
          .from(DbTables.mesai)
          .select('id')
          .eq('donem_id', donemId);

      final izinSayisi = await _client
          .from(DbTables.izinler)
          .select('id')
          .eq('donem_id', donemId);

      final bordroSayisi = await _client
          .from(DbTables.bordro)
          .select('id')
          .ilike('donem_kodu', '$yil-${ay.toString().padLeft(2, '0')}%');

      return {
        'donem_bilgisi': donemBilgisi,
        'mesai_sayisi': mesaiSayisi.length,
        'izin_sayisi': izinSayisi.length,
        'bordro_sayisi': bordroSayisi.length,
      };

    } catch (e) {
      debugPrint('Dönem istatistikleri getirme hatası: $e');
      return {
        'donem_bilgisi': null,
        'mesai_sayisi': 0,
        'izin_sayisi': 0,
        'bordro_sayisi': 0,
      };
    }
  }
}
