-- ==========================================
-- FIRE CASCADE: Atamalari Tablolarına Aktarım
-- ==========================================
-- Dokuma'da fire düşüldükten sonra net adet, 
-- konfeksiyon_atamalari tablosuna yazılır

-- ==========================================
-- 1. ATAMALARI TABLOLARINA hedef_adet KOLONU EKLE
-- ==========================================

-- Konfeksiyon atamaları
ALTER TABLE konfeksiyon_atamalari 
ADD COLUMN IF NOT EXISTS hedef_adet INTEGER DEFAULT 0;

ALTER TABLE konfeksiyon_atamalari 
ADD COLUMN IF NOT EXISTS fire_dusulmus_adet INTEGER DEFAULT 0;

COMMENT ON COLUMN konfeksiyon_atamalari.hedef_adet IS 'Önceki aşamadan (dokuma) gelen toplam hedef adet';
COMMENT ON COLUMN konfeksiyon_atamalari.fire_dusulmus_adet IS 'Fire düşüldükten sonra kalan net adet';

-- Yıkama atamaları
ALTER TABLE yikama_atamalari 
ADD COLUMN IF NOT EXISTS hedef_adet INTEGER DEFAULT 0;

ALTER TABLE yikama_atamalari 
ADD COLUMN IF NOT EXISTS fire_dusulmus_adet INTEGER DEFAULT 0;

-- Ütü atamaları
ALTER TABLE utu_atamalari 
ADD COLUMN IF NOT EXISTS hedef_adet INTEGER DEFAULT 0;

ALTER TABLE utu_atamalari 
ADD COLUMN IF NOT EXISTS fire_dusulmus_adet INTEGER DEFAULT 0;

-- İlik Düğme atamaları
ALTER TABLE ilik_dugme_atamalari 
ADD COLUMN IF NOT EXISTS hedef_adet INTEGER DEFAULT 0;

ALTER TABLE ilik_dugme_atamalari 
ADD COLUMN IF NOT EXISTS fire_dusulmus_adet INTEGER DEFAULT 0;

-- ==========================================
-- 2. SQL FONKSİYONUNU GÜNCELLE
-- ==========================================
-- Hem beden_takip hem de atamalari tablosuna yazar

DROP FUNCTION IF EXISTS update_sonraki_asama_hedef_adetler(UUID, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION update_sonraki_asama_hedef_adetler(
    p_model_id UUID,
    p_tamamlanan_asama TEXT -- 'dokuma', 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme'
) RETURNS VOID AS $$
DECLARE
    v_sonraki_asama TEXT;
    v_sonraki_beden_tablo TEXT;
    v_sonraki_atama_tablo TEXT;
    v_sonraki_atama_id INTEGER;
    v_toplam_hedef INTEGER := 0;
    v_toplam_fire_dusulmus INTEGER := 0;
    v_rec RECORD;
BEGIN
    -- Tamamlanan aşamaya göre sonraki aşamayı belirle
    CASE p_tamamlanan_asama
        WHEN 'dokuma' THEN v_sonraki_asama := 'konfeksiyon';
        WHEN 'konfeksiyon' THEN v_sonraki_asama := 'yikama';
        WHEN 'yikama' THEN v_sonraki_asama := 'utu';
        WHEN 'utu' THEN v_sonraki_asama := 'ilik_dugme';
        WHEN 'ilik_dugme' THEN v_sonraki_asama := 'kalite_kontrol';
        ELSE 
            RAISE NOTICE 'Bilinmeyen aşama: %', p_tamamlanan_asama;
            RETURN;
    END CASE;
    
    v_sonraki_beden_tablo := v_sonraki_asama || '_beden_takip';
    v_sonraki_atama_tablo := v_sonraki_asama || '_atamalari';
    
    -- Sonraki aşama atama_id'sini bul (en son oluşturulanı)
    EXECUTE format('
        SELECT id FROM %I
        WHERE model_id = $1
        ORDER BY created_at DESC
        LIMIT 1
    ', v_sonraki_atama_tablo) INTO v_sonraki_atama_id USING p_model_id;
    
    -- Eğer sonraki atama bulunamadıysa, işlem yapma
    IF v_sonraki_atama_id IS NULL THEN
        RAISE NOTICE 'Sonraki aşama ataması bulunamadı: % için model %', v_sonraki_asama, p_model_id;
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Atama bulundu: % -> atama_id: %', v_sonraki_asama, v_sonraki_atama_id;
    
    -- ==========================================
    -- A) BEDEN TAKIP TABLOSUNA YAZ
    -- ==========================================
    FOR v_rec IN 
        SELECT * FROM get_onceki_asama_gerceklesen_adetler(p_model_id::TEXT, v_sonraki_asama)
    LOOP
        -- Beden bazında hedef adetleri güncelle veya oluştur
        EXECUTE format('
            INSERT INTO %I (atama_id, model_id, beden_kodu, hedef_adet, kayit_tarihi)
            VALUES ($1, $2, $3, $4, NOW())
            ON CONFLICT (atama_id, beden_kodu) 
            DO UPDATE SET 
                hedef_adet = EXCLUDED.hedef_adet,
                guncelleme_tarihi = NOW()
        ', v_sonraki_beden_tablo) 
        USING v_sonraki_atama_id, p_model_id, v_rec.beden_kodu, v_rec.gerceklesen_adet;
        
        -- Toplam adetleri hesapla
        v_toplam_fire_dusulmus := v_toplam_fire_dusulmus + COALESCE(v_rec.gerceklesen_adet, 0);
        
        RAISE NOTICE '   Beden: %, Adet: %', v_rec.beden_kodu, v_rec.gerceklesen_adet;
    END LOOP;
    
    -- ==========================================
    -- B) ATAMALARI TABLOSUNA TOPLAM ADET YAZ
    -- ==========================================
    -- Önceki aşamadan orijinal hedef adeti al
    CASE p_tamamlanan_asama
        WHEN 'dokuma' THEN
            SELECT COALESCE(SUM(hedef_adet), 0) INTO v_toplam_hedef
            FROM dokuma_beden_takip WHERE model_id = p_model_id;
        WHEN 'konfeksiyon' THEN
            SELECT COALESCE(SUM(hedef_adet), 0) INTO v_toplam_hedef
            FROM konfeksiyon_beden_takip WHERE model_id = p_model_id;
        WHEN 'yikama' THEN
            SELECT COALESCE(SUM(hedef_adet), 0) INTO v_toplam_hedef
            FROM yikama_beden_takip WHERE model_id = p_model_id;
        WHEN 'utu' THEN
            SELECT COALESCE(SUM(hedef_adet), 0) INTO v_toplam_hedef
            FROM utu_beden_takip WHERE model_id = p_model_id;
        WHEN 'ilik_dugme' THEN
            SELECT COALESCE(SUM(hedef_adet), 0) INTO v_toplam_hedef
            FROM ilik_dugme_beden_takip WHERE model_id = p_model_id;
        ELSE
            v_toplam_hedef := 0;
    END CASE;
    
    -- Atamalari tablosunu güncelle
    EXECUTE format('
        UPDATE %I 
        SET 
            hedef_adet = $1,
            fire_dusulmus_adet = $2,
            updated_at = NOW()
        WHERE id = $3
    ', v_sonraki_atama_tablo) 
    USING v_toplam_hedef, v_toplam_fire_dusulmus, v_sonraki_atama_id;
    
    RAISE NOTICE '✅ % güncellendi: hedef_adet=%, fire_dusulmus_adet=%', 
        v_sonraki_atama_tablo, v_toplam_hedef, v_toplam_fire_dusulmus;
    
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 3. FONKSİYON AÇIKLAMASI
-- ==========================================
COMMENT ON FUNCTION update_sonraki_asama_hedef_adetler IS 
'Bir aşama tamamlandığında:
1. Beden bazında fire düşülmüş adetleri sonraki aşamanın beden_takip tablosuna yazar
2. Toplam hedef ve fire düşülmüş adetleri sonraki aşamanın atamalari tablosuna yazar

Örnek: Dokuma -> Konfeksiyon
- dokuma_beden_takip: S=100, M=100, L=100 (toplam 300), fire: S=10
- konfeksiyon_beden_takip: S=90, M=100, L=100 (hedef_adet olarak)
- konfeksiyon_atamalari: hedef_adet=300, fire_dusulmus_adet=290';

-- ==========================================
-- 4. TEST
-- ==========================================
-- Manuel test için:
-- SELECT update_sonraki_asama_hedef_adetler('198af513-5732-4b5c-9bae-75d06bf5e66a'::UUID, 'dokuma');

-- Sonucu kontrol et:
-- SELECT * FROM konfeksiyon_beden_takip WHERE model_id = '198af513-5732-4b5c-9bae-75d06bf5e66a';
-- SELECT hedef_adet, fire_dusulmus_adet FROM konfeksiyon_atamalari WHERE model_id = '198af513-5732-4b5c-9bae-75d06bf5e66a';
