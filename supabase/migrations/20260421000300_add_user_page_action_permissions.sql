ALTER TABLE public.kullanici_sayfa_yetkileri
  ADD COLUMN IF NOT EXISTS duzenleme_yetkisi boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS silme_yetkisi boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.kullanici_sayfa_yetkileri.aktif
  IS 'Kullanici bu sayfayi gorebilir mi?';
COMMENT ON COLUMN public.kullanici_sayfa_yetkileri.duzenleme_yetkisi
  IS 'Kullanici bu sayfada duzenleme islemleri yapabilir mi?';
COMMENT ON COLUMN public.kullanici_sayfa_yetkileri.silme_yetkisi
  IS 'Kullanici bu sayfada silme islemleri yapabilir mi?';
