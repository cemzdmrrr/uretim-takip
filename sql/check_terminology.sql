-- TERMİNOLOJİ KARIŞIKLIĞI KONTROLÜ
-- Supabase ve Flutter arasındaki farkları görelim

-- 1. Mevcut asama/süreç adlarını kontrol et
SELECT 
    'URETIM_KAYITLARI ASAMA DEĞERLERİ' as tablo,
    asama,
    COUNT(*) as adet
FROM public.uretim_kayitlari
GROUP BY asama
ORDER BY adet DESC;

-- 2. ATAMA tablolarındaki adları kontrol et
SELECT 'ATAMA TABLO ADI' as tip, 'dokuma_atamalari' as tablo_adi
UNION ALL
SELECT 'ATAMA TABLO ADI', 'konfeksiyon_atamalari'
UNION ALL
SELECT 'ATAMA TABLO ADI', 'yikama_atamalari'
UNION ALL
SELECT 'ATAMA TABLO ADI', 'utu_atamalari'
UNION ALL
SELECT 'ATAMA TABLO ADI', 'ilik_dugme_atamalari'
UNION ALL
SELECT 'ATAMA TABLO ADI', 'kalite_kontrol_atamalari'
UNION ALL
SELECT 'ATAMA TABLO ADI', 'paketleme_atamalari';

-- 3. TEDARİKÇİ faaliyet alanlarını kontrol et
SELECT 
    'TEDARİKÇİ FAALİYET ALANLARI' as tip,
    faaliyet,
    COUNT(*) as tedarikci_sayisi
FROM public.tedarikciler
WHERE faaliyet IS NOT NULL
GROUP BY faaliyet
ORDER BY tedarikci_sayisi DESC;

-- 4. ATOLYE tiplerini kontrol et
SELECT 
    'ATOLYE TİPLERİ' as tip,
    atolye_turu,
    COUNT(*) as atolye_sayisi
FROM public.atolyeler
WHERE atolye_turu IS NOT NULL
GROUP BY atolye_turu
ORDER BY atolye_sayisi DESC;