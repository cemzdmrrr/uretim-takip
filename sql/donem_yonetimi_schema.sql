-- Donemler tablosunu sıfırla ve yeniden oluştur
DROP TABLE IF EXISTS personel_donem CASCADE;
DROP TABLE IF EXISTS donemler CASCADE;

-- Donemler tablosu
CREATE TABLE donemler (
    id SERIAL PRIMARY KEY,
    yil INTEGER NOT NULL,
    ay INTEGER NOT NULL CHECK (ay >= 1 AND ay <= 12),
    donem_adi VARCHAR(20) NOT NULL UNIQUE,
    durum VARCHAR(20) DEFAULT 'aktif' CHECK (durum IN ('aktif', 'tamamlandi', 'arsivlendi')),
    olusturan_kullanici_id UUID REFERENCES auth.users(id),
    olusturulma_tarihi TIMESTAMP DEFAULT NOW(),
    guncellenme_tarihi TIMESTAMP DEFAULT NOW(),
    
    -- Aynı yıl/ay kombinasyonu tekrar etmesin
    UNIQUE(yil, ay)
);

-- Personel dönem ilişki tablosu
CREATE TABLE personel_donem (
    id SERIAL PRIMARY KEY,
    donem_id INTEGER REFERENCES donemler(id) ON DELETE CASCADE,
    personel_id UUID NOT NULL, -- auth.users(id) referansı
    toplam_mesai_saati DECIMAL(8,2) DEFAULT 0,
    toplam_izin_gunu INTEGER DEFAULT 0,
    toplam_avans DECIMAL(12,2) DEFAULT 0,
    bordro_durumu VARCHAR(20) DEFAULT 'beklemede' CHECK (bordro_durumu IN ('beklemede', 'hazirlandi', 'odendi')),
    olusturulma_tarihi TIMESTAMP DEFAULT NOW(),
    guncellenme_tarihi TIMESTAMP DEFAULT NOW(),
    
    -- Aynı dönem/personel kombinasyonu tekrar etmesin
    UNIQUE(donem_id, personel_id)
);

-- İndeksler
CREATE INDEX idx_donemler_durum ON donemler(durum);
CREATE INDEX idx_donemler_yil_ay ON donemler(yil, ay);
CREATE INDEX idx_personel_donem_donem_id ON personel_donem(donem_id);
CREATE INDEX idx_personel_donem_personel_id ON personel_donem(personel_id);

-- Trigger fonksiyonu - güncelleme tarihini otomatik günceller
CREATE OR REPLACE FUNCTION update_guncellenme_tarihi()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncellenme_tarihi = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggerlar
CREATE TRIGGER trigger_donemler_guncellenme_tarihi
    BEFORE UPDATE ON donemler
    FOR EACH ROW
    EXECUTE FUNCTION update_guncellenme_tarihi();

CREATE TRIGGER trigger_personel_donem_guncellenme_tarihi
    BEFORE UPDATE ON personel_donem
    FOR EACH ROW
    EXECUTE FUNCTION update_guncellenme_tarihi();

-- RLS (Row Level Security) Politikaları
ALTER TABLE donemler ENABLE ROW LEVEL SECURITY;
ALTER TABLE personel_donem ENABLE ROW LEVEL SECURITY;

-- Donemler tablosu politikaları
CREATE POLICY "Herkes donemler tablosunu okuyabilir" ON donemler
    FOR SELECT USING (true);

CREATE POLICY "Sadece admin donemler tablosunu değiştirebilir" ON donemler
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM personel 
            WHERE user_id = auth.uid() 
            AND rol IN ('admin', 'ik')
        )
    );

-- Personel dönem tablosu politikaları
CREATE POLICY "Herkes personel_donem tablosunu okuyabilir" ON personel_donem
    FOR SELECT USING (true);

CREATE POLICY "Sadece admin personel_donem tablosunu değiştirebilir" ON personel_donem
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM personel 
            WHERE user_id = auth.uid() 
            AND rol IN ('admin', 'ik')
        )
    );

-- Örnek veri ekleme
INSERT INTO donemler (yil, ay, donem_adi, durum, olusturulma_tarihi) VALUES
(2024, 12, '2024-12', 'tamamlandi', '2024-12-01 00:00:00'),
(2025, 1, '2025-01', 'tamamlandi', '2025-01-01 00:00:00'),
(2025, 2, '2025-02', 'aktif', '2025-02-01 00:00:00');

COMMENT ON TABLE donemler IS 'Çalışma dönemlerini yönetir (aylık bazda)';
COMMENT ON TABLE personel_donem IS 'Personel ve dönem arasındaki ilişkiyi ve dönemsel verileri tutar';
COMMENT ON COLUMN donemler.durum IS 'aktif: Şu anda aktif dönem, tamamlandi: Kapatılmış dönem, arsivlendi: Arşivlenmiş dönem';
COMMENT ON COLUMN personel_donem.bordro_durumu IS 'beklemede: Bordro henüz hazırlanmadı, hazirlandi: Bordro hazırlandı, odendi: Bordro ödendi';
