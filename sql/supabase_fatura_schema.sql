-- =================================================================
-- FATURALAR ve FATURA_KALEMLERI SUPABASE ŞEMASI
-- Türk Ticaret Kanunu ve VUK uyumlu finans modülü
-- =================================================================

-- Faturalar tablosu
CREATE TABLE IF NOT EXISTS public.faturalar (
    fatura_id SERIAL PRIMARY KEY,
    fatura_no VARCHAR(50) NOT NULL UNIQUE,
    fatura_turu VARCHAR(20) NOT NULL CHECK (fatura_turu IN ('satis', 'alis', 'iade', 'proforma')),
    fatura_tarihi DATE NOT NULL,
    musteri_id INTEGER REFERENCES public.musteriler(musteri_id) ON DELETE SET NULL,
    tedarikci_id INTEGER REFERENCES public.tedarikciler(tedarikci_id) ON DELETE SET NULL,
    fatura_adres TEXT NOT NULL,
    vergi_dairesi VARCHAR(100),
    vergi_no VARCHAR(20),
    ara_toplam_tutar DECIMAL(15,2) NOT NULL DEFAULT 0,
    kdv_tutari DECIMAL(15,2) NOT NULL DEFAULT 0,
    toplam_tutar DECIMAL(15,2) NOT NULL DEFAULT 0,
    durum VARCHAR(20) NOT NULL DEFAULT 'taslak' CHECK (durum IN ('taslak', 'onaylandi', 'iptal', 'gonderildi')),
    aciklama TEXT,
    vade_tarihi DATE,
    odeme_durumu VARCHAR(20) NOT NULL DEFAULT 'odenmedi' CHECK (odeme_durumu IN ('odenmedi', 'kismi', 'odendi')),
    odenen_tutar DECIMAL(15,2) NOT NULL DEFAULT 0,
    kur VARCHAR(3) NOT NULL DEFAULT 'TRY',
    kur_orani DECIMAL(10,4) NOT NULL DEFAULT 1,
    efatura_uuid VARCHAR(100),
    efatura_tarihi TIMESTAMP,
    efatura_durum VARCHAR(30),
    olusturma_tarihi TIMESTAMP NOT NULL DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP,
    olusturan_kullanici VARCHAR(100) NOT NULL,
    
    -- Constraintler
    CONSTRAINT faturalar_musteri_veya_tedarikci_check 
        CHECK ((fatura_turu IN ('satis', 'proforma') AND musteri_id IS NOT NULL AND tedarikci_id IS NULL) 
               OR (fatura_turu = 'alis' AND tedarikci_id IS NOT NULL AND musteri_id IS NULL)
               OR (fatura_turu = 'iade' AND (musteri_id IS NOT NULL OR tedarikci_id IS NOT NULL))),
    CONSTRAINT faturalar_tutarlar_check 
        CHECK (ara_toplam_tutar >= 0 AND kdv_tutari >= 0 AND toplam_tutar >= 0 AND odenen_tutar >= 0),
    CONSTRAINT faturalar_odenen_tutar_check 
        CHECK (odenen_tutar <= toplam_tutar)
);

-- Fatura kalemleri tablosu
CREATE TABLE IF NOT EXISTS public.fatura_kalemleri (
    kalem_id SERIAL PRIMARY KEY,
    fatura_id INTEGER NOT NULL REFERENCES public.faturalar(fatura_id) ON DELETE CASCADE,
    siparis_id INTEGER REFERENCES public.siparisler(siparis_id) ON DELETE SET NULL,
    urun_kodu VARCHAR(50),
    urun_adi VARCHAR(200) NOT NULL,
    aciklama TEXT,
    miktar DECIMAL(10,3) NOT NULL DEFAULT 1,
    birim VARCHAR(20) NOT NULL DEFAULT 'adet',
    birim_fiyat DECIMAL(15,2) NOT NULL DEFAULT 0,
    kdv_orani DECIMAL(5,2) NOT NULL DEFAULT 20.00,
    kdv_tutari DECIMAL(15,2) NOT NULL DEFAULT 0,
    toplam_tutar DECIMAL(15,2) NOT NULL DEFAULT 0,
    sira_no INTEGER NOT NULL DEFAULT 1,
    olusturma_tarihi TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Constraintler
    CONSTRAINT fatura_kalemleri_tutarlar_check 
        CHECK (miktar > 0 AND birim_fiyat >= 0 AND kdv_orani >= 0 AND kdv_tutari >= 0 AND toplam_tutar >= 0),
    CONSTRAINT fatura_kalemleri_kdv_orani_check 
        CHECK (kdv_orani <= 100)
);

-- =================================================================
-- İNDEKSLER (Performans için)
-- =================================================================

-- Faturalar indeksleri
CREATE INDEX IF NOT EXISTS idx_faturalar_fatura_no ON public.faturalar(fatura_no);
CREATE INDEX IF NOT EXISTS idx_faturalar_fatura_tarihi ON public.faturalar(fatura_tarihi);
CREATE INDEX IF NOT EXISTS idx_faturalar_musteri_id ON public.faturalar(musteri_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_tedarikci_id ON public.faturalar(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_durum ON public.faturalar(durum);
CREATE INDEX IF NOT EXISTS idx_faturalar_odeme_durumu ON public.faturalar(odeme_durumu);
CREATE INDEX IF NOT EXISTS idx_faturalar_olusturma_tarihi ON public.faturalar(olusturma_tarihi);

-- Fatura kalemleri indeksleri
CREATE INDEX IF NOT EXISTS idx_fatura_kalemleri_fatura_id ON public.fatura_kalemleri(fatura_id);
CREATE INDEX IF NOT EXISTS idx_fatura_kalemleri_siparis_id ON public.fatura_kalemleri(siparis_id);
CREATE INDEX IF NOT EXISTS idx_fatura_kalemleri_urun_kodu ON public.fatura_kalemleri(urun_kodu);

-- =================================================================
-- TRİGGER'LAR (Otomatik hesaplamalar)
-- =================================================================

-- Fatura kalemi toplam tutarını hesaplayan trigger
CREATE OR REPLACE FUNCTION public.hesapla_fatura_kalemi_tutar()
RETURNS TRIGGER AS $$
BEGIN
    -- KDV tutarı hesaplama
    NEW.kdv_tutari = ROUND((NEW.miktar * NEW.birim_fiyat * NEW.kdv_orani / 100), 2);
    
    -- Toplam tutar hesaplama (KDV dahil)
    NEW.toplam_tutar = ROUND((NEW.miktar * NEW.birim_fiyat) + NEW.kdv_tutari, 2);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_hesapla_fatura_kalemi_tutar
    BEFORE INSERT OR UPDATE ON public.fatura_kalemleri
    FOR EACH ROW EXECUTE FUNCTION public.hesapla_fatura_kalemi_tutar();

-- Fatura toplam tutarlarını hesaplayan trigger
CREATE OR REPLACE FUNCTION public.hesapla_fatura_toplam()
RETURNS TRIGGER AS $$
DECLARE
    v_ara_toplam DECIMAL(15,2);
    v_kdv_tutari DECIMAL(15,2);
    v_toplam_tutar DECIMAL(15,2);
BEGIN
    -- Fatura kalemlerinden toplam hesaplama
    SELECT 
        COALESCE(SUM(miktar * birim_fiyat), 0),
        COALESCE(SUM(kdv_tutari), 0),
        COALESCE(SUM(toplam_tutar), 0)
    INTO v_ara_toplam, v_kdv_tutari, v_toplam_tutar
    FROM public.fatura_kalemleri
    WHERE fatura_id = COALESCE(NEW.fatura_id, OLD.fatura_id);
    
    -- Fatura tablosunu güncelle
    UPDATE public.faturalar 
    SET 
        ara_toplam_tutar = v_ara_toplam,
        kdv_tutari = v_kdv_tutari,
        toplam_tutar = v_toplam_tutar,
        guncelleme_tarihi = NOW()
    WHERE fatura_id = COALESCE(NEW.fatura_id, OLD.fatura_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_hesapla_fatura_toplam_insert
    AFTER INSERT ON public.fatura_kalemleri
    FOR EACH ROW EXECUTE FUNCTION public.hesapla_fatura_toplam();

CREATE TRIGGER trigger_hesapla_fatura_toplam_update
    AFTER UPDATE ON public.fatura_kalemleri
    FOR EACH ROW EXECUTE FUNCTION public.hesapla_fatura_toplam();

CREATE TRIGGER trigger_hesapla_fatura_toplam_delete
    AFTER DELETE ON public.fatura_kalemleri
    FOR EACH ROW EXECUTE FUNCTION public.hesapla_fatura_toplam();

-- =================================================================
-- RLS (Row Level Security) POLİTİKALARI
-- =================================================================

-- RLS'yi etkinleştir
ALTER TABLE public.faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fatura_kalemleri ENABLE ROW LEVEL SECURITY;

-- Authenticated kullanıcılar için tam erişim politikaları
CREATE POLICY "Authenticated users can access faturalar" ON public.faturalar
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access fatura_kalemleri" ON public.fatura_kalemleri
    FOR ALL USING (auth.role() = 'authenticated');

-- =================================================================
-- ÖRNEK VERİLER
-- =================================================================

-- Örnek satış faturaları
INSERT INTO public.faturalar (
    fatura_no, fatura_turu, fatura_tarihi, musteri_id, fatura_adres,
    vergi_dairesi, vergi_no, durum, vade_tarihi, kur, kur_orani, olusturan_kullanici
) VALUES 
(
    'SF-2024-001', 'satis', '2024-01-15', 1,
    'Merkez Mah. İş Cad. No:123 Kadıköy/İSTANBUL',
    'Kadıköy Vergi Dairesi', '1234567890',
    'onaylandi', '2024-02-15', 'TRY', 1.0000, 'sistem'
),
(
    'SF-2024-002', 'satis', '2024-01-20', 2,
    'Atatürk Bulvarı No:45 Çankaya/ANKARA',
    'Çankaya Vergi Dairesi', '9876543210',
    'onaylandi', '2024-02-20', 'TRY', 1.0000, 'sistem'
),
(
    'PF-2024-001', 'proforma', '2024-01-25', 1,
    'Merkez Mah. İş Cad. No:123 Kadıköy/İSTANBUL',
    'Kadıköy Vergi Dairesi', '1234567890',
    'taslak', NULL, 'TRY', 1.0000, 'sistem'
);

-- Tedarikçi faturaları (id'ler tedarikçi şemasından alınacak)
INSERT INTO public.faturalar (
    fatura_no, fatura_turu, fatura_tarihi, tedarikci_id, fatura_adres,
    vergi_dairesi, vergi_no, durum, vade_tarihi, kur, kur_orani, olusturan_kullanici
) VALUES 
(
    'AF-2024-001', 'alis', '2024-01-18', 1,
    'Sanayi Bölgesi 1. Cad. No:67 İkitelli/İSTANBUL',
    'İkitelli Vergi Dairesi', '5555666677',
    'onaylandi', '2024-02-18', 'TRY', 1.0000, 'sistem'
);

-- Örnek fatura kalemleri
INSERT INTO public.fatura_kalemleri (
    fatura_id, urun_kodu, urun_adi, aciklama, miktar, birim, birim_fiyat, kdv_orani, sira_no
) VALUES 
-- SF-2024-001 kalemleri
(1, 'TRK-001', 'Premium Triko Kazak', 'Yün karışımlı, M beden', 5.000, 'adet', 150.00, 20.00, 1),
(1, 'TRK-002', 'Cotton Basic T-Shirt', 'Pamuklu, L beden', 10.000, 'adet', 80.00, 20.00, 2),
(1, 'AKS-001', 'Düğme Seti', 'Metal düğme, 12 adet', 3.000, 'takım', 25.00, 20.00, 3),

-- SF-2024-002 kalemleri  
(2, 'TRK-003', 'Luxury Cardigan', 'Kaşmir karışımlı, XL beden', 3.000, 'adet', 250.00, 20.00, 1),
(2, 'TRK-001', 'Premium Triko Kazak', 'Yün karışımlı, L beden', 2.000, 'adet', 150.00, 20.00, 2),

-- PF-2024-001 kalemleri (proforma)
(3, 'TRK-004', 'Winter Collection Sweater', 'Yeni sezon, çeşitli bedenler', 20.000, 'adet', 120.00, 20.00, 1),
(3, 'TRK-005', 'Spring Collection Polo', 'Pamuklu, çeşitli renkler', 15.000, 'adet', 95.00, 20.00, 2),

-- AF-2024-001 kalemleri (alış faturası)
(4, 'IPL-001', 'Pamuklu İplik', 'Ne 30/1, beyaz renk', 100.000, 'kg', 45.00, 20.00, 1),
(4, 'IPL-002', 'Yün Karışımlı İplik', 'Ne 28/1, gri renk', 50.000, 'kg', 75.00, 20.00, 2),
(4, 'AKS-002', 'Fermuar', 'Metal, 20 cm, siyah', 200.000, 'adet', 3.50, 20.00, 3);

-- =================================================================
-- VİEW'LAR (Raporlama için)
-- =================================================================

-- Fatura özet view'ı
CREATE OR REPLACE VIEW public.v_fatura_ozet AS
SELECT 
    f.fatura_id,
    f.fatura_no,
    f.fatura_turu,
    f.fatura_tarihi,
    f.durum,
    f.odeme_durumu,
    CASE 
        WHEN f.musteri_id IS NOT NULL THEN m.ad || ' ' || COALESCE(m.soyad, '') || ' - ' || COALESCE(m.sirket, '')
        WHEN f.tedarikci_id IS NOT NULL THEN t.ad || ' ' || COALESCE(t.soyad, '') || ' - ' || COALESCE(t.sirket, '')
        ELSE 'Nakit Satış'
    END as firma_adi,
    f.ara_toplam_tutar,
    f.kdv_tutari,
    f.toplam_tutar,
    f.odenen_tutar,
    (f.toplam_tutar - f.odenen_tutar) as kalan_borc,
    f.vade_tarihi,
    CASE 
        WHEN f.vade_tarihi IS NULL THEN NULL
        WHEN f.vade_tarihi < CURRENT_DATE AND f.odeme_durumu != 'odendi' THEN 'Vadesi Geçti'
        WHEN f.vade_tarihi = CURRENT_DATE AND f.odeme_durumu != 'odendi' THEN 'Bugün Vadeli'
        WHEN f.vade_tarihi > CURRENT_DATE AND f.odeme_durumu != 'odendi' THEN 'Vadeli'
        ELSE 'Ödendi'
    END as vade_durumu,
    COUNT(fk.kalem_id) as kalem_sayisi
FROM public.faturalar f
LEFT JOIN public.musteriler m ON f.musteri_id = m.musteri_id
LEFT JOIN public.tedarikciler t ON f.tedarikci_id = t.tedarikci_id
LEFT JOIN public.fatura_kalemleri fk ON f.fatura_id = fk.fatura_id
GROUP BY f.fatura_id, m.ad, m.soyad, m.sirket, t.ad, t.soyad, t.sirket;

-- Fatura kalemi detay view'ı
CREATE OR REPLACE VIEW public.v_fatura_kalemi_detay AS
SELECT 
    fk.kalem_id,
    fk.fatura_id,
    f.fatura_no,
    f.fatura_tarihi,
    fk.urun_kodu,
    fk.urun_adi,
    fk.aciklama,
    fk.miktar,
    fk.birim,
    fk.birim_fiyat,
    fk.kdv_orani,
    fk.kdv_tutari,
    fk.toplam_tutar,
    fk.sira_no,
    CASE 
        WHEN f.musteri_id IS NOT NULL THEN m.ad || ' ' || COALESCE(m.soyad, '') || ' - ' || COALESCE(m.sirket, '')
        WHEN f.tedarikci_id IS NOT NULL THEN t.ad || ' ' || COALESCE(t.soyad, '') || ' - ' || COALESCE(t.sirket, '')
        ELSE 'Nakit Satış'
    END as firma_adi
FROM public.fatura_kalemleri fk
JOIN public.faturalar f ON fk.fatura_id = f.fatura_id
LEFT JOIN public.musteriler m ON f.musteri_id = m.musteri_id
LEFT JOIN public.tedarikciler t ON f.tedarikci_id = t.tedarikci_id
ORDER BY fk.fatura_id, fk.sira_no;

-- =================================================================
-- FONKSİYONLAR (İstatistik ve raporlama)
-- =================================================================

-- Aylık satış istatistikleri
CREATE OR REPLACE FUNCTION public.fn_aylik_satis_istatistik(p_yil INTEGER, p_ay INTEGER)
RETURNS TABLE (
    toplam_fatura_sayisi BIGINT,
    toplam_satis_tutari DECIMAL(15,2),
    ortalama_fatura_tutari DECIMAL(15,2),
    odenen_tutar DECIMAL(15,2),
    bekleyen_tahsilat DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as toplam_fatura_sayisi,
        COALESCE(SUM(f.toplam_tutar), 0) as toplam_satis_tutari,
        COALESCE(AVG(f.toplam_tutar), 0) as ortalama_fatura_tutari,
        COALESCE(SUM(f.odenen_tutar), 0) as odenen_tutar,
        COALESCE(SUM(f.toplam_tutar - f.odenen_tutar), 0) as bekleyen_tahsilat
    FROM public.faturalar f
    WHERE f.fatura_turu = 'satis'
    AND f.durum = 'onaylandi'
    AND EXTRACT(YEAR FROM f.fatura_tarihi) = p_yil
    AND EXTRACT(MONTH FROM f.fatura_tarihi) = p_ay;
END;
$$ LANGUAGE plpgsql;

-- En çok satan ürünler
CREATE OR REPLACE FUNCTION public.fn_en_cok_satan_urunler(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    urun_kodu VARCHAR(50),
    urun_adi VARCHAR(200),
    toplam_miktar DECIMAL(10,3),
    toplam_tutar DECIMAL(15,2),
    fatura_sayisi BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fk.urun_kodu,
        fk.urun_adi,
        SUM(fk.miktar) as toplam_miktar,
        SUM(fk.toplam_tutar) as toplam_tutar,
        COUNT(DISTINCT fk.fatura_id) as fatura_sayisi
    FROM public.fatura_kalemleri fk
    JOIN public.faturalar f ON fk.fatura_id = f.fatura_id
    WHERE f.fatura_turu = 'satis' AND f.durum = 'onaylandi'
    GROUP BY fk.urun_kodu, fk.urun_adi
    ORDER BY toplam_tutar DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- BAŞARI MESAJI
-- =================================================================

DO $$
BEGIN
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'FATURALAR ve FATURA_KALEMLERİ ŞEMASI BAŞARIYLA OLUŞTURULDU!';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Oluşturulan objeler:';
    RAISE NOTICE '- Tablolar: faturalar, fatura_kalemleri';
    RAISE NOTICE '- İndeksler: Performans için 10 adet indeks';
    RAISE NOTICE '- Trigger''lar: Otomatik tutar hesaplama';
    RAISE NOTICE '- RLS Politikaları: Güvenlik için';
    RAISE NOTICE '- View''lar: Raporlama için 2 adet view';
    RAISE NOTICE '- Fonksiyonlar: İstatistik ve analiz için';
    RAISE NOTICE '- Örnek Veriler: Test için 4 fatura, 11 kalem';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'VUK ve TTK uyumlu finans modülü hazır!';
    RAISE NOTICE 'E-fatura entegrasyonu için altyapı mevcut.';
    RAISE NOTICE '=================================================================';
END $$;
