-- ==========================================
-- BEDEN BAZLI ÜRETİM TAKİP SİSTEMİ
-- ==========================================
-- Bu script ile her üretim aşamasında beden bazlı adet takibi yapılabilir
-- Örnek: XS: 50, S: 100, M: 150, L: 100, XL: 50 şeklinde

-- ==========================================
-- 1. BEDEN TANIMLARI TABLOSU
-- ==========================================
CREATE TABLE IF NOT EXISTS public.beden_tanimlari (
    id SERIAL PRIMARY KEY,
    beden_kodu VARCHAR(10) NOT NULL UNIQUE, -- XS, S, M, L, XL, XXL, 2XL, 3XL, vb.
    beden_adi VARCHAR(50),
    sira_no INTEGER DEFAULT 0, -- Sıralama için
    aktif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Varsayılan bedenleri ekle
INSERT INTO public.beden_tanimlari (beden_kodu, beden_adi, sira_no) VALUES
    ('XS', 'Extra Small', 1),
    ('S', 'Small', 2),
    ('M', 'Medium', 3),
    ('L', 'Large', 4),
    ('XL', 'Extra Large', 5),
    ('XXL', '2X Large', 6),
    ('3XL', '3X Large', 7),
    ('4XL', '4X Large', 8),
    ('28', 'Beden 28', 10),
    ('30', 'Beden 30', 11),
    ('32', 'Beden 32', 12),
    ('34', 'Beden 34', 13),
    ('36', 'Beden 36', 14),
    ('38', 'Beden 38', 15),
    ('40', 'Beden 40', 16),
    ('42', 'Beden 42', 17),
    ('44', 'Beden 44', 18),
    ('46', 'Beden 46', 19),
    ('48', 'Beden 48', 20),
    ('STD', 'Standart', 99)
ON CONFLICT (beden_kodu) DO NOTHING;

-- ==========================================
-- 2. MODEL BEDEN DAĞILIMI TABLOSU
-- ==========================================
-- Her model için sipariş edilen beden adetleri
CREATE TABLE IF NOT EXISTS public.model_beden_dagilimi (
    id SERIAL PRIMARY KEY,
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    beden_kodu VARCHAR(10) NOT NULL,
    siparis_adedi INTEGER NOT NULL DEFAULT 0, -- Sipariş edilen adet
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id, beden_kodu)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_model_beden_dagilimi_model ON model_beden_dagilimi(model_id);

-- ==========================================
-- 3. DOKUMA BEDEN TAKİP TABLOSU
-- ==========================================
CREATE TABLE IF NOT EXISTS public.dokuma_beden_takip (
    id SERIAL PRIMARY KEY,
    atama_id INTEGER NOT NULL, -- dokuma_atamalari.id
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    beden_kodu VARCHAR(10) NOT NULL,
    hedef_adet INTEGER NOT NULL DEFAULT 0, -- Üretilmesi gereken
    uretilen_adet INTEGER DEFAULT 0, -- Üretilen
    kabul_edilen_adet INTEGER DEFAULT 0, -- Kalite kontrolden geçen
    fire_adet INTEGER DEFAULT 0, -- Fire olan
    kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(atama_id, beden_kodu)
);

CREATE INDEX IF NOT EXISTS idx_dokuma_beden_model ON dokuma_beden_takip(model_id);
CREATE INDEX IF NOT EXISTS idx_dokuma_beden_atama ON dokuma_beden_takip(atama_id);

-- ==========================================
-- 4. KONFEKSİYON BEDEN TAKİP TABLOSU
-- ==========================================
CREATE TABLE IF NOT EXISTS public.konfeksiyon_beden_takip (
    id SERIAL PRIMARY KEY,
    atama_id INTEGER NOT NULL, -- konfeksiyon_atamalari.id
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    beden_kodu VARCHAR(10) NOT NULL,
    hedef_adet INTEGER NOT NULL DEFAULT 0,
    uretilen_adet INTEGER DEFAULT 0,
    kabul_edilen_adet INTEGER DEFAULT 0,
    fire_adet INTEGER DEFAULT 0,
    kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(atama_id, beden_kodu)
);

CREATE INDEX IF NOT EXISTS idx_konfeksiyon_beden_model ON konfeksiyon_beden_takip(model_id);
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_beden_atama ON konfeksiyon_beden_takip(atama_id);

-- ==========================================
-- 5. YIKAMA BEDEN TAKİP TABLOSU
-- ==========================================
CREATE TABLE IF NOT EXISTS public.yikama_beden_takip (
    id SERIAL PRIMARY KEY,
    atama_id INTEGER NOT NULL, -- yikama_atamalari.id
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    beden_kodu VARCHAR(10) NOT NULL,
    hedef_adet INTEGER NOT NULL DEFAULT 0,
    uretilen_adet INTEGER DEFAULT 0,
    kabul_edilen_adet INTEGER DEFAULT 0,
    fire_adet INTEGER DEFAULT 0,
    kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(atama_id, beden_kodu)
);

CREATE INDEX IF NOT EXISTS idx_yikama_beden_model ON yikama_beden_takip(model_id);
CREATE INDEX IF NOT EXISTS idx_yikama_beden_atama ON yikama_beden_takip(atama_id);

-- ==========================================
-- 6. ÜTÜ BEDEN TAKİP TABLOSU
-- ==========================================
CREATE TABLE IF NOT EXISTS public.utu_beden_takip (
    id SERIAL PRIMARY KEY,
    atama_id INTEGER NOT NULL, -- utu_atamalari.id
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    beden_kodu VARCHAR(10) NOT NULL,
    hedef_adet INTEGER NOT NULL DEFAULT 0,
    uretilen_adet INTEGER DEFAULT 0,
    kabul_edilen_adet INTEGER DEFAULT 0,
    fire_adet INTEGER DEFAULT 0,
    kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(atama_id, beden_kodu)
);

CREATE INDEX IF NOT EXISTS idx_utu_beden_model ON utu_beden_takip(model_id);
CREATE INDEX IF NOT EXISTS idx_utu_beden_atama ON utu_beden_takip(atama_id);

-- ==========================================
-- 7. İLİK DÜĞME BEDEN TAKİP TABLOSU
-- ==========================================
CREATE TABLE IF NOT EXISTS public.ilik_dugme_beden_takip (
    id SERIAL PRIMARY KEY,
    atama_id INTEGER NOT NULL, -- ilik_dugme_atamalari.id
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    beden_kodu VARCHAR(10) NOT NULL,
    hedef_adet INTEGER NOT NULL DEFAULT 0,
    uretilen_adet INTEGER DEFAULT 0,
    kabul_edilen_adet INTEGER DEFAULT 0,
    fire_adet INTEGER DEFAULT 0,
    kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(atama_id, beden_kodu)
);

CREATE INDEX IF NOT EXISTS idx_ilik_dugme_beden_model ON ilik_dugme_beden_takip(model_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_beden_atama ON ilik_dugme_beden_takip(atama_id);

-- ==========================================
-- 8. BEDEN BAZLI ÖZET VİEW
-- ==========================================
CREATE OR REPLACE VIEW public.model_beden_ozet AS
SELECT 
    mbd.model_id,
    tt.item_no,
    tt.marka,
    tt.renk,
    mbd.beden_kodu,
    mbd.siparis_adedi,
    COALESCE(dbt.uretilen_adet, 0) as dokuma_uretilen,
    COALESCE(kbt.uretilen_adet, 0) as konfeksiyon_uretilen,
    COALESCE(ybt.uretilen_adet, 0) as yikama_uretilen,
    COALESCE(ubt.uretilen_adet, 0) as utu_uretilen,
    COALESCE(idbt.uretilen_adet, 0) as ilik_dugme_uretilen,
    -- Kalan adetler
    mbd.siparis_adedi - COALESCE(dbt.uretilen_adet, 0) as dokuma_kalan,
    COALESCE(dbt.uretilen_adet, 0) - COALESCE(kbt.uretilen_adet, 0) as konfeksiyon_bekleyen,
    -- Fire toplamları
    COALESCE(dbt.fire_adet, 0) + COALESCE(kbt.fire_adet, 0) + 
    COALESCE(ybt.fire_adet, 0) + COALESCE(ubt.fire_adet, 0) + 
    COALESCE(idbt.fire_adet, 0) as toplam_fire
FROM model_beden_dagilimi mbd
JOIN triko_takip tt ON mbd.model_id = tt.id
LEFT JOIN dokuma_beden_takip dbt ON mbd.model_id = dbt.model_id AND mbd.beden_kodu = dbt.beden_kodu
LEFT JOIN konfeksiyon_beden_takip kbt ON mbd.model_id = kbt.model_id AND mbd.beden_kodu = kbt.beden_kodu
LEFT JOIN yikama_beden_takip ybt ON mbd.model_id = ybt.model_id AND mbd.beden_kodu = ybt.beden_kodu
LEFT JOIN utu_beden_takip ubt ON mbd.model_id = ubt.model_id AND mbd.beden_kodu = ubt.beden_kodu
LEFT JOIN ilik_dugme_beden_takip idbt ON mbd.model_id = idbt.model_id AND mbd.beden_kodu = idbt.beden_kodu
ORDER BY mbd.model_id, 
    CASE mbd.beden_kodu 
        WHEN 'XS' THEN 1 
        WHEN 'S' THEN 2 
        WHEN 'M' THEN 3 
        WHEN 'L' THEN 4 
        WHEN 'XL' THEN 5 
        WHEN 'XXL' THEN 6 
        ELSE 10 
    END;

-- ==========================================
-- 9. MODEL TOPLAM ADET VİEW
-- ==========================================
CREATE OR REPLACE VIEW public.model_toplam_adetler AS
SELECT 
    model_id,
    SUM(siparis_adedi) as toplam_siparis,
    SUM(dokuma_uretilen) as toplam_dokuma,
    SUM(konfeksiyon_uretilen) as toplam_konfeksiyon,
    SUM(yikama_uretilen) as toplam_yikama,
    SUM(utu_uretilen) as toplam_utu,
    SUM(ilik_dugme_uretilen) as toplam_ilik_dugme,
    SUM(toplam_fire) as toplam_fire
FROM model_beden_ozet
GROUP BY model_id;

-- ==========================================
-- 10. BEDEN GİRİŞ FONKSİYONU
-- ==========================================
CREATE OR REPLACE FUNCTION public.beden_uretim_guncelle(
    p_tablo TEXT, -- 'dokuma', 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme'
    p_atama_id INTEGER,
    p_model_id UUID,
    p_beden_kodu VARCHAR(10),
    p_uretilen_adet INTEGER,
    p_fire_adet INTEGER DEFAULT 0
) RETURNS VOID AS $$
DECLARE
    v_tablo_adi TEXT;
BEGIN
    v_tablo_adi := p_tablo || '_beden_takip';
    
    EXECUTE format('
        INSERT INTO %I (atama_id, model_id, beden_kodu, uretilen_adet, fire_adet, guncelleme_tarihi)
        VALUES ($1, $2, $3, $4, $5, NOW())
        ON CONFLICT (atama_id, beden_kodu) 
        DO UPDATE SET 
            uretilen_adet = EXCLUDED.uretilen_adet,
            fire_adet = EXCLUDED.fire_adet,
            guncelleme_tarihi = NOW()
    ', v_tablo_adi) USING p_atama_id, p_model_id, p_beden_kodu, p_uretilen_adet, p_fire_adet;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 11. RLS POLİTİKALARI
-- ==========================================
ALTER TABLE beden_tanimlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_beden_dagilimi ENABLE ROW LEVEL SECURITY;
ALTER TABLE dokuma_beden_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE konfeksiyon_beden_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE yikama_beden_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE utu_beden_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE ilik_dugme_beden_takip ENABLE ROW LEVEL SECURITY;

-- Önce mevcut politikaları kaldır
DROP POLICY IF EXISTS "beden_tanimlari_select" ON beden_tanimlari;
DROP POLICY IF EXISTS "model_beden_dagilimi_select" ON model_beden_dagilimi;
DROP POLICY IF EXISTS "dokuma_beden_takip_select" ON dokuma_beden_takip;
DROP POLICY IF EXISTS "konfeksiyon_beden_takip_select" ON konfeksiyon_beden_takip;
DROP POLICY IF EXISTS "yikama_beden_takip_select" ON yikama_beden_takip;
DROP POLICY IF EXISTS "utu_beden_takip_select" ON utu_beden_takip;
DROP POLICY IF EXISTS "ilik_dugme_beden_takip_select" ON ilik_dugme_beden_takip;
DROP POLICY IF EXISTS "model_beden_dagilimi_all" ON model_beden_dagilimi;
DROP POLICY IF EXISTS "dokuma_beden_takip_all" ON dokuma_beden_takip;
DROP POLICY IF EXISTS "konfeksiyon_beden_takip_all" ON konfeksiyon_beden_takip;
DROP POLICY IF EXISTS "yikama_beden_takip_all" ON yikama_beden_takip;
DROP POLICY IF EXISTS "utu_beden_takip_all" ON utu_beden_takip;
DROP POLICY IF EXISTS "ilik_dugme_beden_takip_all" ON ilik_dugme_beden_takip;

-- Herkes okuyabilir
CREATE POLICY "beden_tanimlari_select" ON beden_tanimlari FOR SELECT USING (true);
CREATE POLICY "model_beden_dagilimi_select" ON model_beden_dagilimi FOR SELECT USING (true);
CREATE POLICY "dokuma_beden_takip_select" ON dokuma_beden_takip FOR SELECT USING (true);
CREATE POLICY "konfeksiyon_beden_takip_select" ON konfeksiyon_beden_takip FOR SELECT USING (true);
CREATE POLICY "yikama_beden_takip_select" ON yikama_beden_takip FOR SELECT USING (true);
CREATE POLICY "utu_beden_takip_select" ON utu_beden_takip FOR SELECT USING (true);
CREATE POLICY "ilik_dugme_beden_takip_select" ON ilik_dugme_beden_takip FOR SELECT USING (true);

-- Authenticated kullanıcılar yazabilir
CREATE POLICY "model_beden_dagilimi_all" ON model_beden_dagilimi FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "dokuma_beden_takip_all" ON dokuma_beden_takip FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "konfeksiyon_beden_takip_all" ON konfeksiyon_beden_takip FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "yikama_beden_takip_all" ON yikama_beden_takip FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "utu_beden_takip_all" ON utu_beden_takip FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "ilik_dugme_beden_takip_all" ON ilik_dugme_beden_takip FOR ALL USING (auth.role() = 'authenticated');

-- ==========================================
-- 12. TEST VERİSİ (ÖRNEK)
-- ==========================================
-- Örnek bir model için beden dağılımı
-- INSERT INTO model_beden_dagilimi (model_id, beden_kodu, siparis_adedi) VALUES
--     ('model-uuid-buraya', 'XS', 50),
--     ('model-uuid-buraya', 'S', 100),
--     ('model-uuid-buraya', 'M', 150),
--     ('model-uuid-buraya', 'L', 100),
--     ('model-uuid-buraya', 'XL', 50);

-- ==========================================
-- ÖZET
-- ==========================================
SELECT 
    'Beden bazlı üretim takip sistemi kuruldu!' as mesaj,
    (SELECT COUNT(*) FROM beden_tanimlari) as beden_sayisi;
