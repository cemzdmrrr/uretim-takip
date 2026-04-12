-- Test için dokuma ataması oluştur
-- Bu scripti çalıştırmadan önce:
-- 1. models_dokuma_durumu_kolonu.sql çalıştırın
-- 2. dokuma_atamalari_schema.sql çalıştırın

-- Mevcut dokuma kullanıcılarını listele
SELECT 
    u.email,
    ur.role,
    u.id as user_id
FROM auth.users u
JOIN user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'dokuma';

-- Mevcut modelleri listele
SELECT 
    id,
    model_adi,
    musteri_adi,
    siparis_adedi,
    dokuma_durumu
FROM modeller
ORDER BY kayit_tarihi DESC
LIMIT 10;

-- ÖRNEK: Dokuma ataması oluştur
-- Bu kısmı gerçek user_id ve model_id ile değiştirin
-- INSERT INTO dokuma_atamalari (model_id, atanan_kullanici_id, durum, notlar) 
-- VALUES (
--     1,  -- Gerçek model ID
--     'gerçek-user-uuid',  -- Gerçek dokuma kullanıcısının UUID'si
--     'atandi',
--     'Test ataması - Öncelikli sipariş'
-- );

-- Atamaları kontrol et
SELECT 
    da.id,
    da.model_id,
    m.model_adi,
    m.musteri_adi,
    da.durum,
    da.atama_tarihi,
    u.email as atanan_kullanici
FROM dokuma_atamalari da
JOIN modeller m ON da.model_id = m.id
JOIN auth.users u ON da.atanan_kullanici_id = u.id
ORDER BY da.atama_tarihi DESC;
