-- Daily / weekly / monthly todo routines and in-app reminders.

CREATE TABLE IF NOT EXISTS public.yapilacaklar (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  baslik text NOT NULL,
  aciklama text,
  kapsam text NOT NULL DEFAULT 'kisisel',
  olusturan_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  atanan_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  periyot text NOT NULL DEFAULT 'gunluk',
  durum text NOT NULL DEFAULT 'aktif',
  oncelik text NOT NULL DEFAULT 'normal',
  hatirlatici_tarihi timestamptz,
  son_hatirlatma_tarihi timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT yapilacaklar_kapsam_check
    CHECK (kapsam IN ('kisisel', 'firma', 'atanan')),
  CONSTRAINT yapilacaklar_periyot_check
    CHECK (periyot IN ('gunluk', 'haftalik', 'aylik', 'tek_seferlik')),
  CONSTRAINT yapilacaklar_durum_check
    CHECK (durum IN ('aktif', 'tamamlandi', 'iptal')),
  CONSTRAINT yapilacaklar_oncelik_check
    CHECK (oncelik IN ('dusuk', 'normal', 'yuksek'))
);

CREATE TABLE IF NOT EXISTS public.yapilacak_tamamlanma_kayitlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  yapilacak_id uuid NOT NULL REFERENCES public.yapilacaklar(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  donem_anahtari text NOT NULL,
  tamamlandi boolean NOT NULL DEFAULT true,
  tamamlanma_tarihi timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  CONSTRAINT yapilacak_tamamlanma_unique
    UNIQUE (firma_id, yapilacak_id, user_id, donem_anahtari)
);

CREATE INDEX IF NOT EXISTS idx_yapilacaklar_firma_kapsam
  ON public.yapilacaklar (firma_id, kapsam, durum);

CREATE INDEX IF NOT EXISTS idx_yapilacaklar_hatirlatici
  ON public.yapilacaklar (firma_id, hatirlatici_tarihi)
  WHERE hatirlatici_tarihi IS NOT NULL AND durum = 'aktif';

CREATE INDEX IF NOT EXISTS idx_yapilacak_tamamlanma_lookup
  ON public.yapilacak_tamamlanma_kayitlari
  (firma_id, yapilacak_id, user_id, donem_anahtari);

ALTER TABLE public.yapilacaklar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yapilacak_tamamlanma_kayitlari ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "yapilacaklar_firma_okuma" ON public.yapilacaklar;
CREATE POLICY "yapilacaklar_firma_okuma" ON public.yapilacaklar
  FOR SELECT USING (
    firma_id IN (
      SELECT ur.firma_id
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid() AND ur.aktif = true
    )
    AND (
      kapsam = 'firma'
      OR olusturan_user_id = auth.uid()
      OR atanan_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "yapilacaklar_firma_yazma" ON public.yapilacaklar;
CREATE POLICY "yapilacaklar_firma_yazma" ON public.yapilacaklar
  FOR ALL USING (
    firma_id IN (
      SELECT ur.firma_id
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid() AND ur.aktif = true
    )
  )
  WITH CHECK (
    firma_id IN (
      SELECT ur.firma_id
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid() AND ur.aktif = true
    )
  );

DROP POLICY IF EXISTS "yapilacak_tamamlanma_firma_yazma" ON public.yapilacak_tamamlanma_kayitlari;
CREATE POLICY "yapilacak_tamamlanma_firma_yazma"
  ON public.yapilacak_tamamlanma_kayitlari
  FOR ALL USING (
    firma_id IN (
      SELECT ur.firma_id
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid() AND ur.aktif = true
    )
    AND user_id = auth.uid()
  )
  WITH CHECK (
    firma_id IN (
      SELECT ur.firma_id
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid() AND ur.aktif = true
    )
    AND user_id = auth.uid()
  );

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'bildirimler'
      AND constraint_name = 'bildirimler_tip_check'
  ) THEN
    ALTER TABLE public.bildirimler DROP CONSTRAINT bildirimler_tip_check;
  END IF;
END $$;

ALTER TABLE public.bildirimler
  ADD CONSTRAINT bildirimler_tip_check
  CHECK (
    tip = ANY (
      ARRAY[
        'atama_bekliyor'::text,
        'atama_onaylandi'::text,
        'atama_reddedildi'::text,
        'uretim_tamamlandi'::text,
        'kalite_onay'::text,
        'kalite_red'::text,
        'sevkiyat_hazir'::text,
        'stok_uyari'::text,
        'termin_uyari'::text,
        'siparis_yeni'::text,
        'mesai_talebi'::text,
        'avans_talebi'::text,
        'izin_talebi'::text,
        'yapilacak_hatirlatici'::text,
        'genel'::text
      ]
    )
  );
