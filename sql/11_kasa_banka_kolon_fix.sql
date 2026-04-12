-- ============================================================
-- KASA BANKA HESAPLARI - EKSIK KOLON DÜZELTME
-- olusturma_tarihi ve guncelleme_tarihi kolonları yoksa ekler
-- veya created_at/updated_at varsa yeniden adlandırır
-- ============================================================

DO $$
BEGIN
    -- olusturma_tarihi yoksa
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema='public' AND table_name='kasa_banka_hesaplari' AND column_name='olusturma_tarihi'
    ) THEN
        -- created_at varsa rename et
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema='public' AND table_name='kasa_banka_hesaplari' AND column_name='created_at'
        ) THEN
            ALTER TABLE public.kasa_banka_hesaplari RENAME COLUMN created_at TO olusturma_tarihi;
            RAISE NOTICE 'kasa_banka_hesaplari: created_at -> olusturma_tarihi olarak yeniden adlandırıldı';
        ELSE
            ALTER TABLE public.kasa_banka_hesaplari ADD COLUMN olusturma_tarihi TIMESTAMPTZ DEFAULT NOW();
            RAISE NOTICE 'kasa_banka_hesaplari: olusturma_tarihi kolonu eklendi';
        END IF;
    ELSE
        RAISE NOTICE 'kasa_banka_hesaplari: olusturma_tarihi zaten mevcut';
    END IF;

    -- guncelleme_tarihi yoksa
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema='public' AND table_name='kasa_banka_hesaplari' AND column_name='guncelleme_tarihi'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema='public' AND table_name='kasa_banka_hesaplari' AND column_name='updated_at'
        ) THEN
            ALTER TABLE public.kasa_banka_hesaplari RENAME COLUMN updated_at TO guncelleme_tarihi;
            RAISE NOTICE 'kasa_banka_hesaplari: updated_at -> guncelleme_tarihi olarak yeniden adlandırıldı';
        ELSE
            ALTER TABLE public.kasa_banka_hesaplari ADD COLUMN guncelleme_tarihi TIMESTAMPTZ DEFAULT NOW();
            RAISE NOTICE 'kasa_banka_hesaplari: guncelleme_tarihi kolonu eklendi';
        END IF;
    ELSE
        RAISE NOTICE 'kasa_banka_hesaplari: guncelleme_tarihi zaten mevcut';
    END IF;
END $$;

-- Aynısını kasa_banka_hareketleri için de yap
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema='public' AND table_name='kasa_banka_hareketleri' AND column_name='olusturma_tarihi'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema='public' AND table_name='kasa_banka_hareketleri' AND column_name='created_at'
        ) THEN
            ALTER TABLE public.kasa_banka_hareketleri RENAME COLUMN created_at TO olusturma_tarihi;
            RAISE NOTICE 'kasa_banka_hareketleri: created_at -> olusturma_tarihi olarak yeniden adlandırıldı';
        ELSE
            ALTER TABLE public.kasa_banka_hareketleri ADD COLUMN olusturma_tarihi TIMESTAMPTZ DEFAULT NOW();
            RAISE NOTICE 'kasa_banka_hareketleri: olusturma_tarihi kolonu eklendi';
        END IF;
    END IF;
END $$;

DO $$ BEGIN RAISE NOTICE 'Kasa/Banka kolon düzeltmesi tamamlandı.'; END $$;
