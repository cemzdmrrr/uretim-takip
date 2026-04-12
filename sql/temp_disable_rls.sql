-- GEÇİCİ ÇÖZÜM - RLS BYPASS FLUTTER İÇİN
-- Bu kodu çalıştırın, Flutter test edin, sonra RLS'i tekrar açın

-- 1. user_roles tablosunu geçici olarak RLS-free yap
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

SELECT 'user_roles RLS kapandı - Flutter test edebilirsiniz' as durum;

-- 2. Kullanıcı durumunu göster
SELECT 
    'KULLANICI DURUM' as tip,
    u.email,
    ur.role,
    ur.aktif,
    'RLS KAPALI - ÇALIŞMALI' as not
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';