-- Üretim Zinciri Rolleri ve Yetkilendirme Sistemi
-- Bu script üretim zincirindeki farklı firmalar ve roller için yetkilendirme kurar

-- 1. MEVCUT ROLLER (user_roles tablosunda)
-- admin: Tüm işlemlere erişim
-- orgu_firma, dokuma_firma: Örgü/dokuma işlemleri
-- konfeksiyon_firma: Konfeksiyon işlemleri  
-- nakis_firma: Nakış işlemleri
-- yikama_firma: Yıkama işlemleri
-- ilik_dugme_firma: İlik düğme işlemleri
-- utu_firma: Ütü işlemleri
-- kalite_kontrol: Kalite kontrol işlemleri
-- paketleme: Paketleme işlemleri
-- firma: Genel firma kullanıcısı

-- 2. ROW LEVEL SECURITY POLİTİKALARI

-- triko_takip tablosu için RLS politikaları
DROP POLICY IF EXISTS "Admin tüm modelleri görebilir" ON triko_takip;
DROP POLICY IF EXISTS "Kullanıcılar sadece atanan modelleri görebilir" ON triko_takip;

-- Admin'ler her şeyi görebilir
CREATE POLICY "Admin tüm modelleri görebilir" 
ON triko_takip FOR ALL
USING (
  auth.jwt() ->> 'role' = 'authenticated' AND
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

-- Diğer kullanıcılar sadece kendilerine atanan modelleri görebilir
CREATE POLICY "Kullanıcılar sadece atanan modelleri görebilir" 
ON triko_takip FOR SELECT
USING (
  auth.jwt() ->> 'role' = 'authenticated' AND
  (
    -- Admin değilse, sadece atanmış modelleri görebilir
    NOT EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    ) AND
    (
      -- Herhangi bir atama tablosunda bu kullanıcıya atanmış model var mı?
      id::text IN (
        SELECT model_id FROM dokuma_atamalari WHERE atanan_kullanici_id = auth.uid()
        UNION
        SELECT model_id FROM konfeksiyon_atamalari WHERE atanan_kullanici_id = auth.uid()
        UNION
        SELECT model_id FROM nakis_atamalari WHERE atanan_kullanici_id = auth.uid()
        UNION
        SELECT model_id FROM yikama_atamalari WHERE atanan_kullanici_id = auth.uid()
        UNION
        SELECT model_id FROM ilik_dugme_atamalari WHERE atanan_kullanici_id = auth.uid()
        UNION
        SELECT model_id FROM utu_atamalari WHERE atanan_kullanici_id = auth.uid()
      )
    )
  )
);

-- 3. ATAMA TABLOLARI İÇİN RLS POLİTİKALARI
-- Her atama tablosu için ayrı politikalar

-- Dokuma atamaları
DROP POLICY IF EXISTS "Admin dokuma atamaları tüm erişim" ON dokuma_atamalari;
DROP POLICY IF EXISTS "Kullanıcı kendi dokuma atamalarını görebilir" ON dokuma_atamalari;

CREATE POLICY "Admin dokuma atamaları tüm erişim" 
ON dokuma_atamalari FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Kullanıcı kendi dokuma atamalarını görebilir" 
ON dokuma_atamalari FOR SELECT
USING (
  atanan_kullanici_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'dokuma_firma', 'orgu_firma')
  )
);

-- Konfeksiyon atamaları
DROP POLICY IF EXISTS "Admin konfeksiyon atamaları tüm erişim" ON konfeksiyon_atamalari;
DROP POLICY IF EXISTS "Kullanıcı kendi konfeksiyon atamalarını görebilir" ON konfeksiyon_atamalari;

CREATE POLICY "Admin konfeksiyon atamaları tüm erişim" 
ON konfeksiyon_atamalari FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Kullanıcı kendi konfeksiyon atamalarını görebilir" 
ON konfeksiyon_atamalari FOR SELECT
USING (
  atanan_kullanici_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'konfeksiyon_firma')
  )
);

-- Nakış atamaları
DROP POLICY IF EXISTS "Admin nakis atamaları tüm erişim" ON nakis_atamalari;
DROP POLICY IF EXISTS "Kullanıcı kendi nakis atamalarını görebilir" ON nakis_atamalari;

CREATE POLICY "Admin nakis atamaları tüm erişim" 
ON nakis_atamalari FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Kullanıcı kendi nakis atamalarını görebilir" 
ON nakis_atamalari FOR SELECT
USING (
  atanan_kullanici_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'nakis_firma')
  )
);

-- Yıkama atamaları
DROP POLICY IF EXISTS "Admin yikama atamaları tüm erişim" ON yikama_atamalari;
DROP POLICY IF EXISTS "Kullanıcı kendi yikama atamalarını görebilir" ON yikama_atamalari;

CREATE POLICY "Admin yikama atamaları tüm erişim" 
ON yikama_atamalari FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Kullanıcı kendi yikama atamalarını görebilir" 
ON yikama_atamalari FOR SELECT
USING (
  atanan_kullanici_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'yikama_firma')
  )
);

-- İlik düğme atamaları
DROP POLICY IF EXISTS "Admin ilik_dugme atamaları tüm erişim" ON ilik_dugme_atamalari;
DROP POLICY IF EXISTS "Kullanıcı kendi ilik_dugme atamalarını görebilir" ON ilik_dugme_atamalari;

CREATE POLICY "Admin ilik_dugme atamaları tüm erişim" 
ON ilik_dugme_atamalari FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Kullanıcı kendi ilik_dugme atamalarını görebilir" 
ON ilik_dugme_atamalari FOR SELECT
USING (
  atanan_kullanici_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'ilik_dugme_firma')
  )
);

-- Ütü atamaları
DROP POLICY IF EXISTS "Admin utu atamaları tüm erişim" ON utu_atamalari;
DROP POLICY IF EXISTS "Kullanıcı kendi utu atamalarını görebilir" ON utu_atamalari;

CREATE POLICY "Admin utu atamaları tüm erişim" 
ON utu_atamalari FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Kullanıcı kendi utu atamalarını görebilir" 
ON utu_atamalari FOR SELECT
USING (
  atanan_kullanici_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'utu_firma')
  )
);

-- 4. RLS'yi ETKINLEŞTIR
ALTER TABLE triko_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE dokuma_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE nakis_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE yikama_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE ilik_dugme_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE utu_atamalari ENABLE ROW LEVEL SECURITY;

-- 5. user_roles TABLOSUNU SADECE KULLANICI KENDİ ROLÜNÜ GÖREBİLSİN
DROP POLICY IF EXISTS "Kullanıcı kendi rolünü görebilir" ON user_roles;
CREATE POLICY "Kullanıcı kendi rolünü görebilir" 
ON user_roles FOR SELECT
USING (user_id = auth.uid());

-- Admin'ler tüm rolleri görebilir
DROP POLICY IF EXISTS "Admin tüm rolleri görebilir" ON user_roles;
CREATE POLICY "Admin tüm rolleri görebilir" 
ON user_roles FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 6. ÖRNEK KULLANICI ROLLERİ EKLE (test amaçlı)
-- Bu kullanıcıları manuel olarak auth.users tablosuna eklemeniz gerekir

/*
-- Örnek kullanıcı rolleri (gerçek UUID'ler ile değiştirilmeli)
INSERT INTO user_roles (user_id, role, created_at) VALUES
  ('kullanici_uuid_1', 'orgu_firma', NOW()),
  ('kullanici_uuid_2', 'konfeksiyon_firma', NOW()),
  ('kullanici_uuid_3', 'nakis_firma', NOW()),
  ('kullanici_uuid_4', 'yikama_firma', NOW()),
  ('kullanici_uuid_5', 'ilik_dugme_firma', NOW()),
  ('kullanici_uuid_6', 'utu_firma', NOW()),
  ('kullanici_uuid_7', 'kalite_kontrol', NOW()),
  ('kullanici_uuid_8', 'paketleme', NOW())
ON CONFLICT (user_id) DO UPDATE SET 
  role = EXCLUDED.role,
  updated_at = NOW();
*/

-- 7. GÜVENLIK KONTROLÜ FONKSIYONU
-- Kullanıcının belirli bir role sahip olup olmadığını kontrol eder
CREATE OR REPLACE FUNCTION has_role(required_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = required_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. ATAMA KONTROL FONKSIYONU
-- Kullanıcının belirli bir modele atanıp atanmadığını kontrol eder
CREATE OR REPLACE FUNCTION is_assigned_to_model(model_id_param TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM (
      SELECT model_id FROM dokuma_atamalari WHERE atanan_kullanici_id = auth.uid()
      UNION
      SELECT model_id FROM konfeksiyon_atamalari WHERE atanan_kullanici_id = auth.uid()
      UNION
      SELECT model_id FROM nakis_atamalari WHERE atanan_kullanici_id = auth.uid()
      UNION
      SELECT model_id FROM yikama_atamalari WHERE atanan_kullanici_id = auth.uid()
      UNION
      SELECT model_id FROM ilik_dugme_atamalari WHERE atanan_kullanici_id = auth.uid()
      UNION
      SELECT model_id FROM utu_atamalari WHERE atanan_kullanici_id = auth.uid()
    ) assignments
    WHERE model_id = model_id_param
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. MEVCUT KULLANICI BİLGİLERİNİ ALMA FONKSIYONU
-- Frontend'den kolayca kullanılabilir
CREATE OR REPLACE FUNCTION get_current_user_info()
RETURNS JSON AS $$
DECLARE
  user_info JSON;
BEGIN
  SELECT json_build_object(
    'user_id', auth.uid(),
    'email', auth.email(),
    'role', ur.role,
    'is_admin', (ur.role = 'admin'),
    'atolye_id', ur.atolye_id
  ) INTO user_info
  FROM user_roles ur
  WHERE ur.user_id = auth.uid();
  
  RETURN user_info;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Kullanıcının atandığı modelleri getirir
CREATE OR REPLACE FUNCTION get_user_assigned_models()
RETURNS TABLE (model_id TEXT, assignment_type TEXT, assignment_status TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    da.model_id,
    'dokuma'::TEXT as assignment_type,
    da.durum as assignment_status
  FROM dokuma_atamalari da
  WHERE da.atanan_kullanici_id = auth.uid()
  
  UNION ALL
  
  SELECT 
    ka.model_id,
    'konfeksiyon'::TEXT as assignment_type,
    ka.durum as assignment_status
  FROM konfeksiyon_atamalari ka
  WHERE ka.atanan_kullanici_id = auth.uid()
  
  UNION ALL
  
  SELECT 
    na.model_id,
    'nakis'::TEXT as assignment_type,
    na.durum as assignment_status
  FROM nakis_atamalari na
  WHERE na.atanan_kullanici_id = auth.uid()
  
  UNION ALL
  
  SELECT 
    ya.model_id,
    'yikama'::TEXT as assignment_type,
    ya.durum as assignment_status
  FROM yikama_atamalari ya
  WHERE ya.atanan_kullanici_id = auth.uid()
  
  UNION ALL
  
  SELECT 
    ida.model_id,
    'ilik_dugme'::TEXT as assignment_type,
    ida.durum as assignment_status
  FROM ilik_dugme_atamalari ida
  WHERE ida.atanan_kullanici_id = auth.uid()
  
  UNION ALL
  
  SELECT 
    ua.model_id,
    'utu'::TEXT as assignment_type,
    ua.durum as assignment_status
  FROM utu_atamalari ua
  WHERE ua.atanan_kullanici_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- BAŞARILI KURULUM MESAJI
DO $$
BEGIN
  RAISE NOTICE '🎉 Üretim zinciri rol tabanlı yetkilendirme sistemi başarıyla kuruldu!';
  RAISE NOTICE '✅ RLS politikaları aktif';
  RAISE NOTICE '✅ Rol kontrol fonksiyonları oluşturuldu'; 
  RAISE NOTICE '✅ Kullanıcılar sadece atanan modelleri görebilir';
  RAISE NOTICE '✅ Admin''ler tüm modellere erişebilir';
  RAISE NOTICE '';
  RAISE NOTICE '📝 Sıradaki adımlar:';
  RAISE NOTICE '1. Kullanıcıları auth.users tablosuna ekleyin';
  RAISE NOTICE '2. user_roles tablosuna rol atamalarını yapın';
  RAISE NOTICE '3. Frontend uygulamada rol kontrollerini test edin';
END $$;