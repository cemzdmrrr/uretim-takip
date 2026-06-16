alter table public.faturalar
  add column if not exists cari_unvan text;

create index if not exists idx_faturalar_cari_unvan
  on public.faturalar using btree (cari_unvan);
