-- AKSESUARLAR TABLOSUNU ÇOKLU BEDEN SİSTEMİ İÇİN GÜNCELLE
-- Mevcut tabloyu bozmadan yeni kolonları ekle

-- Önce mevcut tablo yapısını kontrol et
DO $$
BEGIN
    RAISE NOTICE 'Mevcut aksesuarlar tablosu kontrol ediliyor...';
END $$;

-- Eksik kolonları güvenli şekilde ekle
DO $$ 
BEGIN
    -- sku kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'sku') THEN
        ALTER TABLE aksesuarlar ADD COLUMN sku TEXT;
        RAISE NOTICE 'SKU kolonu eklendi';
    END IF;
    
    -- renk kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'renk') THEN
        ALTER TABLE aksesuarlar ADD COLUMN renk TEXT;
        RAISE NOTICE 'Renk kolonu eklendi';
    END IF;
    
    -- renk_kodu kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'renk_kodu') THEN
        ALTER TABLE aksesuarlar ADD COLUMN renk_kodu TEXT;
        RAISE NOTICE 'Renk kodu kolonu eklendi';
    END IF;
    
    -- birim kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'birim') THEN
        ALTER TABLE aksesuarlar ADD COLUMN birim TEXT DEFAULT 'adet';
        RAISE NOTICE 'Birim kolonu eklendi';
    END IF;
    
    -- birim_fiyat kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'birim_fiyat') THEN
        ALTER TABLE aksesuarlar ADD COLUMN birim_fiyat DECIMAL(10,2) DEFAULT 0.00;
        RAISE NOTICE 'Birim fiyat kolonu eklendi';
    END IF;
    
    -- minimum_stok kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'minimum_stok') THEN
        ALTER TABLE aksesuarlar ADD COLUMN minimum_stok INTEGER DEFAULT 10;
        RAISE NOTICE 'Minimum stok kolonu eklendi';
    END IF;
    
    -- malzeme kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'malzeme') THEN
        ALTER TABLE aksesuarlar ADD COLUMN malzeme TEXT;
        RAISE NOTICE 'Malzeme kolonu eklendi';
    END IF;
    
    -- marka kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'marka') THEN
        ALTER TABLE aksesuarlar ADD COLUMN marka TEXT;
        RAISE NOTICE 'Marka kolonu eklendi';
    END IF;
    
    -- aciklama kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'aciklama') THEN
        ALTER TABLE aksesuarlar ADD COLUMN aciklama TEXT;
        RAISE NOTICE 'Açıklama kolonu eklendi';
    END IF;
    
    -- durum kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'durum') THEN
        ALTER TABLE aksesuarlar ADD COLUMN durum TEXT DEFAULT 'aktif';
        RAISE NOTICE 'Durum kolonu eklendi';
    END IF;
    
    -- updated_at kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'aksesuarlar' AND column_name = 'updated_at') THEN
        ALTER TABLE aksesuarlar ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Updated_at kolonu eklendi';
    END IF;
END $$;

-- Mevcut verilere SKU ata (eğer boşsa)
DO $$
DECLARE
    rec RECORD;
    counter INTEGER := 1;
BEGIN
    FOR rec IN SELECT id FROM aksesuarlar WHERE sku IS NULL OR sku = ''
    LOOP
        UPDATE aksesuarlar 
        SET sku = 'AKS' || LPAD(counter::TEXT, 3, '0')
        WHERE id = rec.id;
        counter := counter + 1;
    END LOOP;
    
    IF counter > 1 THEN
        RAISE NOTICE 'Boş SKU kodları güncellendi: % kayıt', counter - 1;
    END IF;
END $$;

-- SKU kolonu için unique constraint ekle (eğer yoksa)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'aksesuarlar' AND constraint_name = 'aksesuarlar_sku_key') THEN
        ALTER TABLE aksesuarlar ADD CONSTRAINT aksesuarlar_sku_key UNIQUE (sku);
        RAISE NOTICE 'SKU unique constraint eklendi';
    END IF;
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'SKU duplicate değerler var, önce temizlenmeli';
    WHEN others THEN
        RAISE NOTICE 'SKU constraint eklenirken hata: %', SQLERRM;
END $$;

-- Durum kolonu için constraint ekle (eğer yoksa)
DO $$
BEGIN
    -- Önce mevcut durum değerlerini 'aktif' yap
    UPDATE aksesuarlar SET durum = 'aktif' WHERE durum IS NULL OR durum = '';
    
    -- Constraint ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints 
                   WHERE constraint_name = 'aksesuarlar_durum_check') THEN
        ALTER TABLE aksesuarlar ADD CONSTRAINT aksesuarlar_durum_check 
            CHECK (durum IN ('aktif', 'pasif'));
        RAISE NOTICE 'Durum constraint eklendi';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Durum constraint eklenirken hata: %', SQLERRM;
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

-- 5. İNDEXLER
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_marka ON aksesuarlar(marka);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_durum ON aksesuarlar(durum);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_aksesuar_id ON aksesuar_bedenler(aksesuar_id);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_beden ON aksesuar_bedenler(beden);
CREATE INDEX IF NOT EXISTS idx_aksesuar_bedenler_stok ON aksesuar_bedenler(stok_miktari);

-- 6. TRİGGERLAR
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_aksesuarlar_updated_at') THEN
        CREATE TRIGGER update_aksesuarlar_updated_at
            BEFORE UPDATE ON aksesuarlar
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_aksesuar_bedenler_updated_at') THEN
        CREATE TRIGGER update_aksesuar_bedenler_updated_at
            BEFORE UPDATE ON aksesuar_bedenler
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- 7. ÖRNEK VERİLER (Sadece yeni kayıtlar için)
INSERT INTO aksesuarlar (sku, ad, renk, renk_kodu, birim, birim_fiyat, malzeme, marka, aciklama, durum)
VALUES
('BTN001', 'Metal Düğme', 'gümüş', '#C0C0C0', 'adet', 1.25, 'metal', 'Coats', 'Ceket için metal düğme', 'aktif'),
('FRM075', 'Deri Kemer', 'kahverengi', '#8B4513', 'adet', 45.00, 'deri', 'Zara', 'Deri kemer çeşitleri', 'aktif'),
('PG910', 'Plastik Düğme', 'kırmızı', '#FF6B6B', 'adet', 0.75, 'plastik', 'Güneş', 'Gömlek düğmesi', 'aktif')
ON CONFLICT (sku) DO NOTHING;

-- Bedenler ve stoklar
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

-- 8. VIEW'LAR
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
WHERE (a.durum = 'aktif' OR a.durum IS NULL) AND (ab.durum = 'aktif' OR ab.durum IS NULL)
ORDER BY a.sku, ab.beden;

-- 9. SONUÇ RAPORU
DO $$
BEGIN
    RAISE NOTICE '=== AKSESUAR SİSTEMİ GÜNCELLEMESİ TAMAMLANDI ===';
    RAISE NOTICE 'Yeni tablolar: aksesuar_bedenler, aksesuar_stok_hareketleri, model_aksesuar_bedenler';
    RAISE NOTICE 'Güncellenmiş tablo: aksesuarlar (yeni kolonlar eklendi)';
    RAISE NOTICE 'Flutter uygulamasını artık kullanabilirsiniz!';
END $$;
