-- user_roles tablosundaki mevcut constraint'i kaldır ve yenisini ekle
-- Önce mevcut constraint'i kaldır
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;

-- Yeni constraint ekle (tüm rolleri kapsayacak şekilde)
ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_check 
CHECK (role IN (
    -- Sistem rolleri
    'admin',
    'kullanici',
    'ik',
    'personel',
    'orgu_firmasi',

    -- Üretim aşamaları
    'dokuma',
    'konfeksiyon',
    'yikama',
    'utu',
    'ilik_dugme',
    'kalite_kontrol',
    'paketleme',

    -- Diğer departmanlar
    'sevkiyat',
    'muhasebe',
    'satis',
    'tasarim',
    'planlama',
    'depo',

    -- Eski roller (uyumluluk)
    'kalite_personeli',
    'sevkiyat_soforu',
    'atolye_personeli',
    'tekstil',
    'iplik',
    'orgu',
    'nakis',
    'utu_paket',
    'aksesuar',
    'makine',
    'kimyasal',
    'ambalaj',
    'lojistik',
    'diger'
));

-- Alternatif: Constraint'i tamamen kaldırmak isterseniz
-- ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;
