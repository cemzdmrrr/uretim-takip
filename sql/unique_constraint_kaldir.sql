-- Atama tablolarından unique constraint'leri kaldır
-- Aynı model için birden fazla atama kaydı eklenebilmesi için

-- yikama_atamalari
ALTER TABLE IF EXISTS yikama_atamalari DROP CONSTRAINT IF EXISTS yikama_atamalari_model_id_key;

-- nakis_atamalari  
ALTER TABLE IF EXISTS nakis_atamalari DROP CONSTRAINT IF EXISTS nakis_atamalari_model_id_key;

-- konfeksiyon_atamalari
ALTER TABLE IF EXISTS konfeksiyon_atamalari DROP CONSTRAINT IF EXISTS konfeksiyon_atamalari_model_id_key;

-- utu_atamalari
ALTER TABLE IF EXISTS utu_atamalari DROP CONSTRAINT IF EXISTS utu_atamalari_model_id_key;

-- ilik_dugme_atamalari
ALTER TABLE IF EXISTS ilik_dugme_atamalari DROP CONSTRAINT IF EXISTS ilik_dugme_atamalari_model_id_key;

-- paketleme_atamalari
ALTER TABLE IF EXISTS paketleme_atamalari DROP CONSTRAINT IF EXISTS paketleme_atamalari_model_id_key;

-- dokuma_atamalari
ALTER TABLE IF EXISTS dokuma_atamalari DROP CONSTRAINT IF EXISTS dokuma_atamalari_model_id_key;

-- kalite_kontrol_atamalari
ALTER TABLE IF EXISTS kalite_kontrol_atamalari DROP CONSTRAINT IF EXISTS kalite_kontrol_atamalari_model_id_key;

-- sevkiyat_kayitlari
ALTER TABLE IF EXISTS sevkiyat_kayitlari DROP CONSTRAINT IF EXISTS sevkiyat_kayitlari_model_id_key;

-- Diğer olası constraint isimleri
ALTER TABLE IF EXISTS yikama_atamalari DROP CONSTRAINT IF EXISTS yikama_atamalari_model_id_unique;
ALTER TABLE IF EXISTS nakis_atamalari DROP CONSTRAINT IF EXISTS nakis_atamalari_model_id_unique;
ALTER TABLE IF EXISTS konfeksiyon_atamalari DROP CONSTRAINT IF EXISTS konfeksiyon_atamalari_model_id_unique;
ALTER TABLE IF EXISTS utu_atamalari DROP CONSTRAINT IF EXISTS utu_atamalari_model_id_unique;
ALTER TABLE IF EXISTS ilik_dugme_atamalari DROP CONSTRAINT IF EXISTS ilik_dugme_atamalari_model_id_unique;
ALTER TABLE IF EXISTS paketleme_atamalari DROP CONSTRAINT IF EXISTS paketleme_atamalari_model_id_unique;
ALTER TABLE IF EXISTS dokuma_atamalari DROP CONSTRAINT IF EXISTS dokuma_atamalari_model_id_unique;
ALTER TABLE IF EXISTS kalite_kontrol_atamalari DROP CONSTRAINT IF EXISTS kalite_kontrol_atamalari_model_id_unique;

-- Başarı mesajı
SELECT 'Unique constraint''ler kaldırıldı. Artık aynı model için birden fazla atama kaydı eklenebilir.' as sonuc;
