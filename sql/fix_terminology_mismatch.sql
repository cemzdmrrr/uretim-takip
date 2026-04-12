-- TERMİNOLOJİ UYUMLULAŞTIRMA
-- Flutter "örgü" dediğinde Supabase "dokuma" diyor, bunları eşleştirelim

-- 1. Mevcut durumu kontrol et
SELECT 'MEVCUT URETIM KAYITLARI' as tip, asama, COUNT(*) as adet
FROM public.uretim_kayitlari 
GROUP BY asama;

-- 2. Supabase'deki "dokuma" terimini "orgu" olarak güncelleyelim
UPDATE public.uretim_kayitlari 
SET asama = 'orgu' 
WHERE asama = 'dokuma';

-- 3. Atama tablolarının adlarını Flutter ile uyumlu hale getirmek için
-- "dokuma_atamalari" tablosu zaten var, Flutter "orgu" araması yapıyor
-- Bu eşleşmeyi Flutter tarafında düzeltelim

-- 4. Tedarikçi faaliyet alanlarını kontrol et
SELECT 'TEDARİKÇİ FAALİYET - ÖNCE' as durum, faaliyet, COUNT(*) 
FROM public.tedarikciler 
WHERE faaliyet ILIKE '%dokuma%' 
GROUP BY faaliyet;

-- 5. Tedarikçi faaliyet alanında da "Dokuma" yerine "Örgü" kullanalım
UPDATE public.tedarikciler 
SET faaliyet = 'Örgü' 
WHERE faaliyet = 'Dokuma';

-- 6. Kontrol et
SELECT 'GÜNCELLENME SONRASI' as durum, 
       asama, COUNT(*) as uretim_kaydi_adet
FROM public.uretim_kayitlari 
GROUP BY asama;

SELECT 'TEDARİKÇİ FAALİYET - SONRA' as durum, 
       faaliyet, COUNT(*) as tedarikci_adet 
FROM public.tedarikciler 
WHERE faaliyet ILIKE '%örgü%'
GROUP BY faaliyet;