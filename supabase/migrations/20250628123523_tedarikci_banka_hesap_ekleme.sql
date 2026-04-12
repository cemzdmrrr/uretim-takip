-- =============================================
-- TEDARİKÇİLER TABLOSUNA BANKA HESAP BİLGİLERİ EKLEME
-- Bu dosya tedarikçiler tablosu oluşturulduktan sonra çalışır
-- =============================================

-- Tedarikçiler tablosu mevcutsa banka hesap bilgilerini ekle
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tedarikciler') THEN
        ALTER TABLE tedarikciler
        ADD COLUMN IF NOT EXISTS banka_hesap_no VARCHAR(50),
        ADD COLUMN IF NOT EXISTS iban VARCHAR(34),
        ADD COLUMN IF NOT EXISTS banka_adi VARCHAR(100),
        ADD COLUMN IF NOT EXISTS sube_kodu VARCHAR(20),
        ADD COLUMN IF NOT EXISTS sube_adi VARCHAR(100);
    END IF;
END $$;
