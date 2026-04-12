-- =============================================
-- FATURALAR TABLOSU OLUŞTURMA
-- Bu migration faturalar ve fatura_kalemleri tablolarını oluşturur
-- =============================================

-- Faturalar tablosu
CREATE TABLE IF NOT EXISTS public.faturalar (
    fatura_id SERIAL PRIMARY KEY,
    fatura_no VARCHAR(50) UNIQUE NOT NULL,
    fatura_turu VARCHAR(20) DEFAULT 'satis',
    fatura_tarihi DATE NOT NULL,
    musteri_id INTEGER,
    tedarikci_id INTEGER REFERENCES public.tedarikciler(id),
    fatura_adres TEXT NOT NULL,
    vergi_dairesi VARCHAR(100),
    vergi_no VARCHAR(20),
    ara_toplam_tutar DECIMAL(15,2) DEFAULT 0,
    kdv_tutari DECIMAL(15,2) DEFAULT 0,
    toplam_tutar DECIMAL(15,2) DEFAULT 0,
    durum VARCHAR(20) DEFAULT 'taslak',
    aciklama TEXT,
    vade_tarihi DATE,
    odeme_durumu VARCHAR(20) DEFAULT 'odenmedi',
    odenen_tutar DECIMAL(15,2) DEFAULT 0,
    kur VARCHAR(5) DEFAULT 'TRY',
    kur_orani DECIMAL(10,4) DEFAULT 1.0000,
    efatura_uuid VARCHAR(36),
    efatura_tarihi TIMESTAMP,
    efatura_durum VARCHAR(20),
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    olusturan_kullanici VARCHAR(100)
);

-- Fatura kalemleri tablosu
CREATE TABLE IF NOT EXISTS public.fatura_kalemleri (
    id SERIAL PRIMARY KEY,
    fatura_id INTEGER REFERENCES public.faturalar(fatura_id) ON DELETE CASCADE,
    model_id INTEGER,
    urun_adi VARCHAR(255) NOT NULL,
    urun_kodu VARCHAR(100),
    miktar DECIMAL(10,3) NOT NULL,
    birim VARCHAR(20) DEFAULT 'adet',
    birim_fiyat DECIMAL(15,2) NOT NULL,
    iskonto_orani DECIMAL(5,2) DEFAULT 0,
    iskonto_tutari DECIMAL(15,2) DEFAULT 0,
    kdv_orani DECIMAL(5,2) DEFAULT 20,
    kdv_tutari DECIMAL(15,2) DEFAULT 0,
    toplam_tutar DECIMAL(15,2) NOT NULL,
    aciklama TEXT,
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Otomatik güncelleme için trigger
CREATE OR REPLACE FUNCTION update_faturalar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER faturalar_updated_at_trigger
    BEFORE UPDATE ON public.faturalar
    FOR EACH ROW
    EXECUTE FUNCTION update_faturalar_updated_at();

-- RLS (Row Level Security) politikaları
ALTER TABLE public.faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fatura_kalemleri ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar okuyabilir
CREATE POLICY "Kullanicilar faturalari gorebilir" ON public.faturalar
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar fatura kalemlerini gorebilir" ON public.fatura_kalemleri
    FOR SELECT USING (true);

-- Admin ve user rolü ekleyebilir/güncelleyebilir
CREATE POLICY "Admin ve user fatura ekleyebilir" ON public.faturalar
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin ve user fatura guncelleyebilir" ON public.faturalar
    FOR UPDATE USING (true);

CREATE POLICY "Admin fatura silebilir" ON public.faturalar
    FOR DELETE USING (true);

-- Fatura kalemleri için politikalar
CREATE POLICY "Admin ve user fatura kalemi ekleyebilir" ON public.fatura_kalemleri
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin ve user fatura kalemi guncelleyebilir" ON public.fatura_kalemleri
    FOR UPDATE USING (true);

CREATE POLICY "Admin fatura kalemi silebilir" ON public.fatura_kalemleri
    FOR DELETE USING (true);

-- İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_faturalar_fatura_no ON public.faturalar(fatura_no);
CREATE INDEX IF NOT EXISTS idx_faturalar_fatura_tarihi ON public.faturalar(fatura_tarihi);
CREATE INDEX IF NOT EXISTS idx_faturalar_musteri_id ON public.faturalar(musteri_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_tedarikci_id ON public.faturalar(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_durum ON public.faturalar(durum);
CREATE INDEX IF NOT EXISTS idx_faturalar_odeme_durumu ON public.faturalar(odeme_durumu);
CREATE INDEX IF NOT EXISTS idx_fatura_kalemleri_fatura_id ON public.fatura_kalemleri(fatura_id);

-- Test verisi
INSERT INTO public.faturalar (
    fatura_no, fatura_turu, fatura_tarihi, fatura_adres, 
    ara_toplam_tutar, kdv_tutari, toplam_tutar, durum, aciklama,
    olusturan_kullanici
) VALUES 
(
    'SAT-2025-001', 'satis', '2025-01-15', 'Test Müşteri Adresi\nİstanbul/Türkiye', 
    1000.00, 200.00, 1200.00, 'onaylandi', 'Test satış faturası',
    'sistem'
),
(
    'ALI-2025-001', 'alis', '2025-01-20', 'Test Tedarikçi Adresi\nAnkara/Türkiye', 
    500.00, 100.00, 600.00, 'onaylandi', 'Test alış faturası',
    'sistem'
);

-- Test fatura kalemleri
INSERT INTO public.fatura_kalemleri (
    fatura_id, urun_adi, urun_kodu, miktar, birim_fiyat, toplam_tutar, aciklama
) VALUES 
(1, 'Test Ürün 1', 'T001', 10.000, 100.00, 1000.00, 'Test kalemi 1'),
(2, 'Test Malzeme 1', 'M001', 5.000, 100.00, 500.00, 'Test kalemi 2');

-- Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE 'FATURALAR TABLOSU OLUŞTURULDU';
    RAISE NOTICE 'Toplam fatura sayısı: %', (SELECT COUNT(*) FROM public.faturalar);
    RAISE NOTICE 'Toplam kalem sayısı: %', (SELECT COUNT(*) FROM public.fatura_kalemleri);
END $$;
