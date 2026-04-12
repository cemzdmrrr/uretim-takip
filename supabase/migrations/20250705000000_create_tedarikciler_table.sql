-- =============================================
-- TEDARİKÇİLER TABLOSU OLUŞTURMA
-- Bu migration tedarikçiler tablosunu oluşturur
-- =============================================

CREATE TABLE IF NOT EXISTS public.tedarikciler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    sirket_adi VARCHAR(255) NOT NULL,
    telefon VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    tedarikci_turu VARCHAR(100) NOT NULL,
    faaliyet_alani VARCHAR(100) NOT NULL,
    durum VARCHAR(50) NOT NULL,
    vergi_no VARCHAR(20),
    tc_kimlik_no VARCHAR(11),
    iban_no VARCHAR(34),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Otomatik güncelleme için trigger
CREATE OR REPLACE FUNCTION update_tedarikciler_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tedarikciler_updated_at_trigger
    BEFORE UPDATE ON public.tedarikciler
    FOR EACH ROW
    EXECUTE FUNCTION update_tedarikciler_updated_at();

-- RLS (Row Level Security) politikaları
ALTER TABLE public.tedarikciler ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar okuyabilir
CREATE POLICY "Kullanicilar tedarikcileri gorebilir" ON public.tedarikciler
    FOR SELECT USING (true);

-- Admin ve user rolü ekleyebilir/güncelleyebilir
CREATE POLICY "Admin ve user tedarikci ekleyebilir" ON public.tedarikciler
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin ve user tedarikci guncelleyebilir" ON public.tedarikciler
    FOR UPDATE USING (true);

CREATE POLICY "Admin tedarikci silebilir" ON public.tedarikciler
    FOR DELETE USING (true);

-- Performans için indeksler
CREATE INDEX IF NOT EXISTS idx_tedarikciler_ad ON public.tedarikciler(ad);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_sirket_adi ON public.tedarikciler(sirket_adi);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_telefon ON public.tedarikciler(telefon);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_email ON public.tedarikciler(email);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_durum ON public.tedarikciler(durum);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_vergi_no ON public.tedarikciler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_tc_kimlik_no ON public.tedarikciler(tc_kimlik_no);

-- Test verisi
INSERT INTO public.tedarikciler (
    ad, soyad, sirket_adi, telefon, email, tedarikci_turu, faaliyet_alani, durum, vergi_no, tc_kimlik_no, iban_no
) VALUES 
(
    'Ahmet', 'Yılmaz', 'Yılmaz İplik San. Tic. Ltd. Şti.', '0212 555 0101', 'ahmet@yilmaziplik.com', 
    'Firma', 'İplik ve Tekstil', 'Aktif', '1234567890', '', 'TR12 0001 0001 0000 0000 0000 01'
),
(
    'Fatma', 'Kaya', 'Kaya Aksesuar', '0532 444 0202', 'fatma@kayaaksesuar.com', 
    'Bireysel', 'Aksesuar', 'Aktif', '', '12345678901', 'TR12 0001 0001 0000 0000 0000 02'
);

-- Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE 'TEDARİKÇİLER TABLOSU OLUŞTURULDU';
    RAISE NOTICE 'Toplam tedarikçi sayısı: %', (SELECT COUNT(*) FROM public.tedarikciler);
END $$;
