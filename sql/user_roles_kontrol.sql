-- User_roles tablosu test ve düzeltme
-- Bu dosyayı çalıştırarak user_roles tablosunu kontrol edin

-- 1. Mevcut user_roles tablosunu kontrol et
SELECT 
    column_name, 
    data_type, 
    is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_roles' 
ORDER BY ordinal_position;

-- 2. Eğer user_id kolonu yoksa ekle
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_roles' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE user_roles ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE 'user_id kolonu eklendi';
    ELSE
        RAISE NOTICE 'user_id kolonu zaten mevcut';
    END IF;
END $$;

-- 3. Test kaydı ekle
INSERT INTO user_roles (user_id, role) 
VALUES (auth.uid(), 'admin')
ON CONFLICT DO NOTHING;

-- 4. Kontrol et
SELECT * FROM user_roles WHERE user_id = auth.uid();

-- 5. Eğer atolye_id kolonu yoksa ekle (sevkiyat sistemi için)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_roles' AND column_name = 'atolye_id'
    ) THEN
        ALTER TABLE user_roles ADD COLUMN atolye_id INTEGER REFERENCES atolyeler(id);
        RAISE NOTICE 'atolye_id kolonu eklendi';
    ELSE
        RAISE NOTICE 'atolye_id kolonu zaten mevcut';
    END IF;
END $$;

RAISE NOTICE 'user_roles tablosu kontrol edildi ve gerekli düzenlemeler yapıldı.';
