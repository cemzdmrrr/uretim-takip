-- UUID destekli model atama fonksiyonu (triko_takip tablosu için)
CREATE OR REPLACE FUNCTION public.assign_model_to_user_uuid(
    model_ids UUID[], 
    assignee_email TEXT, 
    stage_name TEXT,
    notes TEXT DEFAULT ''
)
RETURNS JSON AS $$
DECLARE
    assignee_uuid UUID;
    table_name TEXT;
    column_name TEXT;
    assigned_count INTEGER := 0;
    result JSON;
    model_id UUID;
BEGIN
    -- Email'den UUID bul
    assignee_uuid := public.get_user_by_email(assignee_email);
    
    IF assignee_uuid IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Kullanıcı bulunamadı: ' || assignee_email
        );
    END IF;
    
    -- Aşama bilgilerini belirle
    CASE stage_name
        WHEN 'dokuma' THEN 
            table_name := 'dokuma_atamalari';
            column_name := 'dokuma_durumu';
        WHEN 'konfeksiyon' THEN 
            table_name := 'konfeksiyon_atamalari';
            column_name := 'konfeksiyon_durumu';
        WHEN 'yikama' THEN 
            table_name := 'yikama_atamalari';
            column_name := 'yikama_durumu';
        WHEN 'utu' THEN 
            table_name := 'utu_atamalari';
            column_name := 'utu_durumu';
        WHEN 'ilik_dugme' THEN 
            table_name := 'ilik_dugme_atamalari';
            column_name := 'ilik_dugme_durumu';
        WHEN 'kalite_kontrol' THEN 
            table_name := 'kalite_kontrol_atamalari';
            column_name := 'kalite_kontrol_durumu';
        WHEN 'paketleme' THEN 
            table_name := 'paketleme_atamalari';
            column_name := 'paketleme_durumu';
        ELSE
            RETURN json_build_object(
                'success', false,
                'error', 'Geçersiz aşama: ' || stage_name
            );
    END CASE;
    
    -- Her model için atama yap
    FOREACH model_id IN ARRAY model_ids
    LOOP
        BEGIN
            -- Mevcut atamayı kontrol et
            EXECUTE format('
                INSERT INTO %I (model_id, atanan_kullanici_id, atama_tarihi, notlar, durum)
                VALUES ($1, $2, NOW(), $3, ''atandi'')
                ON CONFLICT (model_id) 
                DO UPDATE SET
                    atanan_kullanici_id = $2,
                    atama_tarihi = NOW(),
                    notlar = $3,
                    durum = ''atandi'',
                    tamamlanma_tarihi = NULL
            ', table_name)
            USING model_id, assignee_uuid, notes;
            
            -- triko_takip tablosundaki durumu güncelle
            EXECUTE format('
                UPDATE public.triko_takip 
                SET %I = ''atandi''
                WHERE id = $1
            ', column_name)
            USING model_id;
            
            assigned_count := assigned_count + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- Hata durumunda devam et
            CONTINUE;
        END;
    END LOOP;
    
    -- Sonucu döndür
    RETURN json_build_object(
        'success', true,
        'assigned_count', assigned_count,
        'assignee_email', assignee_email,
        'stage_name', stage_name,
        'total_models', array_length(model_ids, 1)
    );
    
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Gerekli izinleri ver
GRANT EXECUTE ON FUNCTION public.assign_model_to_user_uuid(UUID[], TEXT, TEXT, TEXT) TO authenticated;

-- Test fonksiyonu
/*
SELECT public.assign_model_to_user_uuid(
    ARRAY['50d0697a-d8ce-4b61-8337-067480f7a593']::UUID[], 
    'test@example.com', 
    'dokuma', 
    'Test atama'
);
*/