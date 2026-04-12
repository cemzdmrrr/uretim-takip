-- =============================================
-- TEDARİKÇİ PRIMARY KEY DÜZELTMESİ
-- =============================================

-- Tedarikçiler tablosu mevcutsa primary key kontrolü
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tedarikciler') THEN
        -- Primary key var mı kontrol et
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE table_name = 'tedarikciler' 
            AND constraint_type = 'PRIMARY KEY'
        ) THEN
            ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS id SERIAL PRIMARY KEY;
        END IF;
    END IF;
END $$;
