-- =============================================
-- KASA/BANKA HAREKETLERİ VERİTABANI ŞEMASI
-- Tarih: 28.06.2025
-- Açıklama: Kasa ve banka hesaplarındaki para hareketlerini takip eden tablolar
-- =============================================

-- Kasa/Banka hareketleri tablosu
CREATE TABLE IF NOT EXISTS public.kasa_banka_hareketleri (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    kasa_banka_id UUID NOT NULL REFERENCES public.kasa_banka_hesaplari(id) ON DELETE CASCADE,
    hareket_tipi VARCHAR(20) NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'transfer_giden', 'transfer_gelen')),
    tutar DECIMAL(15,2) NOT NULL CHECK (tutar > 0),
    para_birimi VARCHAR(3) NOT NULL DEFAULT 'TRY' CHECK (para_birimi IN ('TRY', 'USD', 'EUR', 'GBP')),
    aciklama TEXT,
    kategori VARCHAR(20) CHECK (kategori IN ('fatura_odeme', 'nakit_giris', 'bank_transfer', 'operasyonel', 'diger')),
    fatura_id UUID REFERENCES public.faturalar(id) ON DELETE SET NULL,
    transfer_kasa_banka_id UUID REFERENCES public.kasa_banka_hesaplari(id) ON DELETE SET NULL,
    referans_no VARCHAR(50),
    islem_tarihi TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    olusturma_tarihi TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    olusturan_kullanici VARCHAR(100),
    onaylanmis_mi BOOLEAN NOT NULL DEFAULT FALSE,
    onaylayan_kullanici VARCHAR(100),
    onaylama_tarihi TIMESTAMP WITH TIME ZONE,
    notlar TEXT,
    
    -- Constraints
    CONSTRAINT valid_transfer_account CHECK (
        (hareket_tipi IN ('transfer_giden', 'transfer_gelen') AND transfer_kasa_banka_id IS NOT NULL) OR
        (hareket_tipi IN ('giris', 'cikis'))
    ),
    CONSTRAINT valid_fatura_payment CHECK (
        (kategori = 'fatura_odeme' AND fatura_id IS NOT NULL) OR
        (kategori != 'fatura_odeme')
    ),
    CONSTRAINT different_transfer_accounts CHECK (
        kasa_banka_id != transfer_kasa_banka_id OR transfer_kasa_banka_id IS NULL
    )
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_hesap_id ON public.kasa_banka_hareketleri(kasa_banka_id);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_islem_tarihi ON public.kasa_banka_hareketleri(islem_tarihi);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_hareket_tipi ON public.kasa_banka_hareketleri(hareket_tipi);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_kategori ON public.kasa_banka_hareketleri(kategori);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_fatura_id ON public.kasa_banka_hareketleri(fatura_id);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_transfer_id ON public.kasa_banka_hareketleri(transfer_kasa_banka_id);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_referans_no ON public.kasa_banka_hareketleri(referans_no);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_onay_durumu ON public.kasa_banka_hareketleri(onaylanmis_mi);

-- RLS Politikaları
ALTER TABLE public.kasa_banka_hareketleri ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar kendi şirketlerinin hareketlerini görüntüleyebilir
CREATE POLICY "Kullanıcılar kendi şirketlerinin hareketlerini görebilir" 
ON public.kasa_banka_hareketleri FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.kasa_banka_hesaplari kb
        WHERE kb.id = kasa_banka_id
        AND kb.sirket_id = (
            SELECT sirket_id FROM public.kullanicilar 
            WHERE auth_user_id = auth.uid()
        )
    )
);

-- Yetkili kullanıcılar hareket ekleyebilir
CREATE POLICY "Yetkili kullanıcılar hareket ekleyebilir" 
ON public.kasa_banka_hareketleri FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.kullanicilar k
        WHERE k.auth_user_id = auth.uid()
        AND k.rol IN ('admin', 'muhasebe', 'finans')
        AND EXISTS (
            SELECT 1 FROM public.kasa_banka_hesaplari kb
            WHERE kb.id = kasa_banka_id
            AND kb.sirket_id = k.sirket_id
        )
    )
);

-- Yetkili kullanıcılar hareket güncelleyebilir
CREATE POLICY "Yetkili kullanıcılar hareket güncelleyebilir" 
ON public.kasa_banka_hareketleri FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM public.kullanicilar k
        WHERE k.auth_user_id = auth.uid()
        AND k.rol IN ('admin', 'muhasebe', 'finans')
        AND EXISTS (
            SELECT 1 FROM public.kasa_banka_hesaplari kb
            WHERE kb.id = kasa_banka_id
            AND kb.sirket_id = k.sirket_id
        )
    )
) WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.kullanicilar k
        WHERE k.auth_user_id = auth.uid()
        AND k.rol IN ('admin', 'muhasebe', 'finans')
        AND EXISTS (
            SELECT 1 FROM public.kasa_banka_hesaplari kb
            WHERE kb.id = kasa_banka_id
            AND kb.sirket_id = k.sirket_id
        )
    )
);

-- Sadece admin kullanıcıları hareket silebilir
CREATE POLICY "Sadece admin kullanıcıları hareket silebilir" 
ON public.kasa_banka_hareketleri FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM public.kullanicilar k
        WHERE k.auth_user_id = auth.uid()
        AND k.rol = 'admin'
        AND EXISTS (
            SELECT 1 FROM public.kasa_banka_hesaplari kb
            WHERE kb.id = kasa_banka_id
            AND kb.sirket_id = k.sirket_id
        )
    )
);

-- =============================================
-- BAKIYE HESAPLAMA FONKSİYONU
-- =============================================

-- Hesap bakiyesini hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION calculate_account_balance(account_id UUID, until_date TIMESTAMP WITH TIME ZONE DEFAULT NOW())
RETURNS DECIMAL(15,2) AS $$
DECLARE
    total_giris DECIMAL(15,2) := 0;
    total_cikis DECIMAL(15,2) := 0;
    balance DECIMAL(15,2) := 0;
BEGIN
    -- Giriş hareketlerini topla
    SELECT COALESCE(SUM(tutar), 0) INTO total_giris
    FROM public.kasa_banka_hareketleri
    WHERE kasa_banka_id = account_id
    AND hareket_tipi IN ('giris', 'transfer_gelen')
    AND onaylanmis_mi = TRUE
    AND islem_tarihi <= until_date;
    
    -- Çıkış hareketlerini topla
    SELECT COALESCE(SUM(tutar), 0) INTO total_cikis
    FROM public.kasa_banka_hareketleri
    WHERE kasa_banka_id = account_id
    AND hareket_tipi IN ('cikis', 'transfer_giden')
    AND onaylanmis_mi = TRUE
    AND islem_tarihi <= until_date;
    
    balance := total_giris - total_cikis;
    
    RETURN balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- HAREKET ÖZETİ VİEW'İ
-- =============================================

-- Hareket özetlerini gösteren view
CREATE OR REPLACE VIEW public.kasa_banka_hareket_ozeti AS
SELECT 
    h.kasa_banka_id,
    kb.adi as hesap_adi,
    kb.turu as hesap_turu,
    kb.para_birimi,
    COUNT(*) as toplam_hareket_sayisi,
    COUNT(CASE WHEN h.hareket_tipi IN ('giris', 'transfer_gelen') THEN 1 END) as giris_sayisi,
    COUNT(CASE WHEN h.hareket_tipi IN ('cikis', 'transfer_giden') THEN 1 END) as cikis_sayisi,
    COALESCE(SUM(CASE WHEN h.hareket_tipi IN ('giris', 'transfer_gelen') AND h.onaylanmis_mi THEN h.tutar END), 0) as toplam_giris,
    COALESCE(SUM(CASE WHEN h.hareket_tipi IN ('cikis', 'transfer_giden') AND h.onaylanmis_mi THEN h.tutar END), 0) as toplam_cikis,
    calculate_account_balance(h.kasa_banka_id) as guncel_bakiye,
    MAX(h.islem_tarihi) as son_hareket_tarihi
FROM public.kasa_banka_hareketleri h
INNER JOIN public.kasa_banka_hesaplari kb ON kb.id = h.kasa_banka_id
GROUP BY h.kasa_banka_id, kb.adi, kb.turu, kb.para_birimi;

-- View için RLS politikası
ALTER VIEW public.kasa_banka_hareket_ozeti SET (security_invoker = true);

-- =============================================
-- TRIGGER FONKSİYONLARI
-- =============================================

-- Hareket onaylandığında bakiye güncelleme trigger'ı
CREATE OR REPLACE FUNCTION update_account_balance_on_approval()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer onay durumu değişmişse bakiye güncelleme yapılabilir
    IF OLD.onaylanmis_mi != NEW.onaylanmis_mi THEN
        -- Burada gerekirse ek işlemler yapılabilir
        -- Örneğin bildirim gönderme, log kaydetme vb.
        NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluştur
DROP TRIGGER IF EXISTS trigger_update_balance_on_approval ON public.kasa_banka_hareketleri;
CREATE TRIGGER trigger_update_balance_on_approval
    AFTER UPDATE ON public.kasa_banka_hareketleri
    FOR EACH ROW
    WHEN (OLD.onaylanmis_mi IS DISTINCT FROM NEW.onaylanmis_mi)
    EXECUTE FUNCTION update_account_balance_on_approval();

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Hareket kategorisi istatistiklerini getiren fonksiyon
CREATE OR REPLACE FUNCTION get_hareket_kategori_istatistikleri(
    account_id UUID,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() - INTERVAL '1 month',
    end_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS TABLE (
    kategori VARCHAR(20),
    hareket_sayisi BIGINT,
    toplam_tutar DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.kategori,
        COUNT(*) as hareket_sayisi,
        COALESCE(SUM(h.tutar), 0) as toplam_tutar
    FROM public.kasa_banka_hareketleri h
    WHERE h.kasa_banka_id = account_id
    AND h.islem_tarihi BETWEEN start_date AND end_date
    AND h.onaylanmis_mi = TRUE
    AND h.hareket_tipi IN ('cikis', 'transfer_giden')
    GROUP BY h.kategori
    ORDER BY toplam_tutar DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Günlük hareket özetini getiren fonksiyon
CREATE OR REPLACE FUNCTION get_gunluk_hareket_ozeti(
    account_id UUID,
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    tarih DATE,
    toplam_giris DECIMAL(15,2),
    toplam_cikis DECIMAL(15,2),
    net_hareket DECIMAL(15,2),
    hareket_sayisi BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.islem_tarihi::DATE as tarih,
        COALESCE(SUM(CASE WHEN h.hareket_tipi IN ('giris', 'transfer_gelen') THEN h.tutar END), 0) as toplam_giris,
        COALESCE(SUM(CASE WHEN h.hareket_tipi IN ('cikis', 'transfer_giden') THEN h.tutar END), 0) as toplam_cikis,
        COALESCE(SUM(CASE WHEN h.hareket_tipi IN ('giris', 'transfer_gelen') THEN h.tutar END), 0) - 
        COALESCE(SUM(CASE WHEN h.hareket_tipi IN ('cikis', 'transfer_giden') THEN h.tutar END), 0) as net_hareket,
        COUNT(*) as hareket_sayisi
    FROM public.kasa_banka_hareketleri h
    WHERE h.kasa_banka_id = account_id
    AND h.islem_tarihi::DATE BETWEEN start_date AND end_date
    AND h.onaylanmis_mi = TRUE
    GROUP BY h.islem_tarihi::DATE
    ORDER BY tarih DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Commit the changes
COMMIT;
