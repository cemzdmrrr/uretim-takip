-- ==========================================
-- SQL FONKSİYONLARININ VAR OLUP OLMADINI KONTROL ET
-- ==========================================

-- 1. Tüm fonksiyonları listele
SELECT proname, pronargs, proargnames 
FROM pg_proc 
WHERE proname LIKE '%asama%' OR proname LIKE '%onceki%'
ORDER BY proname;

-- Sonuç: get_onceki_asama_gerceklesen_adetler ve update_sonraki_asama_hedef_adetler olmalı

-- 2. VIEW'leri kontrol et
SELECT tablename FROM pg_tables WHERE tablename LIKE '%asama%';
SELECT viewname FROM pg_views WHERE viewname LIKE '%asama%';

-- 3. Test: Fonksiyonu çalıştır
-- Eğer dokuma tablosunda veri varsa:
SELECT * FROM get_onceki_asama_gerceklesen_adetler(
  (SELECT id::TEXT FROM triko_takip LIMIT 1),
  'konfeksiyon'
) LIMIT 5;

-- 4. Dokuma tablosunda veri var mı?
SELECT COUNT(*) as dokuma_record_count FROM dokuma_beden_takip;
SELECT * FROM dokuma_beden_takip LIMIT 5;
