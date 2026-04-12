-- Basit tablo oluşturma scripti
CREATE TABLE IF NOT EXISTS sirket_bilgileri (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    unvan TEXT NOT NULL,
    vergi_no TEXT NOT NULL UNIQUE,
    vergi_dairesi TEXT NOT NULL,
    mersis_no TEXT,
    sicil_no TEXT,
    sgk_sicil_no TEXT NOT NULL,
    adres TEXT NOT NULL,
    telefon TEXT NOT NULL,
    email TEXT NOT NULL,
    yetkili TEXT,
    faaliyet TEXT,
    kurulus_yili TEXT,
    iban TEXT,
    banka TEXT,
    web TEXT,
    olusturulma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sistem_ayarlari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    anahtar TEXT NOT NULL UNIQUE,
    deger TEXT NOT NULL,
    aciklama TEXT,
    tip TEXT DEFAULT 'genel',
    olusturulma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gelir_vergisi_dilimleri (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    yil INTEGER NOT NULL,
    dilim_no INTEGER NOT NULL,
    alt_limit DECIMAL(15,2) NOT NULL,
    ust_limit DECIMAL(15,2),
    vergi_orani DECIMAL(5,2) NOT NULL,
    olusturulma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(yil, dilim_no)
);
