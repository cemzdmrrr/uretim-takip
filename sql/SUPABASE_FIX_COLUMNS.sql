-- ÖNEMLİ: Bu SQL komutlarını Supabase Dashboard SQL Editor'da çalıştırın
-- Aktif sekmesine geçiş ve kabul işlemi için gerekli kolonlar

-- 1. ÖNCE MEVCUT DURUMU KONTROL ET
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari' 
  AND table_schema = 'public' 
  AND column_name IN ('onay_tarihi', 'kabul_edilen_adet')
ORDER BY column_name;

-- 2. EKSİK KOLONLARI EKLE
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS onay_tarihi timestamp with time zone;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;

-- 3. DİĞER TABLOLAR İÇİN DE AYNI KOLONLAR
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS onay_tarihi timestamp with time zone;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS talep_edilen_adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tamamlanan_adet integer;

-- 4. MEVCUT TEST ATAMASINI SIFIRLA
UPDATE dokuma_atamalari 
SET durum = 'atandi',
    onay_tarihi = NULL,
    kabul_edilen_adet = NULL,
    tamamlanan_adet = NULL,
    uretici_notlari = NULL,
    tamamlama_tarihi = NULL
WHERE tedarikci_id = 9;

-- 5. SON KONTROL - TABLO YAPISINI DOĞRULA
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 6. TEST VERISINI KONTROL ET
SELECT id, model_id, tedarikci_id, durum, adet, talep_edilen_adet, 
       kabul_edilen_adet, tamamlanan_adet, onay_tarihi
FROM dokuma_atamalari 
WHERE tedarikci_id = 9;