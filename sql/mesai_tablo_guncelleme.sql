-- Mesai tablosuna yemek_ucreti ve carpan sütunlarını ekle
ALTER TABLE mesai ADD COLUMN IF NOT EXISTS yemek_ucreti DECIMAL(10,2) DEFAULT 0;
ALTER TABLE mesai ADD COLUMN IF NOT EXISTS carpan DECIMAL(5,2) DEFAULT 1.0;

-- Mevcut kayıtları güncelle - mesai_turu'na göre varsayılan değerler ata
UPDATE mesai 
SET carpan = CASE 
    WHEN mesai_turu = 'Pazar' OR mesai_turu = 'Pazar Mesaisi' THEN 2.0
    WHEN mesai_turu = 'Bayram' OR mesai_turu = 'Bayram Mesaisi' THEN 1.5
    WHEN mesai_turu = 'Saatlik' OR mesai_turu = 'Normal Mesai' THEN 1.5
    ELSE 1.0
END
WHERE carpan IS NULL OR carpan = 0;

UPDATE mesai 
SET yemek_ucreti = CASE 
    WHEN mesai_turu = 'Pazar' OR mesai_turu = 'Pazar Mesaisi' THEN 50.0
    WHEN mesai_turu = 'Bayram' OR mesai_turu = 'Bayram Mesaisi' THEN 75.0
    ELSE 0.0
END
WHERE yemek_ucreti IS NULL OR yemek_ucreti = 0;

-- Mesai türlerini standart hale getir
UPDATE mesai SET mesai_turu = 'Pazar' WHERE mesai_turu = 'Pazar Mesaisi';
UPDATE mesai SET mesai_turu = 'Bayram' WHERE mesai_turu = 'Bayram Mesaisi';
UPDATE mesai SET mesai_turu = 'Saatlik' WHERE mesai_turu = 'Normal Mesai';

-- Mesai tablosu yapısını kontrol et
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'mesai' 
ORDER BY ordinal_position;
