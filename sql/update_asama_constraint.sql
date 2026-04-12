-- Aşama check constraint'lerini güncelle

-- 1. uretim_kayitlari tablosu için
-- Mevcut constraint'i kaldır
ALTER TABLE uretim_kayitlari DROP CONSTRAINT IF EXISTS uretim_kayitlari_asama_check;

-- Yeni constraint'i ekle (tüm aşamalar dahil)
ALTER TABLE uretim_kayitlari ADD CONSTRAINT uretim_kayitlari_asama_check 
    CHECK (asama IN ('orgu', 'konfeksiyon', 'yikama', 'nakis', 'ilik_dugme', 'utu', 'diger'));

-- 2. bildirimler tablosu için
-- Mevcut constraint'i kaldır
ALTER TABLE bildirimler DROP CONSTRAINT IF EXISTS bildirimler_asama_check;

-- Yeni constraint'i ekle (tüm aşamalar dahil)
ALTER TABLE bildirimler ADD CONSTRAINT bildirimler_asama_check 
    CHECK (asama IN ('orgu', 'konfeksiyon', 'yikama', 'nakis', 'ilik_dugme', 'utu', 'diger'));

-- Mevcut kayıtları kontrol et
SELECT 'uretim_kayitlari' as tablo, asama, COUNT(*) as kayit_sayisi 
FROM uretim_kayitlari 
GROUP BY asama
UNION ALL
SELECT 'bildirimler' as tablo, asama, COUNT(*) as kayit_sayisi 
FROM bildirimler 
WHERE asama IS NOT NULL
GROUP BY asama
ORDER BY tablo, asama;
