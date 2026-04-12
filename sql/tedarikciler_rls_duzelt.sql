-- Tedarikciler tablosu için RLS politikaları düzeltmesi

-- Önce mevcut politikaları kaldır
DROP POLICY IF EXISTS "tedarikciler_select" ON tedarikciler;
DROP POLICY IF EXISTS "tedarikciler_insert" ON tedarikciler;
DROP POLICY IF EXISTS "tedarikciler_update" ON tedarikciler;
DROP POLICY IF EXISTS "tedarikciler_delete" ON tedarikciler;
DROP POLICY IF EXISTS "Herkes tedarikcileri görebilir" ON tedarikciler;
DROP POLICY IF EXISTS "Admin tedarikcileri yönetebilir" ON tedarikciler;
DROP POLICY IF EXISTS "Authenticated users can insert" ON tedarikciler;
DROP POLICY IF EXISTS "Authenticated users can update" ON tedarikciler;

-- RLS'i etkinleştir (eğer değilse)
ALTER TABLE tedarikciler ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
CREATE POLICY "tedarikciler_select_policy" ON tedarikciler
    FOR SELECT USING (true);

-- Authenticated kullanıcılar ekleyebilir
CREATE POLICY "tedarikciler_insert_policy" ON tedarikciler
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Authenticated kullanıcılar güncelleyebilir
CREATE POLICY "tedarikciler_update_policy" ON tedarikciler
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Authenticated kullanıcılar silebilir
CREATE POLICY "tedarikciler_delete_policy" ON tedarikciler
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Başarı mesajı
SELECT 'Tedarikciler tablosu RLS politikaları güncellendi.' as sonuc;
