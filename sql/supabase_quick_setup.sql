--======================================================================
-- Supabase SQL Tabloları Oluşturma ve Test Etme
--======================================================================

-- 1. Tabloları oluştur
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

-- 2. Varsayılan sistem ayarlarını ekle
INSERT INTO sistem_ayarlari (anahtar, deger, aciklama, tip) VALUES
('asgari_ucret', '17002.0', '2024 Asgari Ücret (TL)', 'yasal'),
('sgk_tavani', '149265.0', '2024 SGK Primi Tavanı (TL)', 'yasal'),
('sgk_isci_prim_orani', '14.0', 'SGK İşçi Prim Oranı (%)', 'yasal'),
('sgk_isveren_prim_orani', '20.5', 'SGK İşveren Prim Oranı (%)', 'yasal'),
('issizlik_isci_prim_orani', '1.0', 'İşsizlik İşçi Prim Oranı (%)', 'yasal'),
('issizlik_isveren_prim_orani', '2.0', 'İşsizlik İşveren Prim Oranı (%)', 'yasal'),
('damga_vergisi_orani', '0.759', 'Damga Vergisi Oranı (‰)', 'yasal'),
('isg_prim_orani', '0.1', 'İş Sağlığı Güvenliği Prim Oranı (‰)', 'yasal'),
('mesai_carpani', '1.5', 'Mesai Saati Çarpanı', 'sirket'),
('bayram_carpani', '2.0', 'Bayram Günü Çarpanı', 'sirket'),
('gunluk_calisma_saati', '8', 'Günlük Normal Çalışma Saati', 'sirket'),
('haftalik_calisma_gunu', '5', 'Haftalık Çalışma Günü', 'sirket'),
('yillik_izin_gunu', '14', 'Yıllık İzin Gün Sayısı', 'sirket'),
('dogum_izni_var', 'true', 'Doğum İzni Aktif', 'sirket'),
('evlilik_izni_var', 'true', 'Evlilik İzni Aktif', 'sirket'),
('olum_izni_var', 'true', 'Ölüm İzni Aktif', 'sirket'),
('agi_bir_kere_uygula', 'true', 'AGİ Bir Kere Uygula', 'sirket'),
('ssk_5510_kapsaminda', 'true', '5510 Sayılı Kanun Kapsamında', 'sirket')
ON CONFLICT (anahtar) DO NOTHING;

-- 3. Test verilerini kontrol et
SELECT 'Sistem Ayarları:' as tablo_adi, COUNT(*) as kayit_sayisi FROM sistem_ayarlari
UNION ALL
SELECT 'Şirket Bilgileri:' as tablo_adi, COUNT(*) as kayit_sayisi FROM sirket_bilgileri;

-- 4. Tüm sistem ayarlarını listele
SELECT anahtar, deger, aciklama, tip FROM sistem_ayarlari ORDER BY tip, anahtar;
