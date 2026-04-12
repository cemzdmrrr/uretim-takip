-- ============================================================
-- URETIM DALI KOLONU EKLEME - triko_takip tablosu
-- Her modelin hangi üretim dalına ait olduğunu belirler
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema='public' 
        AND table_name='triko_takip' 
        AND column_name='uretim_dali'
    ) THEN
        ALTER TABLE public.triko_takip 
            ADD COLUMN uretim_dali TEXT DEFAULT 'triko';
        
        -- Mevcut kayıtları 'triko' olarak işaretle (geriye uyumluluk)
        UPDATE public.triko_takip SET uretim_dali = 'triko' WHERE uretim_dali IS NULL;
        
        -- Index ekle (performans)
        CREATE INDEX IF NOT EXISTS idx_triko_takip_uretim_dali 
            ON public.triko_takip(uretim_dali);
        
        RAISE NOTICE 'triko_takip: uretim_dali kolonu eklendi';
    ELSE
        RAISE NOTICE 'triko_takip: uretim_dali zaten mevcut';
    END IF;
END $$;

DO $$ BEGIN RAISE NOTICE 'Üretim dalı kolon ekleme tamamlandı.'; END $$;
