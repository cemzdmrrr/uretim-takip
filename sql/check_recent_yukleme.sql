-- Son 10 dakikada eklenen yükleme kayıtlarını göster
SELECT 
    id,
    model_id,
    adet,
    tarih,
    kaynak,
    ceki_id,
    created_at
FROM yukleme_kayitlari
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- Eğer hiç kayıt yoksa, tüm yükleme kayıtlarını göster
SELECT COUNT(*) as toplam_kayit FROM yukleme_kayitlari;
