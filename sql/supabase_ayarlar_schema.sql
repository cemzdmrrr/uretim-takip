-- Sistem Ayarları için SQL schema
-- Bu script Supabase'de çalıştırılmalıdır

-- 1. Şirket Bilgileri Tablosu
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

-- 2. Sistem Ayarları Tablosu (Yasal oranlar, limitler vb.)
CREATE TABLE IF NOT EXISTS sistem_ayarlari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    anahtar TEXT NOT NULL UNIQUE,
    deger TEXT NOT NULL,
    aciklama TEXT,
    tip TEXT DEFAULT 'genel' CHECK (tip IN ('yasal', 'sirket', 'genel')),
    olusturulma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Gelir Vergisi Dilimleri Tablosu
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

-- Varsayılan sistem ayarlarını ekle
INSERT INTO sistem_ayarlari (anahtar, deger, aciklama, tip) VALUES
-- Yasal Değerler (2024)
('asgari_ucret', '17002.0', '2024 Asgari Ücret (TL)', 'yasal'),
('sgk_tavani', '149265.0', '2024 SGK Primi Tavanı (TL)', 'yasal'),
('gelir_vergisi_matrahi', '110000.0', '2024 Gelir Vergisi Matrahı (TL)', 'yasal'),

-- SGK Primleri
('sgk_isci_prim_orani', '14.0', 'SGK İşçi Prim Oranı (%)', 'yasal'),
('sgk_isveren_prim_orani', '20.5', 'SGK İşveren Prim Oranı (%)', 'yasal'),

-- İşsizlik Sigortası
('issizlik_isci_prim_orani', '1.0', 'İşsizlik İşçi Prim Oranı (%)', 'yasal'),
('issizlik_isveren_prim_orani', '2.0', 'İşsizlik İşveren Prim Oranı (%)', 'yasal'),
('issizlik_devlet_prim_orani', '1.0', 'İşsizlik Devlet Prim Oranı (%)', 'yasal'),

-- Diğer Yasal Oranlar
('damga_vergisi_orani', '0.759', 'Damga Vergisi Oranı (‰)', 'yasal'),
('isg_prim_orani', '0.1', 'İş Sağlığı Güvenliği Prim Oranı (‰)', 'yasal'),

-- Çalışma Ayarları
('mesai_carpani', '1.5', 'Mesai Saati Çarpanı', 'sirket'),
('bayram_carpani', '2.0', 'Bayram Günü Çarpanı', 'sirket'),
('gunluk_calisma_saati', '8', 'Günlük Normal Çalışma Saati', 'sirket'),
('haftalik_calisma_gunu', '5', 'Haftalık Çalışma Günü', 'sirket'),

-- Bordro Ayarları
('agi_bir_kere_uygula', 'true', 'AGİ Bir Kere Uygula', 'sirket'),
('ssk_5510_kapsaminda', 'true', '5510 Sayılı Kanun Kapsamında', 'sirket'),

-- İzin Ayarları
('yillik_izin_gunu', '14', 'Yıllık İzin Gün Sayısı (Başlangıç)', 'sirket'),
('dogum_izni_var', 'true', 'Doğum İzni Aktif', 'sirket'),
('evlilik_izni_var', 'true', 'Evlilik İzni Aktif', 'sirket'),
('olum_izni_var', 'true', 'Ölüm İzni Aktif', 'sirket')

ON CONFLICT (anahtar) DO UPDATE SET
    deger = EXCLUDED.deger,
    guncelleme_tarihi = NOW();

-- 2024 Gelir Vergisi Dilimlerini ekle
INSERT INTO gelir_vergisi_dilimleri (yil, dilim_no, alt_limit, ust_limit, vergi_orani) VALUES
(2024, 1, 0, 110000, 15.0),
(2024, 2, 110000, 230000, 20.0),
(2024, 3, 230000, 580000, 27.0),
(2024, 4, 580000, 3000000, 35.0),
(2024, 5, 3000000, NULL, 40.0)
ON CONFLICT (yil, dilim_no) DO UPDATE SET
    alt_limit = EXCLUDED.alt_limit,
    ust_limit = EXCLUDED.ust_limit,
    vergi_orani = EXCLUDED.vergi_orani;

-- RLS (Row Level Security) Politikaları
ALTER TABLE sirket_bilgileri ENABLE ROW LEVEL SECURITY;
ALTER TABLE sistem_ayarlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE gelir_vergisi_dilimleri ENABLE ROW LEVEL SECURITY;

-- Admin ve IK personeli için erişim politikaları
CREATE POLICY "Admin ve IK sirket bilgilerini yönetebilir" ON sirket_bilgileri
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM kullanicilar 
            WHERE kullanicilar.id = auth.uid() 
            AND kullanicilar.rol IN ('admin', 'ik')
        )
    );

CREATE POLICY "Admin ve IK sistem ayarlarını yönetebilir" ON sistem_ayarlari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM kullanicilar 
            WHERE kullanicilar.id = auth.uid() 
            AND kullanicilar.rol IN ('admin', 'ik')
        )
    );

CREATE POLICY "Admin ve IK gelir vergisi dilimlerini yönetebilir" ON gelir_vergisi_dilimleri
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM kullanicilar 
            WHERE kullanicilar.id = auth.uid() 
            AND kullanicilar.rol IN ('admin', 'ik')
        )
    );

-- Bordro hesaplamalarında kullanılacak fonksiyonlar
CREATE OR REPLACE FUNCTION get_sistem_ayari(anahtar_p TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN (SELECT deger FROM sistem_ayarlari WHERE anahtar = anahtar_p LIMIT 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_gelir_vergisi_orani(maas DECIMAL, yil_p INTEGER DEFAULT EXTRACT(YEAR FROM NOW()))
RETURNS DECIMAL AS $$
DECLARE
    oran DECIMAL := 0;
BEGIN
    SELECT vergi_orani INTO oran
    FROM gelir_vergisi_dilimleri 
    WHERE yil = yil_p 
      AND maas >= alt_limit 
      AND (ust_limit IS NULL OR maas <= ust_limit)
    LIMIT 1;
    
    RETURN COALESCE(oran, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Hesaplama için yardımcı view
CREATE OR REPLACE VIEW v_bordro_parametreleri AS
SELECT 
    get_sistem_ayari('asgari_ucret')::DECIMAL AS asgari_ucret,
    get_sistem_ayari('sgk_tavani')::DECIMAL AS sgk_tavani,
    get_sistem_ayari('sgk_isci_prim_orani')::DECIMAL AS sgk_isci_prim_orani,
    get_sistem_ayari('sgk_isveren_prim_orani')::DECIMAL AS sgk_isveren_prim_orani,
    get_sistem_ayari('issizlik_isci_prim_orani')::DECIMAL AS issizlik_isci_prim_orani,
    get_sistem_ayari('issizlik_isveren_prim_orani')::DECIMAL AS issizlik_isveren_prim_orani,
    get_sistem_ayari('damga_vergisi_orani')::DECIMAL AS damga_vergisi_orani,
    get_sistem_ayari('isg_prim_orani')::DECIMAL AS isg_prim_orani,
    get_sistem_ayari('mesai_carpani')::DECIMAL AS mesai_carpani,
    get_sistem_ayari('bayram_carpani')::DECIMAL AS bayram_carpani;

COMMENT ON TABLE sirket_bilgileri IS 'Şirket yasal bilgileri ve iletişim detayları';
COMMENT ON TABLE sistem_ayarlari IS 'Bordro hesaplamalarında kullanılan yasal oranlar ve şirket ayarları';
COMMENT ON TABLE gelir_vergisi_dilimleri IS 'Yıllık gelir vergisi dilim ve oranları';
COMMENT ON FUNCTION get_sistem_ayari(TEXT) IS 'Sistem ayarı değerini getiren fonksiyon';
COMMENT ON FUNCTION get_gelir_vergisi_orani(DECIMAL, INTEGER) IS 'Maaşa göre gelir vergisi oranını hesaplayan fonksiyon';
COMMENT ON VIEW v_bordro_parametreleri IS 'Bordro hesaplamalarında kullanılan tüm parametreler';
