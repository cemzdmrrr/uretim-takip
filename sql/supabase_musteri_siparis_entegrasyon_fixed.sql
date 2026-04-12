-- MUSTERI-SIPARIS ENTEGRASYONU ICIN VERITABANI GUNCELLEMESI
-- Bu script mevcut triko_takip tablosuna musteri alani ekler

-- 1. triko_takip tablosuna musteri_id kolonu ekle (guvenli yontem)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'musteri_id'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN musteri_id INTEGER REFERENCES musteriler(id);
    END IF;
END $$;

-- 2. Musteri_id icin index olustur (performans icin)
CREATE INDEX IF NOT EXISTS idx_triko_takip_musteri_id ON triko_takip(musteri_id);

-- 3. Siparis durumu ve tarihleri icin ek kolonlar (guvenli yontem)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'siparis_tarihi'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN siparis_tarihi DATE DEFAULT CURRENT_DATE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'siparis_notu'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN siparis_notu TEXT;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'toplam_maliyet'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN toplam_maliyet DECIMAL(10,2);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'kur'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN kur VARCHAR(3) DEFAULT 'TRY';
    END IF;
END $$;

-- 4. Musteri raporlari icin view olustur
CREATE OR REPLACE VIEW musteri_siparis_ozet AS
SELECT 
    m.id as musteri_id,
    m.ad,
    m.soyad,
    m.sirket,
    m.musteri_tipi,
    COUNT(t.id) as toplam_siparis,
    COUNT(CASE WHEN t.tamamlandi = true THEN 1 END) as tamamlanan_siparis,
    COUNT(CASE WHEN t.tamamlandi = false OR t.tamamlandi IS NULL THEN 1 END) as devam_eden_siparis,
    SUM(CASE WHEN t.toplam_maliyet IS NOT NULL THEN t.toplam_maliyet ELSE 0 END) as toplam_ciro,
    MIN(t.siparis_tarihi) as ilk_siparis_tarihi,
    MAX(t.siparis_tarihi) as son_siparis_tarihi
FROM musteriler m
LEFT JOIN triko_takip t ON m.id = t.musteri_id
GROUP BY m.id, m.ad, m.soyad, m.sirket, m.musteri_tipi;

-- 5. Siparis detaylari view (siparis listesi icin)
CREATE OR REPLACE VIEW siparis_detay_view AS
SELECT 
    t.id,
    t.marka,
    t.item_no,
    t.renk,
    t.urun_cinsi,
    t.iplik_cinsi,
    t.uretici,
    t.bedenler,
    t.termin,
    t.tamamlandi,
    t.siparis_tarihi,
    t.siparis_notu,
    t.toplam_maliyet,
    t.kur,
    t.musteri_id,
    m.ad as musteri_ad,
    m.soyad as musteri_soyad,
    m.sirket as musteri_sirket,
    m.telefon as musteri_telefon,
    m.email as musteri_email,
    m.musteri_tipi,
    CONCAT(COALESCE(m.ad, ''), ' ', COALESCE(m.soyad, '')) as musteri_tam_ad,
    COALESCE(m.sirket, CONCAT(COALESCE(m.ad, ''), ' ', COALESCE(m.soyad, ''))) as musteri_display_name
FROM triko_takip t
LEFT JOIN musteriler m ON t.musteri_id = m.id;

-- 6. Musteri siparislerini takip etmek icin trigger olustur
CREATE OR REPLACE FUNCTION update_musteri_bakiye()
RETURNS TRIGGER AS $$
BEGIN
    -- Siparis tamamlandiginda musteri bakiyesini guncelle (istege bagli)
    IF NEW.tamamlandi = true AND (OLD.tamamlandi = false OR OLD.tamamlandi IS NULL) THEN
        UPDATE musteriler 
        SET bakiye = COALESCE(bakiye, 0) + COALESCE(NEW.toplam_maliyet, 0)
        WHERE id = NEW.musteri_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger olustur
DROP TRIGGER IF EXISTS siparis_tamamlandi_trigger ON triko_takip;
CREATE TRIGGER siparis_tamamlandi_trigger
    AFTER UPDATE ON triko_takip
    FOR EACH ROW
    EXECUTE FUNCTION update_musteri_bakiye();

-- 8. Musteri siparislerini getirmek icin fonksiyon
CREATE OR REPLACE FUNCTION get_musteri_siparisleri(musteri_id_param INTEGER)
RETURNS TABLE (
    siparis_id INTEGER,
    marka VARCHAR,
    item_no VARCHAR,
    termin DATE,
    tamamlandi BOOLEAN,
    siparis_tarihi DATE,
    toplam_maliyet DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.marka,
        t.item_no,
        t.termin,
        t.tamamlandi,
        t.siparis_tarihi,
        t.toplam_maliyet
    FROM triko_takip t
    WHERE t.musteri_id = musteri_id_param
    ORDER BY t.siparis_tarihi DESC;
END;
$$ LANGUAGE plpgsql;

-- 9. Musteri istatistiklerini getirmek icin fonksiyon
CREATE OR REPLACE FUNCTION get_musteri_istatistikleri(musteri_id_param INTEGER)
RETURNS TABLE (
    toplam_siparis BIGINT,
    tamamlanan_siparis BIGINT,
    devam_eden_siparis BIGINT,
    toplam_ciro DECIMAL,
    ilk_siparis_tarihi DATE,
    son_siparis_tarihi DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(t.id) as toplam_siparis,
        COUNT(CASE WHEN t.tamamlandi = true THEN 1 END) as tamamlanan_siparis,
        COUNT(CASE WHEN t.tamamlandi = false OR t.tamamlandi IS NULL THEN 1 END) as devam_eden_siparis,
        SUM(CASE WHEN t.toplam_maliyet IS NOT NULL THEN t.toplam_maliyet ELSE 0 END) as toplam_ciro,
        MIN(t.siparis_tarihi) as ilk_siparis_tarihi,
        MAX(t.siparis_tarihi) as son_siparis_tarihi
    FROM triko_takip t
    WHERE t.musteri_id = musteri_id_param;
END;
$$ LANGUAGE plpgsql;

-- Basari mesaji
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'MUSTERI-SIPARIS ENTEGRASYONU TAMAMLANDI';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Eklenen ozellikler:';
    RAISE NOTICE '- triko_takip tablosuna musteri_id kolonu';
    RAISE NOTICE '- Siparis tarihi ve notu kolonlari';
    RAISE NOTICE '- Musteri siparis ozet view';
    RAISE NOTICE '- Siparis detay view';
    RAISE NOTICE '- Otomatik bakiye guncelleme trigger';
    RAISE NOTICE '- Musteri rapor fonksiyonlari';
    RAISE NOTICE '========================================';
END $$;
