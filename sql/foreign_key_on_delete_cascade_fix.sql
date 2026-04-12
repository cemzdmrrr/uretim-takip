-- =====================================================
-- FOREIGN KEY ON DELETE CASCADE FIX
-- =====================================================
-- triko_takip tablosundan model silindiğinde,
-- ona bağlı tüm atamalar otomatik silinsin
-- =====================================================

DO $$ 
DECLARE
  constraint_name text;
BEGIN
  -- 1. UTU_ATAMALARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'utu_atamalari' AND column_name = 'model_id') THEN
    ALTER TABLE utu_atamalari DROP CONSTRAINT IF EXISTS utu_atamalari_model_id_fkey;
    ALTER TABLE utu_atamalari ADD CONSTRAINT utu_atamalari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'utu_atamalari güncellendi';
  END IF;

  -- 2. DOKUMA_ATAMALARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'dokuma_atamalari' AND column_name = 'model_id') THEN
    ALTER TABLE dokuma_atamalari DROP CONSTRAINT IF EXISTS dokuma_atamalari_model_id_fkey;
    ALTER TABLE dokuma_atamalari ADD CONSTRAINT dokuma_atamalari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'dokuma_atamalari güncellendi';
  END IF;

  -- 3. KONFEKSIYON_ATAMALARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'model_id') THEN
    ALTER TABLE konfeksiyon_atamalari DROP CONSTRAINT IF EXISTS konfeksiyon_atamalari_model_id_fkey;
    ALTER TABLE konfeksiyon_atamalari ADD CONSTRAINT konfeksiyon_atamalari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'konfeksiyon_atamalari güncellendi';
  END IF;

  -- 4. YIKAMA_ATAMALARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'yikama_atamalari' AND column_name = 'model_id') THEN
    ALTER TABLE yikama_atamalari DROP CONSTRAINT IF EXISTS yikama_atamalari_model_id_fkey;
    ALTER TABLE yikama_atamalari ADD CONSTRAINT yikama_atamalari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'yikama_atamalari güncellendi';
  END IF;

  -- 5. ILIK_DUGME_ATAMALARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'model_id') THEN
    ALTER TABLE ilik_dugme_atamalari DROP CONSTRAINT IF EXISTS ilik_dugme_atamalari_model_id_fkey;
    ALTER TABLE ilik_dugme_atamalari ADD CONSTRAINT ilik_dugme_atamalari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'ilik_dugme_atamalari güncellendi';
  END IF;

  -- 6. KALITE_KONTROL_ATAMALARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'model_id') THEN
    ALTER TABLE kalite_kontrol_atamalari DROP CONSTRAINT IF EXISTS kalite_kontrol_atamalari_model_id_fkey;
    ALTER TABLE kalite_kontrol_atamalari ADD CONSTRAINT kalite_kontrol_atamalari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'kalite_kontrol_atamalari güncellendi';
  END IF;

  -- 7. PAKETLEME_ATAMALARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'paketleme_atamalari' AND column_name = 'model_id') THEN
    ALTER TABLE paketleme_atamalari DROP CONSTRAINT IF EXISTS paketleme_atamalari_model_id_fkey;
    ALTER TABLE paketleme_atamalari ADD CONSTRAINT paketleme_atamalari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'paketleme_atamalari güncellendi';
  END IF;

  -- 8. SEVKIYAT_KAYITLARI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'sevkiyat_kayitlari' AND column_name = 'model_id') THEN
    ALTER TABLE sevkiyat_kayitlari DROP CONSTRAINT IF EXISTS sevkiyat_kayitlari_model_id_fkey;
    ALTER TABLE sevkiyat_kayitlari ADD CONSTRAINT sevkiyat_kayitlari_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'sevkiyat_kayitlari güncellendi';
  END IF;

  -- 9. MODEL_BEDEN_DAGILIMI
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'model_beden_dagilimi' AND column_name = 'model_id') THEN
    ALTER TABLE model_beden_dagilimi DROP CONSTRAINT IF EXISTS model_beden_dagilimi_model_id_fkey;
    ALTER TABLE model_beden_dagilimi ADD CONSTRAINT model_beden_dagilimi_model_id_fkey 
      FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE;
    RAISE NOTICE 'model_beden_dagilimi güncellendi';
  END IF;

END $$;

-- =====================================================
-- NOT: BEDEN TAKIP TABLOLARI
-- =====================================================
-- Beden takip tabloları (dokuma_beden_takip, konfeksiyon_beden_takip, vb.)
-- genellikle atama_id üzerinden ilişkilendirilir, model_id değil.
-- Bu durumda CASCADE zaten dolaylı çalışır:
-- Model silinir -> Atama silinir -> Beden takip otomatik silinir
-- =====================================================

-- =====================================================
-- İşlem tamamlandı!
-- =====================================================
-- Artık triko_takip tablosundan bir model silindiğinde:
-- - Tüm atama kayıtları (dokuma, konfeksiyon, yıkama, ütü, ilik_dugme, kalite_kontrol, paketleme)
-- - Sevkiyat kayıtları
-- CASCADE zinciri ile beden takip kayıtları da OTOMATIK olarak silinecektir.
-- =====================================================

SELECT 'Foreign key constraints başarıyla güncellendi! ON DELETE CASCADE aktif.' as sonuc;
