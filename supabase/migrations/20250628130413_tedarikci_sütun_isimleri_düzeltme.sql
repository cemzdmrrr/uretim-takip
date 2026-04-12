-- =============================================
-- TEDARİKÇİ SÜTUN İSİMLERİ DÜZELTMESİ
-- =============================================

-- Tedarikçiler tablosu mevcutsa sütun isimlerini düzelt
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tedarikciler') THEN
        -- Sütun isimlerini kontrol et ve gerekli düzeltmeleri yap
        ALTER TABLE tedarikciler
        ADD COLUMN IF NOT EXISTS banka_subesi VARCHAR(100),
        ADD COLUMN IF NOT EXISTS cep_telefonu VARCHAR(20),
        ADD COLUMN IF NOT EXISTS web_sitesi VARCHAR(255),
        ADD COLUMN IF NOT EXISTS yetkili_kisi VARCHAR(100);
    END IF;
END $$;
