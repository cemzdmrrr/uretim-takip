-- ==========================================
-- ÇEKİ LİSTESİ BEDEN BAZLI KOLONLAR
-- ==========================================
-- Paketleme tamamlandığında beden bazlı koli takibi için

-- 1. Beden kodu kolonu ekle
ALTER TABLE ceki_listesi 
ADD COLUMN IF NOT EXISTS beden_kodu VARCHAR(20);

COMMENT ON COLUMN ceki_listesi.beden_kodu IS 'Paketin beden kodu (S, M, L, XL vb.) - tek beden kolileri için';

-- 2. Koli başına adet kolonu ekle
ALTER TABLE ceki_listesi 
ADD COLUMN IF NOT EXISTS adet_per_koli INTEGER DEFAULT 10;

COMMENT ON COLUMN ceki_listesi.adet_per_koli IS 'Her kolide kaç adet var (örn: 10 adet/koli)';

-- 3. Mix koli (karışık beden) desteği
ALTER TABLE ceki_listesi 
ADD COLUMN IF NOT EXISTS is_mix_koli BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN ceki_listesi.is_mix_koli IS 'Bu koli karışık bedenli mi?';

-- 4. Mix koli beden detayları (JSONB)
ALTER TABLE ceki_listesi 
ADD COLUMN IF NOT EXISTS mix_beden_detay JSONB;

COMMENT ON COLUMN ceki_listesi.mix_beden_detay IS 'Mix koli beden dağılımı. Örnek: [{"beden":"S","adet":5},{"beden":"M","adet":3},{"beden":"L","adet":2}]';

-- 5. İndeks ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_ceki_listesi_beden 
ON ceki_listesi(model_id, beden_kodu);

CREATE INDEX IF NOT EXISTS idx_ceki_listesi_mix 
ON ceki_listesi(model_id, is_mix_koli) WHERE is_mix_koli = TRUE;

-- ==========================================
-- ÖRNEK VERİLER
-- ==========================================

-- Tek beden koli örneği:
-- S beden: 100 adet paketlendi, her koliye 10 adet = 10 koli
-- INSERT INTO ceki_listesi (model_id, beden_kodu, adet, adet_per_koli, koli_adedi, is_mix_koli, paketleme_tarihi, gonderim_durumu)
-- VALUES ('model-uuid', 'S', 100, 10, 10, FALSE, NOW(), 'bekliyor');

-- Mix koli örneği:
-- Karışık koli: Her kolide 3S + 4M + 3L = 10 adet, toplam 5 koli
-- INSERT INTO ceki_listesi (model_id, beden_kodu, adet, adet_per_koli, koli_adedi, is_mix_koli, mix_beden_detay, paketleme_tarihi, gonderim_durumu)
-- VALUES (
--   'model-uuid', 
--   'MIX', 
--   50, 
--   10, 
--   5, 
--   TRUE, 
--   '[{"beden":"S","adet":3},{"beden":"M","adet":4},{"beden":"L","adet":3}]'::JSONB,
--   NOW(), 
--   'bekliyor'
-- );

-- ==========================================
-- MIX KOLİ AÇIKLAMASI
-- ==========================================
-- Mix koli: Bir kolide birden fazla beden bulunur
-- Örnek: 1 kolide 3 adet S + 4 adet M + 3 adet L = 10 adet
-- 
-- Avantajları:
-- - Müşteriye karışık gönderi yapılabilir
-- - Stok dengeleme kolaylaşır
-- - Küçük siparişlerde tek koli ile tüm bedenler gönderilebilir
