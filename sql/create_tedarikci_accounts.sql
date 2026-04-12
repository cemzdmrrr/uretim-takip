-- Tedarikciler için auth.users tablosunda hesap oluştur
-- Not: Bu script Supabase Edge Functions veya admin API ile çalıştırılmalıdır

-- Mevcut tedarikciler için geçici şifre ile hesap oluştur
-- Tedarikciler sonradan şifrelerini değiştirebilir

-- 1. Adım: Tedarikciler tablosundaki email adresleri için users tablosunda hesap var mı kontrol et
SELECT 
    t.id as tedarikci_id,
    t.email,
    t.sirket,
    t.ad,
    t.soyad,
    t.faaliyet,
    CASE 
        WHEN au.email IS NOT NULL THEN 'Hesap mevcut'
        ELSE 'Hesap oluşturulacak'
    END as durum
FROM tedarikciler t
LEFT JOIN auth.users au ON au.email = t.email
WHERE t.email IS NOT NULL AND t.email != ''
ORDER BY t.id;

-- 2. Adım: Tedarikciler için varsayılan şifre bilgisi
-- Şifre formatı: sirket_adi + 2024 (örn: akdeniz2024)
-- Tedarikciler ilk girişte şifre değiştirmek zorunda kalacak

-- Bu script'i çalıştırdıktan sonra manuel olarak Supabase Auth'da
-- her tedarikci için hesap oluşturmanız gerekiyor:

/*
Örnek hesap oluşturma (Supabase Dashboard > Authentication > Users > Invite user):

1. Email: ahmet@akdenizorgu.com
   Password: akdeniz2024
   
2. Email: mehmet@istanbulkonf.com  
   Password: istanbul2024
   
3. Email: fatma@egenakis.com
   Password: ege2024

vs...
*/

-- 3. Adım: Tedarikci hesaplarını doğrulamak için
CREATE OR REPLACE FUNCTION verify_tedarikci_accounts() 
RETURNS TABLE (
    tedarikci_id INT,
    email TEXT,
    sirket TEXT,
    has_auth_account BOOLEAN
) 
LANGUAGE SQL 
AS $$
    SELECT 
        t.id,
        t.email,
        t.sirket,
        (au.email IS NOT NULL) as has_auth_account
    FROM tedarikciler t
    LEFT JOIN auth.users au ON au.email = t.email
    WHERE t.email IS NOT NULL AND t.email != '';
$$;

-- Fonksiyonu çalıştır
SELECT * FROM verify_tedarikci_accounts();