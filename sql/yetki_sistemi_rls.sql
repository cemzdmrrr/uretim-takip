-- ============================================================
-- KULLANICI YETKİ SİSTEMİ — RLS & RPC KURULUMU
-- Kapsam: kullanici_sayfa_yetkileri, rol_saypa_yetkileri,
--         firma_saypa_yetkileri, firma_kullanicilari_detay RPC
-- Kullanım: Supabase SQL editöründe çalıştırın.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- YARDIMCI FONKSİYON: Kullanıcının firma rolünü döndürür
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.auth_firma_rol(p_firma_id UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT rol
  FROM public.firma_kullanicilari
  WHERE firma_id = p_firma_id
    AND user_id  = auth.uid()
    AND aktif    = true
  LIMIT 1;
$$;

-- ─────────────────────────────────────────────────────────────
-- 1. kullanici_saypa_yetkileri
-- ─────────────────────────────────────────────────────────────

-- Tablo yoksa oluştur (zaten varsa atlar)
CREATE TABLE IF NOT EXISTS public.kullanici_sayfa_yetkileri (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  firma_id          UUID        NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  user_id           UUID        NOT NULL,
  sayfa_kodu        TEXT        NOT NULL,
  aktif             BOOLEAN     NOT NULL DEFAULT true,
  duzenleme_yetkisi BOOLEAN     NOT NULL DEFAULT false,
  silme_yetkisi     BOOLEAN     NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ          DEFAULT now(),
  updated_at        TIMESTAMPTZ          DEFAULT now(),
  UNIQUE(firma_id, user_id, sayfa_kodu)
);

CREATE INDEX IF NOT EXISTS idx_ksy_firma_user
  ON public.kullanici_sayfa_yetkileri(firma_id, user_id);

ALTER TABLE public.kullanici_sayfa_yetkileri ENABLE ROW LEVEL SECURITY;

-- Eski politikaları kaldır
DROP POLICY IF EXISTS "Admin full access"                        ON public.kullanici_sayfa_yetkileri;
DROP POLICY IF EXISTS "ksy_kendi_goruntule"                     ON public.kullanici_sayfa_yetkileri;
DROP POLICY IF EXISTS "ksy_firma_admin_tam_erisim"              ON public.kullanici_sayfa_yetkileri;

-- Kullanıcı kendi satırlarını okuyabilir
CREATE POLICY "ksy_kendi_goruntule"
  ON public.kullanici_sayfa_yetkileri
  FOR SELECT
  USING (user_id = auth.uid());

-- Firma admini / sahibi kendi firmasındaki tüm yetki kayıtlarını yönetebilir
CREATE POLICY "ksy_firma_admin_tam_erisim"
  ON public.kullanici_sayfa_yetkileri
  FOR ALL
  USING (
    public.auth_firma_rol(firma_id) IN ('admin', 'firma_sahibi', 'firma_admin')
  )
  WITH CHECK (
    public.auth_firma_rol(firma_id) IN ('admin', 'firma_sahibi', 'firma_admin')
  );

-- updated_at tetikleyici
CREATE OR REPLACE FUNCTION public.ksy_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;
DROP TRIGGER IF EXISTS tr_ksy_updated ON public.kullanici_sayfa_yetkileri;
CREATE TRIGGER tr_ksy_updated
  BEFORE UPDATE ON public.kullanici_sayfa_yetkileri
  FOR EACH ROW EXECUTE FUNCTION public.ksy_updated_at();


-- ─────────────────────────────────────────────────────────────
-- 2. rol_saypa_yetkileri
-- ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.rol_sayfa_yetkileri (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id         UUID NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
    rol              TEXT NOT NULL,
    sayfa_kodu       TEXT NOT NULL,
    aktif            BOOLEAN DEFAULT true,
    olusturulma_zamani TIMESTAMPTZ DEFAULT now(),
    guncelleme_zamani  TIMESTAMPTZ DEFAULT now(),
    UNIQUE(firma_id, rol, sayfa_kodu)
);

CREATE INDEX IF NOT EXISTS idx_rsy_firma        ON public.rol_sayfa_yetkileri(firma_id);
CREATE INDEX IF NOT EXISTS idx_rsy_firma_rol    ON public.rol_sayfa_yetkileri(firma_id, rol);
CREATE INDEX IF NOT EXISTS idx_rsy_firma_aktif  ON public.rol_sayfa_yetkileri(firma_id, rol, aktif);

ALTER TABLE public.rol_sayfa_yetkileri ENABLE ROW LEVEL SECURITY;

-- Eski politikaları kaldır
DROP POLICY IF EXISTS "Kullanıcılar kendi firma rol yetkilerini görebilir" ON public.rol_sayfa_yetkileri;
DROP POLICY IF EXISTS "Admin roller rol yetkilerini yönetebilir"           ON public.rol_sayfa_yetkileri;
DROP POLICY IF EXISTS "rsy_firma_kullanicisi_goruntule"                    ON public.rol_sayfa_yetkileri;
DROP POLICY IF EXISTS "rsy_firma_admin_tam_erisim"                         ON public.rol_sayfa_yetkileri;

-- Firma üyesi okuyabilir (kendi firmasına ait kayıtlar)
CREATE POLICY "rsy_firma_kullanicisi_goruntule"
  ON public.rol_sayfa_yetkileri
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.firma_kullanicilari
      WHERE firma_id = rol_sayfa_yetkileri.firma_id
        AND user_id  = auth.uid()
        AND aktif    = true
    )
  );

-- Firma admini / sahibi yönetebilir
CREATE POLICY "rsy_firma_admin_tam_erisim"
  ON public.rol_sayfa_yetkileri
  FOR ALL
  USING (
    public.auth_firma_rol(firma_id) IN ('admin', 'firma_sahibi', 'firma_admin')
  )
  WITH CHECK (
    public.auth_firma_rol(firma_id) IN ('admin', 'firma_sahibi', 'firma_admin')
  );


-- ─────────────────────────────────────────────────────────────
-- 3. firma_saypa_yetkileri (mevcut politikaları güncelle)
-- ─────────────────────────────────────────────────────────────

ALTER TABLE public.firma_sayfa_yetkileri ENABLE ROW LEVEL SECURITY;

-- Eski politikaları kaldır
DROP POLICY IF EXISTS "Herkes okuyabilir"       ON public.firma_sayfa_yetkileri;
DROP POLICY IF EXISTS "Admin herseyi yapabilir" ON public.firma_sayfa_yetkileri;
DROP POLICY IF EXISTS "Firma admini yonetebilir" ON public.firma_sayfa_yetkileri;
DROP POLICY IF EXISTS "fsy_firma_kullanicisi_goruntule" ON public.firma_sayfa_yetkileri;
DROP POLICY IF EXISTS "fsy_firma_admin_tam_erisim"      ON public.firma_sayfa_yetkileri;

-- Firma üyesi kendi firmasının aktif sayfa listesini okuyabilir
CREATE POLICY "fsy_firma_kullanicisi_goruntule"
  ON public.firma_sayfa_yetkileri
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.firma_kullanicilari
      WHERE firma_id = firma_sayfa_yetkileri.firma_id
        AND user_id  = auth.uid()
        AND aktif    = true
    )
  );

-- Firma admini / sahibi yönetebilir
CREATE POLICY "fsy_firma_admin_tam_erisim"
  ON public.firma_sayfa_yetkileri
  FOR ALL
  USING (
    public.auth_firma_rol(firma_id) IN ('admin', 'firma_sahibi', 'firma_admin')
  )
  WITH CHECK (
    public.auth_firma_rol(firma_id) IN ('admin', 'firma_sahibi', 'firma_admin')
  );


-- ─────────────────────────────────────────────────────────────
-- 4. firma_kullanicilari_detay RPC
-- SayfaYetkiService.firmaKullanicilariniGetir() tarafından kullanılır.
-- Yalnızca aynı firmadaki admin roller çağırabilir.
-- ─────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.firma_kullanicilari_detay(UUID);
CREATE OR REPLACE FUNCTION public.firma_kullanicilari_detay(p_firma_id UUID)
RETURNS TABLE (
  id          UUID,
  user_id     UUID,
  firma_id    UUID,
  rol         TEXT,
  aktif       BOOLEAN,
  email       TEXT,
  ad_soyad    TEXT,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_rol TEXT;
BEGIN
  -- Çağıran kullanıcı bu firmada admin mi?
  SELECT fk.rol INTO v_rol
  FROM public.firma_kullanicilari fk
  WHERE fk.firma_id = p_firma_id
    AND fk.user_id  = auth.uid()
    AND fk.aktif    = true
  LIMIT 1;

  IF v_rol IS NULL OR v_rol NOT IN ('admin', 'firma_sahibi', 'firma_admin') THEN
    RAISE EXCEPTION 'Yetkisiz erişim: Bu firmaya ait kullanıcıları görüntüleme yetkiniz yok.';
  END IF;

  RETURN QUERY
  SELECT
    fk.id,
    fk.user_id,
    fk.firma_id,
    fk.rol::TEXT,
    fk.aktif,
    COALESCE(au.email, '')::TEXT         AS email,
    COALESCE(
      au.raw_user_meta_data->>'full_name',
      au.raw_user_meta_data->>'name',
      au.email
    )::TEXT                              AS ad_soyad,
    fk.created_at
  FROM public.firma_kullanicilari fk
  LEFT JOIN auth.users au ON au.id = fk.user_id
  WHERE fk.firma_id = p_firma_id
  ORDER BY fk.created_at;
END;
$$;

-- Anonim ve authenticated rollerine çalıştırma izni
GRANT EXECUTE ON FUNCTION public.firma_kullanicilari_detay(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.firma_kullanicilari_detay(UUID) FROM anon;

COMMENT ON FUNCTION public.firma_kullanicilari_detay IS
  'Admin firma kullanıcılarını detaylı listeler. Yalnızca firma_sahibi/firma_admin çağırabilir.';
