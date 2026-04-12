-- user_roles tablosuna şoför rolü ekleme
-- Bu script, mevcut user_roles tablosunun role constraint'ini günceller

-- Önce mevcut constraint'i kaldır
ALTER TABLE public.user_roles 
DROP CONSTRAINT IF EXISTS user_roles_role_check;

-- Yeni constraint ekle (şoför rolü dahil)
ALTER TABLE public.user_roles
ADD CONSTRAINT user_roles_role_check 
CHECK (role::text = ANY (ARRAY[
  'admin'::character varying, 
  'user'::character varying, 
  'ik'::character varying, 
  'personel'::character varying,
  'tedarikci'::character varying,
  'kalite_kontrol'::character varying,
  'sofor'::character varying
]::text[]));

-- Şoför kullanıcısı oluşturma örneği:
-- Önce auth.users'a kayıt olması gerekir (register veya Supabase dashboard üzerinden)
-- Sonra user_roles'a eklenebilir:

-- INSERT INTO public.user_roles (user_id, role, aktif)
-- VALUES ('USER_UUID_BURAYA', 'sofor', true);

-- Bildirimler tablosu için sevkiyat_hazir tip kontrolü (zaten mevcut ama kontrol edelim)
-- Bildirimler tablosundaki tip constraint'ine bak
-- Şu an mevcut:
-- tip = ANY (ARRAY['atama_bekliyor', 'atama_onaylandi', 'atama_reddedildi', 
--                   'uretim_tamamlandi', 'kalite_onay', 'kalite_red', 
--                   'sevkiyat_hazir', 'genel'])

-- sevk_talepleri tablosu durum constraint'i güncelleme
ALTER TABLE public.sevk_talepleri 
DROP CONSTRAINT IF EXISTS sevk_talepleri_durum_check;

ALTER TABLE public.sevk_talepleri
ADD CONSTRAINT sevk_talepleri_durum_check 
CHECK (durum::text = ANY (ARRAY[
  'bekliyor'::text,
  'kalite_onaylandi'::text,
  'alindi'::text,
  'yolda'::text,
  'teslimde'::text,
  'teslim_edildi'::text,
  'iptal'::text
]));

-- RLS Politikaları için şoför erişimi

-- Şoförler için sevk_talepleri tablosuna erişim
DROP POLICY IF EXISTS "Sofor sevk taleplerini gorebilir" ON public.sevk_talepleri;
CREATE POLICY "Sofor sevk taleplerini gorebilir" ON public.sevk_talepleri
  FOR SELECT
  USING (
    sofor_user_id = auth.uid() 
    OR durum = 'bekliyor' 
    OR durum = 'kalite_onaylandi'
    OR EXISTS (
      SELECT 1 FROM public.user_roles 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'sofor')
    )
  );

DROP POLICY IF EXISTS "Sofor sevk taleplerini guncelleyebilir" ON public.sevk_talepleri;
CREATE POLICY "Sofor sevk taleplerini guncelleyebilir" ON public.sevk_talepleri
  FOR UPDATE
  USING (
    sofor_user_id = auth.uid() 
    OR EXISTS (
      SELECT 1 FROM public.user_roles 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'sofor')
    )
  );

-- Bildirimler tablosu RLS (şoförler kendi bildirimlerini görebilmeli)
DROP POLICY IF EXISTS "Kullanici kendi bildirimlerini gorebilir" ON public.bildirimler;
CREATE POLICY "Kullanici kendi bildirimlerini gorebilir" ON public.bildirimler
  FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Kullanici kendi bildirimlerini guncelleyebilir" ON public.bildirimler;
CREATE POLICY "Kullanici kendi bildirimlerini guncelleyebilir" ON public.bildirimler
  FOR UPDATE
  USING (user_id = auth.uid());

-- Admin ve kalite kontrol yeni bildirim ekleyebilir
DROP POLICY IF EXISTS "Yetkili kullanicilar bildirim olusturabilir" ON public.bildirimler;
CREATE POLICY "Yetkili kullanicilar bildirim olusturabilir" ON public.bildirimler
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_roles 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'kalite_kontrol')
    )
  );

-- Atölyeler tablosu herkes okuyabilir
DROP POLICY IF EXISTS "Herkes atolyeleri gorebilir" ON public.atolyeler;
CREATE POLICY "Herkes atolyeleri gorebilir" ON public.atolyeler
  FOR SELECT
  USING (true);

COMMENT ON TABLE public.sevk_talepleri IS 'Üretim sevkiyat talepleri - Şoför iş akışı için kullanılır';
