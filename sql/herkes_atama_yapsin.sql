-- YETKİ KONTROLÜNÜ KALDIR - HERKES ATAMA YAPABİLSİN
-- RLS'leri devre dışı bırak

-- Ana tablolar
ALTER TABLE IF EXISTS public.uretim_kayitlari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.triko_takip DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.atolyeler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tedarikciler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bildirimler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_roles DISABLE ROW LEVEL SECURITY;

-- Atama tabloları
ALTER TABLE IF EXISTS public.dokuma_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.konfeksiyon_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.yikama_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.utu_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ilik_dugme_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kalite_kontrol_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.paketleme_atamalari DISABLE ROW LEVEL SECURITY;

-- Diğer önemli tablolar
ALTER TABLE IF EXISTS public.siparis_takip DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kasa_banka_hareketleri DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.faturalar DISABLE ROW LEVEL SECURITY;

-- HERKES İÇİN BASIT POLİTİKALAR
-- Gerekirse politika varsa kaldır ve basit allow-all politikası ekle

-- Kontrolde admin olan herkes olsun
UPDATE public.user_roles SET role = 'admin', aktif = true WHERE aktif = true;

-- Yeni kullanıcılar için otomatik admin
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role, aktif)
  VALUES (NEW.id, 'admin', true)
  ON CONFLICT (user_id) DO UPDATE SET role = 'admin', aktif = true;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Sonuç kontrolü
SELECT 'YETKİ KONTROLÜ KALDIRILDI - HERKES ADMIN' as mesaj;

SELECT 
    tablename,
    CASE WHEN rowsecurity THEN 'RLS AKTİF ⚠️' ELSE 'RLS KAPALI ✅' END as durum
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'user_roles', 'uretim_kayitlari', 'triko_takip', 
    'atolyeler', 'tedarikciler', 'bildirimler',
    'dokuma_atamalari', 'konfeksiyon_atamalari'
)
ORDER BY rowsecurity DESC, tablename;