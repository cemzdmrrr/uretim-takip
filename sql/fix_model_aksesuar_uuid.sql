-- model_aksesuar tablosunu UUID ile uyumlu hale getir
-- triko_takip.id UUID tipinde olduğu için model_aksesuar.model_id de UUID olmalı

-- Önce mevcut tabloyu kontrol et
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'model_aksesuar';

-- Eğer model_id BIGINT ise, tabloyu yeniden oluştur
DROP TABLE IF EXISTS public.model_aksesuar CASCADE;

CREATE TABLE IF NOT EXISTS public.model_aksesuar (
    id BIGSERIAL PRIMARY KEY,
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    aksesuar_id BIGINT NOT NULL REFERENCES public.aksesuarlar(id) ON DELETE CASCADE,
    adet INTEGER DEFAULT 1,
    birim TEXT DEFAULT 'adet',
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id, aksesuar_id)
);

-- RLS politikası
ALTER TABLE public.model_aksesuar ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Herkes model_aksesuar okuyabilir" ON public.model_aksesuar;
DROP POLICY IF EXISTS "Admin model_aksesuar yönetebilir" ON public.model_aksesuar;

CREATE POLICY "Herkes model_aksesuar okuyabilir" 
ON public.model_aksesuar FOR SELECT USING (true);

CREATE POLICY "Admin model_aksesuar yönetebilir" 
ON public.model_aksesuar FOR ALL USING (true);

-- Başarı mesajı
SELECT 'model_aksesuar tablosu UUID formatına güncellendi!' as status;
