-- ============================================
-- Firma Sayfa Yetkileri Tablosu
-- Her firma hangi sayfalara erişebileceğini belirler
-- ============================================

-- Tablo oluştur
CREATE TABLE IF NOT EXISTS public.firma_sayfa_yetkileri (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    firma_id UUID NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
    sayfa_kodu TEXT NOT NULL,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(firma_id, sayfa_kodu)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_firma_sayfa_yetkileri_firma 
    ON public.firma_sayfa_yetkileri(firma_id);
CREATE INDEX IF NOT EXISTS idx_firma_sayfa_yetkileri_aktif 
    ON public.firma_sayfa_yetkileri(firma_id, aktif) WHERE aktif = true;

-- RLS
ALTER TABLE public.firma_sayfa_yetkileri ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir (firma kontrolü uygulama katmanında)
CREATE POLICY "Herkes okuyabilir" ON public.firma_sayfa_yetkileri
    FOR SELECT USING (true);

-- Admin herşeyi yapabilir
CREATE POLICY "Admin herseyi yapabilir" ON public.firma_sayfa_yetkileri
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin' 
            AND aktif = true
        )
    );

-- Firma admini kendi firmasının yetkilerini yönetebilir
CREATE POLICY "Firma admini yonetebilir" ON public.firma_sayfa_yetkileri
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.firma_kullanicilari
            WHERE firma_id = firma_sayfa_yetkileri.firma_id
            AND user_id = auth.uid()
            AND rol IN ('firma_sahibi', 'firma_admin')
            AND aktif = true
        )
    );

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_firma_sayfa_yetkileri_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_firma_sayfa_yetkileri_updated ON public.firma_sayfa_yetkileri;
CREATE TRIGGER tr_firma_sayfa_yetkileri_updated
    BEFORE UPDATE ON public.firma_sayfa_yetkileri
    FOR EACH ROW
    EXECUTE FUNCTION update_firma_sayfa_yetkileri_updated_at();
