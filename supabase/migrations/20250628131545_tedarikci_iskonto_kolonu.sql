-- =============================================
-- TEDARİKÇİ İSKONTO KOLONU
-- =============================================

-- Tedarikçiler tablosu mevcutsa iskonto ile ilgili kolonları ekle
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tedarikciler') THEN
        ALTER TABLE tedarikciler
        ADD COLUMN IF NOT EXISTS varsayilan_iskonto DECIMAL(5,2) DEFAULT 0;
    END IF;
END $$;
