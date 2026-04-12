-- USER_ROLES TABLOSU İÇİN YENİ RLS POLİTİKALARI
-- Infinite recursion problemini önleyen güvenli politikalar

-- 1. Önce mevcut durumu temizle
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 2. Tüm eski politikaları kaldır
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT policyname FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'user_roles'
    LOOP
        EXECUTE format('DROP POLICY %I ON public.user_roles', rec.policyname);
        RAISE NOTICE 'Politika kaldırıldı: %', rec.policyname;
    END LOOP;
END $$;

-- 3. Kullanıcı admin durumunu kontrol etmek için güvenli function oluştur
CREATE OR REPLACE FUNCTION public.is_user_admin(check_user_id UUID DEFAULT NULL)
RETURNS boolean AS $$
DECLARE
    target_user_id UUID;
    admin_count INTEGER;
BEGIN
    -- Eğer user_id verilmemişse, mevcut kullanıcıyı kontrol et
    target_user_id := COALESCE(check_user_id, auth.uid());
    
    -- Eğer user_id yoksa false döndür
    IF target_user_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- RLS bypass ederek direkt admin kontrolü yap
    SELECT COUNT(*) INTO admin_count
    FROM public.user_roles ur
    WHERE ur.user_id = target_user_id 
    AND ur.role = 'admin' 
    AND ur.aktif = true;
    
    RETURN admin_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- 4. Güvenli RLS politikaları oluştur
-- Kullanıcılar kendi kayıtlarını görebilir
CREATE POLICY "user_roles_view_own" ON public.user_roles 
FOR SELECT 
USING (user_id = auth.uid());

-- Adminler tüm kayıtları görebilir (function kullanarak recursive problemini önle)
CREATE POLICY "user_roles_view_all_admin" ON public.user_roles 
FOR SELECT 
USING (public.is_user_admin());

-- Sadece adminler yeni kayıt ekleyebilir
CREATE POLICY "user_roles_insert_admin" ON public.user_roles 
FOR INSERT 
WITH CHECK (public.is_user_admin());

-- Sadece adminler güncelleyebilir
CREATE POLICY "user_roles_update_admin" ON public.user_roles 
FOR UPDATE 
USING (public.is_user_admin());

-- Sadece adminler silebilir
CREATE POLICY "user_roles_delete_admin" ON public.user_roles 
FOR DELETE 
USING (public.is_user_admin());

-- 5. RLS'i aktif et
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 6. Test et
SELECT 
    'YENİ RLS POLİTİKALARI OLUŞTURULDU' as durum,
    COUNT(*) as politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'user_roles';

-- 7. Function test et
SELECT 
    'FONKSİYON TESTİ' as test,
    public.is_user_admin('72049fae-1bfa-43ae-9669-9586348e1431') as admin_mi,
    auth.uid() as mevcut_kullanici;

-- 8. Admin kullanıcıları göster
SELECT 
    'ADMİN KULLANICILAR' as tip,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;