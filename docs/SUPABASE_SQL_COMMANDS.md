Bu SQL komutlarını Supabase Dashboard SQL Editor'da çalıştırın:

-- 1. Dokuma atamalari tablosuna eksik kolonları ekle
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS onay_tarihi timestamp with time zone;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS red_sebebi text;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS uretim_baslangic_tarihi timestamp with time zone;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;

-- 2. Diğer atama tablolarına adet kolonları ekle
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS talep_edilen_adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tamamlanan_adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;

-- 3. Test amaçlı mevcut atamayı güncelle (kabul işlemini simüle et)
UPDATE dokuma_atamalari 
SET durum = 'onaylandi', 
    onay_tarihi = NOW(), 
    kabul_edilen_adet = 80
WHERE tedarikci_id = 9 AND durum = 'atandi';