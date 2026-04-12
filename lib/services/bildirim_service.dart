import 'package:flutter/foundation.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Bildirim servisi - Üretim takip sistemi için bildirim yönetimi
/// Desteklenen bildirim tipleri:
/// - atama_bekliyor: Yeni atama bildirimi
/// - atama_onaylandi: Atama onay bildirimi
/// - atama_reddedildi: Atama red bildirimi
/// - uretim_tamamlandi: Üretim tamamlandı bildirimi
/// - kalite_onay: Kalite onaylandı bildirimi
/// - kalite_red: Kalite reddedildi bildirimi
/// - sevkiyat_hazir: Sevkiyat hazır bildirimi
/// - stok_uyari: Stok kritik seviye uyarısı
/// - termin_uyari: Termin yaklaşma uyarısı
/// - siparis_yeni: Yeni sipariş bildirimi
/// - genel: Genel bildirimler
class BildirimService {
  static final BildirimService _instance = BildirimService._internal();
  factory BildirimService() => _instance;
  BildirimService._internal();

  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  /// Bildirim gönder
  Future<void> bildirimGonder({
    required String userId,
    required String baslik,
    required String mesaj,
    required String tip,
    String? modelId,
    String? atamaId,
    String? asama,
    Map<String, dynamic>? ekBilgi,
  }) async {
    try {
      await _supabase.from(DbTables.bildirimler).insert({
        'firma_id': _firmaId,
        'user_id': userId,
        'baslik': baslik,
        'mesaj': mesaj,
        'tip': tip,
        'model_id': modelId,
        'atama_id': atamaId,
        'asama': asama,
        'ek_bilgi': ekBilgi,
        'okundu': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Bildirim gönderildi: $baslik -> $userId');
    } catch (e) {
      debugPrint('❌ Bildirim gönderme hatası: $e');
      rethrow;
    }
  }

  /// Belirli role sahip tüm kullanıcılara bildirim gönder
  Future<void> roleGoreBildirimGonder({
    required String rol,
    required String baslik,
    required String mesaj,
    required String tip,
    String? modelId,
    String? atamaId,
    String? asama,
  }) async {
    try {
      // Bu role sahip kullanıcıları bul
      final kullanicilar = await _supabase
          .from(DbTables.userRoles)
          .select('user_id')
          .eq('role', rol)
          .eq('aktif', true);

      for (var kullanici in kullanicilar) {
        await bildirimGonder(
          userId: kullanici['user_id'],
          baslik: baslik,
          mesaj: mesaj,
          tip: tip,
          modelId: modelId,
          atamaId: atamaId,
          asama: asama,
        );
      }
      debugPrint('✅ ${kullanicilar.length} $rol kullanıcısına bildirim gönderildi');
    } catch (e) {
      debugPrint('❌ Role göre bildirim gönderme hatası: $e');
    }
  }

  /// Şoförlere sevkiyat bildirimi gönder
  Future<void> soforlereSevkiyatBildirimi({
    required String modelId,
    required String modelAdi,
    required int adet,
    required String kaynakAtelye,
    required String hedefAtelye,
    String? sevkTalebiId,
  }) async {
    try {
      // Tüm şoförlere bildirim gönder
      await roleGoreBildirimGonder(
        rol: 'sofor',
        baslik: '🚚 Yeni Sevkiyat Talebi',
        mesaj: '$modelAdi modeli için $adet adet ürün sevk edilecek.\n$kaynakAtelye → $hedefAtelye',
        tip: 'sevkiyat_hazir',
        modelId: modelId,
        atamaId: sevkTalebiId,
      );
    } catch (e) {
      debugPrint('❌ Şoförlere sevkiyat bildirimi hatası: $e');
    }
  }

  /// Kalite kontrole bildirim gönder
  Future<void> kaliteKontroleBildirim({
    required String modelId,
    required String modelAdi,
    required int adet,
    required String asama,
    String? atamaId,
  }) async {
    try {
      await roleGoreBildirimGonder(
        rol: 'kalite_kontrol',
        baslik: '🔍 Kalite Kontrol Bekliyor',
        mesaj: '$modelAdi modeli $asama aşamasından $adet adet ürün kalite kontrole hazır.',
        tip: 'kalite_onay',
        modelId: modelId,
        atamaId: atamaId,
        asama: asama,
      );
    } catch (e) {
      debugPrint('❌ Kalite kontrole bildirim hatası: $e');
    }
  }

  /// Tedarikçiye atama bildirimi gönder
  Future<void> tedarikciAtamaBildirimi({
    required String tedarikciEmail,
    required String modelAdi,
    required int adet,
    required String asama,
    String? modelId,
    String? atamaId,
  }) async {
    try {
      // Tedarikci email'inden user_id bul
      final tedarikci = await _supabase
          .from(DbTables.tedarikciler)
          .select('id, email')
          .eq('firma_id', _firmaId)
          .eq('email', tedarikciEmail)
          .maybeSingle();

      if (tedarikci == null) {
        debugPrint('⚠️ Tedarikci bulunamadı: $tedarikciEmail');
        return;
      }

      // Auth users tablosundan user_id'yi bul
      // Not: Tedarikci login olduğunda auth.users'a kayıt olur
      // Burada tedarikci email'i ile user'ı eşleştirmemiz gerekiyor
      // Şimdilik sadece log yapalım
      debugPrint('📧 Tedarikci atama bildirimi: $tedarikciEmail -> $modelAdi ($adet adet $asama)');
      
    } catch (e) {
      debugPrint('❌ Tedarikci atama bildirimi hatası: $e');
    }
  }

  /// Kullanıcının okunmamış bildirimlerini getir
  Future<List<Map<String, dynamic>>> okunmamisBildirimleriGetir(String userId) async {
    try {
      final bildirimler = await _supabase
          .from(DbTables.bildirimler)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .eq('okundu', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(bildirimler);
    } catch (e) {
      debugPrint('❌ Bildirim getirme hatası: $e');
      return [];
    }
  }

  /// Kullanıcının tüm bildirimlerini getir
  Future<List<Map<String, dynamic>>> tumBildirimleriGetir(String userId, {int limit = 50}) async {
    try {
      final bildirimler = await _supabase
          .from(DbTables.bildirimler)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(bildirimler);
    } catch (e) {
      debugPrint('❌ Bildirim getirme hatası: $e');
      return [];
    }
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> bildirimOkundu(String bildirimId) async {
    try {
      await _supabase
          .from(DbTables.bildirimler)
          .update({'okundu': true})
          .eq('id', bildirimId);
    } catch (e) {
      debugPrint('❌ Bildirim okundu hatası: $e');
    }
  }

  /// Kullanıcının tüm bildirimlerini okundu olarak işaretle
  Future<void> tumBildirimlerOkundu(String userId) async {
    try {
      await _supabase
          .from(DbTables.bildirimler)
          .update({'okundu': true})
          .eq('user_id', userId)
          .eq('okundu', false);
    } catch (e) {
      debugPrint('❌ Tüm bildirimler okundu hatası: $e');
    }
  }

  /// Okunmamış bildirim sayısını getir
  Future<int> okunmamisBildirimSayisi(String userId) async {
    try {
      final response = await _supabase
          .from(DbTables.bildirimler)
          .select('id')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .eq('okundu', false);

      return response.length;
    } catch (e) {
      debugPrint('❌ Bildirim sayısı hatası: $e');
      return 0;
    }
  }

  /// Sevk talebi oluştur ve şoförlere bildirim gönder
  Future<int?> sevkTalebiOlustur({
    required String modelId,
    required int kaynakAtolyeId,
    required int hedefAtolyeId,
    required String talepEdenUserId,
    required int sevkAdeti,
    String? aciklama,
    String onceligi = 'normal',
  }) async {
    try {
      final response = await _supabase
          .from(DbTables.sevkTalepleri)
          .insert({
            'firma_id': _firmaId,
            'model_id': modelId,
            'kaynak_atolye_id': kaynakAtolyeId,
            'hedef_atolye_id': hedefAtolyeId,
            'talep_eden_user_id': talepEdenUserId,
            'sevk_adeti': sevkAdeti,
            'durum': 'bekliyor',
            'onceligi': onceligi,
            'aciklama': aciklama,
          })
          .select('id')
          .single();

      final sevkTalebiId = response['id'];
      debugPrint('✅ Sevk talebi oluşturuldu: $sevkTalebiId');

      // Model bilgilerini al
      final model = await _supabase
          .from(DbTables.trikoTakip)
          .select('marka, item_no')
          .eq('firma_id', _firmaId)
          .eq('id', modelId)
          .single();

      // Atölye bilgilerini al
      final kaynakAtelye = await _supabase
          .from(DbTables.atolyeler)
          .select('atolye_adi')
          .eq('id', kaynakAtolyeId)
          .single();

      final hedefAtelye = await _supabase
          .from(DbTables.atolyeler)
          .select('atolye_adi')
          .eq('id', hedefAtolyeId)
          .single();

      // Şoförlere bildirim gönder
      await soforlereSevkiyatBildirimi(
        modelId: modelId,
        modelAdi: '${model['marka']} - ${model['item_no']}',
        adet: sevkAdeti,
        kaynakAtelye: kaynakAtelye['atolye_adi'],
        hedefAtelye: hedefAtelye['atolye_adi'],
        sevkTalebiId: sevkTalebiId.toString(),
      );

      return sevkTalebiId;
    } catch (e) {
      debugPrint('❌ Sevk talebi oluşturma hatası: $e');
      return null;
    }
  }

  // ==============================================
  // YENİ BİLDİRİM TİPLERİ
  // ==============================================

  /// Stok kritik seviye uyarısı gönder
  Future<void> stokKritikUyarisi({
    required String stokAdi,
    required double mevcutMiktar,
    required double kritikSeviye,
    required String birim,
  }) async {
    try {
      await roleGoreBildirimGonder(
        rol: 'admin',
        baslik: '⚠️ Stok Kritik Seviyede',
        mesaj: '$stokAdi stoğu kritik seviyeye düştü!\nMevcut: $mevcutMiktar $birim\nKritik Seviye: $kritikSeviye $birim',
        tip: 'stok_uyari',
      );
    } catch (e) {
      debugPrint('❌ Stok uyarı bildirimi hatası: $e');
    }
  }

  /// Termin yaklaşma uyarısı gönder
  Future<void> terminYaklasmaUyarisi({
    required String modelId,
    required String modelAdi,
    required DateTime terminTarihi,
    required int kalanGun,
  }) async {
    try {
      await roleGoreBildirimGonder(
        rol: 'admin',
        baslik: '⏰ Termin Yaklaşıyor',
        mesaj: '$modelAdi modeli için termin tarihi yaklaşıyor!\nTermin: ${terminTarihi.day}.${terminTarihi.month}.${terminTarihi.year}\nKalan: $kalanGun gün',
        tip: 'termin_uyari',
        modelId: modelId,
      );
    } catch (e) {
      debugPrint('❌ Termin uyarı bildirimi hatası: $e');
    }
  }

  /// Yeni sipariş bildirimi gönder
  Future<void> yeniSiparisBildirimi({
    required String modelId,
    required String marka,
    required String itemNo,
    required int adet,
  }) async {
    try {
      await roleGoreBildirimGonder(
        rol: 'admin',
        baslik: '📦 Yeni Sipariş Eklendi',
        mesaj: '$marka - $itemNo modeli için $adet adetlik yeni sipariş oluşturuldu.',
        tip: 'siparis_yeni',
        modelId: modelId,
      );
    } catch (e) {
      debugPrint('❌ Yeni sipariş bildirimi hatası: $e');
    }
  }

  /// Toplu bildirim gönder (tüm admin kullanıcılara)
  Future<void> topluBildirimGonder({
    required String baslik,
    required String mesaj,
    String tip = 'genel',
  }) async {
    try {
      await roleGoreBildirimGonder(
        rol: 'admin',
        baslik: baslik,
        mesaj: mesaj,
        tip: tip,
      );
    } catch (e) {
      debugPrint('❌ Toplu bildirim hatası: $e');
    }
  }

  /// Termin kontrolü yap ve yaklaşan terminler için bildirim gönder
  Future<void> terminKontrolEt() async {
    try {
      final now = DateTime.now();
      final birHaftaSonra = now.add(const Duration(days: 7));
      
      // Yaklaşan terminleri getir
      final modeller = await _supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, termin_tarihi')
          .gte('termin_tarihi', now.toIso8601String().split('T')[0])
          .lte('termin_tarihi', birHaftaSonra.toIso8601String().split('T')[0])
          .neq('durum', 'Tamamlandı');

      for (var model in modeller) {
        if (model['termin_tarihi'] != null) {
          final terminTarihi = DateTime.parse(model['termin_tarihi']);
          final kalanGun = terminTarihi.difference(now).inDays;
          
          if (kalanGun <= 3) {
            await terminYaklasmaUyarisi(
              modelId: model['id'],
              modelAdi: '${model['marka']} - ${model['item_no']}',
              terminTarihi: terminTarihi,
              kalanGun: kalanGun,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Termin kontrolü hatası: $e');
    }
  }

  /// Bildirim sil
  Future<void> bildirimSil(String bildirimId) async {
    try {
      await _supabase.from(DbTables.bildirimler).delete().eq('id', bildirimId);
      debugPrint('✅ Bildirim silindi: $bildirimId');
    } catch (e) {
      debugPrint('❌ Bildirim silme hatası: $e');
    }
  }

  /// Kullanıcının tüm bildirimlerini sil
  Future<void> tumBildirimlerSil(String userId) async {
    try {
      await _supabase.from(DbTables.bildirimler).delete().eq('user_id', userId);
      debugPrint('✅ Kullanıcının tüm bildirimleri silindi: $userId');
    } catch (e) {
      debugPrint('❌ Tüm bildirimleri silme hatası: $e');
    }
  }

  /// Okunmuş bildirimleri sil
  Future<void> okunmusBildirimlerSil(String userId) async {
    try {
      await _supabase
          .from(DbTables.bildirimler)
          .delete()
          .eq('user_id', userId)
          .eq('okundu', true);
      debugPrint('✅ Okunmuş bildirimler silindi: $userId');
    } catch (e) {
      debugPrint('❌ Okunmuş bildirimleri silme hatası: $e');
    }
  }
}
