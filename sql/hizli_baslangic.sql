-- =============================================
-- HIZLI BAŞLANGIÇ - TEK KOMUT İLE SETUP
-- =============================================
-- Bu dosyayı Supabase SQL Editor'da çalıştırarak hızlıca başlayabilirsiniz

-- 1. KENDİNİZİ ADMİN YAPIN
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES (auth.uid(), 'admin', 3)
ON CONFLICT (user_id) DO UPDATE SET 
    role = 'admin',
    yetki_seviyesi = 3;

-- 2. ÖRNEK ATÖLYELERİ OLUŞTURUN (eğer yoksa)
INSERT INTO atolyeler (atolye_adi, aciklama, kapasite, aktif) VALUES
('Kesim Atölyesi', 'Kumaş kesim işlemleri', 100, true),
('Dikiş Atölyesi', 'Dikiş ve montaj işlemleri', 150, true),
('Ütü Atölyesi', 'Ütü ve finisaj işlemleri', 80, true),
('Kalite Kontrol', 'Son kontrol ve paketleme', 50, true),
('Sevkiyat', 'Sevkiyat hazırlık ve gönderim', 200, true)
ON CONFLICT (atolye_adi) DO NOTHING;

-- 3. MEVCUT DURUM KONTROLÜ
SELECT 
    'Kullanıcı Rolünüz:' as bilgi,
    role as deger,
    yetki_seviyesi
FROM user_roles 
WHERE user_id = auth.uid()
UNION ALL
SELECT 
    'Toplam Atölye Sayısı:' as bilgi,
    COUNT(*)::text as deger,
    null as yetki_seviyesi
FROM atolyeler
UNION ALL
SELECT 
    'Aktif Model Sayısı:' as bilgi,
    COUNT(*)::text as deger,
    null as yetki_seviyesi
FROM triko_takip;

-- 4. İLK TEST SEVKİYAT TALEBİ (opsiyonel)
-- Eğer model varsa test talebi oluşturun
INSERT INTO sevk_talepleri (model_id, talep_eden_id, hedef_atolye_id, miktar, aciklama, durum)
SELECT 
    tt.id as model_id,
    auth.uid() as talep_eden_id,
    a.id as hedef_atolye_id,
    5 as miktar,
    'İlk test sevkiyat talebi' as aciklama,
    'beklemede' as durum
FROM triko_takip tt
CROSS JOIN atolyeler a
WHERE a.atolye_adi = 'Kesim Atölyesi'
LIMIT 1
ON CONFLICT DO NOTHING;

-- 5. SONUÇ RAPORU
SELECT 
    '✅ Setup tamamlandı!' as mesaj,
    'Admin rolünüz aktif. Flutter uygulamasını yeniden başlatın.' as detay;
