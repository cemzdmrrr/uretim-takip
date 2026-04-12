-- ==========================================
-- AŞAMA ARASI ADET AKTARIMI SİSTEMİ
-- ==========================================
-- Her aşama tamamlandığında, gerçekleşen adetleri bir sonraki aşamaya aktarır
-- Örnek: Dokumada 10 fire verilmişse, konfeksiyona fire düşülmüş adetler geçer

-- ==========================================
-- ESKİ FONKSİYONLARI KALDIR (varsa)
-- ==========================================
DROP FUNCTION IF EXISTS get_onceki_asama_gerceklesen_adetler(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_onceki_asama_gerceklesen_adetler(TEXT, TEXT) CASCADE;

-- ==========================================
-- 1. ÖNCEK İ AŞAMANIN GERÇEKLEŞEN ADETLERİNİ GETİR
-- ==========================================
CREATE FUNCTION get_onceki_asama_gerceklesen_adetler(
    p_model_id TEXT,  -- STRING olarak kabul et, sonra UUID'ye çevir
    p_sonraki_asama TEXT -- 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme', 'kalite_kontrol'
) RETURNS TABLE (
    beden_kodu VARCHAR(10),
    gerceklesen_adet INTEGER
) AS $$
DECLARE
    v_model_uuid UUID;
BEGIN
    -- String'i UUID'ye çevir
    v_model_uuid := p_model_id::UUID;
    
    -- Aşama sırasına göre önceki aşamanın verilerini getir
    CASE p_sonraki_asama
        -- Dokumadan sonra Konfeksiyon
        WHEN 'konfeksiyon' THEN
            RETURN QUERY
            SELECT 
                dbt.beden_kodu,
                GREATEST(0, COALESCE(dbt.uretilen_adet, 0) - COALESCE(dbt.fire_adet, 0)) as gerceklesen_adet
            FROM dokuma_beden_takip dbt
            WHERE dbt.model_id = v_model_uuid
            AND dbt.uretilen_adet > 0;
            
        -- Konfeksiyondan sonra Yıkama
        WHEN 'yikama' THEN
            RETURN QUERY
            SELECT 
                kbt.beden_kodu,
                GREATEST(0, COALESCE(kbt.uretilen_adet, 0) - COALESCE(kbt.fire_adet, 0)) as gerceklesen_adet
            FROM konfeksiyon_beden_takip kbt
            WHERE kbt.model_id = v_model_uuid
            AND kbt.uretilen_adet > 0;
            
        -- Yıkamadan sonra Ütü
        WHEN 'utu' THEN
            RETURN QUERY
            SELECT 
                ybt.beden_kodu,
                GREATEST(0, COALESCE(ybt.uretilen_adet, 0) - COALESCE(ybt.fire_adet, 0)) as gerceklesen_adet
            FROM yikama_beden_takip ybt
            WHERE ybt.model_id = v_model_uuid
            AND ybt.uretilen_adet > 0;
            
        -- Ütüden sonra İlik Düğme
        WHEN 'ilik_dugme' THEN
            RETURN QUERY
            SELECT 
                ubt.beden_kodu,
                GREATEST(0, COALESCE(ubt.uretilen_adet, 0) - COALESCE(ubt.fire_adet, 0)) as gerceklesen_adet
            FROM utu_beden_takip ubt
            WHERE ubt.model_id = v_model_uuid
            AND ubt.uretilen_adet > 0;
            
        -- Kalite Kontrol'e gelmeden önceki aşamayı kontrol et
        -- Konfeksiyon varsa direkt buraya gelebilir, yoksa İlik Düğme'den gelir
        WHEN 'kalite_kontrol' THEN
            -- İlik Düğme'den kontrol et (Konfeksiyon → Yıkama → Ütü → İlik Düğme → Kalite Kontrol)
            RETURN QUERY
            SELECT 
                idbt.beden_kodu,
                GREATEST(0, COALESCE(idbt.uretilen_adet, 0) - COALESCE(idbt.fire_adet, 0)) as gerceklesen_adet
            FROM ilik_dugme_beden_takip idbt
            WHERE idbt.model_id = v_model_uuid
            AND idbt.uretilen_adet > 0
            
            UNION ALL
            
            -- VEYA direkt Konfeksiyon'dan Kalite Kontrol'e
            SELECT 
                kbt.beden_kodu,
                GREATEST(0, COALESCE(kbt.uretilen_adet, 0) - COALESCE(kbt.fire_adet, 0)) as gerceklesen_adet
            FROM konfeksiyon_beden_takip kbt
            WHERE kbt.model_id = v_model_uuid
            AND kbt.uretilen_adet > 0
            AND NOT EXISTS (
                -- Eğer İlik Düğme'de bu model varsa, direkt Konfeksiyon kullanma
                SELECT 1 FROM ilik_dugme_beden_takip idbt2
                WHERE idbt2.model_id = v_model_uuid
                AND idbt2.uretilen_adet > 0
            );
            
        -- Paketlemeden sonra (varsa)
        WHEN 'paketleme' THEN
            RETURN QUERY
            SELECT 
                pbt.beden_kodu,
                GREATEST(0, COALESCE(pbt.uretilen_adet, 0) - COALESCE(pbt.fire_adet, 0)) as gerceklesen_adet
            FROM paketleme_beden_takip pbt
            WHERE pbt.model_id = v_model_uuid
            AND pbt.uretilen_adet > 0;
            
        -- Eğer başka bir aşama belirtilirse, boş döndür
        ELSE
            RETURN QUERY SELECT NULL::VARCHAR(10), 0::INTEGER WHERE FALSE;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 2. BİR SONRAKİ AŞAMANIN HEDEF ADETLERİNİ GÜNCELLE
-- ==========================================
DROP FUNCTION IF EXISTS update_sonraki_asama_hedef_adetler(UUID, TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_sonraki_asama_hedef_adetler(UUID, TEXT) CASCADE;

CREATE FUNCTION update_sonraki_asama_hedef_adetler(
    p_model_id UUID,
    p_tamamlanan_asama TEXT -- 'dokuma', 'konfeksiyon', 'yikama', 'utu', 'ilik_dugme'
) RETURNS VOID AS $$
DECLARE
    v_sonraki_asama TEXT;
    v_sonraki_tablo TEXT;
    v_sonraki_atama_id INTEGER;
    v_rec RECORD;
BEGIN
    -- Tamamlanan aşamaya göre sonraki aşamayı belirle
    CASE p_tamamlanan_asama
        WHEN 'dokuma' THEN v_sonraki_asama := 'konfeksiyon';
        WHEN 'konfeksiyon' THEN v_sonraki_asama := 'yikama';
        WHEN 'yikama' THEN v_sonraki_asama := 'utu';
        WHEN 'utu' THEN v_sonraki_asama := 'ilik_dugme';
        WHEN 'ilik_dugme' THEN v_sonraki_asama := 'kalite_kontrol';
        ELSE RETURN; -- Bilinmeyen aşama
    END CASE;
    
    v_sonraki_tablo := v_sonraki_asama || '_beden_takip';
    
    -- Sonraki aşama atama_id'sini bul (en son oluşturulanı)
    CASE v_sonraki_asama
        WHEN 'konfeksiyon' THEN
            SELECT id INTO v_sonraki_atama_id FROM konfeksiyon_atamalari
            WHERE model_id = p_model_id
            ORDER BY created_at DESC
            LIMIT 1;
        WHEN 'yikama' THEN
            SELECT id INTO v_sonraki_atama_id FROM yikama_atamalari
            WHERE model_id = p_model_id
            ORDER BY created_at DESC
            LIMIT 1;
        WHEN 'utu' THEN
            SELECT id INTO v_sonraki_atama_id FROM utu_atamalari
            WHERE model_id = p_model_id
            ORDER BY created_at DESC
            LIMIT 1;
        WHEN 'ilik_dugme' THEN
            SELECT id INTO v_sonraki_atama_id FROM ilik_dugme_atamalari
            WHERE model_id = p_model_id
            ORDER BY created_at DESC
            LIMIT 1;
        WHEN 'kalite_kontrol' THEN
            SELECT id INTO v_sonraki_atama_id FROM kalite_kontrol_atamalari
            WHERE model_id = p_model_id
            ORDER BY created_at DESC
            LIMIT 1;
    END CASE;
    
    -- Eğer sonraki atama bulunamadıysa, işlem yapma
    IF v_sonraki_atama_id IS NULL THEN
        RAISE NOTICE 'Sonraki aşama ataması bulunamadı: % - %', v_sonraki_asama, p_model_id;
        RETURN;
    END IF;
    
    -- Önceki aşamadan gerçekleşen adetleri al ve sonraki aşamaya yaz
    FOR v_rec IN 
        SELECT * FROM get_onceki_asama_gerceklesen_adetler(p_model_id::TEXT, v_sonraki_asama)
    LOOP
        -- Sonraki aşamanın hedef adetlerini güncelle veya oluştur
        EXECUTE format('
            INSERT INTO %I (atama_id, model_id, beden_kodu, hedef_adet, kayit_tarihi)
            VALUES ($1, $2, $3, $4, NOW())
            ON CONFLICT (atama_id, beden_kodu) 
            DO UPDATE SET 
                hedef_adet = EXCLUDED.hedef_adet,
                guncelleme_tarihi = NOW()
        ', v_sonraki_tablo) 
        USING v_sonraki_atama_id, p_model_id, v_rec.beden_kodu, v_rec.gerceklesen_adet;
        
        RAISE NOTICE 'Aşama: % -> %, Beden: %, Adet: %', 
            p_tamamlanan_asama, v_sonraki_asama, v_rec.beden_kodu, v_rec.gerceklesen_adet;
    END LOOP;
    
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 3. VIEW: AŞAMA SIRASI VE TÜM OLASI GEÇİŞLER
-- ==========================================
CREATE OR REPLACE VIEW asama_sirasi AS
SELECT 1 as sira, 'dokuma' as asama, 'konfeksiyon' as sonraki_asama
UNION ALL
SELECT 2, 'konfeksiyon', 'yikama'
UNION ALL
SELECT 2, 'konfeksiyon', 'kalite_kontrol' -- ⭐ Konfeksiyon direkt Kalite Kontrol'e
UNION ALL
SELECT 3, 'yikama', 'utu'
UNION ALL
SELECT 4, 'utu', 'ilik_dugme'
UNION ALL
SELECT 5, 'ilik_dugme', 'kalite_kontrol'
UNION ALL
SELECT 6, 'ilik_dugme', 'paketleme' -- (varsa)
UNION ALL
SELECT 7, 'paketleme', 'kalite_kontrol' -- (varsa)
ORDER BY sira;

-- ==========================================
-- 4. ÖRNEK KULLANIM
-- ==========================================
-- Dokuma aşaması tamamlandığında, konfeksiyona adetleri aktar:
-- SELECT update_sonraki_asama_hedef_adetler(
--     'model-uuid-buraya'::UUID,
--     'dokuma',
--     123 -- konfeksiyon_atamalari tablosundaki atama_id
-- );

-- ==========================================
-- 5. TETİKLEYİCİ (OPSİYONEL)
-- ==========================================
-- Bir aşama tamamlandığında otomatik olarak sonraki aşamayı güncelleyebilir
-- Ancak atama_id bilgisine ihtiyaç var, bu nedenle uygulama tarafında çağırmak daha mantıklı

COMMENT ON FUNCTION get_onceki_asama_gerceklesen_adetler IS 
'Bir önceki aşamadan gerçekleşen adetleri (üretilen - fire) getirir';

COMMENT ON FUNCTION update_sonraki_asama_hedef_adetler IS 
'Tamamlanan aşamanın gerçekleşen adetlerini bir sonraki aşamanın hedef adetleri olarak günceller';

-- ==========================================
-- 4. RLS POLİTİKALARI - INSERT VE UPDATE
-- ==========================================
-- Tüm beden_takip tablolarına authenticated kullanıcılar için INSERT ve UPDATE izni ver

-- DOKUMA BEDEN TAKIP
CREATE POLICY "Allow authenticated INSERT" ON dokuma_beden_takip
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE" ON dokuma_beden_takip
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

-- KONFEKSIYON BEDEN TAKIP
CREATE POLICY "Allow authenticated INSERT" ON konfeksiyon_beden_takip
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE" ON konfeksiyon_beden_takip
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

-- YIKAMA BEDEN TAKIP
CREATE POLICY "Allow authenticated INSERT" ON yikama_beden_takip
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE" ON yikama_beden_takip
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

-- ÜTÜ BEDEN TAKIP
CREATE POLICY "Allow authenticated INSERT" ON utu_beden_takip
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE" ON utu_beden_takip
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

-- İLİK DÜĞME BEDEN TAKIP
CREATE POLICY "Allow authenticated INSERT" ON ilik_dugme_beden_takip
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE" ON ilik_dugme_beden_takip
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

-- NOT: kalite_kontrol_beden_takip ve paketleme_beden_takip tablolarına 
-- policies eklemek için önce bu tabloları oluşturmalısınız
-- Sonra aşağıdaki kodu çalıştırın:
/*
-- KALİTE KONTROL BEDEN TAKIP
CREATE POLICY "Allow authenticated INSERT" ON kalite_kontrol_beden_takip
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE" ON kalite_kontrol_beden_takip
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

-- PAKETLEME BEDEN TAKIP
CREATE POLICY "Allow authenticated INSERT" ON paketleme_beden_takip
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE" ON paketleme_beden_takip
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);
*/

-- ==========================================
-- 6. TESTİNG
-- ==========================================
-- Test için örnek senaryolar:

-- Örnek 1: Dokumadan Konfeksiyona geçiş
-- 1. Dokumada üretim yapıldı (fire ile)
--    S: 100 üretildi, 10 fire -> 90 geçerli
--    M: 100 üretildi, 0 fire -> 100 geçerli
--    L: 100 üretildi, 0 fire -> 100 geçerli
--
-- 2. Fonksiyon çağrısı:
--    SELECT update_sonraki_asama_hedef_adetler('model-uuid', 'dokuma', konfeksiyon_atama_id);
--
-- 3. Sonuç: Konfeksiyonun hedef_adet kolonları:
--    S: 90
--    M: 100
--    L: 100
