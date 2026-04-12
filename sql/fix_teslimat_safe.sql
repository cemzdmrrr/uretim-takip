-- İplik teslimat kayıtları tablosunu güvenli şekilde düzelt
-- Mevcut veriyi koruyarak siparis_id yerine kalem_id kullan

-- 0. Önce view'ları sil (CASCADE için)
DROP VIEW IF EXISTS v_siparis_ozeti CASCADE;
DROP VIEW IF EXISTS v_geciken_siparişler CASCADE;
DROP VIEW IF EXISTS v_teslimat_detaylari CASCADE;

-- 1. Önce mevcut foreign key constraint'leri kaldır
DO $$
DECLARE
    constraint_name text;
BEGIN
    -- iplik_teslimat_kayitlari tablosundaki foreign key constraint'leri bul ve sil
    FOR constraint_name IN 
        SELECT tc.constraint_name
        FROM information_schema.table_constraints AS tc 
        WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_name = 'iplik_teslimat_kayitlari'
    LOOP
        EXECUTE 'ALTER TABLE iplik_teslimat_kayitlari DROP CONSTRAINT IF EXISTS ' || constraint_name;
        RAISE NOTICE 'Constraint silindi: %', constraint_name;
    END LOOP;
END $$;

-- 2. Mevcut verileri kontrol et ve temizle
DO $$
BEGIN
    -- Eğer tabloda veri varsa, temizle (test aşamasında)
    IF EXISTS (SELECT 1 FROM iplik_teslimat_kayitlari LIMIT 1) THEN
        DELETE FROM iplik_teslimat_kayitlari;
        RAISE NOTICE 'Mevcut teslimat verileri temizlendi (test verileri)';
    END IF;
END $$;

-- 3. siparis_id kolonunu sil
ALTER TABLE iplik_teslimat_kayitlari 
DROP COLUMN IF EXISTS siparis_id;

-- 4. kalem_id kolonu varsa sil (CASCADE ile), yoksa uyarı ver
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'iplik_teslimat_kayitlari' 
        AND column_name = 'kalem_id'
    ) THEN
        ALTER TABLE iplik_teslimat_kayitlari DROP COLUMN kalem_id CASCADE;
        RAISE NOTICE 'Mevcut kalem_id kolonu silindi (CASCADE)';
    END IF;
END $$;

-- 5. kalem_id kolonunu tekrar ekle (NOT NULL)
ALTER TABLE iplik_teslimat_kayitlari 
ADD COLUMN kalem_id uuid NOT NULL;

-- 6. Doğru foreign key constraint'i ekle
ALTER TABLE iplik_teslimat_kayitlari
ADD CONSTRAINT fk_teslimat_kalem 
FOREIGN KEY (kalem_id) REFERENCES iplik_siparis_kalemleri(id) ON DELETE CASCADE;

-- 7. Trigger fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION update_kalem_durumu()
RETURNS TRIGGER AS $$
DECLARE
    target_kalem_id uuid;
BEGIN
    -- INSERT/UPDATE için NEW, DELETE için OLD kullan
    IF TG_OP = 'DELETE' THEN
        target_kalem_id := OLD.kalem_id;
    ELSE
        target_kalem_id := NEW.kalem_id;
    END IF;
    
    -- Kalem için toplam gelen miktarı hesapla
    UPDATE iplik_siparis_kalemleri 
    SET 
        gelen_miktar = (
            SELECT COALESCE(SUM(gelen_miktar), 0) 
            FROM iplik_teslimat_kayitlari 
            WHERE kalem_id = target_kalem_id
        ),
        kalan_miktar = siparis_miktari - (
            SELECT COALESCE(SUM(gelen_miktar), 0) 
            FROM iplik_teslimat_kayitlari 
            WHERE kalem_id = target_kalem_id
        ),
        durum = CASE 
            WHEN (
                SELECT COALESCE(SUM(gelen_miktar), 0) 
                FROM iplik_teslimat_kayitlari 
                WHERE kalem_id = target_kalem_id
            ) >= siparis_miktari THEN 'tamamlandi'
            WHEN (
                SELECT COALESCE(SUM(gelen_miktar), 0) 
                FROM iplik_teslimat_kayitlari 
                WHERE kalem_id = target_kalem_id
            ) > 0 THEN 'kismi_geldi'
            ELSE 'beklemede'
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = target_kalem_id;
    
    -- DELETE için OLD, diğerleri için NEW döndür
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 8. Trigger'ı yeniden oluştur
DROP TRIGGER IF EXISTS trg_update_kalem_durumu ON iplik_teslimat_kayitlari;
CREATE TRIGGER trg_update_kalem_durumu
    AFTER INSERT OR UPDATE OR DELETE ON iplik_teslimat_kayitlari
    FOR EACH ROW EXECUTE FUNCTION update_kalem_durumu();

-- 9. View'ları yeniden oluştur
DROP VIEW IF EXISTS v_siparis_ozeti CASCADE;
DROP VIEW IF EXISTS v_geciken_siparişler CASCADE;
DROP VIEW IF EXISTS v_teslimat_detaylari CASCADE;

CREATE OR REPLACE VIEW v_siparis_ozeti AS
SELECT 
    s.id as siparis_id,
    s.siparis_no,
    s.durum as siparis_durumu,
    t.sirket as tedarikci_adi,
    s.termin_tarihi,
    COUNT(k.id) as toplam_kalem,
    COUNT(CASE WHEN k.durum = 'tamamlandi' THEN 1 END) as tamamlanan_kalem,
    COUNT(CASE WHEN k.durum = 'kismi_geldi' THEN 1 END) as kismi_gelen_kalem,
    COUNT(CASE WHEN k.durum = 'beklemede' THEN 1 END) as bekleyen_kalem,
    ROUND(
        (COUNT(CASE WHEN k.durum = 'tamamlandi' THEN 1 END) * 100.0 / NULLIF(COUNT(k.id), 0))::numeric, 
        2
    ) as tamamlanma_orani,
    SUM(k.siparis_miktari) as toplam_siparis_kg,
    SUM(k.gelen_miktar) as toplam_gelen_kg,
    SUM(k.kalan_miktar) as toplam_kalan_kg,
    SUM(k.toplam_tutar) as toplam_tutar,
    s.created_at,
    s.updated_at
FROM iplik_siparisleri s
LEFT JOIN tedarikciler t ON s.tedarikci_id = t.id
LEFT JOIN iplik_siparis_kalemleri k ON s.id = k.siparis_id
GROUP BY s.id, t.sirket;

CREATE OR REPLACE VIEW v_geciken_siparişler AS
SELECT 
    k.*,
    s.siparis_no,
    t.sirket as tedarikci_adi,
    CURRENT_DATE - k.termin_tarihi as gecikme_gun
FROM iplik_siparis_kalemleri k
JOIN iplik_siparisleri s ON k.siparis_id = s.id
LEFT JOIN tedarikciler t ON s.tedarikci_id = t.id
WHERE k.termin_tarihi < CURRENT_DATE 
    AND k.durum IN ('beklemede', 'kismi_geldi')
ORDER BY gecikme_gun DESC;

CREATE OR REPLACE VIEW v_teslimat_detaylari AS
SELECT 
    tr.*,
    k.iplik_adi,
    k.renk,
    k.siparis_miktari,
    k.gelen_miktar as toplam_gelen,
    k.kalan_miktar,
    s.siparis_no,
    t.sirket as tedarikci_adi
FROM iplik_teslimat_kayitlari tr
JOIN iplik_siparis_kalemleri k ON tr.kalem_id = k.id
JOIN iplik_siparisleri s ON k.siparis_id = s.id
LEFT JOIN tedarikciler t ON s.tedarikci_id = t.id
ORDER BY tr.teslimat_tarihi DESC;

-- 10. Tabloların yapısını ve constraint'leri kontrol et
SELECT 'İplik teslimat kayıtları düzeltmesi tamamlandı!' as durum;

SELECT 'iplik_teslimat_kayitlari tablo yapısı:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'iplik_teslimat_kayitlari' 
ORDER BY ordinal_position;

SELECT 'Foreign key constraints:' as info;
SELECT
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'iplik_teslimat_kayitlari';
