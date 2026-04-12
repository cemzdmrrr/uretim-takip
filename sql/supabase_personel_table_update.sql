-- PERSONEL TABLOSU GÜNCELLEME SQL'İ
-- Bu dosya personel ekleme sayfasındaki tüm alanları destekleyecek şekilde personel tablosunu günceller

-- 1. Önce mevcut personel tablosunu yedekle (opsiyonel)
-- CREATE TABLE IF NOT EXISTS public.personel_backup AS SELECT * FROM public.personel;

-- 2. Ad ve soyad alanlarını ayrı sütunlar olarak ekle
ALTER TABLE public.personel 
ADD COLUMN IF NOT EXISTS ad VARCHAR(100),
ADD COLUMN IF NOT EXISTS soyad VARCHAR(100);

-- 3. Ad ve soyad alanları için NOT NULL constraint'i (veri girildikten sonra)
-- ALTER TABLE public.personel ALTER COLUMN ad SET NOT NULL;
-- ALTER TABLE public.personel ALTER COLUMN soyad SET NOT NULL;

-- 4. Eksik sütunları kontrol et ve ekle
ALTER TABLE public.personel 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS tckn VARCHAR(11) UNIQUE,
ADD COLUMN IF NOT EXISTS pozisyon VARCHAR(100),
ADD COLUMN IF NOT EXISTS departman VARCHAR(100),
ADD COLUMN IF NOT EXISTS email VARCHAR(255),
ADD COLUMN IF NOT EXISTS telefon VARCHAR(20),
ADD COLUMN IF NOT EXISTS ise_baslangic DATE,
ADD COLUMN IF NOT EXISTS brut_maas DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS sgk_sicil_no VARCHAR(50),
ADD COLUMN IF NOT EXISTS gunluk_calisma_saati DECIMAL(4,2) DEFAULT 8.0,
ADD COLUMN IF NOT EXISTS haftalik_calisma_gunu INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS yol_ucreti DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS yemek_ucreti DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS ekstra_prim DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS elden_maas DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS banka_maas DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS adres TEXT,
ADD COLUMN IF NOT EXISTS net_maas DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS yillik_izin_hakki INTEGER DEFAULT 14,
ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'aktif',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- 5. TCKN alanı için unique constraint ekle (eğer yoksa)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'personel_tckn_key' 
        AND table_name = 'personel'
    ) THEN
        ALTER TABLE public.personel ADD CONSTRAINT personel_tckn_key UNIQUE (tckn);
    END IF;
END $$;

-- 6. Email alanı için unique constraint ekle (opsiyonel)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'personel_email_key' 
        AND table_name = 'personel'
    ) THEN
        -- Email'in unique olmasını istiyorsanız bu satırı açın:
        -- ALTER TABLE public.personel ADD CONSTRAINT personel_email_key UNIQUE (email);
    END IF;
END $$;

-- 7. Trigger fonksiyonu: updated_at otomatik güncellemesi için
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Updated_at trigger'ı oluştur
DROP TRIGGER IF EXISTS update_personel_updated_at ON public.personel;
CREATE TRIGGER update_personel_updated_at
    BEFORE UPDATE ON public.personel
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 9. Index'ler oluştur (performans için)
CREATE INDEX IF NOT EXISTS idx_personel_ad ON public.personel(ad);
CREATE INDEX IF NOT EXISTS idx_personel_soyad ON public.personel(soyad);
CREATE INDEX IF NOT EXISTS idx_personel_tckn ON public.personel(tckn);
CREATE INDEX IF NOT EXISTS idx_personel_email ON public.personel(email);
CREATE INDEX IF NOT EXISTS idx_personel_departman ON public.personel(departman);
CREATE INDEX IF NOT EXISTS idx_personel_pozisyon ON public.personel(pozisyon);
CREATE INDEX IF NOT EXISTS idx_personel_durum ON public.personel(durum);

-- 10. RLS (Row Level Security) politikaları güncelle
ALTER TABLE public.personel ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları temizle
DROP POLICY IF EXISTS "Herkes personel verilerini okuyabilir" ON public.personel;
DROP POLICY IF EXISTS "Sadece admin personel ekleyebilir" ON public.personel;
DROP POLICY IF EXISTS "Sadece admin personel güncelleyebilir" ON public.personel;
DROP POLICY IF EXISTS "Sadece admin personel silebilir" ON public.personel;

-- Yeni politikalar oluştur
CREATE POLICY "Herkes personel verilerini okuyabilir" 
ON public.personel FOR SELECT 
USING (true);

CREATE POLICY "Sadece admin personel ekleyebilir" 
ON public.personel FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Sadece admin personel güncelleyebilir" 
ON public.personel FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Sadece admin personel silebilir" 
ON public.personel FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- 11. Personel tablosu için view oluştur (raporlama için)
-- Bu view sadece user_id alanını kullanır, id alanı ile tip uyumsuzluğu olmaması için
CREATE OR REPLACE VIEW public.v_personel_detay AS
SELECT 
    p.user_id,
    p.ad,
    p.soyad,
    CASE 
        WHEN p.ad IS NOT NULL AND p.soyad IS NOT NULL THEN p.ad || ' ' || p.soyad
        WHEN p.ad IS NOT NULL THEN p.ad
        WHEN p.soyad IS NOT NULL THEN p.soyad
        ELSE ''
    END AS ad_soyad_birlesik,
    p.tckn,
    p.pozisyon,
    p.departman,
    p.email,
    p.telefon,
    p.ise_baslangic,
    p.brut_maas,
    p.sgk_sicil_no,
    p.gunluk_calisma_saati,
    p.haftalik_calisma_gunu,
    p.yol_ucreti,
    p.yemek_ucreti,
    p.ekstra_prim,
    p.elden_maas,
    p.banka_maas,
    p.adres,
    p.net_maas,
    p.yillik_izin_hakki,
    p.durum,
    p.created_at,
    p.updated_at,
    ur.role as kullanici_rolu
FROM public.personel p
LEFT JOIN public.user_roles ur ON p.user_id = ur.user_id
WHERE COALESCE(p.durum, 'aktif') = 'aktif';

-- 12. Veri doğrulama için fonksiyonlar
CREATE OR REPLACE FUNCTION validate_tckn(tckn_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- TCKN 11 haneli olmalı ve sadece rakam içermeli
    IF tckn_text IS NULL OR length(tckn_text) != 11 OR tckn_text !~ '^[0-9]+$' THEN
        RETURN FALSE;
    END IF;
    
    -- İlk hane 0 olamaz
    IF substring(tckn_text, 1, 1) = '0' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 13. TCKN doğrulama constraint'i ekle
ALTER TABLE public.personel 
ADD CONSTRAINT check_tckn_valid 
CHECK (tckn IS NULL OR validate_tckn(tckn));

-- 14. Email format doğrulama constraint'i ekle
ALTER TABLE public.personel 
ADD CONSTRAINT check_email_format 
CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- 15. Maaş alanları için constraint'ler
ALTER TABLE public.personel 
ADD CONSTRAINT check_brut_maas_positive 
CHECK (brut_maas IS NULL OR brut_maas >= 0);

ALTER TABLE public.personel 
ADD CONSTRAINT check_net_maas_positive 
CHECK (net_maas IS NULL OR net_maas >= 0);

ALTER TABLE public.personel 
ADD CONSTRAINT check_calisma_saati_positive 
CHECK (gunluk_calisma_saati IS NULL OR gunluk_calisma_saati > 0);

-- 16. Durum alanı için enum constraint
ALTER TABLE public.personel 
DROP CONSTRAINT IF EXISTS check_personel_durum;

ALTER TABLE public.personel 
ADD CONSTRAINT check_personel_durum 
CHECK (durum IN ('aktif', 'pasif', 'izinli', 'isten_ayrilmis'));

-- 17. Başarılı tamamlama mesajı
DO $$
BEGIN
    RAISE NOTICE 'Personel tablosu başarıyla güncellendi!';
    RAISE NOTICE 'Yeni alanlar eklendi: ad, soyad ve diğer detay alanları';
    RAISE NOTICE 'RLS politikaları ve constraint''ler güncellendi';
    RAISE NOTICE 'Performans index''leri oluşturuldu';
    RAISE NOTICE 'View ve trigger''lar hazırlandı';
END $$;
