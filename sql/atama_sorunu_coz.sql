-- ADMIN KONTROLÜ İLE ATAMA SİSTEMİ
-- Sadece admin kullanıcılar atama yapabilir

-- 1. Önemli tabloların RLS'ini kapat (veri erişimi için)
ALTER TABLE IF EXISTS public.uretim_kayitlari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.triko_takip DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.atolyeler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tedarikciler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bildirimler DISABLE ROW LEVEL SECURITY;

-- Atama tabloları
ALTER TABLE IF EXISTS public.dokuma_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.konfeksiyon_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.yikama_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.utu_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ilik_dugme_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kalite_kontrol_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.paketleme_atamalari DISABLE ROW LEVEL SECURITY;

-- 2. user_roles tablosunda RLS aktif tutup admin kontrolü yap
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Politikaları temizle
DROP POLICY IF EXISTS "user_roles_select_policy" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_insert_policy" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_update_policy" ON public.user_roles;

-- Herkes kendi rolünü görebilir
CREATE POLICY "user_roles_select_policy" ON public.user_roles
  FOR SELECT USING (auth.uid() = user_id OR 
  EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.aktif = true));

-- Sadece admin roller değiştirebilir
CREATE POLICY "user_roles_insert_policy" ON public.user_roles
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.aktif = true)
  );

CREATE POLICY "user_roles_update_policy" ON public.user_roles
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.aktif = true)
  );

-- 3. Sadece belli kullanıcıları admin yap (güvenlik için)
-- Mevcut tüm kullanıcıları user yapalım, sonra sadece belirli olanları admin yapacağız
UPDATE public.user_roles SET role = 'user', aktif = true WHERE aktif = true;

-- Belirli email'leri admin yap (bu kısmı kendi admin email'inizle değiştirin)
UPDATE public.user_roles 
SET role = 'admin' 
WHERE user_id IN (
  SELECT u.id 
  FROM auth.users u 
  WHERE u.email IN ('dkja@gmail.com', 'cemmozdemirr.34@gmail.com', 'admin@example.com') -- Admin email'leri buraya ekleyin
);

-- 4. Yeni kullanıcılar için trigger (varsayılan olarak user)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role, aktif)
  VALUES (NEW.id, 'user', true)  -- Varsayılan olarak user
  ON CONFLICT (user_id) DO UPDATE SET aktif = true;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 5. Test verisi ekle (admin kullanıcı tarafından)
INSERT INTO public.uretim_kayitlari (
  model_id,
  asama,
  durum,
  atama_durumu,
  musteri_adi,
  talep_edilen_adet,
  created_at
) VALUES (
  '7b07c17d-4b34-4b49-a067-12c3c1234567', -- örnek model ID
  'dokuma',
  'firma_onay_bekliyor',
  'atandi',
  'Test Müşteri',
  1,
  NOW()
) ON CONFLICT DO NOTHING;

-- 6. Kontrol sorguları
SELECT 'RLS DURUMU' as kontrol_tipi, tablename, 
  CASE WHEN rowsecurity THEN 'AKTİF ⚠️' ELSE 'KAPALI ✅' END as durum
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('uretim_kayitlari', 'triko_takip', 'user_roles', 'tedarikciler')
ORDER BY rowsecurity DESC;

SELECT 'KULLANICI ROLLERİ' as kontrol_tipi, 
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_sayisi,
  COUNT(CASE WHEN role = 'user' THEN 1 END) as user_sayisi
FROM public.user_roles 
WHERE aktif = true;

SELECT 'ADMIN KULLANICILAR' as kontrol_tipi,
  u.email,
  ur.role,
  ur.aktif
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;