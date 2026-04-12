-- Tüm atama tablolarına adet kolonları ekleme
-- Bu script tüm atama tablolarına adet bilgisi kolonlarını ekler

-- Tablo listesi
DO $$
DECLARE
    tablo_adlari text[] := ARRAY[
        'dokuma_atamalari',
        'konfeksiyon_atamalari', 
        'yikama_atamalari',
        'utu_atamalari',
        'ilik_dugme_atamalari',
        'kalite_kontrol_atamalari',
        'paketleme_atamalari'
    ];
    tablo_adi text;
BEGIN
    FOREACH tablo_adi IN ARRAY tablo_adlari
    LOOP
        -- Tablo mevcut mu kontrol et
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = tablo_adi
        ) THEN
            
            RAISE NOTICE 'Tablo işleniyor: %', tablo_adi;
            
            -- Adet kolonu ekle
            EXECUTE format('
                ALTER TABLE %I ADD COLUMN IF NOT EXISTS adet INTEGER
            ', tablo_adi);
            
            -- Talep edilen adet kolonu ekle
            EXECUTE format('
                ALTER TABLE %I ADD COLUMN IF NOT EXISTS talep_edilen_adet INTEGER
            ', tablo_adi);
            
            -- Tamamlanan adet kolonu ekle (NULL olabilir)
            EXECUTE format('
                ALTER TABLE %I ADD COLUMN IF NOT EXISTS tamamlanan_adet INTEGER
            ', tablo_adi);
            
            -- Müşteri adı kolonu ekle
            EXECUTE format('
                ALTER TABLE %I ADD COLUMN IF NOT EXISTS musteri_adi TEXT
            ', tablo_adi);
            
            RAISE NOTICE '% tablosu güncellendi', tablo_adi;
            
        ELSE
            RAISE NOTICE 'Tablo bulunamadı: %', tablo_adi;
        END IF;
    END LOOP;
END $$;

-- Mevcut kayıtlar için varsayılan değerler ayarla
UPDATE dokuma_atamalari SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1),
    tamamlanan_adet = COALESCE(tamamlanan_adet, 0)
WHERE adet IS NULL OR talep_edilen_adet IS NULL OR tamamlanan_adet IS NULL;

UPDATE konfeksiyon_atamalari SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1),
    tamamlanan_adet = COALESCE(tamamlanan_adet, 0)
WHERE adet IS NULL OR talep_edilen_adet IS NULL OR tamamlanan_adet IS NULL;

UPDATE yikama_atamalari SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1),
    tamamlanan_adet = COALESCE(tamamlanan_adet, 0)
WHERE adet IS NULL OR talep_edilen_adet IS NULL OR tamamlanan_adet IS NULL;

UPDATE utu_atamalari SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1),
    tamamlanan_adet = COALESCE(tamamlanan_adet, 0)
WHERE adet IS NULL OR talep_edilen_adet IS NULL OR tamamlanan_adet IS NULL;

UPDATE ilik_dugme_atamalari SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1),
    tamamlanan_adet = COALESCE(tamamlanan_adet, 0)
WHERE adet IS NULL OR talep_edilen_adet IS NULL OR tamamlanan_adet IS NULL;

UPDATE kalite_kontrol_atamalari SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1),
    tamamlanan_adet = COALESCE(tamamlanan_adet, 0)
WHERE adet IS NULL OR talep_edilen_adet IS NULL OR tamamlanan_adet IS NULL;

UPDATE paketleme_atamalari SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1),
    tamamlanan_adet = COALESCE(tamamlanan_adet, 0)
WHERE adet IS NULL OR talep_edilen_adet IS NULL OR tamamlanan_adet IS NULL;

-- Son kontrol - tüm tabloların kolon yapısını göster
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN (
    'dokuma_atamalari',
    'konfeksiyon_atamalari', 
    'yikama_atamalari',
    'utu_atamalari',
    'ilik_dugme_atamalari',
    'kalite_kontrol_atamalari',
    'paketleme_atamalari'
)
AND column_name IN ('adet', 'talep_edilen_adet', 'tamamlanan_adet', 'musteri_adi')
ORDER BY table_name, column_name;

COMMIT;