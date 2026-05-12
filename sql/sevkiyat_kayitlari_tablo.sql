-- Sevkiyat tablolari guvenli migration
-- Not: Bu script veri silmez; mevcut tabloya eksik kolonlari ekler.

CREATE TABLE IF NOT EXISTS public.sevkiyat_kayitlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

ALTER TABLE public.sevkiyat_kayitlari
    ADD COLUMN IF NOT EXISTS model_id UUID,
    ADD COLUMN IF NOT EXISTS kalite_kontrol_id INTEGER,
    ADD COLUMN IF NOT EXISTS sevkiyat_personeli_id UUID,
    ADD COLUMN IF NOT EXISTS alinan_adet INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sevk_edilen_adet INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS kalan_adet INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS hedef_asama VARCHAR(50),
    ADD COLUMN IF NOT EXISTS hedef_tedarikci_id BIGINT,
    ADD COLUMN IF NOT EXISTS durum VARCHAR(30) NOT NULL DEFAULT 'beklemede',
    ADD COLUMN IF NOT EXISTS alis_tarihi TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS sevk_tarihi TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS tamamlanma_tarihi TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS notlar TEXT,
    ADD COLUMN IF NOT EXISTS beden_detaylari JSONB,
    ADD COLUMN IF NOT EXISTS firma_id UUID,
    ADD COLUMN IF NOT EXISTS idempotency_key TEXT,
    ADD COLUMN IF NOT EXISTS kaynak_atama_tablosu TEXT,
    ADD COLUMN IF NOT EXISTS kaynak_atama_id BIGINT,
    ADD COLUMN IF NOT EXISTS onceki_asama TEXT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_kayitlari_model_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_kayitlari
                ADD CONSTRAINT sevkiyat_kayitlari_model_id_fkey
                FOREIGN KEY (model_id) REFERENCES public.triko_takip(id) ON DELETE CASCADE;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_kayitlari_model_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_kayitlari_kalite_kontrol_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_kayitlari
                ADD CONSTRAINT sevkiyat_kayitlari_kalite_kontrol_id_fkey
                FOREIGN KEY (kalite_kontrol_id) REFERENCES public.kalite_kontrol_atamalari(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_kayitlari_kalite_kontrol_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_kayitlari_sevkiyat_personeli_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_kayitlari
                ADD CONSTRAINT sevkiyat_kayitlari_sevkiyat_personeli_id_fkey
                FOREIGN KEY (sevkiyat_personeli_id) REFERENCES auth.users(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_kayitlari_sevkiyat_personeli_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_kayitlari_firma_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_kayitlari
                ADD CONSTRAINT sevkiyat_kayitlari_firma_id_fkey
                FOREIGN KEY (firma_id) REFERENCES public.firmalar(id);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_kayitlari_firma_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_kayitlari_hedef_tedarikci_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_kayitlari
                ADD CONSTRAINT sevkiyat_kayitlari_hedef_tedarikci_id_fkey
                FOREIGN KEY (hedef_tedarikci_id) REFERENCES public.tedarikciler(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_kayitlari_hedef_tedarikci_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.sevkiyat_detaylari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sevkiyat_id UUID NOT NULL,
    sevk_adet INTEGER NOT NULL,
    hedef_asama VARCHAR(50) NOT NULL,
    hedef_tedarikci_id INTEGER,
    hedef_atama_id BIGINT,
    sevk_eden_id UUID,
    sevk_tarihi TIMESTAMPTZ DEFAULT NOW(),
    notlar TEXT,
    beden_detaylari JSONB,
    irsaliye_id UUID,
    irsaliye_no TEXT,
    firma_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.sevkiyat_detaylari
    ADD COLUMN IF NOT EXISTS sevkiyat_id UUID,
    ADD COLUMN IF NOT EXISTS sevk_adet INTEGER,
    ADD COLUMN IF NOT EXISTS hedef_asama VARCHAR(50),
    ADD COLUMN IF NOT EXISTS hedef_tedarikci_id INTEGER,
    ADD COLUMN IF NOT EXISTS hedef_atama_id BIGINT,
    ADD COLUMN IF NOT EXISTS sevk_eden_id UUID,
    ADD COLUMN IF NOT EXISTS sevk_tarihi TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS notlar TEXT,
    ADD COLUMN IF NOT EXISTS beden_detaylari JSONB,
    ADD COLUMN IF NOT EXISTS irsaliye_id UUID,
    ADD COLUMN IF NOT EXISTS irsaliye_no TEXT,
    ADD COLUMN IF NOT EXISTS firma_id UUID,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

DO $$
BEGIN
    BEGIN
        ALTER TABLE public.sevkiyat_detaylari
            ALTER COLUMN sevk_adet SET NOT NULL;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'sevkiyat_detaylari.sevk_adet NOT NULL atanamadi: %', SQLERRM;
    END;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_detaylari_sevkiyat_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_detaylari
                ADD CONSTRAINT sevkiyat_detaylari_sevkiyat_id_fkey
                FOREIGN KEY (sevkiyat_id) REFERENCES public.sevkiyat_kayitlari(id) ON DELETE CASCADE;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_detaylari_sevkiyat_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_detaylari_sevk_eden_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_detaylari
                ADD CONSTRAINT sevkiyat_detaylari_sevk_eden_id_fkey
                FOREIGN KEY (sevk_eden_id) REFERENCES auth.users(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_detaylari_sevk_eden_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_detaylari_firma_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_detaylari
                ADD CONSTRAINT sevkiyat_detaylari_firma_id_fkey
                FOREIGN KEY (firma_id) REFERENCES public.firmalar(id);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_detaylari_firma_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_detaylari_hedef_tedarikci_id_fkey'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_detaylari
                ADD CONSTRAINT sevkiyat_detaylari_hedef_tedarikci_id_fkey
                FOREIGN KEY (hedef_tedarikci_id) REFERENCES public.tedarikciler(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_detaylari_hedef_tedarikci_id_fkey eklenemedi: %', SQLERRM;
        END;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sevkiyat_kayitlari_durum_check'
    ) THEN
        BEGIN
            ALTER TABLE public.sevkiyat_kayitlari
                ADD CONSTRAINT sevkiyat_kayitlari_durum_check
                CHECK (durum IN ('beklemede', 'kismen_sevk', 'sevk_ediliyor', 'tamamlandi', 'iptal'));
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'sevkiyat_kayitlari_durum_check eklenemedi: %', SQLERRM;
        END;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_model_id
    ON public.sevkiyat_kayitlari(model_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_durum
    ON public.sevkiyat_kayitlari(durum);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_personel
    ON public.sevkiyat_kayitlari(sevkiyat_personeli_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_kalite
    ON public.sevkiyat_kayitlari(kalite_kontrol_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_firma
    ON public.sevkiyat_kayitlari(firma_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_idempotency
    ON public.sevkiyat_kayitlari(idempotency_key);

CREATE INDEX IF NOT EXISTS idx_sevkiyat_detaylari_sevkiyat
    ON public.sevkiyat_detaylari(sevkiyat_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_detaylari_hedef
    ON public.sevkiyat_detaylari(hedef_asama);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_detaylari_firma
    ON public.sevkiyat_detaylari(firma_id);

ALTER TABLE public.sevkiyat_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sevkiyat_detaylari ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'sevkiyat_kayitlari' AND policyname = 'sevkiyat_kayitlari_select'
    ) THEN
        CREATE POLICY sevkiyat_kayitlari_select ON public.sevkiyat_kayitlari
            FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'sevkiyat_kayitlari' AND policyname = 'sevkiyat_kayitlari_insert'
    ) THEN
        CREATE POLICY sevkiyat_kayitlari_insert ON public.sevkiyat_kayitlari
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'sevkiyat_kayitlari' AND policyname = 'sevkiyat_kayitlari_update'
    ) THEN
        CREATE POLICY sevkiyat_kayitlari_update ON public.sevkiyat_kayitlari
            FOR UPDATE USING (auth.uid() IS NOT NULL);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'sevkiyat_detaylari' AND policyname = 'sevkiyat_detaylari_select'
    ) THEN
        CREATE POLICY sevkiyat_detaylari_select ON public.sevkiyat_detaylari
            FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'sevkiyat_detaylari' AND policyname = 'sevkiyat_detaylari_insert'
    ) THEN
        CREATE POLICY sevkiyat_detaylari_insert ON public.sevkiyat_detaylari
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'sevkiyat_detaylari' AND policyname = 'sevkiyat_detaylari_update'
    ) THEN
        CREATE POLICY sevkiyat_detaylari_update ON public.sevkiyat_detaylari
            FOR UPDATE USING (auth.uid() IS NOT NULL);
    END IF;
END $$;

COMMENT ON TABLE public.sevkiyat_kayitlari IS 'Kalite kontrolden gecen urunlerin sevkiyat bekleyen kayitlari';
COMMENT ON TABLE public.sevkiyat_detaylari IS 'Her sevk isleminin detay kaydi';
