alter table public.uyumsoft_gelen_faturalar
  drop constraint if exists uyumsoft_gelen_faturalar_kaynak_check;

alter table public.uyumsoft_gelen_faturalar
  add constraint uyumsoft_gelen_faturalar_kaynak_check
  check (kaynak = any (array['api'::text, 'xml'::text]));
