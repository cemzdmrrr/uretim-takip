-- ULTIMATE KALAN_MIKTAR FIX
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Önce tüm tabloları ve view'leri kontrol edelim
DO $$
DECLARE
    tbl_name text;
    view_name text;
BEGIN
    -- Tüm view'leri sil
    FOR view_name IN 
        SELECT viewname FROM pg_views WHERE schemaname = 'public'
        AND (viewname LIKE '%iplik%' OR viewname LIKE '%hareket%' OR viewname LIKE '%teslimat%')
    LOOP
        EXECUTE 'DROP VIEW IF EXISTS ' || view_name || ' CASCADE';
        RAISE NOTICE 'Dropped view: %', view_name;
    END LOOP;
    
    -- Tüm generated column'ları ve constraint'leri sil
    FOR tbl_name IN 
        SELECT t.table_name FROM information_schema.tables t
        WHERE t.table_schema = 'public' 
        AND t.table_type = 'BASE TABLE'
        AND t.table_name IN ('iplik_hareketleri', 'iplik_stoklari', 'iplik_siparisleri')
    LOOP
        -- Kalan_miktar ile ilgili tüm constraint'leri sil
        DECLARE
            constraint_name text;
        BEGIN
            FOR constraint_name IN 
                SELECT tc.constraint_name 
                FROM information_schema.table_constraints tc
                WHERE tc.table_name = tbl_name
            LOOP
                BEGIN
                    EXECUTE 'ALTER TABLE ' || tbl_name || ' DROP CONSTRAINT IF EXISTS ' || constraint_name || ' CASCADE';
                EXCEPTION WHEN OTHERS THEN 
                    NULL; -- Ignore errors
                END;
            END LOOP;
        END;
        
        -- Kalan_miktar kolonunu sil
        BEGIN
            EXECUTE 'ALTER TABLE ' || tbl_name || ' DROP COLUMN IF EXISTS kalan_miktar CASCADE';
            RAISE NOTICE 'Dropped kalan_miktar from: %', tbl_name;
        EXCEPTION WHEN OTHERS THEN 
            RAISE NOTICE 'Could not drop kalan_miktar from: %, Error: %', tbl_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 2. İplik siparişleri tablosunu düzelt
DO $$
BEGIN
    -- Önce id kolonu var mı kontrol et
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'id') THEN
        -- id kolonu yoksa ekle
        ALTER TABLE iplik_siparisleri ADD COLUMN id UUID DEFAULT gen_random_uuid();
    END IF;
    
    -- Primary key var mı kontrol et
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'iplik_siparisleri' AND constraint_type = 'PRIMARY KEY') THEN
        -- Primary key yoksa ekle
        ALTER TABLE iplik_siparisleri ADD PRIMARY KEY (id);
    END IF;
    
    -- Eksik kolonları ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'durum') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN durum TEXT DEFAULT 'beklemede';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'birim') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN birim TEXT DEFAULT 'kg';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'birim_fiyat') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN birim_fiyat NUMERIC(10,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'para_birimi') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN para_birimi TEXT DEFAULT 'TL';
    END IF;
END $$;

-- 3. Teslimat tablolarını yeniden oluştur
DROP TABLE IF EXISTS iplik_teslimat_kayitlari CASCADE;
DROP TABLE IF EXISTS iplik_siparis_kalemleri CASCADE;

-- 4. Temiz tablolar oluştur
CREATE TABLE iplik_siparis_kalemleri (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  siparis_id UUID NOT NULL REFERENCES iplik_siparisleri(id) ON DELETE CASCADE,
  kalem_no INTEGER NOT NULL,
  iplik_adi TEXT NOT NULL,
  renk TEXT,
  siparis_miktari NUMERIC(10,2) NOT NULL DEFAULT 0,
  birim TEXT DEFAULT 'kg',
  birim_fiyat NUMERIC(10,2),
  para_birimi TEXT DEFAULT 'TL',
  durum TEXT DEFAULT 'beklemede',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE iplik_teslimat_kayitlari (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  kalem_id UUID NOT NULL REFERENCES iplik_siparis_kalemleri(id) ON DELETE CASCADE,
  teslimat_no TEXT NOT NULL,
  teslimat_tarihi DATE NOT NULL DEFAULT CURRENT_DATE,
  gelen_miktar NUMERIC(10,2) NOT NULL,
  lot_no TEXT,
  notlar TEXT,
  kalite_durumu TEXT DEFAULT 'onaylandi' CHECK (kalite_durumu IN ('onaylandi', 'beklemede', 'sartli_kabul', 'reddedildi')),
  eklenen_kisi TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. RLS ve politikalar
ALTER TABLE iplik_siparis_kalemleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE iplik_teslimat_kayitlari ENABLE ROW LEVEL SECURITY;

CREATE POLICY allow_all ON iplik_siparis_kalemleri FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY allow_all ON iplik_teslimat_kayitlari FOR ALL USING (true) WITH CHECK (true);

-- 6. İndeksler
CREATE INDEX idx_siparis_kalemleri_siparis_id ON iplik_siparis_kalemleri(siparis_id);
CREATE INDEX idx_siparis_kalemleri_kalem_no ON iplik_siparis_kalemleri(kalem_no);
CREATE INDEX idx_teslimat_kayitlari_kalem_id ON iplik_teslimat_kayitlari(kalem_id);
CREATE INDEX idx_teslimat_kayitlari_teslimat_no ON iplik_teslimat_kayitlari(teslimat_no);

-- 7. Trigger'ları güncelle
DROP TRIGGER IF EXISTS update_iplik_siparis_kalemleri_modtime ON iplik_siparis_kalemleri;
DROP TRIGGER IF EXISTS update_iplik_teslimat_kayitlari_modtime ON iplik_teslimat_kayitlari;

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_iplik_siparis_kalemleri_modtime 
    BEFORE UPDATE ON iplik_siparis_kalemleri 
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_iplik_teslimat_kayitlari_modtime 
    BEFORE UPDATE ON iplik_teslimat_kayitlari 
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Final kontrol
SELECT 'ULTIMATE FIX TAMAMLANDI!' as sonuc,
       COUNT(*) as tablosayisi
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('iplik_siparis_kalemleri', 'iplik_teslimat_kayitlari');
