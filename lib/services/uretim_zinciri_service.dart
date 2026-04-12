// ÜRETİM ZİNCİRİ GÜVENLİK SERVİSİ
// Email bazlı atama ve firma izolasyonu

import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/asama_registry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class UretimZinciriService {
  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  
  // Public getter for Supabase client
  SupabaseClient get supabase => _supabase;

  // Admin bazlı atama - Sadece admin kullanıcılar atama yapabilir
  Future<Map<String, dynamic>> assignModelsToUser({
    required List<String> modelIds, // UUID string formatı
    required String assigneeEmail,
    required String stageName,
    String notes = '',
    int? requestedQuantity, // İstenen adet
  }) async {
    try {
      // Mevcut kullanıcının admin olup olmadığını kontrol et
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Kullanıcı giriş yapmamış'};
      }
      
      // Kullanıcının admin rolüne sahip olup olmadığını kontrol et
      final userRoleResponse = await _supabase
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id)
          .eq('aktif', true)
          .maybeSingle();
      
      if (userRoleResponse == null || userRoleResponse['role'] != 'admin') {
        return {'success': false, 'error': 'Bu işlem için admin yetkisi gerekli'};
      }
      
      // Admin kontrolü geçtikten sonra atamayı gerçekleştir
      final String userId = currentUser.id;

      int successCount = 0;
      final List<String> errors = [];

      // 2. Her model için atama yap
      for (String modelId in modelIds) {
        try {
          // Model'in varlığını ve detaylarını kontrol et
          final modelCheck = await _supabase
              .from(DbTables.trikoTakip)
              .select('id, model_adi, toplam_adet')  // musteri_adi kaldırıldı - bu kolon yok
              .eq('firma_id', _firmaId)
              .eq('id', modelId)
              .maybeSingle();

          if (modelCheck == null) {
            errors.add('Model bulunamadı: $modelId');
            continue;
          }

          // Model detaylarından adet bilgisini al
          final int modelAdet = modelCheck['toplam_adet'] ?? 1;  // toplam_adet kolonu kullan
          final int atamaAdet = requestedQuantity ?? modelAdet; // İstenen adet yoksa tüm siparişi ata

          // Atama tablosu adını belirle
          final String tableName = _getAssignmentTableName(stageName);

          // 1. Atama tablosuna kayıt ekle (adet bilgisi ile)
          final atamaData = <String, dynamic>{
            'model_id': modelId,
            'atanan_kullanici_id': userId,
            'durum': 'atandi',
            'notlar': notes,
            'atama_tarihi': DateTime.now().toIso8601String(),
          };

          // Adet bilgilerini ekle
          atamaData['adet'] = atamaAdet;
          atamaData['talep_edilen_adet'] = atamaAdet;
          atamaData['tamamlanan_adet'] = 0; // Başlangıçta 0
          atamaData['firma_id'] = _firmaId;
          
          // Model bilgilerini de ekle (varsa) - musteri_adi modelden değil currentModelData'dan alınır
          // if (modelCheck['musteri_adi'] != null) {
          //   atamaData['musteri_adi'] = modelCheck['musteri_adi'];
          // }

          await _supabase.from(tableName).insert(atamaData);

          // 2. ÖNEMLİ: uretim_kayitlari tablosuna da kayıt ekle (UI'da görünür olsun)
          // Sadece kesin olan minimum kolonları kullan
          final insertData = <String, dynamic>{
            'firma_id': _firmaId,
            'model_id': modelId,
            'asama': _getStageNameForUretimKayitlari(stageName), // Doğru aşama adını kullan
            'durum': 'atandi',
            'tamamlanan_adet': 0,      // Bu kesinlikle var (NOT NULL hata verdi)
          };
          
          debugPrint('📊 Minimal insert verisi: $insertData');

          // Tedarikci bilgisini ekle (eski firma_id değil, tedarikci referansı)
          try {
            final firmaResponse = await _supabase
                .from(DbTables.tedarikciler)
                .select('id')
                .eq('email', assigneeEmail)
                .maybeSingle();
            
            if (firmaResponse != null) {
              insertData['tedarikci_id'] = firmaResponse['id'];
            }
          } catch (e) {
            debugPrint('Tedarikci ID bulunamadı, devam ediliyor: $e');
          }

          // uretim_kayitlari tablosuna ekle - güvenli yaklaşım
          try {
            await _supabase.from(DbTables.uretimKayitlari).insert(insertData);
            debugPrint('✅ uretim_kayitlari tablosuna başarıyla eklendi');
          } catch (e) {
            debugPrint('❌ uretim_kayitlari insert hatası: $e');
            
            // Daha minimal versiyon dene
            try {
              final minimalData = <String, dynamic>{
                'firma_id': _firmaId,
                'model_id': modelId,
                'asama': _getStageNameForUretimKayitlari(stageName),
                'durum': 'atandi',
                'tamamlanan_adet': 0, // NOT NULL olduğu için ekle
              };
              await _supabase.from(DbTables.uretimKayitlari).insert(minimalData);
              debugPrint('✅ Minimal versiyon başarılı');
            } catch (e2) {
              debugPrint('❌ Minimal versiyon da başarısız: $e2');
              // Atama tablosu işlemi yine de başarılı, devam et
            }
          }

          successCount++;
        } catch (e) {
          debugPrint('❌ Model $modelId atama detaylı hatası: $e');
          debugPrint('📊 Hata tipi: ${e.runtimeType}');
          errors.add('Model $modelId atama hatası: $e');
        }
      }

      return {
        'success': successCount > 0,
        'assigned_count': successCount,
        'total_requested': modelIds.length,
        'errors': errors,
        'message': '$successCount model başarıyla atandı',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Atama işlemi başarısız: $e',
      };
    }
  }

  // Aşama adından tablo adını çıkar - AsamaRegistry üzerinden
  String _getAssignmentTableName(String stageName) {
    final aktifDallar = TenantManager.instance.aktifUretimDallari;
    for (final dal in aktifDallar) {
      final asama = AsamaRegistry.asamaBul(dal, stageName.toLowerCase());
      if (asama != null) return asama.atamaTablosu;
    }
    // Fallback: tüm yüklü dallarda ara
    for (final dal in AsamaRegistry.yukluDallar) {
      final asama = AsamaRegistry.asamaBul(dal, stageName.toLowerCase());
      if (asama != null) return asama.atamaTablosu;
    }
    return 'uretim_atamalari';
  }

  // Aşama adını uretim_kayitlari tablosu için uygun formata çevir
  String _getStageNameForUretimKayitlari(String stageName) {
    final aktifDallar = TenantManager.instance.aktifUretimDallari;
    for (final dal in aktifDallar) {
      final asama = AsamaRegistry.asamaBul(dal, stageName.toLowerCase());
      if (asama?.eskiDurumKolonu != null) {
        final kolon = asama!.eskiDurumKolonu!;
        return kolon.replaceAll('_durumu', '');
      }
    }
    // Fallback: tüm yüklü dallarda ara
    for (final dal in AsamaRegistry.yukluDallar) {
      final asama = AsamaRegistry.asamaBul(dal, stageName.toLowerCase());
      if (asama?.eskiDurumKolonu != null) {
        final kolon = asama!.eskiDurumKolonu!;
        return kolon.replaceAll('_durumu', '');
      }
    }
    return stageName.toLowerCase();
  }

  // Kullanıcının atanmış modellerini getir
  Future<List<Map<String, dynamic>>> getAssignedModels(String stageName) async {
    try {
      final response = await _supabase.rpc('get_assigned_models', params: {
        'stage_name': stageName,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Atanmış modeller getirme hatası: $e');
      return [];
    }
  }

  // Email bazlı personel listesi
  Future<List<Map<String, dynamic>>> getStagePersonnel(String stageName) async {
    try {
      // Aşama adını atölye türüne çevir
      final String atolyeTuru = _getAtolyeTuru(stageName);
      
      final response = await _supabase
          .from(DbTables.atolyeler)
          .select('id, atolye_adi, atolye_turu, email, telefon, adres, kapasitesi, aktif')
          .eq('atolye_turu', atolyeTuru)
          .eq('aktif', true)
          .order('atolye_adi'); // Alphabetic sıralama ekle

      // Duplicate'ları temizle - email bazlı benzersiz atölyeler
      final Map<String, Map<String, dynamic>> benzersizAtolyeler = {};
      
      for (final atolye in response) {
        String email = atolye['email'] ?? '';
        final String atolyeAdi = atolye['atolye_adi'] ?? '';
        
        // Email yoksa atölye adından oluştur
        if (email.isEmpty && atolyeAdi.isNotEmpty) {
          email = '${atolyeAdi.toLowerCase().replaceAll(' ', '').replaceAll(RegExp(r'[^a-z0-9]'), '')}@atolye.com';
          atolye['email'] = email;
        }
        
        // Benzersiz email kontrolü
        if (email.isNotEmpty && !benzersizAtolyeler.containsKey(email)) {
          benzersizAtolyeler[email] = atolye;
        }
      }

      return benzersizAtolyeler.values.toList();
    } catch (e) {
      debugPrint('Atölye listesi getirme hatası: $e');
      return [];
    }
  }

  // Aşama adını atölye türüne çeviren helper fonksiyon
  String _getAtolyeTuru(String stageName) {
    switch (stageName.toLowerCase()) {
      case 'dokuma':
      case 'orgu':
        return 'Tekstil'; // veya 'orgu' - atölye verilerine göre
      case 'konfeksiyon':
        return 'Konfeksiyon';
      case 'yikama':
        return 'Yıkama';
      case 'utu':
        return 'Ütü Paket';
      case 'ilik_dugme':
        return 'İlik Düğme';
      case 'kalite_kontrol':
        return 'kalite';
      default:
        return stageName;
    }
  }

  // Atama istatistikleri
  Future<List<Map<String, dynamic>>> getAssignmentStatistics() async {
    try {
      final response = await _supabase
          .from(DbTables.atamaIstatistikleri)
          .select('*');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('İstatistik getirme hatası: $e');
      return [];
    }
  }

  // Model durumu güncelle
  Future<bool> updateModelStatus({
    required int modelId,
    required String stageName,
    required String newStatus,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('Kullanıcı giriş yapmamış');
        return false;
      }

      final tableName = '${stageName}_atamalari';
      
      await _supabase
          .from(tableName)
          .update({
            'durum': newStatus,
            if (newStatus == 'baslatildi') 'baslama_tarihi': DateTime.now().toIso8601String(),
            if (newStatus == 'tamamlandi') 'tamamlama_tarihi': DateTime.now().toIso8601String(),
          })
          .eq('model_id', modelId)
          .eq('atanan_kullanici_id', currentUser.id);

      return true;
    } catch (e) {
      debugPrint('Durum güncelleme hatası: $e');
      return false;
    }
  }

  // Rol kontrolü (güvenlik)
  Future<bool> checkUserRole(String email, String role) async {
    try {
      final response = await _supabase.rpc('check_user_role', params: {
        'email_addr': email,
        'expected_role': role,
      });

      return response == true;
    } catch (e) {
      debugPrint('Rol kontrolü hatası: $e');
      return false;
    }
  }

  // Email'den UUID bulma
  Future<String?> getUserIdByEmail(String email) async {
    try {
      final response = await _supabase.rpc('get_user_by_email', params: {
        'email_addr': email,
      });

      return response as String?;
    } catch (e) {
      debugPrint('Email UUID bulma hatası: $e');
      return null;
    }
  }

  // Mevcut kullanıcının rolünü getir
  Future<String?> getCurrentUserRole() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', currentUser.id)
          .eq('aktif', true)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      debugPrint('Kullanıcı rolü getirme hatası: $e');
      return null;
    }
  }

  // Güvenli model listesi (sadece yetkili modeller)
  Future<List<Map<String, dynamic>>> getAuthorizedModels({
    String? stageName,
    String? status,
  }) async {
    try {
      final currentUserRole = await getCurrentUserRole();
      
      if (currentUserRole == 'admin') {
        // Admin tüm modelleri görebilir
        var query = _supabase.from(DbTables.modeller).select('*').eq('firma_id', _firmaId);
        
        if (status != null) {
          final statusColumn = '${stageName}_durumu';
          query = query.eq(statusColumn, status);
        }
        
        final response = await query;
        return List<Map<String, dynamic>>.from(response);
      } else if (stageName != null && currentUserRole == stageName) {
        // Sadece kendi aşamasındaki modelleri görebilir
        return await getAssignedModels(stageName);
      } else {
        // Yetkisiz erişim
        return [];
      }
    } catch (e) {
      debugPrint('Yetkili model listesi hatası: $e');
      return [];
    }
  }

  // Toplu durum güncelleme
  Future<Map<String, dynamic>> bulkUpdateStatus({
    required List<int> modelIds,
    required String stageName,
    required String newStatus,
  }) async {
    try {
      int successCount = 0;
      int failCount = 0;

      for (final modelId in modelIds) {
        final success = await updateModelStatus(
          modelId: modelId,
          stageName: stageName,
          newStatus: newStatus,
        );
        
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      return {
        'success': failCount == 0,
        'successCount': successCount,
        'failCount': failCount,
        'total': modelIds.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Toplu güncelleme hatası: $e',
      };
    }
  }
}

// Enum'lar
enum UretimAsamasi {
  dokuma('dokuma', 'Dokuma'),
  konfeksiyon('konfeksiyon', 'Konfeksiyon'),
  yikama('yikama', 'Yıkama'),
  utu('utu', 'Ütü'),
  ilikDugme('ilik_dugme', 'İlik Düğme'),
  kaliteKontrol('kalite_kontrol', 'Kalite Kontrol'),
  paketleme('paketleme', 'Paketleme');

  const UretimAsamasi(this.kod, this.displayName);
  final String kod;
  final String displayName;
}

enum ModelDurum {
  atandi('atandi', 'Atandı'),
  baslatildi('baslatildi', 'Başlatıldı'),
  tamamlandi('tamamlandi', 'Tamamlandı'),
  beklemede('beklemede', 'Beklemede');

  const ModelDurum(this.kod, this.displayName);
  final String kod;
  final String displayName;
}

// Widget için yardımcı sınıf
class UretimAtamaWidget {
  static List<DropdownMenuItem<String>> buildPersonelDropdown(
    List<Map<String, dynamic>> personeller
  ) {
    return personeller.map((personel) {
      return DropdownMenuItem<String>(
        value: personel['email'],
        child: Text('${personel['email']} (${personel['asama']})'),
      );
    }).toList();
  }

  static List<DropdownMenuItem<String>> buildStageDropdown() {
    return UretimAsamasi.values.map((asama) {
      return DropdownMenuItem<String>(
        value: asama.kod,
        child: Text(asama.displayName),
      );
    }).toList();
  }

  static List<DropdownMenuItem<String>> buildStatusDropdown() {
    return ModelDurum.values.map((durum) {
      return DropdownMenuItem<String>(
        value: durum.kod,
        child: Text(durum.displayName),
      );
    }).toList();
  }
}
