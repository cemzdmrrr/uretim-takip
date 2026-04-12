-- User_roles tablosunu düzelt ve eksik kolonları ekle

-- Önce mevcut user_roles tablosunu yedekle (eğer veri varsa)
-- CREATE TABLE user_roles_backup AS SELECT * FROM user_roles;

-- user_roles tablosunu güncelle
ALTER TABLE public.user_roles 
ADD COLUMN IF NOT EXISTS yetki_seviyesi TEXT DEFAULT 'user',
ADD COLUMN IF NOT EXISTS aktif BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS atolye_id UUID,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Role constraint'ini güncelle - tüm rolleri destekle
ALTER TABLE public.user_roles 
DROP CONSTRAINT IF EXISTS user_roles_role_check;

ALTER TABLE public.user_roles 
ADD CONSTRAINT user_roles_role_check 
CHECK (role IN ('admin', 'yonetici', 'kullanici', 'personel', 'orgu_firmasi', 'kalite_personeli', 'sevkiyat_soforu', 'atolye_personeli'));

-- Updated_at trigger ekle
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_user_roles_updated_at ON public.user_roles;
CREATE TRIGGER update_user_roles_updated_at 
    BEFORE UPDATE ON public.user_roles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS politikalarını güncelle
DROP POLICY IF EXISTS "Kullanıcılar kendi verilerine erişebilir" ON public.user_roles;
CREATE POLICY "Kullanıcılar kendi verilerine erişebilir" 
ON public.user_roles FOR ALL 
USING (auth.uid() = user_id);

-- Admin politikası ekle
DROP POLICY IF EXISTS "Admin tüm verilere erişebilir" ON public.user_roles;
CREATE POLICY "Admin tüm verilere erişebilir" 
ON public.user_roles FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur 
        WHERE ur.user_id = auth.uid() 
        AND ur.role = 'admin'
    )
);

-- Service role için tam erişim
DROP POLICY IF EXISTS "Service role tam erişim" ON public.user_roles;
CREATE POLICY "Service role tam erişim" 
ON public.user_roles FOR ALL 
USING (auth.role() = 'service_role');

-- Indexes ekle
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_aktif ON public.user_roles(aktif);

-- Test için kullanıcı ekle (eğer yoksa)
DO $$
DECLARE
    admin_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM public.user_roles WHERE role = 'admin') INTO admin_exists;
    
    IF NOT admin_exists THEN
        RAISE NOTICE 'Admin kullanıcı bulunamadı. Lütfen giriş yaptıktan sonra rolünüzü admin olarak ayarlayın.';
    END IF;
END $$;
