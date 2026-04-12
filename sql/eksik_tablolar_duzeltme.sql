-- EKSIK TABLOLAR VE KOLONLAR DÜZELTMESİ

-- 1. bordro tablosunu oluştur (personel_arsiv_page için)
CREATE TABLE IF NOT EXISTS public.bordro (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID,
    donem VARCHAR(10), -- 2025-01 formatında
    yil INTEGER,
    ay INTEGER,
    brut_maas DECIMAL(10,2) DEFAULT 0,
    net_maas DECIMAL(10,2) DEFAULT 0,
    vergi DECIMAL(10,2) DEFAULT 0,
    sgk DECIMAL(10,2) DEFAULT 0,
    damga_vergisi DECIMAL(10,2) DEFAULT 0,
    gelir_vergisi DECIMAL(10,2) DEFAULT 0,
    toplam_kesinti DECIMAL(10,2) DEFAULT 0,
    net_odeme DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 1.1. puantaj tablosunu oluştur (personel_arsiv_page ve puantaj sistemi için)
CREATE TABLE IF NOT EXISTS public.puantaj (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID,
    ad VARCHAR(100),
    ay INTEGER,
    yil INTEGER,
    gun INTEGER DEFAULT 0,
    calisma_saati INTEGER DEFAULT 0,
    fazla_mesai INTEGER DEFAULT 0,
    eksik_gun INTEGER DEFAULT 0,
    devamsizlik INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Eksik kolonları tüm tablolara ekle
ALTER TABLE public.odeme_kayitlari 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID, -- Flutter'ın aradığı kolon
ADD COLUMN IF NOT EXISTS user_id UUID; -- Flutter'ın aradığı user_id kolonu

ALTER TABLE public.izinler 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID, -- Flutter'ın aradığı kolon
ADD COLUMN IF NOT EXISTS user_id UUID, -- Flutter'ın aradığı user_id kolonu
ADD COLUMN IF NOT EXISTS bitis_tarihi DATE; -- İzin bitiş tarihi kolonu eklendi (NOT NULL constraint için)

ALTER TABLE public.mesai 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID, -- Flutter'ın aradığı kolon
ADD COLUMN IF NOT EXISTS user_id UUID, -- Flutter'ın aradığı user_id kolonu
ADD COLUMN IF NOT EXISTS tarih DATE, -- Mesai tarihi kolonu
ADD COLUMN IF NOT EXISTS baslangic_saati TIME, -- Mesai başlangıç saati kolonu
ADD COLUMN IF NOT EXISTS bitis_saati TIME, -- Mesai bitiş saati kolonu
ADD COLUMN IF NOT EXISTS mesai_turu VARCHAR(50), -- Mesai türü kolonu
ADD COLUMN IF NOT EXISTS onay_durumu VARCHAR(20) DEFAULT 'beklemede', -- Onay durumu kolonu
ADD COLUMN IF NOT EXISTS saat DECIMAL(5,2), -- Mesai saat kolonu
ADD COLUMN IF NOT EXISTS mesai_ucret DECIMAL(10,2); -- Mesai ücreti kolonu

ALTER TABLE public.personel_arsiv 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID; -- Flutter'ın aradığı kolon

-- Puantaj tablosu için eksik kolonları ekle
ALTER TABLE public.puantaj 
ADD COLUMN IF NOT EXISTS personel_id UUID,
ADD COLUMN IF NOT EXISTS ad VARCHAR(100),
ADD COLUMN IF NOT EXISTS ay INTEGER,
ADD COLUMN IF NOT EXISTS yil INTEGER,
ADD COLUMN IF NOT EXISTS gun INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS calisma_saati INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS fazla_mesai INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS eksik_gun INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS devamsizlik INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

ALTER TABLE public.bordro 
ADD COLUMN IF NOT EXISTS personel_id UUID,
ADD COLUMN IF NOT EXISTS donem VARCHAR(10),
ADD COLUMN IF NOT EXISTS yil INTEGER,
ADD COLUMN IF NOT EXISTS ay INTEGER,
ADD COLUMN IF NOT EXISTS brut_maas DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS net_maas DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS vergi DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS sgk DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS damga_vergisi DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS gelir_vergisi DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS toplam_kesinti DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS net_odeme DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- 3. Önce personel_id kolonlarının tiplerini UUID'ye dönüştür
DO $$
BEGIN
    -- personel tablosunun id kolonunu da kontrol et ve gerekirse UUID'ye dönüştür
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'personel' 
        AND column_name = 'id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce bu tabloya referans eden tüm foreign key'leri kaldır
        ALTER TABLE public.bordro DROP CONSTRAINT IF EXISTS bordro_personel_id_fkey;
        ALTER TABLE public.odeme_kayitlari DROP CONSTRAINT IF EXISTS odeme_kayitlari_personel_id_fkey;
        ALTER TABLE public.izinler DROP CONSTRAINT IF EXISTS izinler_personel_id_fkey;
        ALTER TABLE public.mesai DROP CONSTRAINT IF EXISTS mesai_personel_id_fkey;
        ALTER TABLE public.personel_arsiv DROP CONSTRAINT IF EXISTS personel_arsiv_personel_id_fkey;
        
        -- personel tablosunun id kolonunu UUID'ye dönüştür - ama dikkat: 
        -- Flutter personel!.userId kullanıyor, bu yüzden user_id'ye odaklanmalıyız
        RAISE NOTICE 'personel.id kolonu integer - ama Flutter user_id kullanıyor';
    END IF;

    -- personel tablosunun user_id kolonunun UUID olduğundan emin ol
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'personel' 
        AND column_name = 'user_id' 
        AND data_type = 'uuid'
    ) THEN
        -- user_id kolonu yoksa veya UUID değilse, onu oluştur/düzelt
        ALTER TABLE public.personel ADD COLUMN IF NOT EXISTS user_id UUID;
        RAISE NOTICE 'personel.user_id kolonu eklendi/kontrol edildi';
    END IF;

    -- bordro tablosu için personel_id tipini kontrol et ve dönüştür
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bordro' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce tüm foreign key constraint'leri kaldır
        ALTER TABLE public.bordro DROP CONSTRAINT IF EXISTS bordro_personel_id_fkey;
        ALTER TABLE public.bordro DROP CONSTRAINT IF EXISTS bordro_personel_fkey;
        ALTER TABLE public.bordro DROP CONSTRAINT IF EXISTS fk_bordro_personel;
        
        -- Mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.bordro SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.bordro ALTER COLUMN personel_id TYPE UUID USING NULL;
        RAISE NOTICE 'bordro.personel_id UUID tipine dönüştürüldü';
    END IF;

    -- odeme_kayitlari tablosu için personel_id tipini kontrol et ve dönüştür
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
        
        -- Mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.odeme_kayitlari SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.odeme_kayitlari ALTER COLUMN personel_id TYPE UUID USING NULL;
        RAISE NOTICE 'odeme_kayitlari.personel_id UUID tipine dönüştürüldü';
    END IF;

    -- izinler tablosu için personel_id tipini kontrol et ve dönüştür
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'izinler' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce RLS politikalarını kaldır
        DROP POLICY IF EXISTS "Personel kendi izinlerini görebilir" ON public.izinler;
        DROP POLICY IF EXISTS "Admin izin yönetebilir" ON public.izinler;
        
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.izinler DROP CONSTRAINT IF EXISTS izinler_personel_id_fkey;
        ALTER TABLE public.izinler DROP CONSTRAINT IF EXISTS izinler_personel_fkey;
        ALTER TABLE public.izinler DROP CONSTRAINT IF EXISTS fk_izinler_personel;
        
        -- Mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.izinler SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.izinler ALTER COLUMN personel_id TYPE UUID USING NULL;
        RAISE NOTICE 'izinler.personel_id UUID tipine dönüştürüldü';
    END IF;

    -- mesai tablosu için personel_id tipini kontrol et ve dönüştür
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesai' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce RLS politikalarını kaldır
        DROP POLICY IF EXISTS "Personel kendi mesailerini görebilir" ON public.mesai;
        DROP POLICY IF EXISTS "Admin mesai yönetebilir" ON public.mesai;
        
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.mesai DROP CONSTRAINT IF EXISTS mesai_personel_id_fkey;
        ALTER TABLE public.mesai DROP CONSTRAINT IF EXISTS mesai_personel_fkey;
        ALTER TABLE public.mesai DROP CONSTRAINT IF EXISTS fk_mesai_personel;
        
        -- Mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.mesai SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.mesai ALTER COLUMN personel_id TYPE UUID USING NULL;
        RAISE NOTICE 'mesai.personel_id UUID tipine dönüştürüldü';
    END IF;

    -- personel_arsiv tablosu için personel_id tipini kontrol et ve dönüştür
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
        RAISE NOTICE 'personel_arsiv.personel_id UUID tipine dönüştürüldü';
    END IF;

    -- puantaj tablosu için personel_id tipini kontrol et ve dönüştür
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'puantaj' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.puantaj DROP CONSTRAINT IF EXISTS puantaj_personel_id_fkey;
        ALTER TABLE public.puantaj DROP CONSTRAINT IF EXISTS puantaj_personel_fkey;
        ALTER TABLE public.puantaj DROP CONSTRAINT IF EXISTS fk_puantaj_personel;
        
        -- Mevcut verileri temizle ve sütun tipini değiştür
        UPDATE public.puantaj SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.puantaj ALTER COLUMN personel_id TYPE UUID USING NULL;
        RAISE NOTICE 'puantaj.personel_id UUID tipine dönüştürüldü';
    END IF;
END $$;

-- 4. Mevcut onaylayan_user_id verilerini onaylayan_id'ye kopyala (UUID dönüşümden sonra)
UPDATE public.odeme_kayitlari 
SET onaylayan_id = onaylayan_user_id 
WHERE onaylayan_user_id IS NOT NULL AND onaylayan_id IS NULL;

-- 4.1. odeme_kayitlari tablosunda user_id'yi personel_id ile senkronize et (güvenli şekilde)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'odeme_kayitlari' 
        AND column_name = 'user_id'
    ) THEN
        UPDATE public.odeme_kayitlari 
        SET user_id = personel_id 
        WHERE personel_id IS NOT NULL;
        RAISE NOTICE 'odeme_kayitlari.user_id senkronize edildi';
    ELSE
        RAISE NOTICE 'odeme_kayitlari.user_id sütunu bulunamadı, atlanıyor';
    END IF;
END $$;

-- 4.2. izinler tablosunda user_id'yi personel_id ile senkronize et (güvenli şekilde)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'izinler' 
        AND column_name = 'user_id'
    ) THEN
        UPDATE public.izinler 
        SET user_id = personel_id 
        WHERE personel_id IS NOT NULL;
        RAISE NOTICE 'izinler.user_id senkronize edildi';
    ELSE
        RAISE NOTICE 'izinler.user_id sütunu bulunamadı, atlanıyor';
    END IF;
END $$;

-- 4.3. mesai tablosunda user_id'yi personel_id ile senkronize et (güvenli şekilde)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesai' 
        AND column_name = 'user_id'
    ) THEN
        UPDATE public.mesai 
        SET user_id = personel_id 
        WHERE personel_id IS NOT NULL;
        RAISE NOTICE 'mesai.user_id senkronize edildi';
    ELSE
        RAISE NOTICE 'mesai.user_id sütunu bulunamadı, atlanıyor';
    END IF;
END $$;

-- 4.4. izinler tablosunda bitis_tarihi sütunu için NOT NULL constraint düzeltmesi
DO $$
BEGIN
    -- Önce mevcut NULL değerleri için varsayılan bir değer ata
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'izinler' 
        AND column_name = 'bitis_tarihi'
    ) THEN
        -- NULL olan bitis_tarihi değerlerini baslama_tarihi + 1 gün olarak ayarla
        UPDATE public.izinler 
        SET bitis_tarihi = baslama_tarihi + INTERVAL '1 day'
        WHERE bitis_tarihi IS NULL AND baslama_tarihi IS NOT NULL;
        
        -- Hem baslama_tarihi hem bitis_tarihi NULL olanlar için bugünün tarihini kullan
        UPDATE public.izinler 
        SET bitis_tarihi = CURRENT_DATE + INTERVAL '1 day',
            baslama_tarihi = CURRENT_DATE
        WHERE bitis_tarihi IS NULL AND baslama_tarihi IS NULL;
        
        RAISE NOTICE 'izinler.bitis_tarihi NULL değerleri düzeltildi';
    ELSE
        RAISE NOTICE 'izinler.bitis_tarihi sütunu bulunamadı, atlanıyor';
    END IF;
END $$;

-- 4.5. mesai tablosunda eksik sütunları kontrol et ve varsayılan değerleri düzelt
DO $$
BEGIN
    -- tarih sütunu var mı kontrol et
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesai' 
        AND column_name = 'tarih'
    ) THEN
        -- NULL olan tarih değerlerini bugün olarak ayarla
        UPDATE public.mesai 
        SET tarih = CURRENT_DATE
        WHERE tarih IS NULL;
        
        RAISE NOTICE 'mesai.tarih NULL değerleri düzeltildi';
    ELSE
        RAISE NOTICE 'mesai.tarih sütunu bulunamadı, eklendi';
    END IF;

    -- baslangic_saati sütunu var mı kontrol et
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesai' 
        AND column_name = 'baslangic_saati'
    ) THEN
        -- NULL olan baslangic_saati değerlerini varsayılan '09:00' olarak ayarla
        UPDATE public.mesai 
        SET baslangic_saati = '09:00'
        WHERE baslangic_saati IS NULL;
        
        RAISE NOTICE 'mesai.baslangic_saati NULL değerleri düzeltildi';
    ELSE
        RAISE NOTICE 'mesai.baslangic_saati sütunu bulunamadı, eklendi';
    END IF;

    -- bitis_saati sütunu var mı kontrol et
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesai' 
        AND column_name = 'bitis_saati'
    ) THEN
        -- NULL olan bitis_saati değerlerini varsayılan '18:00' olarak ayarla
        UPDATE public.mesai 
        SET bitis_saati = '18:00'
        WHERE bitis_saati IS NULL;
        
        RAISE NOTICE 'mesai.bitis_saati NULL değerleri düzeltildi';
    ELSE
        RAISE NOTICE 'mesai.bitis_saati sütunu bulunamadı, eklendi';
    END IF;

    -- mesai_turu sütunu var mı kontrol et
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesai' 
        AND column_name = 'mesai_turu'
    ) THEN
        -- NULL olan mesai_turu değerlerini varsayılan 'normal' olarak ayarla
        UPDATE public.mesai 
        SET mesai_turu = 'normal'
        WHERE mesai_turu IS NULL;
        
        RAISE NOTICE 'mesai.mesai_turu NULL değerleri düzeltildi';
    ELSE
        RAISE NOTICE 'mesai.mesai_turu sütunu bulunamadı, eklendi';
    END IF;

    -- onay_durumu sütunu var mı kontrol et
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesai' 
        AND column_name = 'onay_durumu'
    ) THEN
        -- NULL olan onay_durumu değerlerini varsayılan 'beklemede' olarak ayarla
        UPDATE public.mesai 
        SET onay_durumu = 'beklemede'
        WHERE onay_durumu IS NULL;
        
        RAISE NOTICE 'mesai.onay_durumu NULL değerleri düzeltildi';
    ELSE
        RAISE NOTICE 'mesai.onay_durumu sütunu bulunamadı, eklendi';
    END IF;
END $$;

UPDATE public.izinler 
SET onaylayan_id = onaylayan_user_id 
WHERE onaylayan_user_id IS NOT NULL AND onaylayan_id IS NULL;

UPDATE public.mesai 
SET onaylayan_id = onaylayan_user_id 
WHERE onaylayan_user_id IS NOT NULL AND onaylayan_id IS NULL;

UPDATE public.personel_arsiv 
SET onaylayan_id = yukleyen_user_id 
WHERE yukleyen_user_id IS NOT NULL AND onaylayan_id IS NULL;

-- 5. RLS politikalarını yeniden oluştur (UUID dönüşümden sonra)
ALTER TABLE public.odeme_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.izinler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesai ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personel_arsiv ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.puantaj ENABLE ROW LEVEL SECURITY;

-- odeme_kayitlari politikaları (personel_id = user_id karşılaştırması)
DROP POLICY IF EXISTS "Admin ödeme yönetebilir" ON public.odeme_kayitlari;
CREATE POLICY "Admin ödeme yönetebilir" ON public.odeme_kayitlari 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'muhasebe', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi ödemelerini görebilir" ON public.odeme_kayitlari;
CREATE POLICY "Personel kendi ödemelerini görebilir" ON public.odeme_kayitlari 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- sadece personel_id kontrolü (user_id güvenli olmayabilir)
);

-- Personel kendi avanslarını ekleyebilir
DROP POLICY IF EXISTS "Personel kendi avansını ekleyebilir" ON public.odeme_kayitlari;
CREATE POLICY "Personel kendi avansını ekleyebilir" ON public.odeme_kayitlari 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- Personel kendi avanslarını güncelleyebilir (sadece beklemede olanlar)
DROP POLICY IF EXISTS "Personel kendi avansını güncelleyebilir" ON public.odeme_kayitlari;
CREATE POLICY "Personel kendi avansını güncelleyebilir" ON public.odeme_kayitlari 
FOR UPDATE USING (
    -- Personel kendi kayıtlarını güncelleyebilir (sadece beklemedeki durumları)
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND personel_id = auth.uid() AND durum = 'beklemede')
    OR
    -- Admin/IK/Muhasebe tüm durumları güncelleyebilir  
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    ))
) WITH CHECK (
    -- Personel sadece kendi kayıtlarını güncelleyebilir
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND personel_id = auth.uid())
    OR
    -- Admin/IK/Muhasebe tüm kayıtları güncelleyebilir
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    ))
);

-- Personel kendi avanslarını silebilir
DROP POLICY IF EXISTS "Personel kendi avansını silebilir" ON public.odeme_kayitlari;
CREATE POLICY "Personel kendi avansını silebilir" ON public.odeme_kayitlari 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- izinler politikaları (personel_id = user_id karşılaştırması)
DROP POLICY IF EXISTS "Admin izin yönetebilir" ON public.izinler;
CREATE POLICY "Admin izin yönetebilir" ON public.izinler 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    )
);

DROP POLICY IF EXISTS "Personel kendi izinlerini görebilir" ON public.izinler;
CREATE POLICY "Personel kendi izinlerini görebilir" ON public.izinler 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- sadece personel_id kontrolü
);

-- Personel kendi izinlerini ekleyebilir
DROP POLICY IF EXISTS "Personel kendi iznini ekleyebilir" ON public.izinler;
CREATE POLICY "Personel kendi iznini ekleyebilir" ON public.izinler 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- Personel kendi izinlerini güncelleyebilir (sadece beklemede olanlar)
DROP POLICY IF EXISTS "Personel kendi iznini güncelleyebilir" ON public.izinler;
CREATE POLICY "Personel kendi iznini güncelleyebilir" ON public.izinler 
FOR UPDATE USING (
    -- Personel kendi kayıtlarını güncelleyebilir (sadece beklemedeki durumları)
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND personel_id = auth.uid() AND onay_durumu = 'beklemede')
    OR
    -- Admin/IK/Muhasebe tüm durumları güncelleyebilir  
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    ))
) WITH CHECK (
    -- Personel sadece kendi kayıtlarını güncelleyebilir
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND personel_id = auth.uid())
    OR
    -- Admin/IK/Muhasebe tüm kayıtları güncelleyebilir
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    ))
);

-- Personel kendi izinlerini silebilir (sadece onaylanmamışları)
DROP POLICY IF EXISTS "Personel kendi iznini silebilir" ON public.izinler;
CREATE POLICY "Personel kendi iznini silebilir" ON public.izinler 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() AND
    onay_durumu = 'beklemede' -- sadece beklemedeki izinleri silebilir
);

-- mesai politikaları (personel_id = user_id karşılaştırması)
DROP POLICY IF EXISTS "Admin mesai yönetebilir" ON public.mesai;
CREATE POLICY "Admin mesai yönetebilir" ON public.mesai 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    )
);

DROP POLICY IF EXISTS "Personel kendi mesailerini görebilir" ON public.mesai;
CREATE POLICY "Personel kendi mesailerini görebilir" ON public.mesai 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- sadece personel_id kontrolü
);

-- Personel kendi mesailerini ekleyebilir
DROP POLICY IF EXISTS "Personel kendi mesaisini ekleyebilir" ON public.mesai;
CREATE POLICY "Personel kendi mesaisini ekleyebilir" ON public.mesai 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- Personel kendi mesailerini güncelleyebilir (sadece beklemede olanlar)
DROP POLICY IF EXISTS "Personel kendi mesaisini güncelleyebilir" ON public.mesai;
CREATE POLICY "Personel kendi mesaisini güncelleyebilir" ON public.mesai 
FOR UPDATE USING (
    -- Personel kendi kayıtlarını güncelleyebilir (sadece beklemedeki durumları)
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND personel_id = auth.uid() AND onay_durumu = 'beklemede')
    OR
    -- Admin/IK/Muhasebe tüm durumları güncelleyebilir  
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    ))
) WITH CHECK (
    -- Personel sadece kendi kayıtlarını güncelleyebilir
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND personel_id = auth.uid())
    OR
    -- Admin/IK/Muhasebe tüm kayıtları güncelleyebilir
    (EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    ))
);

-- Personel kendi mesailerini silebilir (sadece onaylanmamışları)
DROP POLICY IF EXISTS "Personel kendi mesaisini silebilir" ON public.mesai;
CREATE POLICY "Personel kendi mesaisini silebilir" ON public.mesai 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() AND
    onay_durumu = 'beklemede' -- sadece beklemedeki mesaileri silebilir
);

-- personel_arsiv politikaları (personel_id = user_id karşılaştırması)
DROP POLICY IF EXISTS "Admin arşiv yönetebilir" ON public.personel_arsiv;
CREATE POLICY "Admin arşiv yönetebilir" ON public.personel_arsiv 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    )
);

DROP POLICY IF EXISTS "Personel kendi arşivini görebilir" ON public.personel_arsiv;
CREATE POLICY "Personel kendi arşivini görebilir" ON public.personel_arsiv 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- sadece personel_id kontrolü
);

-- 6. Bordro tablosu için RLS politikaları (personel_id = user_id karşılaştırması)
ALTER TABLE public.bordro ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin bordro yönetebilir" ON public.bordro;
CREATE POLICY "Admin bordro yönetebilir" ON public.bordro 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'muhasebe', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi bordrosunu görebilir" ON public.bordro;
CREATE POLICY "Personel kendi bordrosunu görebilir" ON public.bordro 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- sadece personel_id kontrolü
);

-- 7. Puantaj tablosu için RLS politikaları
DROP POLICY IF EXISTS "Admin puantaj yönetebilir" ON public.puantaj;
CREATE POLICY "Admin puantaj yönetebilir" ON public.puantaj 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'muhasebe')
    )
);

DROP POLICY IF EXISTS "Personel kendi puantajını görebilir" ON public.puantaj;
CREATE POLICY "Personel kendi puantajını görebilir" ON public.puantaj 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- sadece personel_id kontrolü
);

-- 7. Index'ler ekle
CREATE INDEX IF NOT EXISTS idx_bordro_personel_id ON public.bordro(personel_id);
CREATE INDEX IF NOT EXISTS idx_bordro_donem ON public.bordro(donem);
CREATE INDEX IF NOT EXISTS idx_bordro_yil_ay ON public.bordro(yil, ay);

CREATE INDEX IF NOT EXISTS idx_puantaj_personel_id ON public.puantaj(personel_id);
CREATE INDEX IF NOT EXISTS idx_puantaj_yil_ay ON public.puantaj(yil, ay);

CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_onaylayan_id ON public.odeme_kayitlari(onaylayan_id);
CREATE INDEX IF NOT EXISTS idx_izinler_onaylayan_id ON public.izinler(onaylayan_id);
CREATE INDEX IF NOT EXISTS idx_mesai_onaylayan_id ON public.mesai(onaylayan_id);

-- 8. Trigger ekle
DROP TRIGGER IF EXISTS update_bordro_updated_at ON public.bordro;
CREATE TRIGGER update_bordro_updated_at
    BEFORE UPDATE ON public.bordro
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_puantaj_updated_at ON public.puantaj;
CREATE TRIGGER update_puantaj_updated_at
    BEFORE UPDATE ON public.puantaj
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. Kontrol sorgusu - Tablo yapılarını ve sütun durumlarını kontrol et
SELECT 
    'Tablolar oluşturuldu!' as durum,
    (SELECT COUNT(*) FROM public.bordro) as bordro_kayit_sayisi,
    (SELECT COUNT(*) FROM public.odeme_kayitlari WHERE onaylayan_id IS NOT NULL) as odeme_onaylayan_dolu,
    (SELECT COUNT(*) FROM public.izinler WHERE onaylayan_id IS NOT NULL) as izin_onaylayan_dolu,
    (SELECT COUNT(*) FROM public.mesai WHERE onaylayan_id IS NOT NULL) as mesai_onaylayan_dolu;

-- 10. Sütun durumlarını kontrol et
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('izinler', 'mesai', 'odeme_kayitlari', 'puantaj', 'bordro') 
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- 11. donemler tablosunu kontrol et ve gerekirse oluştur
CREATE TABLE IF NOT EXISTS public.donemler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kod VARCHAR(10) UNIQUE NOT NULL,
    ad VARCHAR(100) NOT NULL,
    baslangic_tarihi DATE,
    bitis_tarihi DATE,
    aktif BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Eksik sütunları ekle (eğer yoksa) - mevcut tablo yapısına uygun
DO $$
BEGIN
    -- Mevcut sütun adlarını kontrol et ve eksik olanları ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'baslama_tarihi') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'baslangic_tarihi') THEN
        -- Eğer her iki tarih sütunu da yoksa baslama_tarihi ekle (mevcut format)
        ALTER TABLE public.donemler ADD COLUMN IF NOT EXISTS baslama_tarihi DATE;
        RAISE NOTICE 'donemler tablosuna baslama_tarihi sütunu eklendi';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'bitis_tarihi') THEN
        ALTER TABLE public.donemler ADD COLUMN IF NOT EXISTS bitis_tarihi DATE;
        RAISE NOTICE 'donemler tablosuna bitis_tarihi sütunu eklendi';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'aktif') THEN
        ALTER TABLE public.donemler ADD COLUMN IF NOT EXISTS aktif BOOLEAN DEFAULT false;
        RAISE NOTICE 'donemler tablosuna aktif sütunu eklendi';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'created_at') THEN
        ALTER TABLE public.donemler ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();
        RAISE NOTICE 'donemler tablosuna created_at sütunu eklendi';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'updated_at') THEN
        ALTER TABLE public.donemler ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();
        RAISE NOTICE 'donemler tablosuna updated_at sütunu eklendi';
    END IF;
END $$;

-- 2025 yılı dönemlerini ekle (eğer yoksa) - mevcut tablo yapısına uygun
DO $$
BEGIN
    -- Önce donemler tablosunun yapısını kontrol et
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'donemler') THEN
        
        -- Hangi sütunların mevcut olduğunu kontrol et
        DECLARE
            has_baslangic_tarihi BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'baslangic_tarihi');
            has_baslama_tarihi BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'baslama_tarihi');
            has_bitis_tarihi BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'bitis_tarihi');
            has_aktif BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'aktif');
            has_created_at BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'created_at');
            has_updated_at BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'donemler' AND column_name = 'updated_at');
        BEGIN
            -- Eğer baslama_tarihi sütunu varsa (mevcut tablo formatı)
            IF has_baslama_tarihi THEN
                RAISE NOTICE 'donemler tablosunda baslama_tarihi sütunu mevcut, bu formata göre insert yapılıyor';
                
                -- Mevcut tablo formatına uygun insert
                INSERT INTO public.donemler (kod, ad, baslama_tarihi, bitis_tarihi, aktif, created_at, updated_at) 
                VALUES 
                    ('2025-01', 'Ocak 2025', '2025-01-01', '2025-01-31', false, now(), now()),
                    ('2025-02', 'Şubat 2025', '2025-02-01', '2025-02-28', false, now(), now()),
                    ('2025-03', 'Mart 2025', '2025-03-01', '2025-03-31', false, now(), now()),
                    ('2025-04', 'Nisan 2025', '2025-04-01', '2025-04-30', false, now(), now()),
                    ('2025-05', 'Mayıs 2025', '2025-05-01', '2025-05-31', false, now(), now()),
                    ('2025-06', 'Haziran 2025', '2025-06-01', '2025-06-30', false, now(), now()),
                    ('2025-07', 'Temmuz 2025', '2025-07-01', '2025-07-31', true, now(), now()),
                    ('2025-08', 'Ağustos 2025', '2025-08-01', '2025-08-31', false, now(), now()),
                    ('2025-09', 'Eylül 2025', '2025-09-01', '2025-09-30', false, now(), now()),
                    ('2025-10', 'Ekim 2025', '2025-10-01', '2025-10-31', false, now(), now()),
                    ('2025-11', 'Kasım 2025', '2025-11-01', '2025-11-30', false, now(), now()),
                    ('2025-12', 'Aralık 2025', '2025-12-01', '2025-12-31', false, now(), now())
                ON CONFLICT (kod) DO NOTHING;
                
            -- Eğer baslangic_tarihi sütunu varsa (yeni tablo formatı)  
            ELSIF has_baslangic_tarihi THEN
                RAISE NOTICE 'donemler tablosunda baslangic_tarihi sütunu mevcut, bu formata göre insert yapılıyor';
                
                -- Yeni tablo formatına uygun insert
                INSERT INTO public.donemler (kod, ad, baslangic_tarihi, bitis_tarihi, aktif, created_at, updated_at) 
                VALUES 
                    ('2025-01', 'Ocak 2025', '2025-01-01', '2025-01-31', false, now(), now()),
                    ('2025-02', 'Şubat 2025', '2025-02-01', '2025-02-28', false, now(), now()),
                    ('2025-03', 'Mart 2025', '2025-03-01', '2025-03-31', false, now(), now()),
                    ('2025-04', 'Nisan 2025', '2025-04-01', '2025-04-30', false, now(), now()),
                    ('2025-05', 'Mayıs 2025', '2025-05-01', '2025-05-31', false, now(), now()),
                    ('2025-06', 'Haziran 2025', '2025-06-01', '2025-06-30', false, now(), now()),
                    ('2025-07', 'Temmuz 2025', '2025-07-01', '2025-07-31', true, now(), now()),
                    ('2025-08', 'Ağustos 2025', '2025-08-01', '2025-08-31', false, now(), now()),
                    ('2025-09', 'Eylül 2025', '2025-09-01', '2025-09-30', false, now(), now()),
                    ('2025-10', 'Ekim 2025', '2025-10-01', '2025-10-31', false, now(), now()),
                    ('2025-11', 'Kasım 2025', '2025-11-01', '2025-11-30', false, now(), now()),
                    ('2025-12', 'Aralık 2025', '2025-12-01', '2025-12-31', false, now(), now())
                ON CONFLICT (kod) DO NOTHING;
                
            ELSE
                -- Sadece temel sütunlar varsa basit insert
                RAISE NOTICE 'donemler tablosunda sadece temel sütunlar mevcut, basit insert yapılıyor';
                
                INSERT INTO public.donemler (kod, ad) 
                VALUES 
                    ('2025-01', 'Ocak 2025'),
                    ('2025-02', 'Şubat 2025'),
                    ('2025-03', 'Mart 2025'),
                    ('2025-04', 'Nisan 2025'),
                    ('2025-05', 'Mayıs 2025'),
                    ('2025-06', 'Haziran 2025'),
                    ('2025-07', 'Temmuz 2025'),
                    ('2025-08', 'Ağustos 2025'),
                    ('2025-09', 'Eylül 2025'),
                    ('2025-10', 'Ekim 2025'),
                    ('2025-11', 'Kasım 2025'),
                    ('2025-12', 'Aralık 2025')
                ON CONFLICT (kod) DO NOTHING;
            END IF;
            
            -- Eğer aktif sütunu varsa 2025-07'yi aktif yap
            IF has_aktif THEN
                UPDATE public.donemler SET aktif = false WHERE aktif = true;
                UPDATE public.donemler SET aktif = true WHERE kod = '2025-07';
                RAISE NOTICE '2025-07 dönemi aktif olarak ayarlandı';
            END IF;
            
            RAISE NOTICE 'donemler tablosuna 2025 dönemleri eklendi';
        END;
    ELSE
        RAISE NOTICE 'donemler tablosu bulunamadı';
    END IF;
END $$;
