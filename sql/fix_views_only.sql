-- İplik sipariş takip view'larını yeniden oluştur
-- Bu script sadece view'ları düzeltir

-- 1. Mevcut view'ları sil
DROP VIEW IF EXISTS v_siparis_ozeti CASCADE;
DROP VIEW IF EXISTS v_geciken_siparişler CASCADE;
DROP VIEW IF EXISTS v_teslimat_detaylari CASCADE;

-- 2. View'ları yeniden oluştur
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

-- 3. Tabloların varlığını kontrol et
DO $$
BEGIN
    -- iplik_siparis_kalemleri tablosu kontrol
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'iplik_siparis_kalemleri') THEN
        RAISE NOTICE 'HATA: iplik_siparis_kalemleri tablosu bulunamadı!';
    ELSE
        RAISE NOTICE 'iplik_siparis_kalemleri tablosu mevcut.';
    END IF;
    
    -- iplik_teslimat_kayitlari tablosu kontrol
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'iplik_teslimat_kayitlari') THEN
        RAISE NOTICE 'HATA: iplik_teslimat_kayitlari tablosu bulunamadı!';
    ELSE
        RAISE NOTICE 'iplik_teslimat_kayitlari tablosu mevcut.';
    END IF;
    
    -- iplik_siparisleri tablosu kontrol
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'iplik_siparisleri') THEN
        RAISE NOTICE 'HATA: iplik_siparisleri tablosu bulunamadı!';
    ELSE
        RAISE NOTICE 'iplik_siparisleri tablosu mevcut.';
    END IF;
    
    -- tedarikciler tablosu kontrol
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tedarikciler') THEN
        RAISE NOTICE 'HATA: tedarikciler tablosu bulunamadı!';
    ELSE
        RAISE NOTICE 'tedarikciler tablosu mevcut.';
    END IF;
END $$;

SELECT 'İplik sipariş takip view\'ları başarıyla oluşturuldu!' as durum;
