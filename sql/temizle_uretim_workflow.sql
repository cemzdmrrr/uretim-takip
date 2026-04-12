-- Önceki workflow tablolarını temizle
DROP TABLE IF EXISTS sevkiyat_kayitlari CASCADE;
DROP TABLE IF EXISTS uretim_kayitlari CASCADE;
DROP TABLE IF EXISTS bildirimler CASCADE;

-- View'ları da sil
DROP VIEW IF EXISTS uretim_kayitlari_detay CASCADE;
DROP VIEW IF EXISTS bildirimler_detay CASCADE;

-- Trigger'ları sil
DROP TRIGGER IF EXISTS trigger_notify_quality_control ON uretim_kayitlari;
DROP TRIGGER IF EXISTS trigger_notify_shipping_personnel ON uretim_kayitlari;

-- Fonksiyonları sil
DROP FUNCTION IF EXISTS notify_quality_control CASCADE;
DROP FUNCTION IF EXISTS notify_shipping_personnel CASCADE;
