-- Önce mevcut rolleri kontrol et
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- Hangi roller constraint'e uymuyor görmek için
SELECT DISTINCT role
FROM user_roles 
WHERE role NOT IN (
    'admin', 
    'user', 
    'ik', 
    'personel', 
    'orgu_firmasi', 
    'dokuma',
    'konfeksiyon',
    'yikama',
    'utu',
    'ilik_dugme',
    'kalite_kontrol',
    'paketleme',
    'sevkiyat',
    'muhasebe',
    'satis',
    'tasarim',
    'planlama',
    'depo'
);

-- Problemli kullanıcıları detayıyla listele
SELECT ur.user_id, ur.role, u.email
FROM user_roles ur
LEFT JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role NOT IN (
    'admin', 
    'user', 
    'ik', 
    'personel', 
    'orgu_firmasi', 
    'dokuma',
    'konfeksiyon',
    'yikama',
    'utu',
    'ilik_dugme',
    'kalite_kontrol',
    'paketleme',
    'sevkiyat',
    'muhasebe',
    'satis',
    'tasarim',
    'planlama',
    'depo'
);
