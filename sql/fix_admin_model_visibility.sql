-- Admin kullanıcı modelleri görebilmesi için RLS politikaları düzelt
-- Issue: Admin kullanıcı kayıtlı modelleri göremiyor

-- 1. Mevcut is_admin_user() fonksiyonunu kontrol et/oluştur
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS boolean AS $$
BEGIN
    -- Direkt kontrol - sonsuz döngü riski yok
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin' 
        AND aktif = true
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- 2. triko_takip tablosu RLS'i etkinleştir
ALTER TABLE public.triko_takip ENABLE ROW LEVEL SECURITY;

-- 3. Mevcut politikaları temizle (varsa)
DROP POLICY IF EXISTS "triko_takip_read_all" ON public.triko_takip;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.triko_takip;
DROP POLICY IF EXISTS "triko_takip_admin_select" ON public.triko_takip;
DROP POLICY IF EXISTS "Herkes sipariş verilerini okuyabilir" ON public.triko_takip;
DROP POLICY IF EXISTS "Herkes okuyabilir" ON public.triko_takip;
DROP POLICY IF EXISTS "Admin tüm triko_takip verilerine erişebilir" ON public.triko_takip;
DROP POLICY IF EXISTS "triko_takip_admin_write" ON public.triko_takip;
DROP POLICY IF EXISTS "triko_takip_admin_update" ON public.triko_takip;
DROP POLICY IF EXISTS "triko_takip_admin_delete" ON public.triko_takip;

-- 4. Yeni politikaları oluştur
-- SELECT: Herkes okuyabilir (ama admin'ler mutlaka görebilir)
CREATE POLICY "triko_takip_select_all" ON public.triko_takip 
FOR SELECT 
USING (true);

-- INSERT: Sadece admin'ler
CREATE POLICY "triko_takip_insert_admin" ON public.triko_takip 
FOR INSERT 
WITH CHECK (public.is_admin_user());

-- UPDATE: Sadece admin'ler
CREATE POLICY "triko_takip_update_admin" ON public.triko_takip 
FOR UPDATE 
USING (public.is_admin_user());

-- DELETE: Sadece admin'ler
CREATE POLICY "triko_takip_delete_admin" ON public.triko_takip 
FOR DELETE 
USING (public.is_admin_user());

-- 5. modeller tablosu (eğer varsa) için de kontrol et
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'modeller') THEN
        ALTER TABLE public.modeller ENABLE ROW LEVEL SECURITY;
        
        -- Mevcut politikaları temizle
        DROP POLICY IF EXISTS "admin_access" ON public.modeller;
        DROP POLICY IF EXISTS "modeller_admin_select" ON public.modeller;
        
        -- Yeni politikaları oluştur
        CREATE POLICY "modeller_select_all" ON public.modeller 
        FOR SELECT 
        USING (true);
        
        CREATE POLICY "modeller_insert_admin" ON public.modeller 
        FOR INSERT 
        WITH CHECK (public.is_admin_user());
        
        CREATE POLICY "modeller_update_admin" ON public.modeller 
        FOR UPDATE 
        USING (public.is_admin_user());
        
        CREATE POLICY "modeller_delete_admin" ON public.modeller 
        FOR DELETE 
        USING (public.is_admin_user());
        
        RAISE NOTICE '✅ modeller tablosu politikaları güncellendi';
    END IF;
END $$;

-- 6. user_roles tablosu politikaları (admin kontrol döngüsü olmadan)
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları temizle
DROP POLICY IF EXISTS "user_roles_own_select" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_admin_select" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_select_policy" ON public.user_roles;
DROP POLICY IF EXISTS "admin_access" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_admin_insert" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_insert_policy" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_admin_update" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_update_policy" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_admin_delete" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_delete_policy" ON public.user_roles;

-- Yeni politikalar
CREATE POLICY "user_roles_select_own_or_admin" ON public.user_roles 
FOR SELECT 
USING (
    user_id = auth.uid() 
    OR public.is_admin_user()
);

CREATE POLICY "user_roles_insert_admin" ON public.user_roles 
FOR INSERT 
WITH CHECK (public.is_admin_user());

CREATE POLICY "user_roles_update_admin" ON public.user_roles 
FOR UPDATE 
USING (public.is_admin_user());

CREATE POLICY "user_roles_delete_admin" ON public.user_roles 
FOR DELETE 
USING (public.is_admin_user());

-- 7. Test sorgusu - admin kullanıcı test
-- NOT: Bu sorguyu çalıştırmak için admin olarak giriş yapmanız gerekir
SELECT 'RLS politikaları başarıyla güncellendi!' as sonuc;

-- 8. Politikaları kontrol et
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('triko_takip', 'modeller', 'user_roles')
ORDER BY tablename, policyname;
