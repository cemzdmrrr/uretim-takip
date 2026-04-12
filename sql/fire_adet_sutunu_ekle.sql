-- ==========================================
-- ATAMA TABLOLARINA FIRE_ADET SÜTUNU EKLE
-- ==========================================

-- Dokuma atamaları
ALTER TABLE dokuma_atamalari 
ADD COLUMN IF NOT EXISTS fire_adet INTEGER DEFAULT 0;

-- Konfeksiyon atamaları
ALTER TABLE konfeksiyon_atamalari 
ADD COLUMN IF NOT EXISTS fire_adet INTEGER DEFAULT 0;

-- Yıkama atamaları
ALTER TABLE yikama_atamalari 
ADD COLUMN IF NOT EXISTS fire_adet INTEGER DEFAULT 0;

-- Ütü atamaları
ALTER TABLE utu_atamalari 
ADD COLUMN IF NOT EXISTS fire_adet INTEGER DEFAULT 0;

-- İlik düğme atamaları
ALTER TABLE ilik_dugme_atamalari 
ADD COLUMN IF NOT EXISTS fire_adet INTEGER DEFAULT 0;

-- Kontrol
SELECT 'fire_adet sütunları eklendi!' as mesaj;
