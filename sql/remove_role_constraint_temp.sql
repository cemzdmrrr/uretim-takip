-- GEÇİCİ ÇÖZÜM: Role constraint'ini kaldır
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;

-- İsteğe bağlı: Constraint olmadan roller eklemek için
-- Bu komuttan sonra herhangi bir role değeri ekleyebilirsiniz
