-- KESIN ÇÖZÜM - USER_ROLES TABLOSUNU RLS'SİZ KULLAN
-- Bu kodu Supabase SQL Editor'da çalıştırın

-- 1. user_roles tablosunun RLS'ini tamamen kapat
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 2. Tüm politikaları kaldır
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
    
    IF NOT FOUND THEN
        RAISE NOTICE 'Kaldırılacak politika bulunamadı';
    END IF;
END $$;

-- 3. Kullanıcıyı admin yap
DELETE FROM public.user_roles 
WHERE user_id = '72049fae-1bfa-43ae-9669-9586348e1431';

INSERT INTO public.user_roles (user_id, role, aktif, created_at, updated_at)
VALUES ('72049fae-1bfa-43ae-9669-9586348e1431', 'admin', true, now(), now());

-- 4. Başarı kontrolü
SELECT 
    'BAŞARILI! KULLANICI ADMİN OLDU' as durum,
    u.email,
    ur.role,
    ur.aktif,
    'RLS KAPALI - GÜVENLİ' as not
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';

-- 5. RLS durumunu kontrol et
SELECT 
    'RLS DURUMU' as tip,
    tablename,
    rowsecurity as rls_aktif
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'user_roles';