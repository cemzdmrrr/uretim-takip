-- REALTIME VIEW HATASI ÇÖZÜMÜ
-- VIEW tablolar realtime desteklemez, sadece gerçek tablolar destekler

-- 1. Hangi tablolar VIEW olduğunu kontrol et
SELECT 
    schemaname,
    viewname as tablo_adi,
    'VIEW' as tablo_tipi
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname LIKE '%uretim_kayitlari%'

UNION ALL

SELECT 
    schemaname,
    tablename as tablo_adi,
    'TABLE' as tablo_tipi
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename LIKE '%uretim_kayitlari%'

ORDER BY tablo_adi;

-- 2. Eğer uretim_kayitlari_detay bir VIEW ise, realtime'dan çıkar
-- Supabase Dashboard → Database → Replication → uretim_kayitlari_detay'i kapat

-- 3. Sadece gerçek tablolar için realtime aktif et
-- Realtime için sadece bu tablolar güvenli:
-- - uretim_kayitlari (TABLE)
-- - dokuma_atamalari (TABLE)
-- - konfeksiyon_atamalari (TABLE)
-- - user_roles (TABLE)

-- 4. VIEW tanımını gör (eğer varsa)
SELECT definition 
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname = 'uretim_kayitlari_detay';