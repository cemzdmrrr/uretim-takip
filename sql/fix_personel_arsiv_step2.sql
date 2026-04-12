-- ADIM 2: INTEGER olan personel_id kolonlarını UUID'ye dönüştür

-- personel_arsiv tablosu için personel_id tipini kontrol et ve dönüştür
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'personel_arsiv' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce RLS politikalarını kaldır
        DROP POLICY IF EXISTS "Personel kendi arşivini görebilir" ON public.personel_arsiv;
        DROP POLICY IF EXISTS "Admin arşiv yönetebilir" ON public.personel_arsiv;
        
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.personel_arsiv DROP CONSTRAINT IF EXISTS personel_arsiv_personel_id_fkey;
        ALTER TABLE public.personel_arsiv DROP CONSTRAINT IF EXISTS personel_arsiv_personel_fkey;
        ALTER TABLE public.personel_arsiv DROP CONSTRAINT IF EXISTS fk_personel_arsiv_personel;
        
        -- Mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.personel_arsiv SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.personel_arsiv ALTER COLUMN personel_id TYPE UUID USING NULL;
        
        RAISE NOTICE 'personel_arsiv.personel_id başarıyla UUID tipine dönüştürüldü';
    ELSE
        RAISE NOTICE 'personel_arsiv.personel_id zaten UUID tipinde';
    END IF;
END $$;

-- odeme_kayitlari tablosu için personel_id tipini kontrol et ve dönüştür
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'odeme_kayitlari' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce RLS politikalarını kaldır
        DROP POLICY IF EXISTS "Personel kendi ödemelerini görebilir" ON public.odeme_kayitlari;
        DROP POLICY IF EXISTS "Admin ödeme yönetebilir" ON public.odeme_kayitlari;
        
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.odeme_kayitlari DROP CONSTRAINT IF EXISTS odeme_kayitlari_personel_id_fkey;
        ALTER TABLE public.odeme_kayitlari DROP CONSTRAINT IF EXISTS odeme_kayitlari_personel_fkey;
        ALTER TABLE public.odeme_kayitlari DROP CONSTRAINT IF EXISTS fk_odeme_kayitlari_personel;
        
        -- Mevcut verileri temizle ve sütun tipini değiştür
        UPDATE public.odeme_kayitlari SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.odeme_kayitlari ALTER COLUMN personel_id TYPE UUID USING NULL;
        
        RAISE NOTICE 'odeme_kayitlari.personel_id başarıyla UUID tipine dönüştürüldü';
    ELSE
        RAISE NOTICE 'odeme_kayitlari.personel_id zaten UUID tipinde';
    END IF;
END $$;
