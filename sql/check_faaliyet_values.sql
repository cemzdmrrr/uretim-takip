-- Tedarikciler tablosundaki faaliyet kolonunun distinct değerlerini kontrol et
SELECT DISTINCT faaliyet, COUNT(*) as adet 
FROM tedarikciler 
GROUP BY faaliyet 
ORDER BY adet DESC;