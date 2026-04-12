-- Migrasyon durumu kontrol RPC fonksiyonları
-- Phase 10: Veri Migrasyonu & Geriye Uyumluluk

-- 0. Migrasyon durumu tablosu
CREATE TABLE IF NOT EXISTS public.migrasyon_durumu (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adim_adi text NOT NULL,
  durum text NOT NULL DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'baslamis', 'tamamlandi', 'hata')),
  hata_mesaji text,
  baslangic_tarihi timestamp with time zone DEFAULT now(),
  bitis_tarihi timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 0.1 Destek Talepleri tablosu (eksik)
CREATE TABLE IF NOT EXISTS public.destek_talepleri (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id uuid NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  konu text NOT NULL,
  aciklama text NOT NULL,
  durum text NOT NULL DEFAULT 'acik' CHECK (durum IN ('acik', 'inceleniyor', 'cevaplandi', 'kapali')),
  onem_seviyesi text DEFAULT 'normal' CHECK (onem_seviyesi IN ('dusuk', 'normal', 'yuksek', 'kritik')),
  cevap text,
  cevaplayan_id uuid REFERENCES auth.users(id),
  cevap_tarihi timestamp with time zone,
  kapatma_tarihi timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 0.1.1 firma_modulleri tablosu - var olduğunu varsay ve düzelt
DROP TABLE IF EXISTS public.firma_modulleri CASCADE;

CREATE TABLE public.firma_modulleri (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id uuid NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
  modul_id uuid NOT NULL REFERENCES modul_tanimlari(id) ON DELETE CASCADE,
  aktif boolean DEFAULT true,
  aktivasyon_tarihi timestamp with time zone DEFAULT now(),
  bitis_tarihi timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  UNIQUE(firma_id, modul_id)
);

-- 0.1.2 firma_uretim_modulleri tablosu - var olduğunu varsay ve düzelt
DROP TABLE IF EXISTS public.firma_uretim_modulleri CASCADE;

CREATE TABLE public.firma_uretim_modulleri (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id uuid NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
  uretim_modul_id uuid NOT NULL REFERENCES uretim_modulleri(id) ON DELETE CASCADE,
  tekstil_dali text,
  aktif boolean DEFAULT true,
  aktivasyon_tarihi timestamp with time zone DEFAULT now(),
  bitis_tarihi timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  UNIQUE(firma_id, uretim_modul_id)
);

-- 0.2 uretim_modulleri'ye sira_no kolonu ekle (varsa eksiği doldur)
ALTER TABLE uretim_modulleri ADD COLUMN IF NOT EXISTS sira_no integer;

-- Window function kullanılmadan sira_no doldur
WITH numbered AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as new_sira_no
  FROM uretim_modulleri
  WHERE sira_no IS NULL
)
UPDATE uretim_modulleri
SET sira_no = numbered.new_sira_no
FROM numbered
WHERE uretim_modulleri.id = numbered.id;

-- Varsayılan değer ata
ALTER TABLE uretim_modulleri ALTER COLUMN sira_no SET NOT NULL;

-- 0.3 Platform firma özet view'ı
CREATE OR REPLACE VIEW v_platform_firma_ozet AS
SELECT 
  f.id,
  f.firma_adi,
  f.firma_kodu,
  f.aktif,
  f.created_at as kayit_tarihi,
  COALESCE(fa.durum, 'yok') as abonelik_durumu,
  COALESCE(ap.plan_adi, '-') as plan_adi,
  COALESCE(ap.aylik_ucret, 0) as aylik_ucret,
  COUNT(DISTINCT fk.user_id) as kullanici_sayisi,
  COUNT(DISTINCT fm.modul_id) FILTER (WHERE fm.aktif = true) as modul_sayisi
FROM firmalar f
LEFT JOIN firma_abonelikleri fa ON fa.firma_id = f.id AND fa.durum IN ('aktif', 'deneme')
LEFT JOIN abonelik_planlari ap ON ap.id = fa.plan_id
LEFT JOIN firma_kullanicilari fk ON fk.firma_id = f.id AND fk.aktif = true
LEFT JOIN firma_modulleri fm ON fm.firma_id = f.id
GROUP BY f.id, f.firma_adi, f.firma_kodu, f.aktif, f.created_at, fa.durum, ap.plan_adi, ap.aylik_ucret;

-- 0.3.1 Platform istatistikleri view'ı
CREATE OR REPLACE VIEW v_platform_istatistikleri AS
SELECT 
  COUNT(DISTINCT CASE WHEN f.aktif = true THEN f.id END) as aktif_firma_sayisi,
  COUNT(DISTINCT CASE WHEN f.aktif = false THEN f.id END) as pasif_firma_sayisi,
  COUNT(DISTINCT f.id) as toplam_firma_sayisi,
  COUNT(DISTINCT fk.user_id) as toplam_kullanici_sayisi,
  COUNT(DISTINCT CASE WHEN fa.durum = 'aktif' THEN fa.id END) as aktif_abonelik_sayisi,
  COUNT(DISTINCT CASE WHEN fa.durum = 'deneme' THEN fa.id END) as deneme_abonelik_sayisi,
  COALESCE(SUM(CASE WHEN fa.durum IN ('aktif', 'deneme') THEN ap.aylik_ucret ELSE 0 END), 0) as aylik_gelir,
  COUNT(DISTINCT CASE WHEN dt.durum = 'acik' THEN dt.id END) as acik_destek_sayisi
FROM firmalar f
LEFT JOIN firma_abonelikleri fa ON fa.firma_id = f.id
LEFT JOIN abonelik_planlari ap ON ap.id = fa.plan_id
LEFT JOIN firma_kullanicilari fk ON fk.firma_id = f.id
LEFT JOIN destek_talepleri dt ON dt.firma_id = f.id;

-- 1. Sistem sağlığı raporunu döndüren fonksiyon
CREATE OR REPLACE FUNCTION migrasyon_saglik_raporu()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_aktif_firma_sayisi int;
  v_aktif_kullanici_sayisi int;
  v_null_firma_id_modeller int;
  v_null_firma_id_donemler int;
  v_null_firma_id_uretim int;
  v_null_firma_id_tablo_sayisi int;
  v_rls_eksik_tablo_sayisi int;
  v_firmaya_atanmamis_kullanici int;
  v_aboneligi_olmayan_firma int;
  v_saglik_durumu text;
BEGIN
  -- Aktif firma sayısı
  SELECT COUNT(*) INTO v_aktif_firma_sayisi
  FROM firmalar WHERE aktif = true;

  -- Aktif kullanıcı sayısı
  SELECT COUNT(*) INTO v_aktif_kullanici_sayisi
  FROM user_roles WHERE role IN ('admin', 'muhasebe', 'satislar', 'kalite');

  -- NULL firma_id kontrolleri (ayrı ayrı)
  SELECT COUNT(*) INTO v_null_firma_id_modeller
  FROM modeller WHERE firma_id IS NULL;
  
  SELECT COUNT(*) INTO v_null_firma_id_donemler
  FROM donemler WHERE firma_id IS NULL;
  
  SELECT COUNT(*) INTO v_null_firma_id_uretim
  FROM uretim_kayitlari WHERE firma_id IS NULL;

  v_null_firma_id_tablo_sayisi := 0;
  IF v_null_firma_id_modeller > 0 THEN v_null_firma_id_tablo_sayisi := v_null_firma_id_tablo_sayisi + 1; END IF;
  IF v_null_firma_id_donemler > 0 THEN v_null_firma_id_tablo_sayisi := v_null_firma_id_tablo_sayisi + 1; END IF;
  IF v_null_firma_id_uretim > 0 THEN v_null_firma_id_tablo_sayisi := v_null_firma_id_tablo_sayisi + 1; END IF;

  -- RLS eksik olan tablolar (basit kontrol)
  SELECT COUNT(*) INTO v_rls_eksik_tablo_sayisi
  FROM information_schema.tables t
  WHERE t.table_schema = 'public'
  AND t.table_name IN ('modeller', 'donemler', 'uretim_kayitlari', 'personel')
  AND NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.tablename = t.table_name
  );

  -- Firmaya atanmamış kullanıcı
  SELECT COUNT(*) INTO v_firmaya_atanmamis_kullanici
  FROM user_roles ur
  WHERE NOT EXISTS (
    SELECT 1 FROM firma_kullanicilari fk
    WHERE fk.user_id = ur.user_id
  );

  -- Aboneliği olmayan firma
  SELECT COUNT(*) INTO v_aboneligi_olmayan_firma
  FROM firmalar f
  WHERE f.aktif = true
  AND NOT EXISTS (
    SELECT 1 FROM firma_abonelikleri fa
    WHERE fa.firma_id = f.id
    AND fa.durum IN ('aktif', 'deneme')
  );

  -- Sağlık durumu belirle
  v_saglik_durumu := CASE
    WHEN v_null_firma_id_tablo_sayisi > 0 OR v_rls_eksik_tablo_sayisi > 0 THEN 'kritik'
    WHEN v_firmaya_atanmamis_kullanici > 0 OR v_aboneligi_olmayan_firma > 0 THEN 'uyari'
    ELSE 'saglikli'
  END;

  RETURN json_build_object(
    'saglik_durumu', v_saglik_durumu,
    'aktif_firma_sayisi', v_aktif_firma_sayisi,
    'aktif_kullanici_sayisi', v_aktif_kullanici_sayisi,
    'null_firma_id_tablo_sayisi', v_null_firma_id_tablo_sayisi,
    'rls_eksik_tablo_sayisi', v_rls_eksik_tablo_sayisi,
    'firmaya_atanmamis_kullanici', v_firmaya_atanmamis_kullanici,
    'aboneligi_olmayan_firma', v_aboneligi_olmayan_firma
  );
END;
$$;

-- 2. firma_id NULL olan tabloları listeleyen fonksiyon
CREATE OR REPLACE FUNCTION migrasyon_firma_id_kontrol()
RETURNS TABLE(tablo_adi text, null_kayit_sayisi bigint, toplam_kayit bigint)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 'modeller'::text, 
         COUNT(*) FILTER (WHERE firma_id IS NULL)::bigint,
         COUNT(*)::bigint
  FROM modeller
  UNION ALL
  SELECT 'donemler'::text,
         COUNT(*) FILTER (WHERE firma_id IS NULL)::bigint,
         COUNT(*)::bigint
  FROM donemler
  UNION ALL
  SELECT 'uretim_kayitlari'::text,
         COUNT(*) FILTER (WHERE firma_id IS NULL)::bigint,
         COUNT(*)::bigint
  FROM uretim_kayitlari;
$$;

-- 3. RLS durumunu kontrol eden fonksiyon
CREATE OR REPLACE FUNCTION migrasyon_rls_kontrol()
RETURNS TABLE(tablo_adi text, rls_aktif boolean, politika_sayisi int)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT t.table_name::text,
         (SELECT rowsecurity FROM pg_tables WHERE tablename = t.table_name),
         (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.table_name)::int
  FROM information_schema.tables t
  WHERE t.table_schema = 'public'
  AND t.table_name IN (
    'modeller', 'donemler', 'uretim_kayitlari', 'personel',
    'dokuma_atamalari', 'konfeksiyon_atamalari', 'boyama_atamalari',
    'kalite_kontrol_kayitlari', 'sevkiyat_kayitlari'
  );
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION migrasyon_saglik_raporu() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION migrasyon_firma_id_kontrol() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION migrasyon_rls_kontrol() TO authenticated, anon;

-- 0.4 Firma kullanıcıları detay fonksiyonu (auth.users ile join)
CREATE OR REPLACE FUNCTION firma_kullanicilari_detay(p_firma_id uuid)
RETURNS TABLE(
  id uuid,
  firma_id uuid,
  user_id uuid,
  rol text,
  aktif boolean,
  katilim_tarihi timestamptz,
  davet_tarihi timestamptz,
  created_at timestamptz,
  email text,
  ad text,
  soyad text,
  display_name text,
  firma_adi text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    fk.id,
    fk.firma_id,
    fk.user_id,
    fk.rol,
    fk.aktif,
    fk.katilim_tarihi,
    fk.davet_tarihi,
    fk.created_at,
    u.email,
    COALESCE(u.raw_user_meta_data->>'ad', '') as ad,
    COALESCE(u.raw_user_meta_data->>'soyad', '') as soyad,
    COALESCE(u.raw_user_meta_data->>'display_name', u.email) as display_name,
    f.firma_adi
  FROM firma_kullanicilari fk
  LEFT JOIN auth.users u ON u.id = fk.user_id
  LEFT JOIN firmalar f ON f.id = fk.firma_id
  WHERE fk.firma_id = p_firma_id
  ORDER BY fk.katilim_tarihi;
$$;

GRANT EXECUTE ON FUNCTION firma_kullanicilari_detay(uuid) TO authenticated, anon;

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_firma_modulleri_firma_id ON firma_modulleri(firma_id);
CREATE INDEX IF NOT EXISTS idx_firma_modulleri_modul_id ON firma_modulleri(modul_id);
CREATE INDEX IF NOT EXISTS idx_firma_modulleri_aktif ON firma_modulleri(aktif);

CREATE INDEX IF NOT EXISTS idx_firma_uretim_modulleri_firma_id ON firma_uretim_modulleri(firma_id);
CREATE INDEX IF NOT EXISTS idx_firma_uretim_modulleri_aktif ON firma_uretim_modulleri(aktif);

CREATE INDEX IF NOT EXISTS idx_destek_talepleri_firma_id ON destek_talepleri(firma_id);
CREATE INDEX IF NOT EXISTS idx_destek_talepleri_durum ON destek_talepleri(durum);
