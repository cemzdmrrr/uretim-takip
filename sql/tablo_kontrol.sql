-- Tablo isimlerini doğrula ve admin politikalarını güvenli şekilde uygula
-- Önce mevcut tabloları kontrol et

SELECT 'Mevcut tablolar:' as bilgi;

SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'user_roles',
    'modeller', 
    'personel',
    'personeller',
    'tedarikciler',
    'faturalar',
    'kasa_banka',
    'kasa_banka_hareketleri',
    'dosyalar',
    'ayarlar',
    'donemler',
    'dokuma_atamalari',
    'konfeksiyon_atamalari',
    'yikama_atamalari',
    'utu_atamalari',
    'ilik_dugme_atamalari',
    'kalite_kontrol_atamalari',
    'paketleme_atamalari',
    'aksesuarlar',
    'iplik_siparisler',
    'iplik_siparis_takip',
    'teslimatlar',
    'stok_hareketleri',
    'rapor_verileri',
    'izinler',
    'mesailer',
    'bordro',
    'odemeler'
)
ORDER BY tablename;

-- RLS durumunu kontrol et
SELECT 'RLS durumu:' as bilgi;

SELECT schemaname, tablename, rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
AND rowsecurity = true
ORDER BY tablename;

-- Mevcut admin politikalarını listele
SELECT 'Mevcut admin politikaları:' as bilgi;

SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'public'
AND (policyname LIKE '%admin%' OR policyname LIKE '%Admin%')
ORDER BY tablename, policyname;

SELECT 'Tablo kontrolü tamamlandı!' as message;
