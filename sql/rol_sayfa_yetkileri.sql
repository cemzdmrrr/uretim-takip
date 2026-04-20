-- Rol bazlı sayfa yetkileri tablosu
-- Her role hangi sayfaları görebileceğini tanımlar

CREATE TABLE IF NOT EXISTS public.rol_sayfa_yetkileri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
    rol TEXT NOT NULL, -- 'kullanici', 'personel', 'yonetici', vb.
    sayfa_kodu TEXT NOT NULL, -- 'genel_uretim', 'dokuma', vb.
    aktif BOOLEAN DEFAULT true,
    olusturulma_zamani TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_zamani TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Aynı firma için aynı rol-sayfa kombinasyonu sadece bir kez olabilir
    UNIQUE(firma_id, rol, sayfa_kodu)
);

-- Index'ler
CREATE INDEX IF NOT EXISTS idx_rol_sayfa_yetkileri_firma ON public.rol_sayfa_yetkileri(firma_id);
CREATE INDEX IF NOT EXISTS idx_rol_sayfa_yetkileri_rol ON public.rol_sayfa_yetkileri(firma_id, rol);
CREATE INDEX IF NOT EXISTS idx_rol_sayfa_yetkileri_aktif ON public.rol_sayfa_yetkileri(firma_id, rol, aktif);

-- RLS Politikaları
ALTER TABLE public.rol_sayfa_yetkileri ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi firmalarının rol yetkilerini görebilir
CREATE POLICY "Kullanıcılar kendi firma rol yetkilerini görebilir"
    ON public.rol_sayfa_yetkileri
    FOR SELECT
    USING (
        firma_id IN (
            SELECT firma_id 
            FROM public.user_roles 
            WHERE user_id = auth.uid()
        )
    );

-- Sadece admin roller rol yetkilerini değiştirebilir
CREATE POLICY "Admin roller rol yetkilerini yönetebilir"
    ON public.rol_sayfa_yetkileri
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND firma_id = rol_sayfa_yetkileri.firma_id
            AND role IN ('firma_sahibi', 'firma_admin', 'yonetici')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND firma_id = rol_sayfa_yetkileri.firma_id
            AND role IN ('firma_sahibi', 'firma_admin', 'yonetici')
        )
    );

COMMENT ON TABLE public.rol_sayfa_yetkileri IS 'Her role atanmış sayfa erişim yetkileri';
COMMENT ON COLUMN public.rol_sayfa_yetkileri.rol IS 'Kullanıcı rolü (kullanici, personel, yonetici, vb.)';
COMMENT ON COLUMN public.rol_sayfa_yetkileri.sayfa_kodu IS 'Sayfa kodu (genel_uretim, dokuma, vb.)';
