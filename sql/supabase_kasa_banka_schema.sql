-- =============================================
-- KASA/BANKA YÖNETİMİ MODÜLÜ - SUPABASE SCHEMA
-- Tarih: 27.06.2025
-- Versiyon: 1.0
-- =============================================

-- 1. KASA/BANKA HESAPLARI TABLOSU
-- =============================================
CREATE TABLE IF NOT EXISTS kasa_banka_hesaplari (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    tip VARCHAR(20) NOT NULL CHECK (tip IN ('KASA', 'BANKA', 'KREDI_KARTI', 'CEK_HESABI')),
    banka_adi VARCHAR(100),
    hesap_no VARCHAR(50),
    iban VARCHAR(34),
    sube_kodu VARCHAR(20),
    sube_adi VARCHAR(100),
    bakiye DECIMAL(15,2) DEFAULT 0.00 NOT NULL,
    doviz_turu VARCHAR(3) DEFAULT 'TRY' NOT NULL,
    durumu VARCHAR(10) DEFAULT 'AKTIF' NOT NULL CHECK (durumu IN ('AKTIF', 'PASIF', 'DONUK')),
    aciklama TEXT,
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- İndeksler
    CONSTRAINT unique_hesap_adi UNIQUE(ad),
    CONSTRAINT unique_hesap_no UNIQUE(hesap_no),
    CONSTRAINT unique_iban UNIQUE(iban)
);

-- İndeksler
CREATE INDEX idx_kasa_banka_tip ON kasa_banka_hesaplari(tip);
CREATE INDEX idx_kasa_banka_durumu ON kasa_banka_hesaplari(durumu);
CREATE INDEX idx_kasa_banka_doviz ON kasa_banka_hesaplari(doviz_turu);

-- 2. KASA/BANKA HAREKETLERİ TABLOSU
-- =============================================
CREATE TABLE IF NOT EXISTS kasa_banka_hareketleri (
    id SERIAL PRIMARY KEY,
    hesap_id INTEGER NOT NULL REFERENCES kasa_banka_hesaplari(id) ON DELETE CASCADE,
    hareket_turu VARCHAR(20) NOT NULL CHECK (hareket_turu IN ('giris', 'cikis', 'transfer')),
    tutar DECIMAL(15,2) NOT NULL,
    aciklama TEXT NOT NULL,
    belge_no VARCHAR(50),
    belge_turu VARCHAR(20), -- 'fatura', 'makbuz', 'dekont', 'other'
    belge_id INTEGER, -- İlgili belgenin ID'si (fatura_id vs.)
    
    -- Transfer işlemleri için
    karsi_hesap_id INTEGER REFERENCES kasa_banka_hesaplari(id),
    
    -- Mali bilgiler  
    musteri_id INTEGER REFERENCES musteriler(id),
    tedarikci_id INTEGER REFERENCES tedarikciler(id),
    
    -- Tarih bilgileri
    hareket_tarihi TIMESTAMP NOT NULL,
    islem_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Durum
    onaylandi BOOLEAN DEFAULT false NOT NULL,
    iptal_edildi BOOLEAN DEFAULT false NOT NULL,
    iptal_tarihi TIMESTAMP,
    iptal_sebebi TEXT,
    
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    olusturan_kullanici VARCHAR(100)
);

-- İndeksler
CREATE INDEX idx_kasa_banka_hareketleri_hesap_id ON kasa_banka_hareketleri(hesap_id);
CREATE INDEX idx_kasa_banka_hareketleri_hareket_turu ON kasa_banka_hareketleri(hareket_turu);
CREATE INDEX idx_kasa_banka_hareketleri_hareket_tarihi ON kasa_banka_hareketleri(hareket_tarihi);
CREATE INDEX idx_kasa_banka_hareketleri_belge ON kasa_banka_hareketleri(belge_turu, belge_id);
CREATE INDEX idx_kasa_banka_hareketleri_musteri ON kasa_banka_hareketleri(musteri_id);
CREATE INDEX idx_kasa_banka_hareketleri_tedarikci ON kasa_banka_hareketleri(tedarikci_id);

-- 3. TRIGGER: Otomatik güncelleme tarihi
-- =============================================
CREATE OR REPLACE FUNCTION update_kasa_banka_guncelleme_tarihi()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_kasa_banka_hesaplari_guncelleme
    BEFORE UPDATE ON kasa_banka_hesaplari
    FOR EACH ROW
    EXECUTE FUNCTION update_kasa_banka_guncelleme_tarihi();

-- 4. TRIGGER: Bakiye otomatik güncelleme
-- =============================================
CREATE OR REPLACE FUNCTION kasa_banka_bakiye_guncelle()
RETURNS TRIGGER AS $$
BEGIN
    -- Hareket iptal edilmişse işlem yapma
    IF NEW.iptal_edildi = true THEN
        RETURN NEW;
    END IF;
    
    -- Eski hareket varsa eski bakiyeyi geri al
    IF TG_OP = 'UPDATE' AND OLD.iptal_edildi = false THEN
        IF OLD.hareket_turu = 'giris' THEN
            UPDATE kasa_banka_hesaplari 
            SET bakiye = bakiye - OLD.tutar 
            WHERE id = OLD.hesap_id;
        ELSIF OLD.hareket_turu = 'cikis' THEN
            UPDATE kasa_banka_hesaplari 
            SET bakiye = bakiye + OLD.tutar 
            WHERE id = OLD.hesap_id;
        ELSIF OLD.hareket_turu = 'transfer' THEN
            -- Çıkış hesabına geri ekle
            UPDATE kasa_banka_hesaplari 
            SET bakiye = bakiye + OLD.tutar 
            WHERE id = OLD.hesap_id;
            -- Giriş hesabından çıkar
            UPDATE kasa_banka_hesaplari 
            SET bakiye = bakiye - OLD.tutar 
            WHERE id = OLD.karsi_hesap_id;
        END IF;
    END IF;
    
    -- Yeni bakiyeyi güncelle
    IF NEW.hareket_turu = 'giris' THEN
        UPDATE kasa_banka_hesaplari 
        SET bakiye = bakiye + NEW.tutar 
        WHERE id = NEW.hesap_id;
    ELSIF NEW.hareket_turu = 'cikis' THEN
        UPDATE kasa_banka_hesaplari 
        SET bakiye = bakiye - NEW.tutar 
        WHERE id = NEW.hesap_id;
    ELSIF NEW.hareket_turu = 'transfer' THEN
        -- Çıkış hesabından düş
        UPDATE kasa_banka_hesaplari 
        SET bakiye = bakiye - NEW.tutar 
        WHERE id = NEW.hesap_id;
        -- Giriş hesabına ekle
        UPDATE kasa_banka_hesaplari 
        SET bakiye = bakiye + NEW.tutar 
        WHERE id = NEW.karsi_hesap_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_kasa_banka_bakiye_guncelle
    AFTER INSERT OR UPDATE ON kasa_banka_hareketleri
    FOR EACH ROW
    EXECUTE FUNCTION kasa_banka_bakiye_guncelle();

-- 5. VIEWS: Raporlama için
-- =============================================

-- Hesap özeti view
CREATE OR REPLACE VIEW v_kasa_banka_ozeti AS
SELECT 
    h.id,
    h.ad as hesap_adi,
    h.tip as hesap_turu,
    h.banka_adi,
    h.bakiye,
    h.doviz_turu as kur,
    CASE WHEN h.durumu = 'AKTIF' THEN true ELSE false END as aktif,
    COUNT(hr.id) as toplam_hareket_sayisi,
    SUM(CASE WHEN hr.hareket_turu = 'giris' AND hr.iptal_edildi = false THEN hr.tutar ELSE 0 END) as toplam_giris,
    SUM(CASE WHEN hr.hareket_turu = 'cikis' AND hr.iptal_edildi = false THEN hr.tutar ELSE 0 END) as toplam_cikis,
    MAX(hr.hareket_tarihi) as son_hareket_tarihi
FROM kasa_banka_hesaplari h
LEFT JOIN kasa_banka_hareketleri hr ON h.id = hr.hesap_id
GROUP BY h.id, h.ad, h.tip, h.banka_adi, h.bakiye, h.doviz_turu, h.durumu;

-- Günlük hareket özeti
CREATE OR REPLACE VIEW v_gunluk_kasa_banka_ozeti AS
SELECT 
    DATE(hr.hareket_tarihi) as tarih,
    h.ad as hesap_adi,
    h.tip as hesap_turu,
    hr.hareket_turu,
    COUNT(*) as hareket_sayisi,
    SUM(hr.tutar) as toplam_tutar
FROM kasa_banka_hareketleri hr
JOIN kasa_banka_hesaplari h ON hr.hesap_id = h.id
WHERE hr.iptal_edildi = false
GROUP BY DATE(hr.hareket_tarihi), h.ad, h.tip, hr.hareket_turu
ORDER BY tarih DESC;

-- 6. RLS (Row Level Security) KURALLARI
-- =============================================

-- RLS'yi etkinleştir
ALTER TABLE kasa_banka_hesaplari ENABLE ROW LEVEL SECURITY;
ALTER TABLE kasa_banka_hareketleri ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar için okuma/yazma izni (şimdilik basit)
CREATE POLICY "Enable all access for all users" ON kasa_banka_hesaplari
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Enable all access for all users" ON kasa_banka_hareketleri
    FOR ALL  
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 7. ÖRNEK VERİLER
-- =============================================

-- Temel kasa hesabı
INSERT INTO kasa_banka_hesaplari (ad, tip, bakiye, doviz_turu, aciklama) 
VALUES ('Ana Kasa', 'KASA', 10000.00, 'TRY', 'Şirket ana kasa hesabı')
ON CONFLICT (ad) DO NOTHING;

-- Temel banka hesabı
INSERT INTO kasa_banka_hesaplari (ad, tip, banka_adi, hesap_no, iban, bakiye, doviz_turu, aciklama)
VALUES ('İş Bankası Vadesiz', 'BANKA', 'Türkiye İş Bankası', '1234567890', 'TR320006400000011234567890', 50000.00, 'TRY', 'Şirket ana banka hesabı')
ON CONFLICT (ad) DO NOTHING;

-- USD hesabı
INSERT INTO kasa_banka_hesaplari (ad, tip, banka_adi, hesap_no, iban, bakiye, doviz_turu, aciklama)
VALUES ('İş Bankası USD', 'BANKA', 'Türkiye İş Bankası', '1234567891', 'TR320006400000011234567891', 1000.00, 'USD', 'USD döviz hesabı')
ON CONFLICT (ad) DO NOTHING;

-- 8. HELPER FUNCTIONS
-- =============================================

-- Hesap bakiyesi kontrol fonksiyonu
CREATE OR REPLACE FUNCTION kasa_banka_bakiye_kontrol(p_hesap_id INTEGER, p_tutar DECIMAL)
RETURNS BOOLEAN AS $$
DECLARE
    mevcut_bakiye DECIMAL;
BEGIN
    SELECT bakiye INTO mevcut_bakiye
    FROM kasa_banka_hesaplari
    WHERE id = p_hesap_id AND durumu = 'AKTIF';
    
    IF mevcut_bakiye IS NULL THEN
        RETURN false;
    END IF;
    
    RETURN mevcut_bakiye >= p_tutar;
END;
$$ LANGUAGE plpgsql;

-- Transfer işlemi fonksiyonu
CREATE OR REPLACE FUNCTION kasa_banka_transfer(
    p_cikis_hesap_id INTEGER,
    p_giris_hesap_id INTEGER,
    p_tutar DECIMAL,
    p_aciklama TEXT,
    p_kullanici VARCHAR(100) DEFAULT 'sistem'
) RETURNS INTEGER AS $$
DECLARE
    hareket_id INTEGER;
BEGIN
    -- Bakiye kontrolü
    IF NOT kasa_banka_bakiye_kontrol(p_cikis_hesap_id, p_tutar) THEN
        RAISE EXCEPTION 'Yetersiz bakiye';
    END IF;
    
    -- Transfer hareketi oluştur
    INSERT INTO kasa_banka_hareketleri (
        hesap_id, karsi_hesap_id, hareket_turu, tutar, aciklama,
        hareket_tarihi, onaylandi, olusturan_kullanici
    ) VALUES (
        p_cikis_hesap_id, p_giris_hesap_id, 'transfer', p_tutar, p_aciklama,
        CURRENT_TIMESTAMP, true, p_kullanici
    ) RETURNING id INTO hareket_id;
    
    RETURN hareket_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- SCHEMA OLUŞTURULDU
-- =============================================

COMMENT ON TABLE kasa_banka_hesaplari IS 'Şirket kasa ve banka hesapları tablosu';
COMMENT ON TABLE kasa_banka_hareketleri IS 'Kasa ve banka hesap hareketleri tablosu';
COMMENT ON VIEW v_kasa_banka_ozeti IS 'Kasa/Banka hesap özet bilgileri';
COMMENT ON VIEW v_gunluk_kasa_banka_ozeti IS 'Günlük kasa/banka hareket özeti';
