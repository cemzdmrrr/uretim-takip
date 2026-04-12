-- user_roles tablosundaki mevcut constraint'i kaldır ve yenisini ekle
-- Önce mevcut constraint'i kaldır
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;

-- Yeni constraint ekle (tüm rolleri kapsayacak şekilde)
ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_check 
CHECK (role IN (
    'admin',
    'ik', 
    'personel',
    'orgu_firmasi',
    'kalite_personeli',
    'sevkiyat_soforu',
    'atolye_personeli',
    'tekstil',
    'iplik',
    'orgu',
    'dokuma',
    'konfeksiyon',
    'nakis',
    'utu_paket',
    'yikama',
    'ilik_dugme',
    'aksesuar',
    'makine',
    'kimyasal',
    'ambalaj',
    'lojistik',
    'diger'
));

-- Alternatif: Constraint'i tamamen kaldırmak isterseniz
-- ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;
