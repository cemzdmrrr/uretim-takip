-- ============================================================
-- Deneme planını güncelle: Tüm modüller dahil, max_modul sınırsız
-- TexPilot SaaS — 14 gün deneme tüm modüllerle
-- ============================================================

UPDATE abonelik_planlari
SET
    aciklama = '14 günlük ücretsiz deneme — tüm modüller dahil',
    max_kullanici = 5,
    max_modul = NULL,
    dahil_moduller = '["uretim","finans","ik","stok","sevkiyat","tedarik","musteri","rapor","kalite","ayarlar"]'::jsonb,
    ozellikler = '{"deneme_suresi_gun": 14, "destek": "email", "tum_moduller": true}'::jsonb
WHERE plan_kodu = 'deneme';

DO $$ BEGIN RAISE NOTICE 'Deneme planı güncellendi: Tüm modüller dahil, max_modul sınırsız, max_kullanici 5.'; END $$;
