-- Mevcut dosyalar modülünü temizle

-- ÖNCE: Storage politikalarını sil (Dashboard'dan veya SQL ile)
-- Storage > Policies > dosyalar bucket > her policy'i tek tek sil

-- Alternatif: Storage politikalarını SQL ile sil
DROP POLICY IF EXISTS "Dosya Okuma İzni" ON storage.objects;
DROP POLICY IF EXISTS "Dosya Yükleme İzni" ON storage.objects;
DROP POLICY IF EXISTS "Dosya Güncelleme İzni" ON storage.objects;
DROP POLICY IF EXISTS "Dosya Silme İzni" ON storage.objects;

-- Mevcut trigger'ları sil
DROP TRIGGER IF EXISTS dosyalar_guncelleme_tarihi ON dosyalar;
DROP TRIGGER IF EXISTS dosyalar_gecmis_trigger ON dosyalar;

-- Mevcut politikaları sil
DROP POLICY IF EXISTS dosyalar_select_policy ON dosyalar;
DROP POLICY IF EXISTS dosyalar_insert_policy ON dosyalar;
DROP POLICY IF EXISTS dosyalar_update_policy ON dosyalar;
DROP POLICY IF EXISTS dosyalar_delete_policy ON dosyalar;
DROP POLICY IF EXISTS dosya_paylasimlari_select_policy ON dosya_paylasimlari;
DROP POLICY IF EXISTS dosya_paylasimlari_insert_policy ON dosya_paylasimlari;
DROP POLICY IF EXISTS dosya_paylasimlari_update_policy ON dosya_paylasimlari;
DROP POLICY IF EXISTS dosya_paylasimlari_delete_policy ON dosya_paylasimlari;
DROP POLICY IF EXISTS dosya_gecmisi_select_policy ON dosya_gecmisi;
DROP POLICY IF EXISTS dosya_gecmisi_insert_policy ON dosya_gecmisi;
DROP POLICY IF EXISTS dosya_yorumlari_select_policy ON dosya_yorumlari;
DROP POLICY IF EXISTS dosya_yorumlari_insert_policy ON dosya_yorumlari;
DROP POLICY IF EXISTS dosya_yorumlari_update_policy ON dosya_yorumlari;
DROP POLICY IF EXISTS dosya_yorumlari_delete_policy ON dosya_yorumlari;

-- Mevcut tabloları sil (CASCADE ile bağımlılıkları da sil)
DROP TABLE IF EXISTS dosya_yorumlari CASCADE;
DROP TABLE IF EXISTS dosya_gecmisi CASCADE;
DROP TABLE IF EXISTS dosya_paylasimlari CASCADE;
DROP TABLE IF EXISTS dosyalar CASCADE;

-- Mevcut fonksiyonları sil
DROP FUNCTION IF EXISTS update_guncelleme_tarihi() CASCADE;
DROP FUNCTION IF EXISTS dosya_gecmis_kayit() CASCADE;

-- Şimdi supabase_dosyalar_basit.sql dosyasını çalıştırabilirsiniz
