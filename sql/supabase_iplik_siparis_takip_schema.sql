-- İplik Sipariş Takip Sistemi - Gelişmiş Schema

-- Sipariş Kalemleri Tablosu (Her renk/tür ayrı kalem)
CREATE TABLE IF NOT EXISTS iplik_siparis_kalemleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    siparis_id UUID REFERENCES iplik_siparisleri(id) ON DELETE CASCADE,
    kalem_no INTEGER NOT NULL,
    
    -- İplik bilgileri
    iplik_adi VARCHAR NOT NULL,
    renk VARCHAR,
    iplik_turu VARCHAR, -- 30/1, 20/1 gibi
    ozellikler JSONB, -- kompozisyon, özel özellikler
    
    -- Miktar bilgileri
    siparis_miktari DECIMAL(10,2) NOT NULL,
    gelen_miktar DECIMAL(10,2) DEFAULT 0,
    kalan_miktar DECIMAL(10,2) GENERATED ALWAYS AS (siparis_miktari - gelen_miktar) STORED,
    birim VARCHAR DEFAULT 'kg',
    
    -- Fiyat bilgileri
    birim_fiyat DECIMAL(10,2),
    para_birimi VARCHAR DEFAULT 'TL',
    toplam_tutar DECIMAL(10,2) GENERATED ALWAYS AS (siparis_miktari * COALESCE(birim_fiyat,0)) STORED,
    
    -- Durum takibi
    durum VARCHAR DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'kismi_geldi', 'tamamlandi', 'iptal')),
    oncelik INTEGER DEFAULT 5, -- 1:Çok Yüksek, 5:Normal, 10:Düşük
    
    -- Tarih bilgileri
    termin_tarihi DATE,
    ilk_teslimat_tarihi TIMESTAMP,
    son_teslimat_tarihi TIMESTAMP,
    
    -- Meta
    notlar TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(siparis_id, kalem_no)
);

-- Teslimat Kayıtları Tablosu
CREATE TABLE IF NOT EXISTS iplik_teslimat_kayitlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kalem_id UUID REFERENCES iplik_siparis_kalemleri(id) ON DELETE CASCADE,
    
    -- Teslimat bilgileri
    teslimat_no VARCHAR UNIQUE,
    teslimat_tarihi DATE NOT NULL,
    gelen_miktar DECIMAL(10,2) NOT NULL,
    birim VARCHAR DEFAULT 'kg',
    
    -- Parti/lot bilgileri
    lot_no VARCHAR,
    parti_no VARCHAR,
    uretim_tarihi DATE,
    son_kullanma_tarihi DATE,
    
    -- Kalite kontrol
    kalite_durumu VARCHAR DEFAULT 'beklemede' CHECK (kalite_durumu IN ('beklemede', 'onaylandi', 'reddedildi', 'sartli_kabul')),
    kalite_notu TEXT,
    kalite_kontrol_tarihi TIMESTAMP,
    kalite_kontrol_personeli VARCHAR,
    
    -- Depo bilgileri
    depo_yeri VARCHAR,
    raf_no VARCHAR,
    
    -- Fatura bilgileri
    fatura_no VARCHAR,
    fatura_tarihi DATE,
    
    -- Meta
    notlar TEXT,
    eklenen_kisi VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sipariş Durumu Update Trigger
CREATE OR REPLACE FUNCTION update_kalem_durumu()
RETURNS TRIGGER AS $$
BEGIN
    -- Kalem durumunu güncelle
    UPDATE iplik_siparis_kalemleri 
    SET 
        durum = CASE 
            WHEN gelen_miktar >= siparis_miktari THEN 'tamamlandi'
            WHEN gelen_miktar > 0 THEN 'kismi_geldi'
            ELSE 'beklemede'
        END,
        son_teslimat_tarihi = CASE 
            WHEN NEW.teslimat_tarihi IS NOT NULL THEN NEW.teslimat_tarihi::TIMESTAMP
            ELSE son_teslimat_tarihi
        END,
        ilk_teslimat_tarihi = CASE 
            WHEN ilk_teslimat_tarihi IS NULL AND NEW.teslimat_tarihi IS NOT NULL 
            THEN NEW.teslimat_tarihi::TIMESTAMP
            ELSE ilk_teslimat_tarihi
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.kalem_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS trigger_update_kalem_durumu ON iplik_teslimat_kayitlari;
CREATE TRIGGER trigger_update_kalem_durumu
    AFTER INSERT OR UPDATE OF gelen_miktar ON iplik_teslimat_kayitlari
    FOR EACH ROW
    EXECUTE FUNCTION update_kalem_durumu();

-- Gelen miktar toplamını güncelleyen trigger
CREATE OR REPLACE FUNCTION update_gelen_miktar_toplami()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE iplik_siparis_kalemleri 
    SET gelen_miktar = (
        SELECT COALESCE(SUM(gelen_miktar), 0) 
        FROM iplik_teslimat_kayitlari 
        WHERE kalem_id = COALESCE(NEW.kalem_id, OLD.kalem_id)
        AND kalite_durumu IN ('onaylandi', 'sartli_kabul')
    )
    WHERE id = COALESCE(NEW.kalem_id, OLD.kalem_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS trigger_update_gelen_miktar ON iplik_teslimat_kayitlari;
CREATE TRIGGER trigger_update_gelen_miktar
    AFTER INSERT OR UPDATE OR DELETE ON iplik_teslimat_kayitlari
    FOR EACH ROW
    EXECUTE FUNCTION update_gelen_miktar_toplami();

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_siparis_kalemleri_siparis_id ON iplik_siparis_kalemleri(siparis_id);
CREATE INDEX IF NOT EXISTS idx_siparis_kalemleri_durum ON iplik_siparis_kalemleri(durum);
CREATE INDEX IF NOT EXISTS idx_siparis_kalemleri_termin ON iplik_siparis_kalemleri(termin_tarihi);
CREATE INDEX IF NOT EXISTS idx_teslimat_kayitlari_kalem_id ON iplik_teslimat_kayitlari(kalem_id);
CREATE INDEX IF NOT EXISTS idx_teslimat_kayitlari_tarih ON iplik_teslimat_kayitlari(teslimat_tarihi);
CREATE INDEX IF NOT EXISTS idx_teslimat_kayitlari_kalite ON iplik_teslimat_kayitlari(kalite_durumu);

-- Örnek veriler
DO $$
DECLARE
    siparis_id UUID;
    kalem_id1 UUID;
    kalem_id2 UUID;
    kalem_id3 UUID;
    tedarikci_count INTEGER;
BEGIN
    -- Tedarikçi var mı kontrol et
    SELECT COUNT(*) INTO tedarikci_count FROM tedarikciler WHERE durum = 'aktif';
    
    IF tedarikci_count > 0 THEN
        -- Önce ana sipariş oluştur (iplik_adi olmadan - kalemler seviyesinde olacak)
        INSERT INTO iplik_siparisleri (
            siparis_no, tedarikci_id, termin_tarihi, durum, aciklama
        ) VALUES (
            'SIP-2025-001', 
            (SELECT id FROM tedarikciler WHERE durum = 'aktif' LIMIT 1),
            CURRENT_DATE + INTERVAL '30 days',
            'onaylandi',
            'Örnek karışık renk iplik siparişi - Takip sistemi testi'
        ) RETURNING id INTO siparis_id;
        
        -- Sipariş kalemleri ekle
        INSERT INTO iplik_siparis_kalemleri (
            siparis_id, kalem_no, iplik_adi, renk, iplik_turu, siparis_miktari, birim_fiyat, termin_tarihi
        ) VALUES 
        (siparis_id, 1, 'Pamuk İplik', 'Beyaz', '30/1', 100.00, 15.50, CURRENT_DATE + INTERVAL '30 days'),
        (siparis_id, 2, 'Pamuk İplik', 'Siyah', '30/1', 80.00, 15.50, CURRENT_DATE + INTERVAL '30 days'),
        (siparis_id, 3, 'Pamuk İplik', 'Kırmızı', '30/1', 60.00, 15.50, CURRENT_DATE + INTERVAL '30 days')
        RETURNING id;
        
        -- Kalemlerin ID'lerini al
        SELECT id INTO kalem_id1 FROM iplik_siparis_kalemleri WHERE siparis_id = siparis_id AND kalem_no = 1;
        SELECT id INTO kalem_id2 FROM iplik_siparis_kalemleri WHERE siparis_id = siparis_id AND kalem_no = 2;
        SELECT id INTO kalem_id3 FROM iplik_siparis_kalemleri WHERE siparis_id = siparis_id AND kalem_no = 3;
        
        -- Örnek teslimat kayıtları (kısmi teslimat)
        INSERT INTO iplik_teslimat_kayitlari (
            kalem_id, teslimat_no, teslimat_tarihi, gelen_miktar, lot_no, kalite_durumu
        ) VALUES 
        (kalem_id1, 'TES-001', CURRENT_DATE - INTERVAL '5 days', 50.00, 'LOT-2025-001', 'onaylandi'),
        (kalem_id2, 'TES-002', CURRENT_DATE - INTERVAL '3 days', 80.00, 'LOT-2025-002', 'onaylandi');
        
        RAISE NOTICE 'Örnek sipariş ve teslimat verileri başarıyla oluşturuldu.';
    ELSE
        RAISE NOTICE 'Aktif tedarikçi bulunamadı. Önce tedarikçi ekleyin.';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Örnek veri oluşturulurken hata: %', SQLERRM;
END $$;

-- Dashboard için yararlı view'lar
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
        (COUNT(CASE WHEN k.durum = 'tamamlandi' THEN 1 END) * 100.0 / COUNT(k.id))::numeric, 
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

-- Geciken siparişler view
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

-- Teslimat detayları view
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

COMMENT ON TABLE iplik_siparis_kalemleri IS 'Her sipariş kalemi (renk/tür) için ayrı kayıt';
COMMENT ON TABLE iplik_teslimat_kayitlari IS 'Her teslimat için ayrı kayıt - kısmi teslimatlar dahil';
COMMENT ON VIEW v_siparis_ozeti IS 'Sipariş tamamlanma oranları ve özet bilgiler';
COMMENT ON VIEW v_geciken_siparişler IS 'Termin tarihi geçen bekleyen siparişler';
