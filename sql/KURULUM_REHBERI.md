# Sevkiyat Sistemi Kurulum Rehberi

## Sorun Çözümü

❌ **Hata:** `foreign key constraint "sevk_talepleri_model_id_fkey" cannot be implemented`
✅ **Çözüm:** Model ID UUID formatına uygun şekilde düzeltildi.

## Kurulum Adımları

### 1. Güvenli SQL Dosyasını Kullanın

Mevcut tablo yapısından bağımsız çalışacak şekilde **`sevkiyat_sistemi_safe.sql`** dosyası oluşturuldu.

Bu dosya:
- Model ID'yi UUID olarak tanımlar
- Foreign key hatalarını önler  
- Mevcut tablolarla uyumlu çalışır
- Güvenli kurulum yapar

### 2. Supabase'de Çalıştırın

```sql
-- sevkiyat_sistemi_safe.sql dosyasının içeriğini Supabase SQL editöründe çalıştırın
```

### 3. Kullanıcı Rolleri Atayın

**HIZLI BAŞLANGIÇ:** `hizli_baslangic.sql` dosyasını çalıştırın (kendinizi otomatik admin yapar)

**MANUEL ATAMA:** 

İlk olarak UUID'nizi öğrenin:
```sql
-- uuid_bulma_yardimci.sql dosyasını çalıştırın veya:
SELECT auth.uid(), auth.email();
```

Sonra kendinizi admin yapın:
```sql
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES (auth.uid(), 'admin', 3);
```

**Detaylı rehber:** `ROL_ATAMA_REHBERI.md` dosyasını inceleyin.

### 4. Test Sevk Talebi Oluşturun

```sql
-- Test sevk talebi (gerçek model UUID'si ile)
INSERT INTO sevk_talepleri (
    model_id, 
    kaynak_atolye_id, 
    hedef_atolye_id, 
    talep_eden_user_id, 
    sevk_adeti
) VALUES (
    'your-model-uuid',  -- Gerçek triko_takip id'si
    1,                  -- Örgü atölyesi
    2,                  -- Kesim atölyesi
    'your-user-uuid',   -- Talep eden kullanıcı
    100                 -- Sevk adeti
);
```

## Sistem Özellikleri

✅ **Tablo Uyumluluğu:** Mevcut UUID/Integer karışıklığı çözüldü
✅ **Otomatik Bildirimler:** Trigger'lar çalışır durumda
✅ **Workflow Takibi:** Durum değişiklikleri kayıtlı
✅ **Performans:** İndeksler eklendi
✅ **Güvenlik:** Role-based access hazır

## Sonraki Adımlar

1. SQL dosyasını çalıştırın
2. Kullanıcı rolleri atayın  
3. Test verileri ekleyin
4. Flutter uygulamasında test edin

**Not:** Eğer hala hata alırsanız, lütfen tam hata mesajını paylaşın.
