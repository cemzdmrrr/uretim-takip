-- İplik Siparişleri Tablosu Oluşturma
-- Bu SQL kodunu Supabase SQL Editor'de çalıştırın

-- İplik siparişleri tablosunu oluştur
CREATE TABLE IF NOT EXISTS public.iplik_siparisleri (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    siparis_no VARCHAR(50) UNIQUE NOT NULL,
    tedarikci_id INTEGER REFERENCES public.tedarikciler(id) ON DELETE SET NULL,
    iplik_adi VARCHAR(255) NOT NULL,
    renk VARCHAR(100),
    miktar DECIMAL(10,3) NOT NULL CHECK (miktar > 0),
    birim VARCHAR(20) DEFAULT 'kg',
    birim_fiyat DECIMAL(10,2),
    para_birimi VARCHAR(5) DEFAULT 'TL' CHECK (para_birimi IN ('TL', 'USD', 'EUR')),
    toplam_tutar DECIMAL(12,2),
    termin_tarihi DATE,
    siparis_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    durum VARCHAR(20) DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'uretimde', 'hazir', 'teslim_edildi', 'iptal')),
    aciklama TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- İndeksler oluştur
CREATE INDEX IF NOT EXISTS idx_iplik_siparisleri_siparis_no ON public.iplik_siparisleri (siparis_no);
CREATE INDEX IF NOT EXISTS idx_iplik_siparisleri_tedarikci ON public.iplik_siparisleri (tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_iplik_siparisleri_durum ON public.iplik_siparisleri (durum);
CREATE INDEX IF NOT EXISTS idx_iplik_siparisleri_siparis_tarihi ON public.iplik_siparisleri (siparis_tarihi DESC);
CREATE INDEX IF NOT EXISTS idx_iplik_siparisleri_termin_tarihi ON public.iplik_siparisleri (termin_tarihi);

-- RLS (Row Level Security) etkinleştir
ALTER TABLE public.iplik_siparisleri ENABLE ROW LEVEL SECURITY;

-- RLS politikaları oluştur
CREATE POLICY "Herkes iplik siparişlerini görebilir" ON public.iplik_siparisleri
    FOR SELECT USING (true);

CREATE POLICY "Authenticated kullanıcılar iplik siparişi ekleyebilir" ON public.iplik_siparisleri
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated kullanıcılar iplik siparişlerini güncelleyebilir" ON public.iplik_siparisleri
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated kullanıcılar iplik siparişlerini silebilir" ON public.iplik_siparisleri
    FOR DELETE USING (auth.role() = 'authenticated');

-- Trigger fonksiyonu oluştur (updated_at otomatik güncelleme için)
CREATE OR REPLACE FUNCTION update_iplik_siparisleri_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS update_iplik_siparisleri_updated_at ON public.iplik_siparisleri;
CREATE TRIGGER update_iplik_siparisleri_updated_at
    BEFORE UPDATE ON public.iplik_siparisleri
    FOR EACH ROW
    EXECUTE FUNCTION update_iplik_siparisleri_updated_at();

-- Toplam tutar otomatik hesaplama trigger'ı
CREATE OR REPLACE FUNCTION calculate_iplik_siparis_toplam()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.miktar IS NOT NULL AND NEW.birim_fiyat IS NOT NULL THEN
        NEW.toplam_tutar = NEW.miktar * NEW.birim_fiyat;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Toplam tutar hesaplama trigger'ı
DROP TRIGGER IF EXISTS calculate_iplik_siparis_toplam ON public.iplik_siparisleri;
CREATE TRIGGER calculate_iplik_siparis_toplam
    BEFORE INSERT OR UPDATE ON public.iplik_siparisleri
    FOR EACH ROW
    EXECUTE FUNCTION calculate_iplik_siparis_toplam();

-- Test verisi (isteğe bağlı - silebilirsiniz)
-- INSERT INTO public.iplik_siparisleri (
--     siparis_no, 
--     iplik_adi, 
--     renk, 
--     miktar, 
--     birim_fiyat, 
--     para_birimi,
--     termin_tarihi,
--     durum,
--     aciklama
-- ) VALUES (
--     'SIP' || EXTRACT(EPOCH FROM NOW())::INTEGER,
--     'Pamuk İplik 30/1',
--     'Ekru',
--     100.0,
--     15.50,
--     'TL',
--     CURRENT_DATE + INTERVAL '14 days',
--     'beklemede',
--     'Test sipariş kaydı'
-- );

COMMENT ON TABLE public.iplik_siparisleri IS 'İplik siparişleri tablosu - tedarikçilerden sipariş edilen ipliklerin takibi';
COMMENT ON COLUMN public.iplik_siparisleri.siparis_no IS 'Benzersiz sipariş numarası';
COMMENT ON COLUMN public.iplik_siparisleri.tedarikci_id IS 'Siparişin verildiği tedarikçi';
COMMENT ON COLUMN public.iplik_siparisleri.durum IS 'Sipariş durumu: beklemede, onaylandi, uretimde, hazir, teslim_edildi, iptal';
COMMENT ON COLUMN public.iplik_siparisleri.termin_tarihi IS 'Siparişin teslim edilmesi gereken tarih';
COMMENT ON COLUMN public.iplik_siparisleri.toplam_tutar IS 'Miktar x Birim Fiyat (otomatik hesaplanır)';
