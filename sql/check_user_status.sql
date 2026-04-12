-- KULLANICI DURUMUNU KONTROL ET
SELECT 
    'MEVCUT DURUM' as tip,
    u.id,
    u.email,
    ur.role,
    ur.aktif,
    public.is_user_admin(u.id) as fonksiyon_sonuc
FROM auth.users u
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';

-- RLS durumunu kontrol et
SELECT 
    'RLS DURUMU' as tip,
    tablename,
    rowsecurity as rls_aktif
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'user_roles';

-- Politikaları kontrol et
SELECT 
    'POLİTİKALAR' as tip,
    policyname,
    cmd as komut
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'user_roles';