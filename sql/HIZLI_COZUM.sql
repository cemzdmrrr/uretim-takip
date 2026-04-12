-- SUPABASE DASHBOARD'DA ÇALIŞTIRIN: Eksik Kolonları Ekle
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS onay_tarihi timestamp with time zone;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS red_sebebi text;

-- Test amaçlı mevcut atamayı sıfırla
UPDATE dokuma_atamalari 
SET durum = 'atandi',
    onay_tarihi = NULL,
    kabul_edilen_adet = NULL
WHERE tedarikci_id = 9;

-- Sonuç kontrol
SELECT id, durum, onay_tarihi, kabul_edilen_adet 
FROM dokuma_atamalari 
WHERE tedarikci_id = 9;