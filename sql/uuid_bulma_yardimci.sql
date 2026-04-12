-- =============================================
-- KULLANICI UUID BULMA VE ROL ATAMA
-- =============================================

-- 1. KENDİ UUID'NİZİ ÖĞRENME
SELECT 
    'Sizin UUID''niz:' as bilgi,
    auth.uid() as uuid,
    auth.email() as email;

-- 2. TÜM KAYITLI KULLANICILARI GÖRME
SELECT 
    'Kayıtlı kullanıcılar:' as bilgi,
    id as uuid,
    email
FROM auth.users
ORDER BY created_at DESC;

-- 3. MEVCUT ROLLERİ GÖRME
SELECT 
    '📋 Mevcut Roller:' as baslik,
    au.email,
    ur.role,
    ur.yetki_seviyesi,
    CASE ur.yetki_seviyesi
        WHEN 1 THEN '👁️ Görüntüleme'
        WHEN 2 THEN '✏️ Düzenleme'
        WHEN 3 THEN '🔧 Admin'
        ELSE '❓ Bilinmiyor'
    END as yetki_aciklama
FROM user_roles ur
LEFT JOIN auth.users au ON ur.user_id = au.id
ORDER BY ur.yetki_seviyesi DESC, ur.created_at DESC;

-- 4. KOPYALANABİLİR ROL ATAMA KOMUTLARI
-- Aşağıdaki komutları kopyalayıp UUID'leri değiştirerek kullanın:

/*
-- KENDİNİZE ADMİN ROLÜ ATAMA:
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES (auth.uid(), 'admin', 3);

-- BAŞKA BİRİNE ADMIN ROLÜ ATAMA:
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES ('UUID_BURAYA_YAZIN', 'admin', 3);

-- KALİTE KONTROL PERSONELİ ATAMA:
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES ('UUID_BURAYA_YAZIN', 'kalite_kontrolu', 2);

-- SEVKİYAT YÖNETİCİSİ ATAMA:
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES ('UUID_BURAYA_YAZIN', 'sevkiyat_yoneticisi', 3);

-- ATÖLYE YÖNETİCİSİ ATAMA (önce atölye ID'si bulun):
SELECT id, atolye_adi FROM atolyeler;
INSERT INTO user_roles (user_id, role, atolye_id, yetki_seviyesi) 
VALUES ('UUID_BURAYA_YAZIN', 'atolye_yoneticisi', ATOLYE_ID_BURAYA, 2);
*/
