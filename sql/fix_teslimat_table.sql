-- Önce ilgili view'ları düşür
DROP VIEW IF EXISTS v_teslimat_detaylari CASCADE;
DROP VIEW IF EXISTS v_siparis_ozeti CASCADE;
DROP VIEW IF EXISTS v_geciken_siparişler CASCADE;

-- Teslimat tablosunu güncelle (eğer siparis_id varsa kaldır)
DO $$ 
BEGIN
    -- siparis_id sütunu varsa kaldır
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'iplik_teslimat_kayitlari' 
        AND column_name = 'siparis_id'
    ) THEN
        ALTER TABLE iplik_teslimat_kayitlari DROP COLUMN siparis_id;
    END IF;

    -- kalem_id sütunu yoksa ekle
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'iplik_teslimat_kayitlari' 
        AND column_name = 'kalem_id'
    ) THEN
        ALTER TABLE iplik_teslimat_kayitlari ADD COLUMN kalem_id UUID NOT NULL;
        ALTER TABLE iplik_teslimat_kayitlari 
        ADD CONSTRAINT fk_teslimat_kalem 
        FOREIGN KEY (kalem_id) 
        REFERENCES iplik_siparis_kalemleri(id);
    END IF;
END $$;

-- View'ları yeniden oluştur
CREATE OR REPLACE VIEW v_teslimat_detaylari AS
SELECT 
    t.*,
    k.iplik_adi,
    k.renk,
    k.siparis_miktari,
    s.siparis_no,
    s.tedarikci_id
FROM iplik_teslimat_kayitlari t
JOIN iplik_siparis_kalemleri k ON t.kalem_id = k.id
JOIN iplik_siparisleri s ON k.siparis_id = s.id;

CREATE OR REPLACE VIEW v_siparis_ozeti AS
SELECT 
    s.id as siparis_id,
    s.siparis_no,
    s.tedarikci_id,
    t.sirket as tedarikci_adi,
    s.termin_tarihi,
    COUNT(DISTINCT k.id) as toplam_kalem,
    COUNT(DISTINCT CASE WHEN k.durum = 'tamamlandi' THEN k.id END) as tamamlanan_kalem,
    SUM(k.siparis_miktari) as toplam_siparis_kg,
    SUM(k.gelen_miktar) as toplam_gelen_kg,
    CASE 
        WHEN SUM(k.siparis_miktari) > 0 
        THEN (SUM(k.gelen_miktar) / SUM(k.siparis_miktari) * 100)
        ELSE 0 
    END as tamamlanma_orani,
    s.created_at
FROM iplik_siparisleri s
JOIN tedarikciler t ON s.tedarikci_id = t.id
LEFT JOIN iplik_siparis_kalemleri k ON s.id = k.siparis_id
GROUP BY s.id, s.siparis_no, s.tedarikci_id, t.sirket, s.termin_tarihi, s.created_at;

CREATE OR REPLACE VIEW v_geciken_siparişler AS
SELECT 
    k.id,
    k.siparis_id,
    k.iplik_adi,
    k.renk,
    k.siparis_miktari,
    k.gelen_miktar,
    k.kalan_miktar,
    k.durum,
    s.siparis_no,
    s.termin_tarihi,
    t.sirket as tedarikci_adi,
    (CURRENT_DATE - s.termin_tarihi) as gecikme_gun
FROM iplik_siparis_kalemleri k
JOIN iplik_siparisleri s ON k.siparis_id = s.id
JOIN tedarikciler t ON s.tedarikci_id = t.id
WHERE k.durum != 'tamamlandi'
AND s.termin_tarihi < CURRENT_DATE;

-- Trigger fonksiyonunu güncelle
CREATE OR REPLACE FUNCTION update_kalem_durumu()
RETURNS TRIGGER AS $$
BEGIN
    -- Kalem için toplam gelen miktarı hesapla
    WITH toplam_gelen AS (
        SELECT 
            kalem_id,
            SUM(gelen_miktar) as toplam_miktar
        FROM iplik_teslimat_kayitlari
        WHERE kalem_id = COALESCE(NEW.kalem_id, OLD.kalem_id)
        GROUP BY kalem_id
    )
    UPDATE iplik_siparis_kalemleri k
    SET 
        gelen_miktar = COALESCE(t.toplam_miktar, 0),
        kalan_miktar = k.siparis_miktari - COALESCE(t.toplam_miktar, 0),
        durum = CASE 
            WHEN k.siparis_miktari <= COALESCE(t.toplam_miktar, 0) THEN 'tamamlandi'
            WHEN COALESCE(t.toplam_miktar, 0) > 0 THEN 'kismi_geldi'
            ELSE 'beklemede'
        END
    FROM toplam_gelen t
    WHERE k.id = COALESCE(NEW.kalem_id, OLD.kalem_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı yeniden oluştur
DROP TRIGGER IF EXISTS teslimat_after_change ON iplik_teslimat_kayitlari;
CREATE TRIGGER teslimat_after_change
AFTER INSERT OR UPDATE OR DELETE ON iplik_teslimat_kayitlari
FOR EACH ROW EXECUTE FUNCTION update_kalem_durumu();
