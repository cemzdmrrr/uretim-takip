-- ATAMA HATASI TEŞHİS VE ÇÖZÜM
-- Bu SQL'i Supabase Dashboard > SQL'de çalıştır

-- 1. Kullanıcının admin olup olmadığını kontrol et
SELECT 
  'KULLANICI ROL KONTROLÜ' as test_tipi,
  u.email,
  ur.role,
  ur.aktif,
  CASE 
    WHEN ur.role = 'admin' AND ur.aktif = true THEN '✅ ADMIN'
    WHEN ur.role IS NULL THEN '❌ KULLANICI BULUNAMADI'
    ELSE '⚠️ ADMIN DEĞİL'
  END as durum
FROM auth.users u
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.email = 'dkja@gmail.com';

-- 2. Tablolar mevcut mu?
SELECT 
  'TABLO MEVCUT KONTROLÜ' as test_tipi,
  t.tablename,
  CASE WHEN t.tablename IS NOT NULL THEN '✅ MEVCUT' ELSE '❌ YOK' END as durum
FROM (
  VALUES 
    ('uretim_kayitlari'),
    ('dokuma_atamalari'),
    ('user_roles'),
    ('tedarikciler'),
    ('triko_takip')
) v(tablo_adi)
LEFT JOIN pg_tables t ON t.tablename = v.tablo_adi AND t.schemaname = 'public';

-- 3. RLS durumu
SELECT 
  'RLS DURUM KONTROLÜ' as test_tipi,
  tablename,
  CASE 
    WHEN rowsecurity = true THEN '⚠️ RLS AKTİF'
    ELSE '✅ RLS KAPALI'
  END as durum
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('uretim_kayitlari', 'dokuma_atamalari', 'user_roles')
ORDER BY tablename;

-- 4. Test insert (manuel)
-- Bu işlem başarısızsa RLS/yetki sorunu var
INSERT INTO public.uretim_kayitlari (
  model_id,
  asama,
  durum,
  atama_durumu,
  musteri_adi,
  talep_edilen_adet,
  created_at
) VALUES (
  'test-model-id',
  'dokuma',
  'firma_onay_bekliyor',
  'atandi',
  'Test Müşteri',
  1,
  NOW()
) ON CONFLICT DO NOTHING;

-- 5. Son kayıtları kontrol et
SELECT 
  'SON KAYITLAR' as test_tipi,
  model_id,
  asama,
  durum,
  created_at
FROM public.uretim_kayitlari 
ORDER BY created_at DESC 
LIMIT 5;