-- ================================================================================================
-- FATURALAR TABLOSU - BASIT VERSİYON
-- ================================================================================================
-- Bu script basit bir faturalar tablosu oluşturur
-- Türk Ticaret Kanunu ve Vergi Usul Kanunu'na uygun
-- ================================================================================================

-- Mevcut tabloları sil ve yeniden oluştur
DROP TABLE IF EXISTS fatura_kalemleri CASCADE;
DROP TABLE IF EXISTS faturalar CASCADE;

-- Basit faturalar tablosu
CREATE TABLE faturalar (
    fatura_id SERIAL PRIMARY KEY,
    fatura_no VARCHAR(50) UNIQUE NOT NULL,
    fatura_turu VARCHAR(20) DEFAULT 'satis', -- 'satis', 'alis', 'iade', 'proforma'
    fatura_tarihi DATE NOT NULL,
    musteri_id INTEGER REFERENCES musteriler(id),
    tedarikci_id INTEGER REFERENCES tedarikciler(id),
    fatura_adres TEXT NOT NULL,
    vergi_dairesi VARCHAR(100),
    vergi_no VARCHAR(20),
    ara_toplam_tutar DECIMAL(15,2) DEFAULT 0,
    kdv_tutari DECIMAL(15,2) DEFAULT 0,
    toplam_tutar DECIMAL(15,2) DEFAULT 0,
    durum VARCHAR(20) DEFAULT 'taslak', -- 'taslak', 'onaylandi', 'gonderildi', 'iptal'
    aciklama TEXT,
    vade_tarihi DATE,
    odeme_durumu VARCHAR(20) DEFAULT 'odenmedi', -- 'odenmedi', 'kismi', 'odendi'
    odenen_tutar DECIMAL(15,2) DEFAULT 0,
    kur VARCHAR(5) DEFAULT 'TRY',
    kur_orani DECIMAL(10,4) DEFAULT 1.0000,
    efatura_uuid VARCHAR(36),
    efatura_tarihi TIMESTAMP,
    efatura_durum VARCHAR(20),
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    olusturan_kullanici VARCHAR(100)
);

-- Fatura kalemleri tablosu
CREATE TABLE fatura_kalemleri (
    id SERIAL PRIMARY KEY,
    fatura_id INTEGER REFERENCES faturalar(fatura_id) ON DELETE CASCADE,
    model_id INTEGER REFERENCES modeller(id),
    urun_adi VARCHAR(255) NOT NULL,
    urun_kodu VARCHAR(100),
    miktar DECIMAL(10,3) NOT NULL,
    birim VARCHAR(20) DEFAULT 'adet',
    birim_fiyat DECIMAL(15,2) NOT NULL,
    iskonto_orani DECIMAL(5,2) DEFAULT 0,
    iskonto_tutari DECIMAL(15,2) DEFAULT 0,
    kdv_orani DECIMAL(5,2) DEFAULT 20,
    kdv_tutari DECIMAL(15,2) DEFAULT 0,
    toplam_tutar DECIMAL(15,2) NOT NULL,
    aciklama TEXT,
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Otomatik güncelleme için trigger
CREATE OR REPLACE FUNCTION update_fatura_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS faturalar_updated_at_trigger ON faturalar;
CREATE TRIGGER faturalar_updated_at_trigger
    BEFORE UPDATE ON faturalar
    FOR EACH ROW
    EXECUTE FUNCTION update_fatura_updated_at();

-- RLS (Row Level Security) politikaları
ALTER TABLE faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE fatura_kalemleri ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar okuyabilir
CREATE POLICY "Kullanicilar faturalari gorebilir" ON faturalar
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar fatura kalemlerini gorebilir" ON fatura_kalemleri
    FOR SELECT USING (true);

-- Admin ve user rolü ekleyebilir/güncelleyebilir
CREATE POLICY "Admin ve user fatura ekleyebilir" ON faturalar
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin ve user fatura guncelleyebilir" ON faturalar
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin fatura silebilir" ON faturalar
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Fatura kalemleri için politikalar
CREATE POLICY "Admin ve user fatura kalemi ekleyebilir" ON fatura_kalemleri
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin ve user fatura kalemi guncelleyebilir" ON fatura_kalemleri
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin fatura kalemi silebilir" ON fatura_kalemleri
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_faturalar_fatura_no ON faturalar(fatura_no);
CREATE INDEX IF NOT EXISTS idx_faturalar_fatura_tarihi ON faturalar(fatura_tarihi);
CREATE INDEX IF NOT EXISTS idx_faturalar_musteri_id ON faturalar(musteri_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_tedarikci_id ON faturalar(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_durum ON faturalar(durum);
CREATE INDEX IF NOT EXISTS idx_faturalar_odeme_durumu ON faturalar(odeme_durumu);
CREATE INDEX IF NOT EXISTS idx_fatura_kalemleri_fatura_id ON fatura_kalemleri(fatura_id);

-- Örnek test verisi
INSERT INTO faturalar (
    fatura_no, fatura_turu, fatura_tarihi, fatura_adres, 
    ara_toplam_tutar, kdv_tutari, toplam_tutar, durum, aciklama,
    olusturan_kullanici
) VALUES 
(
    'SAT-2025-001', 'satis', '2025-01-15', 'Test Müşteri Adresi\nİstanbul/Türkiye', 
    1000.00, 200.00, 1200.00, 'onaylandi', 'Test satış faturası',
    'sistem'
),
(
    'ALI-2025-001', 'alis', '2025-01-20', 'Test Tedarikçi Adresi\nAnkara/Türkiye', 
    500.00, 100.00, 600.00, 'onaylandi', 'Test alış faturası',
    'sistem'
);

-- Test fatura kalemleri
INSERT INTO fatura_kalemleri (
    fatura_id, urun_adi, urun_kodu, miktar, birim_fiyat, toplam_tutar, aciklama
) VALUES 
(1, 'Test Ürün 1', 'T001', 10.000, 100.00, 1000.00, 'Test kalemi 1'),
(2, 'Test Malzeme 1', 'M001', 5.000, 100.00, 500.00, 'Test kalemi 2');

-- Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'FATURALAR MODÜLÜ KURULDU';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Oluşturulan tablolar:';
    RAISE NOTICE '- faturalar (ana tablo)';
    RAISE NOTICE '- fatura_kalemleri (detay tablo)';
    RAISE NOTICE '';
    RAISE NOTICE 'Toplam fatura sayısı: %', (SELECT COUNT(*) FROM faturalar);
    RAISE NOTICE 'Toplam kalem sayısı: %', (SELECT COUNT(*) FROM fatura_kalemleri);
    RAISE NOTICE '========================================';
END $$;
