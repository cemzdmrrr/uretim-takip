-- Foreign key constraint'i kaldır
ALTER TABLE yukleme_kayitlari 
DROP CONSTRAINT yukleme_kayitlari_model_id_fkey;

-- Kontrol et - constraint kaldırıldı mı?
SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'yukleme_kayitlari';
