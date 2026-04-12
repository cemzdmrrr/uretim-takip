-- ÖNCE: Mevcut yukleme_kayitlari verilerini kontrol et (varsa)
SELECT COUNT(*) FROM yukleme_kayitlari;

-- SONRA: model_id sütununu UUID'den integer'a çevir
ALTER TABLE yukleme_kayitlari 
ALTER COLUMN model_id TYPE integer USING NULL;

-- Foreign key ekle (opsiyonel ama önerilen)
ALTER TABLE yukleme_kayitlari
ADD CONSTRAINT fk_yukleme_model 
FOREIGN KEY (model_id) REFERENCES modeller(id);

-- Kontrol et
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'yukleme_kayitlari'
  AND column_name = 'model_id';
