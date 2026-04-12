-- model_aksesuar tablosuna eksik kolonları ekle
-- miktar: aksesuar miktarı (varsayılan 1)
-- adet_per_model: model başına kaç adet kullanılacak

ALTER TABLE public.model_aksesuar ADD COLUMN IF NOT EXISTS miktar INTEGER DEFAULT 1;
ALTER TABLE public.model_aksesuar ADD COLUMN IF NOT EXISTS adet_per_model INTEGER DEFAULT 1;
ALTER TABLE public.model_aksesuar ADD COLUMN IF NOT EXISTS firma_id UUID;
