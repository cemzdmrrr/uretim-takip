-- ÇOKLU BEDEN-ADET SİSTEMİ İÇİN VERİTABANI ŞEMASI (Flutter Uyumlu)
-- Her beden için ayrı adet takibi

-- 1. AKSESUARLAR TABLOSU (Ana aksesuar bilgileri)
DROP TABLE IF EXISTS model_aksesuar_bedenler CASCADE;
DROP TABLE IF EXISTS aksesuar_stok_hareketleri CASCADE;
DROP TABLE IF EXISTS aksesuar_bedenler CASCADE;
DROP TABLE IF EXISTS aksesuarlar CASCADE;

CREATE TABLE aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL, -- Ana SKU (BTN001, FRM075)
    ad TEXT NOT NULL, -- Aksesuar adı
    
    -- RENK VE DESEN BİLGİLERİ
    renk TEXT, -- kırmızı, mavi, desenli
    renk_kodu TEXT, -- hex kodu veya pantone kodu
    
    -- TEMEL BİLGİLER
    birim TEXT NOT NULL DEFAULT 'adet', -- adet, metre, kg, gr
    birim_fiyat DECIMAL(10,2) DEFAULT 0.00,
    minimum_stok INTEGER DEFAULT 10, -- Genel minimum stok
    
    -- AÇIKLAMA VE ÖZELLİKLER
    aciklama TEXT, -- Detaylı açıklama
    malzeme TEXT, -- plastik, metal, kumaş, deri
    marka TEXT, -- YKK, Coats, vb.
    
    -- SİSTEM BİLGİLERİ
    durum TEXT DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. AKSESUAR_BEDENLER TABLOSU (Her beden için ayrı kayıt)
CREATE TABLE aksesuar_bedenler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    
    -- BEDEN BİLGİLERİ
    beden TEXT NOT NULL, -- 'S', 'M', 'L', '75cm', '18mm'
    
    -- STOK BİLGİLERİ
    stok_miktari INTEGER NOT NULL DEFAULT 0,
    
    -- SİSTEM BİLGİLERİ
    durum TEXT DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Her aksesuar için beden adı benzersiz olmalı
    UNIQUE(aksesuar_id, beden)
);

-- 3. AKSESUAR_STOK_HAREKETLERI TABLOSU (Beden bazında stok takibi)
CREATE TABLE aksesuar_stok_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_beden_id UUID NOT NULL REFERENCES aksesuar_bedenler(id) ON DELETE CASCADE,
    
    -- HAREKET BİLGİLERİ
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'duzeltme', 'fire', 'sayim')),
    miktar INTEGER NOT NULL, -- +/- değer olabilir
    onceki_stok INTEGER NOT NULL,
    yeni_stok INTEGER NOT NULL,
    
    -- REFERANS BİLGİLERİ
    model_id INTEGER, -- Hangi model için kullanıldı
    siparis_no TEXT, -- Sipariş numarası
    fatura_no TEXT, -- Fatura numarası
    
    -- AÇIKLAMA
    aciklama TEXT,
    
    -- KULLANICI BİLGİSİ
    kullanici_id UUID, -- Kim yaptı bu hareketi
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. MODEL-AKSESUAR İLİŞKİSİ TABLOSU (Güncellenecek)
CREATE TABLE model_aksesuar_bedenler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id INTEGER NOT NULL,
    aksesuar_beden_id UUID NOT NULL REFERENCES aksesuar_bedenler(id) ON DELETE CASCADE,
    
    -- KULLANIM BİLGİLERİ
    kullanim_miktari DECIMAL NOT NULL DEFAULT 1, -- Model başına kaç adet/metre
    zorunlu BOOLEAN DEFAULT true, -- Bu aksesuar modelde zorunlu mu?
    
    -- KONUM BİLGİSİ
    kullanim_yeri TEXT, -- yaka, kol, bel, düğme, vb.
    sira_no INTEGER, -- Aksesuarın modeldeki sırası
    
    -- NOTLAR
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Her model-aksesuar-beden kombinasyonu benzersiz olmalı
    UNIQUE(model_id, aksesuar_beden_id)
);

-- 5. İNDEXLER
CREATE INDEX idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX idx_aksesuarlar_marka ON aksesuarlar(marka);
CREATE INDEX idx_aksesuarlar_durum ON aksesuarlar(durum);
CREATE INDEX idx_aksesuar_bedenler_aksesuar_id ON aksesuar_bedenler(aksesuar_id);
CREATE INDEX idx_aksesuar_bedenler_beden ON aksesuar_bedenler(beden);
CREATE INDEX idx_aksesuar_bedenler_stok ON aksesuar_bedenler(stok_miktari);
CREATE INDEX idx_aksesuar_bedenler_durum ON aksesuar_bedenler(durum);

-- 6. TRİGGERLAR
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_aksesuarlar_updated_at
    BEFORE UPDATE ON aksesuarlar
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_aksesuar_bedenler_updated_at
    BEFORE UPDATE ON aksesuar_bedenler
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. ÖRNEK VERİLER
-- Ana aksesuarlar
INSERT INTO aksesuarlar (sku, ad, renk, renk_kodu, birim, birim_fiyat, malzeme, marka, aciklama)
VALUES
('BTN001', 'Metal Düğme', 'gümüş', '#C0C0C0', 'adet', 1.25, 'metal', 'Coats', 'Ceket için metal düğme'),
('FRM075', 'Deri Kemer', 'kahverengi', '#8B4513', 'adet', 45.00, 'deri', 'Zara', 'Deri kemer çeşitleri'),
('PG910', 'Plastik Düğme', 'kırmızı', '#FF6B6B', 'adet', 0.75, 'plastik', 'Güneş', 'Gömlek düğmesi')
ON CONFLICT (sku) DO NOTHING;

-- Bedenler ve stoklar
INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'S', 500
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'M', 750
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'L', 300
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'FRM075'),
    '75cm', 50
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'FRM075')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'FRM075'),
    '85cm', 75
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'FRM075')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'PG910'),
    '18mm', 2000
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'PG910')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'PG910'),
    '20mm', 1500
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'PG910')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

-- 8. YARDIMCI VIEW'LAR
-- Aksesuar özet görünümü (beden-stok detaylarıyla)
CREATE OR REPLACE VIEW aksesuar_beden_ozet AS
SELECT
    a.id as aksesuar_id,
    a.sku,
    a.ad as aksesuar_adi,
    a.marka,
    a.renk,
    a.malzeme,
    ab.id as beden_id,
    ab.beden,
    ab.stok_miktari,
    CASE
        WHEN ab.stok_miktari <= 10 THEN 'KRITIK'
        WHEN ab.stok_miktari <= 50 THEN 'DÜŞÜK'
        ELSE 'NORMAL'
    END as stok_durumu,
    a.birim_fiyat,
    a.created_at
FROM aksesuarlar a
LEFT JOIN aksesuar_bedenler ab ON a.id = ab.aksesuar_id
WHERE a.durum = 'aktif' AND (ab.durum = 'aktif' OR ab.durum IS NULL)
ORDER BY a.sku, ab.beden;

-- Toplam stok özeti
CREATE OR REPLACE VIEW aksesuar_toplam_stok AS
SELECT
    a.id,
    a.sku,
    a.ad,
    a.marka,
    COALESCE(SUM(ab.stok_miktari), 0) as toplam_stok,
    COUNT(ab.id) as beden_sayisi,
    a.minimum_stok,
    CASE
        WHEN COALESCE(SUM(ab.stok_miktari), 0) <= a.minimum_stok THEN 'KRITIK'
        WHEN COALESCE(SUM(ab.stok_miktari), 0) <= (a.minimum_stok * 2) THEN 'DÜŞÜK'
        ELSE 'NORMAL'
    END as genel_stok_durumu
FROM aksesuarlar a
LEFT JOIN aksesuar_bedenler ab ON a.id = ab.aksesuar_id AND ab.durum = 'aktif'
WHERE a.durum = 'aktif'
GROUP BY a.id, a.sku, a.ad, a.marka, a.minimum_stok
ORDER BY a.sku;
