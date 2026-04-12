-- ADIM 1: Temel tabloları oluştur ve UUID tipine dönüştür

-- Personel tablosu
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

-- odeme_kayitlari tablosu (Flutter'ın aradığı)
CREATE TABLE IF NOT EXISTS public.odeme_kayitlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID,
    tur VARCHAR(50) CHECK (tur IN ('avans', 'maas', 'prim', 'ikramiye', 'diger')),
    tutar DECIMAL(10,2) CHECK (tutar > 0),
    aciklama TEXT,
    tarih DATE, -- Flutter "tarih" kolonu arıyor
    odeme_tarihi DATE, -- Backward compatibility
    odeme_yontemi VARCHAR(30) DEFAULT 'nakit' CHECK (odeme_yontemi IN ('nakit', 'banka', 'cek')),
    durum VARCHAR(20) DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'odendi', 'iptal')),
    onaylayan_user_id UUID REFERENCES auth.users(id),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- personel_arsiv tablosu
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

-- Eksik kolonları ekle
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

ALTER TABLE public.personel_arsiv 
ADD COLUMN IF NOT EXISTS personel_id UUID,
ADD COLUMN IF NOT EXISTS belge_turu VARCHAR(50),
ADD COLUMN IF NOT EXISTS belge_adi VARCHAR(255),
ADD COLUMN IF NOT EXISTS dosya_yolu TEXT,
ADD COLUMN IF NOT EXISTS dosya_boyutu BIGINT,
ADD COLUMN IF NOT EXISTS mime_type VARCHAR(100),
ADD COLUMN IF NOT EXISTS aciklama TEXT,
ADD COLUMN IF NOT EXISTS yukleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS yukleyen_user_id UUID,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();
