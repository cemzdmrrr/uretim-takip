-- TÜM ATAMA TABLOLARINDAKİ RLS'İ KAPATALIM
-- Atama işlemi birçok tabloyu kullanıyor

-- 1. Atama ile ilgili tüm tabloların RLS'ini kapat
ALTER TABLE public.uretim_kayitlari DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.triko_takip DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.atolyeler DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tedarikciler DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.bildirimler DISABLE ROW LEVEL SECURITY;

-- Atama tabloları (eğer varsa)
ALTER TABLE IF EXISTS public.dokuma_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.konfeksiyon_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.yikama_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.utu_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ilik_dugme_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kalite_kontrol_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.paketleme_atamalari DISABLE ROW LEVEL SECURITY;

-- 2. Kontrol et - Hangi tablolarda RLS aktif
SELECT 
    tablename,
    rowsecurity as rls_aktif,
    CASE WHEN rowsecurity THEN 'PROBLEM!' ELSE 'OK' END as durum
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'user_roles', 'uretim_kayitlari', 'triko_takip', 
    'atolyeler', 'tedarikciler', 'bildirimler'
)
ORDER BY rowsecurity DESC, tablename;

-- 3. Kullanıcı admin durumu
SELECT 
    'KULLANICI ADMIN DURUMU' as tip,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';