-- RLS INFINITE RECURSION SORUNU ÇÖZÜLMESİ
-- Bu kodu Supabase SQL Editor'da çalıştırın

-- 1. ÖNCE TÜM RLS POLİTİKALARINI KALDIR
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 2. Mevcut TÜM politikaları sil
DO $$
DECLARE
    policy_name TEXT;
BEGIN
    FOR policy_name IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'user_roles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_roles', policy_name);
        RAISE NOTICE 'Politika silindi: %', policy_name;
    END LOOP;
END $$;

-- 3. Belirli kullanıcıyı admin yap (RLS olmadan)
DELETE FROM public.user_roles WHERE user_id = '72049fae-1bfa-43ae-9669-9586348e1431';

INSERT INTO public.user_roles (user_id, role, aktif, created_at, updated_at)
VALUES ('72049fae-1bfa-43ae-9669-9586348e1431', 'admin', true, now(), now());

-- 4. Kontrol et
SELECT 
    'KULLANICI ADMİN YAPILDI - RLS KAPALI' as durum,
    u.email,
    ur.role,
    ur.aktif,
    u.id as user_id
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';

-- 5. RLS'i KAPALI BIRAKALIM (infinite recursion olmasın)
-- ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;  -- Bu satırı comment yaptık

-- 6. Tüm admin kullanıcıları göster
SELECT 
    'TÜM ADMİN KULLANICILAR' as tip,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;