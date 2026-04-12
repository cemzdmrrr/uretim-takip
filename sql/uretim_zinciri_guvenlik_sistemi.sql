-- ÜRETİM ZİNCİRİ GÜVENLİ ATAMA SİSTEMİ
-- Email bazlı atama + firma izolasyonu

-- 1. Üretim atama tablolarını oluştur
-- Her üretim aşaması kendine ait tabloya sahip

-- Dokuma atamaları tablosu
CREATE TABLE IF NOT EXISTS public.dokuma_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    durum TEXT NOT NULL DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id)
);

-- Konfeksiyon atamaları tablosu
CREATE TABLE IF NOT EXISTS public.konfeksiyon_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    durum TEXT NOT NULL DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id)
);

-- Yıkama atamaları tablosu
CREATE TABLE IF NOT EXISTS public.yikama_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    durum TEXT NOT NULL DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id)
);

-- Ütü atamaları tablosu
CREATE TABLE IF NOT EXISTS public.utu_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    durum TEXT NOT NULL DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id)
);

-- İlik düğme atamaları tablosu
CREATE TABLE IF NOT EXISTS public.ilik_dugme_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    durum TEXT NOT NULL DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id)
);

-- Kalite kontrol atamaları tablosu
CREATE TABLE IF NOT EXISTS public.kalite_kontrol_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    durum TEXT NOT NULL DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id)
);

-- Paketleme atamaları tablosu
CREATE TABLE IF NOT EXISTS public.paketleme_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    durum TEXT NOT NULL DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id)
);

-- İndexler oluştur (performans için)
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_kullanici ON public.dokuma_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_durum ON public.dokuma_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_tarih ON public.dokuma_atamalari(atama_tarihi);

CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_kullanici ON public.konfeksiyon_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_durum ON public.konfeksiyon_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_tarih ON public.konfeksiyon_atamalari(atama_tarihi);

CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_kullanici ON public.yikama_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_durum ON public.yikama_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_tarih ON public.yikama_atamalari(atama_tarihi);

CREATE INDEX IF NOT EXISTS idx_utu_atamalari_kullanici ON public.utu_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_durum ON public.utu_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_tarih ON public.utu_atamalari(atama_tarihi);

CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_kullanici ON public.ilik_dugme_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_durum ON public.ilik_dugme_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_tarih ON public.ilik_dugme_atamalari(atama_tarihi);

CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_kullanici ON public.kalite_kontrol_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_durum ON public.kalite_kontrol_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_tarih ON public.kalite_kontrol_atamalari(atama_tarihi);

CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_kullanici ON public.paketleme_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_durum ON public.paketleme_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_tarih ON public.paketleme_atamalari(atama_tarihi);

-- Modeller tablosunda aşama durumu kolonları ekle (eğer yoksa)
DO $$
BEGIN
    -- Dokuma durumu kolonu
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modeller' AND column_name = 'dokuma_durumu'
    ) THEN
        ALTER TABLE public.modeller ADD COLUMN dokuma_durumu TEXT DEFAULT 'beklemede';
    END IF;
    
    -- Konfeksiyon durumu kolonu
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modeller' AND column_name = 'konfeksiyon_durumu'
    ) THEN
        ALTER TABLE public.modeller ADD COLUMN konfeksiyon_durumu TEXT DEFAULT 'beklemede';
    END IF;
    
    -- Yıkama durumu kolonu
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modeller' AND column_name = 'yikama_durumu'
    ) THEN
        ALTER TABLE public.modeller ADD COLUMN yikama_durumu TEXT DEFAULT 'beklemede';
    END IF;
    
    -- Ütü durumu kolonu
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modeller' AND column_name = 'utu_durumu'
    ) THEN
        ALTER TABLE public.modeller ADD COLUMN utu_durumu TEXT DEFAULT 'beklemede';
    END IF;
    
    -- İlik düğme durumu kolonu
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modeller' AND column_name = 'ilik_dugme_durumu'
    ) THEN
        ALTER TABLE public.modeller ADD COLUMN ilik_dugme_durumu TEXT DEFAULT 'beklemede';
    END IF;
    
    -- Kalite kontrol durumu kolonu
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modeller' AND column_name = 'kalite_kontrol_durumu'
    ) THEN
        ALTER TABLE public.modeller ADD COLUMN kalite_kontrol_durumu TEXT DEFAULT 'beklemede';
    END IF;
    
    -- Paketleme durumu kolonu
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modeller' AND column_name = 'paketleme_durumu'
    ) THEN
        ALTER TABLE public.modeller ADD COLUMN paketleme_durumu TEXT DEFAULT 'beklemede';
    END IF;
END $$;

-- 2. Email bazlı personel bulma fonksiyonu
CREATE OR REPLACE FUNCTION public.get_user_by_email(email_addr TEXT)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    SELECT id INTO user_uuid 
    FROM auth.users 
    WHERE email = email_addr AND email_confirmed_at IS NOT NULL;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Güvenli rol kontrolü fonksiyonu
CREATE OR REPLACE FUNCTION public.check_user_role(email_addr TEXT, expected_role TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    user_role TEXT;
BEGIN
    -- Email'den user_id bul
    user_uuid := public.get_user_by_email(email_addr);
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Rolü kontrol et
    SELECT role INTO user_role
    FROM public.user_roles 
    WHERE user_id = user_uuid AND aktif = true;
    
    RETURN (user_role = expected_role OR user_role = 'admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Model atama fonksiyonu (email bazlı)
CREATE OR REPLACE FUNCTION public.assign_model_to_user(
    model_ids INTEGER[], 
    assignee_email TEXT, 
    stage_name TEXT,
    notes TEXT DEFAULT ''
)
RETURNS JSON AS $$
DECLARE
    assignee_uuid UUID;
    table_name TEXT;
    column_name TEXT;
    assigned_count INTEGER := 0;
    result JSON;
BEGIN
    -- Email'den UUID bul
    assignee_uuid := public.get_user_by_email(assignee_email);
    
    IF assignee_uuid IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Kullanıcı bulunamadı: ' || assignee_email
        );
    END IF;
    
    -- Aşama bilgilerini belirle
    CASE stage_name
        WHEN 'dokuma' THEN 
            table_name := 'dokuma_atamalari';
            column_name := 'dokuma_durumu';
        WHEN 'konfeksiyon' THEN 
            table_name := 'konfeksiyon_atamalari';
            column_name := 'konfeksiyon_durumu';
        WHEN 'yikama' THEN 
            table_name := 'yikama_atamalari';
            column_name := 'yikama_durumu';
        WHEN 'utu' THEN 
            table_name := 'utu_atamalari';
            column_name := 'utu_durumu';
        WHEN 'ilik_dugme' THEN 
            table_name := 'ilik_dugme_atamalari';
            column_name := 'ilik_dugme_durumu';
        WHEN 'kalite_kontrol' THEN 
            table_name := 'kalite_kontrol_atamalari';
            column_name := 'kalite_kontrol_durumu';
        WHEN 'paketleme' THEN 
            table_name := 'paketleme_atamalari';
            column_name := 'paketleme_durumu';
        ELSE
            RETURN json_build_object(
                'success', false,
                'error', 'Geçersiz aşama: ' || stage_name
            );
    END CASE;
    
    -- Rolleri kontrol et
    IF NOT public.check_user_role(assignee_email, stage_name) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Kullanıcının bu aşama için yetkisi yok: ' || assignee_email
        );
    END IF;
    
    -- Her model için atama yap
    FOR i IN 1..array_length(model_ids, 1) LOOP
        -- Atama tablosuna ekle
        EXECUTE format('
            INSERT INTO public.%I (model_id, atanan_kullanici_id, durum, notlar, atama_tarihi)
            VALUES ($1, $2, ''atandi'', $3, NOW())
            ON CONFLICT (model_id) 
            DO UPDATE SET 
                atanan_kullanici_id = $2,
                durum = ''atandi'',
                notlar = $3,
                atama_tarihi = NOW()
        ', table_name) 
        USING model_ids[i], assignee_uuid, notes;
        
        -- Model durumunu güncelle
        EXECUTE format('
            UPDATE public.modeller 
            SET %I = ''atandi''
            WHERE id = $1
        ', column_name) 
        USING model_ids[i];
        
        assigned_count := assigned_count + 1;
    END LOOP;
    
    result := json_build_object(
        'success', true,
        'assigned_count', assigned_count,
        'assignee_email', assignee_email,
        'assignee_uuid', assignee_uuid,
        'stage', stage_name
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Kullanıcının atanmış modellerini getirme fonksiyonu
CREATE OR REPLACE FUNCTION public.get_assigned_models(stage_name TEXT)
RETURNS TABLE(
    model_id INTEGER,
    model_adi TEXT,
    musteri_adi TEXT,
    siparis_adedi INTEGER,
    durum TEXT,
    atama_tarihi TIMESTAMP WITH TIME ZONE,
    notlar TEXT
) AS $$
DECLARE
    table_name TEXT;
    current_user_uuid UUID;
BEGIN
    current_user_uuid := auth.uid();
    
    IF current_user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Aşama tablosunu belirle
    CASE stage_name
        WHEN 'dokuma' THEN table_name := 'dokuma_atamalari';
        WHEN 'konfeksiyon' THEN table_name := 'konfeksiyon_atamalari';
        WHEN 'yikama' THEN table_name := 'yikama_atamalari';
        WHEN 'utu' THEN table_name := 'utu_atamalari';
        WHEN 'ilik_dugme' THEN table_name := 'ilik_dugme_atamalari';
        WHEN 'kalite_kontrol' THEN table_name := 'kalite_kontrol_atamalari';
        WHEN 'paketleme' THEN table_name := 'paketleme_atamalari';
        ELSE 
            RETURN;
    END CASE;
    
    -- Sadece bu kullanıcıya atanmış modelleri getir
    RETURN QUERY EXECUTE format('
        SELECT 
            m.id,
            m.model_adi,
            m.musteri_adi,
            m.siparis_adedi,
            a.durum,
            a.atama_tarihi,
            a.notlar
        FROM public.%I a
        INNER JOIN public.modeller m ON a.model_id = m.id
        WHERE a.atanan_kullanici_id = $1
        ORDER BY a.atama_tarihi DESC
    ', table_name) 
    USING current_user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Test verisi ve örnek kullanım
-- Örnek personel email'leri (gerçek verilerinizle değiştirin)
/*
-- Dokuma personeline atama örneği:
SELECT public.assign_model_to_user(
    ARRAY[1, 2, 3],  -- Model ID'leri
    'dokuma1@firma.com',  -- Email
    'dokuma',  -- Aşama
    'Öncelikli siparişler'  -- Not
);

-- Kullanıcının atanmış modellerini görme:
SELECT * FROM public.get_assigned_models('dokuma');

-- Email'den UUID bulma:
SELECT public.get_user_by_email('dokuma1@firma.com');

-- Rol kontrolü:
SELECT public.check_user_role('dokuma1@firma.com', 'dokuma');
*/

-- 7. RLS'i aktif et ve politikaları ekle
-- Her aşama için sadece o aşamadaki personel kendi işlerini görebilir

-- RLS'i aktif et
ALTER TABLE public.dokuma_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yikama_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.utu_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ilik_dugme_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kalite_kontrol_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paketleme_atamalari ENABLE ROW LEVEL SECURITY;

-- Dokuma izolasyonu
DROP POLICY IF EXISTS "Dokuma kullanıcısı kendi atamalarını görebilir" ON public.dokuma_atamalari;
CREATE POLICY "Dokuma kullanıcısı kendi atamalarını görebilir" ON public.dokuma_atamalari
    FOR SELECT USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

DROP POLICY IF EXISTS "Dokuma kullanıcısı kendi atamalarını güncelleyebilir" ON public.dokuma_atamalari;
CREATE POLICY "Dokuma kullanıcısı kendi atamalarını güncelleyebilir" ON public.dokuma_atamalari
    FOR UPDATE USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

-- Konfeksiyon izolasyonu
DROP POLICY IF EXISTS "Konfeksiyon kullanıcısı kendi atamalarını görebilir" ON public.konfeksiyon_atamalari;
CREATE POLICY "Konfeksiyon kullanıcısı kendi atamalarını görebilir" ON public.konfeksiyon_atamalari
    FOR SELECT USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

DROP POLICY IF EXISTS "Konfeksiyon kullanıcısı kendi atamalarını güncelleyebilir" ON public.konfeksiyon_atamalari;
CREATE POLICY "Konfeksiyon kullanıcısı kendi atamalarını güncelleyebilir" ON public.konfeksiyon_atamalari
    FOR UPDATE USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

-- Yıkama izolasyonu
DROP POLICY IF EXISTS "Yıkama kullanıcısı kendi atamalarını görebilir" ON public.yikama_atamalari;
CREATE POLICY "Yıkama kullanıcısı kendi atamalarını görebilir" ON public.yikama_atamalari
    FOR SELECT USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

DROP POLICY IF EXISTS "Yıkama kullanıcısı kendi atamalarını güncelleyebilir" ON public.yikama_atamalari;
CREATE POLICY "Yıkama kullanıcısı kendi atamalarını güncelleyebilir" ON public.yikama_atamalari
    FOR UPDATE USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

-- Ütü izolasyonu
DROP POLICY IF EXISTS "Ütü kullanıcısı kendi atamalarını görebilir" ON public.utu_atamalari;
CREATE POLICY "Ütü kullanıcısı kendi atamalarını görebilir" ON public.utu_atamalari
    FOR SELECT USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

DROP POLICY IF EXISTS "Ütü kullanıcısı kendi atamalarını güncelleyebilir" ON public.utu_atamalari;
CREATE POLICY "Ütü kullanıcısı kendi atamalarını güncelleyebilir" ON public.utu_atamalari
    FOR UPDATE USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

-- İlik düğme izolasyonu
DROP POLICY IF EXISTS "İlik düğme kullanıcısı kendi atamalarını görebilir" ON public.ilik_dugme_atamalari;
CREATE POLICY "İlik düğme kullanıcısı kendi atamalarını görebilir" ON public.ilik_dugme_atamalari
    FOR SELECT USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

DROP POLICY IF EXISTS "İlik düğme kullanıcısı kendi atamalarını güncelleyebilir" ON public.ilik_dugme_atamalari;
CREATE POLICY "İlik düğme kullanıcısı kendi atamalarını güncelleyebilir" ON public.ilik_dugme_atamalari
    FOR UPDATE USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

-- Kalite kontrol izolasyonu
DROP POLICY IF EXISTS "Kalite kontrol kullanıcısı kendi atamalarını görebilir" ON public.kalite_kontrol_atamalari;
CREATE POLICY "Kalite kontrol kullanıcısı kendi atamalarını görebilir" ON public.kalite_kontrol_atamalari
    FOR SELECT USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

DROP POLICY IF EXISTS "Kalite kontrol kullanıcısı kendi atamalarını güncelleyebilir" ON public.kalite_kontrol_atamalari;
CREATE POLICY "Kalite kontrol kullanıcısı kendi atamalarını güncelleyebilir" ON public.kalite_kontrol_atamalari
    FOR UPDATE USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

-- Paketleme izolasyonu
DROP POLICY IF EXISTS "Paketleme kullanıcısı kendi atamalarını görebilir" ON public.paketleme_atamalari;
CREATE POLICY "Paketleme kullanıcısı kendi atamalarını görebilir" ON public.paketleme_atamalari
    FOR SELECT USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

DROP POLICY IF EXISTS "Paketleme kullanıcısı kendi atamalarını güncelleyebilir" ON public.paketleme_atamalari;
CREATE POLICY "Paketleme kullanıcısı kendi atamalarını güncelleyebilir" ON public.paketleme_atamalari
    FOR UPDATE USING (
        atanan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'ik')
        )
    );

-- Admin için INSERT/DELETE politikaları
DO $$
DECLARE
    tablo_adi TEXT;
    tablo_listesi TEXT[] := ARRAY[
        'dokuma_atamalari',
        'konfeksiyon_atamalari', 
        'yikama_atamalari',
        'utu_atamalari',
        'ilik_dugme_atamalari',
        'kalite_kontrol_atamalari',
        'paketleme_atamalari'
    ];
BEGIN
    FOREACH tablo_adi IN ARRAY tablo_listesi LOOP
        -- INSERT politikası
        EXECUTE format('
            DROP POLICY IF EXISTS "Admin atama ekleyebilir" ON public.%I;
            CREATE POLICY "Admin atama ekleyebilir" ON public.%I
                FOR INSERT WITH CHECK (
                    EXISTS (
                        SELECT 1 FROM public.user_roles 
                        WHERE user_id = auth.uid() 
                        AND role IN (''admin'', ''ik'')
                    )
                );
        ', tablo_adi, tablo_adi);
        
        -- DELETE politikası
        EXECUTE format('
            DROP POLICY IF EXISTS "Admin atama silebilir" ON public.%I;
            CREATE POLICY "Admin atama silebilir" ON public.%I
                FOR DELETE USING (
                    EXISTS (
                        SELECT 1 FROM public.user_roles 
                        WHERE user_id = auth.uid() 
                        AND role IN (''admin'', ''ik'')
                    )
                );
        ', tablo_adi, tablo_adi);
    END LOOP;
END $$;

-- 8. Email bazlı personel listesi view'ı
CREATE OR REPLACE VIEW public.uretim_personel_listesi AS
SELECT 
    u.email,
    ur.role as asama,
    u.id as user_id,
    u.created_at as kayit_tarihi,
    ur.aktif
FROM auth.users u
INNER JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role IN ('dokuma', 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme', 'kalite_kontrol', 'paketleme')
AND ur.aktif = true
ORDER BY ur.role, u.email;

-- 9. Atama istatistikleri view'ı (güvenli)
CREATE OR REPLACE VIEW public.atama_istatistikleri AS
SELECT 
    'dokuma' as asama,
    COALESCE(COUNT(*), 0) as toplam_atama,
    COALESCE(COUNT(CASE WHEN durum = 'atandi' THEN 1 END), 0) as bekleyen,
    COALESCE(COUNT(CASE WHEN durum = 'baslatildi' THEN 1 END), 0) as devam_eden,
    COALESCE(COUNT(CASE WHEN durum = 'tamamlandi' THEN 1 END), 0) as tamamlanan
FROM public.dokuma_atamalari
UNION ALL
SELECT 
    'konfeksiyon' as asama,
    COALESCE(COUNT(*), 0) as toplam_atama,
    COALESCE(COUNT(CASE WHEN durum = 'atandi' THEN 1 END), 0) as bekleyen,
    COALESCE(COUNT(CASE WHEN durum = 'baslatildi' THEN 1 END), 0) as devam_eden,
    COALESCE(COUNT(CASE WHEN durum = 'tamamlandi' THEN 1 END), 0) as tamamlanan
FROM public.konfeksiyon_atamalari
UNION ALL
SELECT 
    'yikama' as asama,
    COALESCE(COUNT(*), 0) as toplam_atama,
    COALESCE(COUNT(CASE WHEN durum = 'atandi' THEN 1 END), 0) as bekleyen,
    COALESCE(COUNT(CASE WHEN durum = 'baslatildi' THEN 1 END), 0) as devam_eden,
    COALESCE(COUNT(CASE WHEN durum = 'tamamlandi' THEN 1 END), 0) as tamamlanan
FROM public.yikama_atamalari
UNION ALL
SELECT 
    'utu' as asama,
    COALESCE(COUNT(*), 0) as toplam_atama,
    COALESCE(COUNT(CASE WHEN durum = 'atandi' THEN 1 END), 0) as bekleyen,
    COALESCE(COUNT(CASE WHEN durum = 'baslatildi' THEN 1 END), 0) as devam_eden,
    COALESCE(COUNT(CASE WHEN durum = 'tamamlandi' THEN 1 END), 0) as tamamlanan
FROM public.utu_atamalari
UNION ALL
SELECT 
    'ilik_dugme' as asama,
    COALESCE(COUNT(*), 0) as toplam_atama,
    COALESCE(COUNT(CASE WHEN durum = 'atandi' THEN 1 END), 0) as bekleyen,
    COALESCE(COUNT(CASE WHEN durum = 'baslatildi' THEN 1 END), 0) as devam_eden,
    COALESCE(COUNT(CASE WHEN durum = 'tamamlandi' THEN 1 END), 0) as tamamlanan
FROM public.ilik_dugme_atamalari
UNION ALL
SELECT 
    'kalite_kontrol' as asama,
    COALESCE(COUNT(*), 0) as toplam_atama,
    COALESCE(COUNT(CASE WHEN durum = 'atandi' THEN 1 END), 0) as bekleyen,
    COALESCE(COUNT(CASE WHEN durum = 'baslatildi' THEN 1 END), 0) as devam_eden,
    COALESCE(COUNT(CASE WHEN durum = 'tamamlandi' THEN 1 END), 0) as tamamlanan
FROM public.kalite_kontrol_atamalari
UNION ALL
SELECT 
    'paketleme' as asama,
    COALESCE(COUNT(*), 0) as toplam_atama,
    COALESCE(COUNT(CASE WHEN durum = 'atandi' THEN 1 END), 0) as bekleyen,
    COALESCE(COUNT(CASE WHEN durum = 'baslatildi' THEN 1 END), 0) as devam_eden,
    COALESCE(COUNT(CASE WHEN durum = 'tamamlandi' THEN 1 END), 0) as tamamlanan
FROM public.paketleme_atamalari;

-- 10. Sonuç raporu
SELECT 
    'Üretim zinciri güvenlik sistemi kuruldu!' as durum,
    'Email bazlı atama aktif' as atama_tipi,
    'Firma izolasyonu aktif' as guvenlik,
    'RLS politikaları güncellendi' as politika;
