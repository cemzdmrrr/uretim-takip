-- ÇOKLU BEDEN-ADET SİSTEMİ İÇİN VERİTABANI ŞEMASI (Supabase Uyumlu)
-- Mevcut tabloları güncelleme yaklaşımı

-- 1. AKSESUARLAR TABLOSU (Mevcut tabloyu güncelle veya oluştur)
CREATE TABLE IF NOT EXISTS aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL,
    ad TEXT NOT NULL,
    renk TEXT,
    renk_kodu TEXT,
    birim TEXT NOT NULL DEFAULT 'adet',
    birim_fiyat DECIMAL(10,2) DEFAULT 0.00,
    minimum_stok INTEGER DEFAULT 10,
    aciklama TEXT,
    malzeme TEXT,
    marka TEXT,
    durum TEXT DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Eksik sütunları ekle (hata vermez, zaten varsa)
DO $$ 
BEGIN
    -- durum sütunu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'durum') THEN
        ALTER TABLE aksesuarlar ADD COLUMN durum TEXT DEFAULT 'aktif';
        ALTER TABLE aksesuarlar ADD CONSTRAINT aksesuarlar_durum_check 
            CHECK (durum IN ('aktif', 'pasif'));
    END IF;
    
    -- updated_at sütunu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'updated_at') THEN
        ALTER TABLE aksesuarlar ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- marka sütunu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'marka') THEN
        ALTER TABLE aksesuarlar ADD COLUMN marka TEXT;
    END IF;
    
    -- aciklama sütunu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'aciklama') THEN
        ALTER TABLE aksesuarlar ADD COLUMN aciklama TEXT;
    END IF;
END $$;

-- 2. AKSESUAR_BEDENLER TABLOSU (Yeni tablo)
CREATE TABLE IF NOT EXISTS aksesuar_bedenler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    beden TEXT NOT NULL,
    stok_miktari INTEGER NOT NULL DEFAULT 0,
    durum TEXT DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(aksesuar_id, beden)
);

-- 3. AKSESUAR_STOK_HAREKETLERI TABLOSU
CREATE TABLE IF NOT EXISTS aksesuar_stok_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_beden_id UUID NOT NULL REFERENCES aksesuar_bedenler(id) ON DELETE CASCADE,
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'duzeltme', 'fire', 'sayim')),
    miktar INTEGER NOT NULL,
    onceki_stok INTEGER NOT NULL,
    yeni_stok INTEGER NOT NULL,
    model_id INTEGER,
    siparis_no TEXT,
    fatura_no TEXT,
    aciklama TEXT,
    kullanici_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. MODEL-AKSESUAR İLİŞKİSİ TABLOSU
CREATE TABLE IF NOT EXISTS model_aksesuar_bedenler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id INTEGER NOT NULL,
    aksesuar_beden_id UUID NOT NULL REFERENCES aksesuar_bedenler(id) ON DELETE CASCADE,
    kullanim_miktari DECIMAL NOT NULL DEFAULT 1,
    zorunlu BOOLEAN DEFAULT true,
    kullanim_yeri TEXT,
    sira_no INTEGER,
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id, aksesuar_beden_id)
);

-- 5. İNDEXLER (IF NOT EXISTS ile güvenli oluşturma)
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_marka ON aksesuarlar(marka);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_durum ON aksesuarlar(durum);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_aksesuar_id ON aksesuar_bedenler(aksesuar_id);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_beden ON aksesuar_bedenler(beden);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_stok ON aksesuar_bedenler(stok_miktari);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_durum ON aksesuar_bedenler(durum);

-- 6. TRİGGER FONKSİYONU VE TRİGGERLAR
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'ları güvenli şekilde oluştur
DO $$
BEGIN
    -- aksesuarlar tablosu için trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_aksesuarlar_updated_at') THEN
        CREATE TRIGGER update_aksesuarlar_updated_at
            BEFORE UPDATE ON aksesuarlar
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- aksesuar_bedenler tablosu için trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_aksesuar_bedenler_updated_at') THEN
        CREATE TRIGGER update_aksesuar_bedenler_updated_at
            BEFORE UPDATE ON aksesuar_bedenler
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- 7. MEVCUT VERİLERİ GÜNCELLEMEKSİZİN ÖRNEK VERİLER EKLE
-- Ana aksesuarlar (sadece yoksa ekle)
INSERT INTO aksesuarlar (sku, ad, renk, renk_kodu, birim, birim_fiyat, malzeme, marka, aciklama, durum)
VALUES
('BTN001', 'Metal Düğme', 'gümüş', '#C0C0C0', 'adet', 1.25, 'metal', 'Coats', 'Ceket için metal düğme', 'aktif'),
('FRM075', 'Deri Kemer', 'kahverengi', '#8B4513', 'adet', 45.00, 'deri', 'Zara', 'Deri kemer çeşitleri', 'aktif'),
('PG910', 'Plastik Düğme', 'kırmızı', '#FF6B6B', 'adet', 0.75, 'plastik', 'Güneş', 'Gömlek düğmesi', 'aktif')
ON CONFLICT (sku) DO NOTHING;

-- Bedenler ve stoklar (sadece yoksa ekle)
INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari, durum)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'S', 500, 'aktif'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari, durum)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'M', 750, 'aktif'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari, durum)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'BTN001'),
    'L', 300, 'aktif'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'BTN001')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari, durum)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'FRM075'),
    '75cm', 50, 'aktif'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'FRM075')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari, durum)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'FRM075'),
    '85cm', 75, 'aktif'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'FRM075')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari, durum)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'PG910'),
    '18mm', 2000, 'aktif'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'PG910')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

INSERT INTO aksesuar_bedenler (aksesuar_id, beden, stok_miktari, durum)
SELECT
    (SELECT id FROM aksesuarlar WHERE sku = 'PG910'),
    '20mm', 1500, 'aktif'
WHERE EXISTS (SELECT 1 FROM aksesuarlar WHERE sku = 'PG910')
ON CONFLICT (aksesuar_id, beden) DO NOTHING;

-- 8. YARDIMCI VIEW'LAR (OR REPLACE ile güvenli güncelleme)
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

-- 9. BAŞARI MESAJI
DO $$
BEGIN
    RAISE NOTICE 'Çoklu beden aksesuar sistemi başarıyla kuruldu!';
    RAISE NOTICE 'Yeni tablolar: aksesuar_bedenler, aksesuar_stok_hareketleri, model_aksesuar_bedenler';
    RAISE NOTICE 'Güncellenen tablo: aksesuarlar (yeni kolonlar eklendi)';
END $$;
