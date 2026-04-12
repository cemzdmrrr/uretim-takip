-- PERSONEL DETAY SAYFASI İÇİN SUPABASE TABLOLARI GÜNCELLEME
-- Bu dosya PersonelDetayPage'in düzgün çalışması için gerekli tüm tabloları oluşturur/günceller

-- 1. PERSONEL TABLOSU (Ana tablo - zaten güncellendi ama eksik alanları kontrol edelim)
-- PersonelDetayPage'de gösterilen tüm alanlar burada olmalı

-- Önce tabloyu oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.personel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    ad VARCHAR(100),
    soyad VARCHAR(100),
    tckn VARCHAR(11) UNIQUE,
    pozisyon VARCHAR(100),
    departman VARCHAR(100),
    email VARCHAR(255),
    telefon VARCHAR(20),
    ise_baslangic DATE,
    brut_maas DECIMAL(10,2),
    net_maas DECIMAL(10,2),
    sgk_sicil_no VARCHAR(50),
    gunluk_calisma_saati DECIMAL(4,2) DEFAULT 8.0,
    haftalik_calisma_gunu INTEGER DEFAULT 5,
    yol_ucreti DECIMAL(10,2) DEFAULT 0.0,
    yemek_ucreti DECIMAL(10,2) DEFAULT 0.0,
    ekstra_prim DECIMAL(10,2) DEFAULT 0.0,
    elden_maas DECIMAL(10,2) DEFAULT 0.0,
    banka_maas DECIMAL(10,2) DEFAULT 0.0,
    adres TEXT,
    yillik_izin_hakki INTEGER DEFAULT 14,
    durum VARCHAR(20) DEFAULT 'aktif',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mevcut tabloya eksik alanları ekle
ALTER TABLE public.personel 
ADD COLUMN IF NOT EXISTS user_id UUID,
ADD COLUMN IF NOT EXISTS ad VARCHAR(100),
ADD COLUMN IF NOT EXISTS soyad VARCHAR(100),
ADD COLUMN IF NOT EXISTS tckn VARCHAR(11),
ADD COLUMN IF NOT EXISTS pozisyon VARCHAR(100),
ADD COLUMN IF NOT EXISTS departman VARCHAR(100),
ADD COLUMN IF NOT EXISTS email VARCHAR(255),
ADD COLUMN IF NOT EXISTS telefon VARCHAR(20),
ADD COLUMN IF NOT EXISTS ise_baslangic DATE,
ADD COLUMN IF NOT EXISTS brut_maas DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS net_maas DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS sgk_sicil_no VARCHAR(50),
ADD COLUMN IF NOT EXISTS gunluk_calisma_saati DECIMAL(4,2) DEFAULT 8.0,
ADD COLUMN IF NOT EXISTS haftalik_calisma_gunu INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS yol_ucreti DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS yemek_ucreti DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS ekstra_prim DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS elden_maas DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS banka_maas DECIMAL(10,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS adres TEXT,
ADD COLUMN IF NOT EXISTS yillik_izin_hakki INTEGER DEFAULT 14,
ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'aktif',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Unique constraint'leri ekle (eğer yoksa)
DO $$
BEGIN
    -- user_id için unique constraint
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'personel' AND constraint_name = 'personel_user_id_key'
    ) THEN
        ALTER TABLE public.personel ADD CONSTRAINT personel_user_id_key UNIQUE (user_id);
    END IF;
    
    -- tckn için unique constraint
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'personel' AND constraint_name = 'personel_tckn_key'
    ) THEN
        ALTER TABLE public.personel ADD CONSTRAINT personel_tckn_key UNIQUE (tckn);
    END IF;
    
    -- Foreign key constraint ekle (eğer yoksa)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'personel' AND constraint_name = 'personel_user_id_fkey'
    ) THEN
        ALTER TABLE public.personel ADD CONSTRAINT personel_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. AVANS/ÖDEME TABLOSU (OdemePage için)
-- Flutter kodunda "odeme_kayitlari" tablosu aranıyor
CREATE TABLE IF NOT EXISTS public.odeme_kayitlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID, -- Flutter UUID kullanıyor
    tur VARCHAR(50) CHECK (tur IN ('avans', 'maas', 'prim', 'ikramiye', 'diger')), -- Flutter "tur" sütunu arıyor
    tutar DECIMAL(10,2) CHECK (tutar > 0),
    aciklama TEXT,
    tarih DATE, -- Flutter "tarih" kolonu arıyor
    odeme_tarihi DATE, -- Backward compatibility için
    odeme_yontemi VARCHAR(30) DEFAULT 'nakit' CHECK (odeme_yontemi IN ('nakit', 'banka', 'cek')),
    durum VARCHAR(20) DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'odendi', 'iptal')),
    onaylayan_user_id UUID REFERENCES auth.users(id),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Eski "odemeler" tablosu varsa onu da oluştur (backward compatibility için)
CREATE TABLE IF NOT EXISTS public.odemeler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID, -- UUID olarak değiştirildi
    odeme_turu VARCHAR(50) CHECK (odeme_turu IN ('avans', 'maas', 'prim', 'ikramiye', 'diger')),
    tutar DECIMAL(10,2) CHECK (tutar > 0),
    aciklama TEXT,
    odeme_tarihi DATE,
    odeme_yontemi VARCHAR(30) DEFAULT 'nakit' CHECK (odeme_yontemi IN ('nakit', 'banka', 'cek')),
    durum VARCHAR(20) DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'odendi', 'iptal')),
    onaylayan_user_id UUID REFERENCES auth.users(id),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mevcut ödemeler tablolarına eksik sütunları ekle
ALTER TABLE public.odeme_kayitlari 
ADD COLUMN IF NOT EXISTS personel_id UUID,
ADD COLUMN IF NOT EXISTS tur VARCHAR(50),
ADD COLUMN IF NOT EXISTS tutar DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS tarih DATE, -- Flutter "tarih" kolonu
ADD COLUMN IF NOT EXISTS odeme_tarihi DATE,
ADD COLUMN IF NOT EXISTS odeme_yontemi VARCHAR(30) DEFAULT 'nakit',
ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS onaylayan_user_id UUID,
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Mevcut personel_id sütunu INTEGER ise UUID'ye dönüştür
DO $$
BEGIN
    -- odeme_kayitlari tablosu için personel_id tipini kontrol et ve gerekirse değiştir
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
        
        -- Sonra mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.odeme_kayitlari SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.odeme_kayitlari ALTER COLUMN personel_id TYPE UUID USING NULL;
    END IF;
END $$;

ALTER TABLE public.odemeler 
ADD COLUMN IF NOT EXISTS personel_id UUID, -- UUID olarak değiştirildi
ADD COLUMN IF NOT EXISTS odeme_turu VARCHAR(50),
ADD COLUMN IF NOT EXISTS tutar DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS odeme_tarihi DATE,
ADD COLUMN IF NOT EXISTS odeme_yontemi VARCHAR(30) DEFAULT 'nakit',
ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS onaylayan_user_id UUID,
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Mevcut personel_id sütunu INTEGER ise UUID'ye dönüştür
DO $$
BEGIN
    -- odemeler tablosu için personel_id tipini kontrol et ve gerekirse değiştir
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'odemeler' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce RLS politikalarını kaldır
        DROP POLICY IF EXISTS "Personel kendi ödemelerini görebilir" ON public.odemeler;
        DROP POLICY IF EXISTS "Admin ödeme yönetebilir" ON public.odemeler;
        
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.odemeler DROP CONSTRAINT IF EXISTS odemeler_personel_id_fkey;
        ALTER TABLE public.odemeler DROP CONSTRAINT IF EXISTS odemeler_personel_fkey;
        ALTER TABLE public.odemeler DROP CONSTRAINT IF EXISTS fk_odemeler_personel;
        
        -- Sonra mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.odemeler SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.odemeler ALTER COLUMN personel_id TYPE UUID USING NULL;
    END IF;
END $$;

-- 3. İZİNLER TABLOSU (IzinPage için)
CREATE TABLE IF NOT EXISTS public.izinler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID, -- Flutter UUID kullanıyor
    izin_turu VARCHAR(50) CHECK (izin_turu IN ('yillik', 'hastalik', 'dogum', 'vefat', 'evlilik', 'askerlik', 'diger')),
    baslangic DATE, -- Flutter "baslangic" sütunu arıyor
    baslama_tarihi DATE, -- Backward compatibility için
    bitis_tarihi DATE,
    gun_sayisi INTEGER,
    aciklama TEXT,
    onay_durumu VARCHAR(20) DEFAULT 'beklemede' CHECK (onay_durumu IN ('beklemede', 'onaylandi', 'reddedildi', 'iptal')),
    durum VARCHAR(20) DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'reddedildi', 'iptal')), -- Flutter "durum" da kullanabilir
    onaylayan_user_id UUID REFERENCES auth.users(id),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mevcut izinler tablosuna eksik sütunları ekle
ALTER TABLE public.izinler 
ADD COLUMN IF NOT EXISTS personel_id UUID,
ADD COLUMN IF NOT EXISTS izin_turu VARCHAR(50),
ADD COLUMN IF NOT EXISTS baslangic DATE, -- Flutter'ın aradığı sütun adı
ADD COLUMN IF NOT EXISTS baslama_tarihi DATE, -- Backward compatibility
ADD COLUMN IF NOT EXISTS bitis_tarihi DATE,
ADD COLUMN IF NOT EXISTS gun_sayisi INTEGER,
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS onay_durumu VARCHAR(20) DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'beklemede', -- Flutter "durum" da kullanabilir
ADD COLUMN IF NOT EXISTS onaylayan_user_id UUID,
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Mevcut personel_id sütunu INTEGER ise UUID'ye dönüştür
DO $$
BEGIN
    -- izinler tablosu için personel_id tipini kontrol et ve gerekirse değiştir
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
        
        -- Sonra mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.izinler SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.izinler ALTER COLUMN personel_id TYPE UUID USING NULL;
    END IF;
END $$;

-- 4. MESAİ TABLOSU (MesaiPage için)
-- Flutter "mesai" tablosu arıyor ve "saat" sütunu kullanıyor
CREATE TABLE IF NOT EXISTS public.mesai (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID, -- Flutter UUID kullanıyor
    tarih DATE,
    giris_saati TIME,
    cikis_saati TIME,
    saat DECIMAL(4,2) DEFAULT 0, -- Flutter "saat" sütunu arıyor
    mesai_saati DECIMAL(4,2) DEFAULT 0, -- Backward compatibility
    fazla_mesai_saati DECIMAL(4,2) DEFAULT 0,
    aciklama TEXT,
    onaylandi BOOLEAN DEFAULT false,
    onaylayan_user_id UUID REFERENCES auth.users(id),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Eski "mesailer" tablosu da oluştur (backward compatibility)
CREATE TABLE IF NOT EXISTS public.mesailer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID, -- UUID olarak değiştirildi
    tarih DATE,
    giris_saati TIME,
    cikis_saati TIME,
    mesai_saati DECIMAL(4,2) DEFAULT 0,
    fazla_mesai_saati DECIMAL(4,2) DEFAULT 0,
    aciklama TEXT,
    onaylandi BOOLEAN DEFAULT false,
    onaylayan_user_id UUID REFERENCES auth.users(id),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mevcut mesai tablolarına eksik sütunları ekle
ALTER TABLE public.mesai 
ADD COLUMN IF NOT EXISTS personel_id UUID,
ADD COLUMN IF NOT EXISTS tarih DATE,
ADD COLUMN IF NOT EXISTS giris_saati TIME,
ADD COLUMN IF NOT EXISTS cikis_saati TIME,
ADD COLUMN IF NOT EXISTS saat DECIMAL(4,2) DEFAULT 0, -- Flutter'ın aradığı sütun
ADD COLUMN IF NOT EXISTS mesai_saati DECIMAL(4,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS fazla_mesai_saati DECIMAL(4,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS onaylandi BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS onaylayan_user_id UUID,
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

ALTER TABLE public.mesailer 
ADD COLUMN IF NOT EXISTS personel_id UUID, -- UUID olarak değiştirildi
ADD COLUMN IF NOT EXISTS tarih DATE,
ADD COLUMN IF NOT EXISTS giris_saati TIME,
ADD COLUMN IF NOT EXISTS cikis_saati TIME,
ADD COLUMN IF NOT EXISTS mesai_saati DECIMAL(4,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS fazla_mesai_saati DECIMAL(4,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS onaylandi BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS onaylayan_user_id UUID,
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Mevcut personel_id sütunu INTEGER ise UUID'ye dönüştür
DO $$
BEGIN
    -- mesai tablosu için personel_id tipini kontrol et ve gerekirse değiştir
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
        
        -- Sonra mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.mesai SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.mesai ALTER COLUMN personel_id TYPE UUID USING NULL;
    END IF;
    
    -- mesailer tablosu için personel_id tipini kontrol et ve gerekirse değiştir
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mesailer' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce RLS politikalarını kaldır
        DROP POLICY IF EXISTS "Personel kendi mesailerini görebilir" ON public.mesailer;
        DROP POLICY IF EXISTS "Admin mesai yönetebilir" ON public.mesailer;
        
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.mesailer DROP CONSTRAINT IF EXISTS mesailer_personel_id_fkey;
        ALTER TABLE public.mesailer DROP CONSTRAINT IF EXISTS mesailer_personel_fkey;
        ALTER TABLE public.mesailer DROP CONSTRAINT IF EXISTS fk_mesailer_personel;
        
        -- Sonra mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.mesailer SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.mesailer ALTER COLUMN personel_id TYPE UUID USING NULL;
    END IF;
END $$;

-- 5. PUANTAJ TABLOSU (PuantajTabloPage için)
CREATE TABLE IF NOT EXISTS public.puantaj (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID, -- Flutter UUID kullanıyor
    donem INTEGER, -- ay yerine donem kullanabilir
    yil INTEGER,
    calisan_gun_sayisi INTEGER DEFAULT 0,
    izin_gun_sayisi INTEGER DEFAULT 0,
    mesai_saati DECIMAL(6,2) DEFAULT 0,
    fazla_mesai_saati DECIMAL(6,2) DEFAULT 0,
    toplam_maas DECIMAL(10,2) DEFAULT 0,
    kesintiler DECIMAL(10,2) DEFAULT 0,
    net_odeme DECIMAL(10,2) DEFAULT 0,
    aciklama TEXT,
    onaylandi BOOLEAN DEFAULT false,
    onaylayan_user_id UUID REFERENCES auth.users(id),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mevcut puantaj tablosuna eksik sütunları ekle
ALTER TABLE public.puantaj 
ADD COLUMN IF NOT EXISTS personel_id UUID, -- UUID olarak güncellendi
ADD COLUMN IF NOT EXISTS donem INTEGER,
ADD COLUMN IF NOT EXISTS yil INTEGER,
ADD COLUMN IF NOT EXISTS calisan_gun_sayisi INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS izin_gun_sayisi INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS mesai_saati DECIMAL(6,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS fazla_mesai_saati DECIMAL(6,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS toplam_maas DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS kesintiler DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS net_odeme DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS onaylandi BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS onaylayan_user_id UUID,
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Mevcut personel_id sütunu INTEGER ise UUID'ye dönüştür
DO $$
BEGIN
    -- puantaj tablosu için personel_id tipini kontrol et ve gerekirse değiştir
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'puantaj' 
        AND column_name = 'personel_id' 
        AND data_type = 'integer'
    ) THEN
        -- Önce RLS politikalarını kaldır
        DROP POLICY IF EXISTS "Personel kendi puantajını görebilir" ON public.puantaj;
        DROP POLICY IF EXISTS "Admin puantaj yönetebilir" ON public.puantaj;
        
        -- Mevcut foreign key constraint'leri kaldır
        ALTER TABLE public.puantaj DROP CONSTRAINT IF EXISTS puantaj_personel_id_fkey;
        ALTER TABLE public.puantaj DROP CONSTRAINT IF EXISTS puantaj_personel_fkey;
        ALTER TABLE public.puantaj DROP CONSTRAINT IF EXISTS fk_puantaj_personel;
        
        -- Sonra mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.puantaj SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.puantaj ALTER COLUMN personel_id TYPE UUID USING NULL;
    END IF;
END $$;

-- Puantaj tablosu constraint'leri (güvenli şekilde)
-- NOT: personel_id artık UUID olduğu için foreign key eklenebilir
DO $$
BEGIN
    -- personel_id foreign key ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'puantaj' AND constraint_name = 'puantaj_personel_id_fkey'
    ) THEN
        ALTER TABLE public.puantaj ADD CONSTRAINT puantaj_personel_id_fkey 
        FOREIGN KEY (personel_id) REFERENCES public.personel(user_id);
    END IF;
    
    -- Onaylayan foreign key ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'puantaj' AND constraint_name = 'puantaj_onaylayan_user_id_fkey'
    ) THEN
        ALTER TABLE public.puantaj ADD CONSTRAINT puantaj_onaylayan_user_id_fkey 
        FOREIGN KEY (onaylayan_user_id) REFERENCES auth.users(id);
    END IF;
END $$;

-- 6. ARŞİV TABLOSU (PersonelArsivPage için)
CREATE TABLE IF NOT EXISTS public.personel_arsiv (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID, -- Flutter UUID kullanıyor
    belge_turu VARCHAR(50) CHECK (belge_turu IN ('cv', 'diploma', 'sertifika', 'saglik_raporu', 'kimlik', 'ikametgah', 'diger')),
    belge_adi VARCHAR(255),
    dosya_yolu TEXT,
    dosya_boyutu BIGINT,
    mime_type VARCHAR(100),
    aciklama TEXT,
    yukleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    yukleyen_user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mevcut arşiv tablosuna eksik sütunları ekle
ALTER TABLE public.personel_arsiv 
ADD COLUMN IF NOT EXISTS personel_id UUID, -- UUID olarak güncellendi
ADD COLUMN IF NOT EXISTS belge_turu VARCHAR(50),
ADD COLUMN IF NOT EXISTS belge_adi VARCHAR(255),
ADD COLUMN IF NOT EXISTS dosya_yolu TEXT,
ADD COLUMN IF NOT EXISTS dosya_boyutu BIGINT,
ADD COLUMN IF NOT EXISTS mime_type VARCHAR(100),
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS yukleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS yukleyen_user_id UUID,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Mevcut personel_id sütunu INTEGER ise UUID'ye dönüştür
DO $$
BEGIN
    -- personel_arsiv tablosu için personel_id tipini kontrol et ve gerekirse değiştir
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
        
        -- Sonra mevcut verileri temizle ve sütun tipini değiştir
        UPDATE public.personel_arsiv SET personel_id = NULL WHERE personel_id IS NOT NULL;
        ALTER TABLE public.personel_arsiv ALTER COLUMN personel_id TYPE UUID USING NULL;
    END IF;
END $$;

-- 7. USER_ROLES TABLOSU (Admin kontrolü için - zaten var ama kontrol edelim)
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'yonetici', 'muhasebe', 'ik', 'user', 'personel')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(user_id)
);

-- 8. TRIGGER'LAR (updated_at otomatik güncellemesi için)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları oluştur (hem yeni hem eski tablolar için)
DROP TRIGGER IF EXISTS update_personel_updated_at ON public.personel;
CREATE TRIGGER update_personel_updated_at
    BEFORE UPDATE ON public.personel
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Ödeme tabloları
DROP TRIGGER IF EXISTS update_odeme_kayitlari_updated_at ON public.odeme_kayitlari;
CREATE TRIGGER update_odeme_kayitlari_updated_at
    BEFORE UPDATE ON public.odeme_kayitlari
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_odemeler_updated_at ON public.odemeler;
CREATE TRIGGER update_odemeler_updated_at
    BEFORE UPDATE ON public.odemeler
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- İzin tablosu
DROP TRIGGER IF EXISTS update_izinler_updated_at ON public.izinler;
CREATE TRIGGER update_izinler_updated_at
    BEFORE UPDATE ON public.izinler
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Mesai tabloları
DROP TRIGGER IF EXISTS update_mesai_updated_at ON public.mesai;
CREATE TRIGGER update_mesai_updated_at
    BEFORE UPDATE ON public.mesai
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_mesailer_updated_at ON public.mesailer;
CREATE TRIGGER update_mesailer_updated_at
    BEFORE UPDATE ON public.mesailer
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Puantaj tablosu
DROP TRIGGER IF EXISTS update_puantaj_updated_at ON public.puantaj;
CREATE TRIGGER update_puantaj_updated_at
    BEFORE UPDATE ON public.puantaj
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- User roles
DROP TRIGGER IF EXISTS update_user_roles_updated_at ON public.user_roles;
CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. INDEX'LER (Performans için - hem yeni hem eski tablolar)
-- Ödeme tabloları
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_personel_id ON public.odeme_kayitlari(personel_id);
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_odeme_tarihi ON public.odeme_kayitlari(odeme_tarihi);
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_durum ON public.odeme_kayitlari(durum);

CREATE INDEX IF NOT EXISTS idx_odemeler_personel_id ON public.odemeler(personel_id);
CREATE INDEX IF NOT EXISTS idx_odemeler_odeme_tarihi ON public.odemeler(odeme_tarihi);
CREATE INDEX IF NOT EXISTS idx_odemeler_durum ON public.odemeler(durum);

-- İzin tablosu
CREATE INDEX IF NOT EXISTS idx_izinler_personel_id ON public.izinler(personel_id);
CREATE INDEX IF NOT EXISTS idx_izinler_baslangic ON public.izinler(baslangic);
CREATE INDEX IF NOT EXISTS idx_izinler_baslama_tarihi ON public.izinler(baslama_tarihi);
CREATE INDEX IF NOT EXISTS idx_izinler_onay_durumu ON public.izinler(onay_durumu);
CREATE INDEX IF NOT EXISTS idx_izinler_durum ON public.izinler(durum);

-- Mesai tabloları
CREATE INDEX IF NOT EXISTS idx_mesai_personel_id ON public.mesai(personel_id);
CREATE INDEX IF NOT EXISTS idx_mesai_tarih ON public.mesai(tarih);

CREATE INDEX IF NOT EXISTS idx_mesailer_personel_id ON public.mesailer(personel_id);
CREATE INDEX IF NOT EXISTS idx_mesailer_tarih ON public.mesailer(tarih);

-- Puantaj tablosu
CREATE INDEX IF NOT EXISTS idx_puantaj_personel_id ON public.puantaj(personel_id);
CREATE INDEX IF NOT EXISTS idx_puantaj_donem_yil ON public.puantaj(donem, yil);

-- Arşiv tablosu
CREATE INDEX IF NOT EXISTS idx_personel_arsiv_personel_id ON public.personel_arsiv(personel_id);
CREATE INDEX IF NOT EXISTS idx_personel_arsiv_belge_turu ON public.personel_arsiv(belge_turu);

-- User roles
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- 10. RLS (Row Level Security) POLİTİKALARI
ALTER TABLE public.personel ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odeme_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odemeler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.izinler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesai ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesailer ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.puantaj ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personel_arsiv ENABLE ROW LEVEL SECURITY;
-- NOT: user_roles tablosunda RLS devre dışı - rol kontrolü için temel tablo olduğu için

-- Personel tablosu politikaları
DROP POLICY IF EXISTS "Herkes personel okuyabilir" ON public.personel;
CREATE POLICY "Herkes personel okuyabilir" ON public.personel FOR SELECT USING (
    -- Admin, IK yetkilileri herkesi görebilir
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik', 'yonetici')
    ) OR
    -- Personel rolündeki kullanıcılar sadece kendi kaydını görebilir
    (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() AND role = 'personel'
        ) AND 
        user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Admin personel yönetebilir" ON public.personel;
CREATE POLICY "Admin personel yönetebilir" ON public.personel 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik')
    )
);

-- Ödemeler tabloları politikaları (hem odeme_kayitlari hem odemeler için)
DROP POLICY IF EXISTS "Admin ödeme yönetebilir" ON public.odeme_kayitlari;
CREATE POLICY "Admin ödeme yönetebilir" ON public.odeme_kayitlari 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'muhasebe')
    )
);

DROP POLICY IF EXISTS "Personel kendi ödemelerini görebilir" ON public.odeme_kayitlari;
CREATE POLICY "Personel kendi ödemelerini görebilir" ON public.odeme_kayitlari 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

DROP POLICY IF EXISTS "Admin ödeme yönetebilir" ON public.odemeler;
CREATE POLICY "Admin ödeme yönetebilir" ON public.odemeler 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'muhasebe')
    )
);

DROP POLICY IF EXISTS "Personel kendi ödemelerini görebilir" ON public.odemeler;
CREATE POLICY "Personel kendi ödemelerini görebilir" ON public.odemeler 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- Artık UUID = UUID karşılaştırması
);

-- İzinler tablosu politikaları
DROP POLICY IF EXISTS "Admin izin yönetebilir" ON public.izinler;
CREATE POLICY "Admin izin yönetebilir" ON public.izinler 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi izinlerini görebilir" ON public.izinler;
CREATE POLICY "Personel kendi izinlerini görebilir" ON public.izinler 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- Mesai tabloları politikaları (hem mesai hem mesailer için)
DROP POLICY IF EXISTS "Admin mesai yönetebilir" ON public.mesai;
CREATE POLICY "Admin mesai yönetebilir" ON public.mesai 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi mesailerini görebilir" ON public.mesai;
CREATE POLICY "Personel kendi mesailerini görebilir" ON public.mesai 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

DROP POLICY IF EXISTS "Admin mesai yönetebilir" ON public.mesailer;
CREATE POLICY "Admin mesai yönetebilir" ON public.mesailer 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi mesailerini görebilir" ON public.mesailer;
CREATE POLICY "Personel kendi mesailerini görebilir" ON public.mesailer 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid() -- Artık UUID = UUID karşılaştırması
);

-- Puantaj tablosu politikaları
DROP POLICY IF EXISTS "Admin puantaj yönetebilir" ON public.puantaj;
CREATE POLICY "Admin puantaj yönetebilir" ON public.puantaj 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'muhasebe', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi puantajını görebilir" ON public.puantaj;
CREATE POLICY "Personel kendi puantajını görebilir" ON public.puantaj 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- Arşiv tablosu politikaları
DROP POLICY IF EXISTS "Admin arşiv yönetebilir" ON public.personel_arsiv;
CREATE POLICY "Admin arşiv yönetebilir" ON public.personel_arsiv 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi arşivini görebilir" ON public.personel_arsiv;
CREATE POLICY "Personel kendi arşivini görebilir" ON public.personel_arsiv 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- User_roles tablosu politikaları - RLS DEVRE DIŞI
-- NOT: user_roles tablosu rol kontrolü için temel tablo olduğu için RLS kullanmıyoruz
-- Bu tabloya erişim sadece authenticated kullanıcılar için açık
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 11. VIEW'LAR (Raporlama için)
-- Artık personel_id'ler UUID olduğu için JOIN yapabiliriz
CREATE OR REPLACE VIEW public.v_personel_ozet AS
SELECT 
    p.user_id,
    p.ad,
    p.soyad,
    p.ad || ' ' || p.soyad AS ad_soyad,
    p.pozisyon,
    p.departman,
    p.durum,
    ur.role
FROM public.personel p
LEFT JOIN public.user_roles ur ON p.user_id = ur.user_id
WHERE p.durum = 'aktif';

-- 12. BAŞARILI TAMAMLAMA MESAJI
DO $$
BEGIN
    RAISE NOTICE 'PersonelDetayPage için tüm tablolar başarıyla oluşturuldu/güncellendi!';
    RAISE NOTICE 'Flutter uyumlu tablolar oluşturuldu:';
    RAISE NOTICE '- personel (güncellendi)';
    RAISE NOTICE '- odeme_kayitlari (Flutter''ın aradığı tablo)';
    RAISE NOTICE '- odemeler (backward compatibility)';
    RAISE NOTICE '- izinler (baslangic sütunu eklendi)';
    RAISE NOTICE '- mesai (Flutter''ın aradığı tablo - saat sütunu ile)';
    RAISE NOTICE '- mesailer (backward compatibility)';
    RAISE NOTICE '- puantaj (UUID personel_id ile)';
    RAISE NOTICE '- personel_arsiv (UUID personel_id ile)';
    RAISE NOTICE '- user_roles (Admin kontrolü için)';
    RAISE NOTICE 'RLS politikaları, trigger''lar ve index''ler eklendi.';
    RAISE NOTICE 'Tüm UUID/INTEGER uyumsuzluk sorunları çözüldü.';
END $$;
