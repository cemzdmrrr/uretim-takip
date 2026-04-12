-- ÇOKLU BEDEN-ADET SİSTEMİ İÇİN VERİTABANI ŞEMASI
-- Her beden için ayrı adet takibi

-- 1. AKSESUARLAR TABLOSU (Ana aksesuar bilgileri)
CREATE TABLE IF NOT EXISTS aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL, -- Ana SKU (BTN001, FRM075)
    ad TEXT NOT NULL, -- Aksesuar adı
    kategori TEXT NOT NULL DEFAULT 'genel', -- düğme, fermuar, etiket, kemer, şapka
    
    -- RENK VE DESEN BİLGİLERİ
    renk TEXT, -- 1024, kırmızı, mavi, desenli
    renk_kodu TEXT, -- hex kodu veya pantone kodu
    desen TEXT, -- çizgili, puantiyeli, düz
    
    -- TEMEL BİLGİLER
    birim TEXT NOT NULL DEFAULT 'adet', -- adet, metre, kg, gr
    birim_fiyat DECIMAL(10,2) DEFAULT 0.00,
    minimum_stok INTEGER DEFAULT 10, -- Genel minimum stok
    
    -- AÇIKLAMA VE ÖZELLIKLER
    aciklama TEXT, -- Detaylı açıklama
    malzeme TEXT, -- plastik, metal, kumaş, deri
    marka TEXT, -- YKK, Coats, vb.
    tedarikci_kodu TEXT, -- Tedarikçideki ürün kodu
    
    -- SİSTEM BİLGİLERİ
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. AKSESUAR_BEDENLER TABLOSU (Her beden için ayrı kayıt)
CREATE TABLE IF NOT EXISTS aksesuar_bedenler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    
    -- BEDEN VE ÖLÇÜ BİLGİLERİ
    beden_tipi TEXT NOT NULL, -- 'beden', 'olcu'
    beden_adi TEXT NOT NULL, -- 'S', 'M', 'L', '75cm', '18mm'
    beden_degeri DECIMAL, -- Sayısal değer (75, 18, vb.)
    beden_birimi TEXT, -- 'cm', 'mm', 'gr'
    
    -- STOK BİLGİLERİ
    stok_miktari INTEGER NOT NULL DEFAULT 0,
    minimum_stok INTEGER DEFAULT 10,
    maksimum_stok INTEGER,
    
    -- ÖZEL BİLGİLER
    ozel_sku TEXT, -- BTN001-S, FRM075-L gibi
    notlar TEXT,
    
    -- SİSTEM BİLGİLERİ
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Her aksesuar için beden adı benzersiz olmalı
    UNIQUE(aksesuar_id, beden_adi)
);

-- 3. AKSESUAR_STOK_HAREKETLERI TABLOSU (Beden bazında stok takibi)
CREATE TABLE IF NOT EXISTS aksesuar_stok_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_beden_id UUID NOT NULL REFERENCES aksesuar_bedenler(id) ON DELETE CASCADE,
    
    -- HAREKET BİLGİLERİ
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'duzeltme', 'fire', 'sayim')),
    miktar INTEGER NOT NULL, -- +/- değer olabilir
    onceki_stok INTEGER NOT NULL,
    yeni_stok INTEGER NOT NULL,
    
    -- REFERANS BİLGİLERİ
    model_id INTEGER REFERENCES modeller(id), -- Hangi model için kullanıldı
    siparis_no TEXT, -- Sipariş numarası
    fatura_no TEXT, -- Fatura numarası
    
    -- AÇIKLAMA
    aciklama TEXT,
    
    -- KULLANICI BİLGİSİ
    kullanici_id UUID, -- Kim yaptı bu hareketi
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. MODEL-AKSESUAR İLİŞKİSİ TABLOSU (Güncellendi)
CREATE TABLE IF NOT EXISTS model_aksesuar_bedenler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    aksesuar_beden_id UUID NOT NULL REFERENCES aksesuar_bedenler(id) ON DELETE CASCADE,
    
    -- KULLANIM BİLGİLERİ
    kullanim_miktari DECIMAL NOT NULL DEFAULT 1, -- Model başına kaç adet/metre
    zorunlu BOOLEAN DEFAULT true, -- Bu aksesuar modelde zorunlu mu?
    alternatif_grup TEXT, -- Alternatif aksesuarlar için grup kodu
    
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
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_marka ON aksesuarlar(marka);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_aksesuar_id ON aksesuar_bedenler(aksesuar_id);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_beden_adi ON aksesuar_bedenler(beden_adi);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_stok ON aksesuar_bedenler(stok_miktari);

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
INSERT INTO aksesuarlar (sku, ad, kategori, renk, renk_kodu, birim, birim_fiyat, malzeme, marka, aciklama) 
VALUES 
('BTN001', 'Metal Düğme', 'düğme', 'gümüş', '#C0C0C0', 'adet', 1.25, 'metal', 'Coats', 'Ceket için metal düğme'),
('FRM075', 'Deri Kemer', 'kemer', 'kahverengi', '#8B4513', 'adet', 45.00, 'deri', 'Zara', 'Deri kemer çeşitleri'),
('PG910', 'Plastik Düğme', 'düğme', '1024', '#FF6B6B', 'adet', 0.75, 'plastik', 'Güneş', 'Gömlek düğmesi')
ON CONFLICT (sku) DO NOTHING;

-- Bedenler ve stoklar
INSERT INTO aksesuar_bedenler (aksesuar_id, beden_tipi, beden_adi, beden_degeri, beden_birimi, stok_miktari, ozel_sku)
SELECT 
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'beden', 'S', NULL, NULL, 500, 'BTN001-S'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden_adi) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden_tipi, beden_adi, beden_degeri, beden_birimi, stok_miktari, ozel_sku)
SELECT 
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'beden', 'M', NULL, NULL, 750, 'BTN001-M'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden_adi) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden_tipi, beden_adi, beden_degeri, beden_birimi, stok_miktari, ozel_sku)
SELECT 
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'beden', 'L', NULL, NULL, 300, 'BTN001-L'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden_adi) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden_tipi, beden_adi, beden_degeri, beden_birimi, stok_miktari, ozel_sku)
SELECT 
    (SELECT id FROM aksesuarlar WHERE sku = 'FRM075'),
    'olcu', '75cm', 75, 'cm', 50, 'FRM075-75'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'FRM075')
ON CONFLICT (aksesuar_id, beden_adi) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden_tipi, beden_adi, beden_degeri, beden_birimi, stok_miktari, ozel_sku)
SELECT 
    (SELECT id FROM aksesuarlar WHERE sku = 'FRM075'),
    'olcu', '85cm', 85, 'cm', 75, 'FRM075-85'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'FRM075')
ON CONFLICT (aksesuar_id, beden_adi) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden_tipi, beden_adi, beden_degeri, beden_birimi, stok_miktari, ozel_sku)
SELECT 
    (SELECT id FROM aksesuarlar WHERE sku = 'PG910'),
    'olcu', '18mm', 18, 'mm', 2000, 'PG910-18'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'PG910')
ON CONFLICT (aksesuar_id, beden_adi) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden_tipi, beden_adi, beden_degeri, beden_birimi, stok_miktari, ozel_sku)
SELECT 
    (SELECT id FROM aksesuarlar WHERE sku = 'PG910'),
    'olcu', '20mm', 20, 'mm', 1500, 'PG910-20'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'PG910')
ON CONFLICT (aksesuar_id, beden_adi) DO NOTHING;

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
    ab.beden_tipi,
    ab.beden_adi,
    ab.beden_degeri,
    ab.beden_birimi,
    ab.stok_miktari,
    ab.minimum_stok,
    ab.ozel_sku,
    CASE 
        WHEN ab.stok_miktari <= ab.minimum_stok THEN 'KRITIK'
        WHEN ab.stok_miktari <= (ab.minimum_stok * 2) THEN 'DÜŞÜK'
        ELSE 'NORMAL'
    END as stok_durumu,
    a.birim_fiyat,
    a.created_at
FROM aksesuarlar a
LEFT JOIN aksesuar_bedenler ab ON a.id = ab.aksesuar_id
WHERE a.aktif = true AND (ab.aktif = true OR ab.aktif IS NULL)
ORDER BY a.sku, ab.beden_adi;
