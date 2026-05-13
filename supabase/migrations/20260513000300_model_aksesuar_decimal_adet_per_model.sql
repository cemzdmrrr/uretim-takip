-- Model başına aksesuar kullanım miktarı kesirli olabilir.
-- Örn: 1 model için 0.025 metre/gram/kg vb. aksesuar kullanımı.
ALTER TABLE public.model_aksesuar
  ALTER COLUMN adet_per_model TYPE numeric(12, 4)
  USING adet_per_model::numeric;

