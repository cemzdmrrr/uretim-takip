-- Tedarikciler tablosundaki tüm faaliyet değerlerini ve kayıt sayılarını göster
SELECT faaliyet, COUNT(*) as kayit_sayisi
FROM tedarikciler 
WHERE faaliyet IS NOT NULL
GROUP BY faaliyet
ORDER BY kayit_sayisi DESC;

-- İlk 5 tedarikci örneğini de göster
SELECT id, ad, soyad, sirket, faaliyet, email, telefon
FROM tedarikciler 
WHERE faaliyet IS NOT NULL
LIMIT 5;