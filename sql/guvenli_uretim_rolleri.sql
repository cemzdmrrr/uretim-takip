-- Güvenli Üretim Rolleri Yetkilendirme Sistemi
-- Bu script sadece mevcut tablolar için RLS kurar

-- 1. MEVCUT TABLOLARI KONTROL ET
DO $$
DECLARE
    table_exists boolean;
BEGIN
    -- Tabloların varlığını kontrol et
    SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'triko_takip') INTO table_exists;
    IF NOT table_exists THEN
        RAISE EXCEPTION 'triko_takip tablosu mevcut değil!';
    END IF;
    
    SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'dokuma_atamalari') INTO table_exists;
    IF NOT table_exists THEN
        RAISE EXCEPTION 'dokuma_atamalari tablosu mevcut değil!';
    END IF;
    
    SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_roles') INTO table_exists;
    IF NOT table_exists THEN
        RAISE EXCEPTION 'user_roles tablosu mevcut değil!';
    END IF;
    
    RAISE NOTICE 'Temel tablolar mevcut, devam ediliyor...';
END $$;

-- 2. GÜVENLIK KONTROLÜ FONKSIYONLARI
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

-- Admin kontrolü
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN has_role('admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. ATAMA KONTROL FONKSIYONU (Sadece mevcut tablolar için)
CREATE OR REPLACE FUNCTION is_assigned_to_model(model_id_param TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    assignment_count INTEGER := 0;
BEGIN
  -- Dokuma atamaları kontrolü
  SELECT COUNT(*) INTO assignment_count
  FROM dokuma_atamalari 
  WHERE model_id = model_id_param AND atanan_kullanici_id = auth.uid();
  
  IF assignment_count > 0 THEN
    RETURN TRUE;
  END IF;
  
  -- Konfeksiyon atamaları kontrolü (varsa)
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'konfeksiyon_atamalari') THEN
    SELECT COUNT(*) INTO assignment_count
    FROM konfeksiyon_atamalari 
    WHERE model_id = model_id_param AND atanan_kullanici_id = auth.uid();
    
    IF assignment_count > 0 THEN
      RETURN TRUE;
    END IF;
  END IF;
  
  -- Diğer atama tabloları (varsa)
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'nakis_atamalari') THEN
    SELECT COUNT(*) INTO assignment_count
    FROM nakis_atamalari 
    WHERE model_id = model_id_param AND atanan_kullanici_id = auth.uid();
    
    IF assignment_count > 0 THEN
      RETURN TRUE;
    END IF;
  END IF;
  
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'yikama_atamalari') THEN
    SELECT COUNT(*) INTO assignment_count
    FROM yikama_atamalari 
    WHERE model_id = model_id_param AND atanan_kullanici_id = auth.uid();
    
    IF assignment_count > 0 THEN
      RETURN TRUE;
    END IF;
  END IF;
  
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ilik_dugme_atamalari') THEN
    SELECT COUNT(*) INTO assignment_count
    FROM ilik_dugme_atamalari 
    WHERE model_id = model_id_param AND atanan_kullanici_id = auth.uid();
    
    IF assignment_count > 0 THEN
      RETURN TRUE;
    END IF;
  END IF;
  
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utu_atamalari') THEN
    SELECT COUNT(*) INTO assignment_count
    FROM utu_atamalari 
    WHERE model_id = model_id_param AND atanan_kullanici_id = auth.uid();
    
    IF assignment_count > 0 THEN
      RETURN TRUE;
    END IF;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. MEVCUT KULLANICI BİLGİLERİNİ ALMA FONKSIYONU
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
  
  RETURN COALESCE(user_info, json_build_object(
    'user_id', auth.uid(),
    'email', auth.email(),
    'role', null,
    'is_admin', false,
    'atolye_id', null
  ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RLS POLİTİKALARI - TRIKO_TAKIP TABLOSU
-- Eski politikaları temizle
DROP POLICY IF EXISTS "Admin tüm modelleri görebilir" ON triko_takip;
DROP POLICY IF EXISTS "Kullanıcılar sadece atanan modelleri görebilir" ON triko_takip;
DROP POLICY IF EXISTS "Herkes modelleri görebilir" ON triko_takip;
DROP POLICY IF EXISTS "Admin politikası" ON triko_takip;
DROP POLICY IF EXISTS "Kullanıcı politikası" ON triko_takip;

-- Admin'ler her şeyi görebilir
CREATE POLICY "Admin modeller tum erisim" 
ON triko_takip FOR ALL
USING (is_admin());

-- Normal kullanıcılar sadece atanan modelleri görebilir
CREATE POLICY "Kullanici atanmis modeller" 
ON triko_takip FOR SELECT
USING (
  NOT is_admin() AND is_assigned_to_model(id::text)
);

-- RLS etkinleştir
ALTER TABLE triko_takip ENABLE ROW LEVEL SECURITY;

-- 6. RLS POLİTİKALARI - USER_ROLES TABLOSU
-- Eski politikaları temizle
DROP POLICY IF EXISTS "Kullanıcı kendi rolünü görebilir" ON user_roles;
DROP POLICY IF EXISTS "Admin tüm rolleri görebilir" ON user_roles;

-- Kullanıcılar kendi rollerini görebilir
CREATE POLICY "Kullanici kendi rol bilgisi" 
ON user_roles FOR SELECT
USING (user_id = auth.uid());

-- Admin'ler tüm rolleri görebilir ve yönetebilir
CREATE POLICY "Admin roller tum erisim" 
ON user_roles FOR ALL
USING (is_admin());

-- RLS etkinleştir
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 7. RLS POLİTİKALARI - DOKUMA ATAMALARI
-- Eski politikaları temizle
DROP POLICY IF EXISTS "Admin dokuma atamaları tüm erişim" ON dokuma_atamalari;
DROP POLICY IF EXISTS "Kullanıcı kendi dokuma atamalarını görebilir" ON dokuma_atamalari;

-- Admin'ler tüm atamaları görebilir
CREATE POLICY "Admin dokuma atamalari tum erisim" 
ON dokuma_atamalari FOR ALL
USING (is_admin());

-- Kullanıcılar kendi atamalarını görebilir
CREATE POLICY "Kullanici kendi dokuma atamalari" 
ON dokuma_atamalari FOR SELECT
USING (atanan_kullanici_id = auth.uid());

-- Kullanıcılar kendi atamalarını güncelleyebilir
CREATE POLICY "Kullanici dokuma atama guncelleme" 
ON dokuma_atamalari FOR UPDATE
USING (atanan_kullanici_id = auth.uid());

-- RLS etkinleştir
ALTER TABLE dokuma_atamalari ENABLE ROW LEVEL SECURITY;

-- 8. KONFEKSIYON ATAMALARI (VARSA)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'konfeksiyon_atamalari') THEN
    -- Eski politikaları temizle
    DROP POLICY IF EXISTS "Admin konfeksiyon atamaları tüm erişim" ON konfeksiyon_atamalari;
    DROP POLICY IF EXISTS "Kullanıcı kendi konfeksiyon atamalarını görebilir" ON konfeksiyon_atamalari;
    
    -- Yeni politikalar
    EXECUTE 'CREATE POLICY "Admin konfeksiyon atamalari tum erisim" ON konfeksiyon_atamalari FOR ALL USING (is_admin())';
    EXECUTE 'CREATE POLICY "Kullanici kendi konfeksiyon atamalari" ON konfeksiyon_atamalari FOR SELECT USING (atanan_kullanici_id = auth.uid())';
    EXECUTE 'CREATE POLICY "Kullanici konfeksiyon atama guncelleme" ON konfeksiyon_atamalari FOR UPDATE USING (atanan_kullanici_id = auth.uid())';
    
    -- RLS etkinleştir
    ALTER TABLE konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Konfeksiyon atamaları tablosu için RLS kuruldu';
  ELSE
    RAISE NOTICE 'Konfeksiyon atamaları tablosu mevcut değil, atlanıyor...';
  END IF;
END $$;

-- 9. DİĞER ATAMA TABLOLARI (VARLARSA)
DO $$
DECLARE
  tablo_listesi TEXT[] := ARRAY['nakis_atamalari', 'yikama_atamalari', 'ilik_dugme_atamalari', 'utu_atamalari'];
  tablo_adi TEXT;
BEGIN
  FOREACH tablo_adi IN ARRAY tablo_listesi
  LOOP
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = tablo_adi) THEN
      -- Eski politikaları temizle
      EXECUTE format('DROP POLICY IF EXISTS "Admin %s tüm erişim" ON %s', tablo_adi, tablo_adi);
      EXECUTE format('DROP POLICY IF EXISTS "Kullanıcı kendi %s görebilir" ON %s', tablo_adi, tablo_adi);
      
      -- Yeni politikalar
      EXECUTE format('CREATE POLICY "Admin %s tum erisim" ON %s FOR ALL USING (is_admin())', tablo_adi, tablo_adi);
      EXECUTE format('CREATE POLICY "Kullanici kendi %s" ON %s FOR SELECT USING (atanan_kullanici_id = auth.uid())', tablo_adi, tablo_adi);
      EXECUTE format('CREATE POLICY "Kullanici %s guncelleme" ON %s FOR UPDATE USING (atanan_kullanici_id = auth.uid())', tablo_adi, tablo_adi);
      
      -- RLS etkinleştir
      EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', tablo_adi);
      
      RAISE NOTICE '% tablosu için RLS kuruldu', tablo_adi;
    ELSE
      RAISE NOTICE '% tablosu mevcut değil, atlanıyor...', tablo_adi;
    END IF;
  END LOOP;
END $$;

-- 10. BAŞARILI KURULUM MESAJI
DO $$
DECLARE
  mevcut_tablolar TEXT := '';
  table_rec RECORD;
BEGIN
  -- Mevcut atama tablolarını listele
  FOR table_rec IN 
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%atamalari' 
    ORDER BY table_name
  LOOP
    mevcut_tablolar := mevcut_tablolar || table_rec.table_name || ', ';
  END LOOP;
  
  -- Son virgülü kaldır
  IF length(mevcut_tablolar) > 0 THEN
    mevcut_tablolar := left(mevcut_tablolar, length(mevcut_tablolar) - 2);
  END IF;
  
  RAISE NOTICE '🎉 Güvenli üretim zinciri rol tabanlı yetkilendirme sistemi başarıyla kuruldu!';
  RAISE NOTICE '✅ RLS politikaları aktif';
  RAISE NOTICE '✅ Rol kontrol fonksiyonları oluşturuldu'; 
  RAISE NOTICE '✅ Mevcut atama tabloları: %', COALESCE(mevcut_tablolar, 'Hiçbiri');
  RAISE NOTICE '✅ Kullanıcılar sadece atanan modelleri görebilir';
  RAISE NOTICE '✅ Admin''ler tüm modellere erişebilir';
  RAISE NOTICE '';
  RAISE NOTICE '📝 Sıradaki adımlar:';
  RAISE NOTICE '1. Eksik atama tablolarını oluşturmak için eksik_atama_tablolari_olustur.sql çalıştırın';
  RAISE NOTICE '2. Kullanıcılara roller atayın';
  RAISE NOTICE '3. Frontend uygulamada test edin';
END $$;