alter table public.fatura_kalemleri
  add column if not exists kategori text not null default 'diger';

update public.fatura_kalemleri
set kategori = 'diger'
where kategori is null or kategori = '';

alter table public.fatura_kalemleri
  drop constraint if exists fatura_kalemleri_kategori_check;

alter table public.fatura_kalemleri
  add constraint fatura_kalemleri_kategori_check
  check (
    kategori = any (
      array[
        'iplik'::text,
        'aksesuar'::text,
        'fason_uretim'::text,
        'genel_gider'::text,
        'nakliye'::text,
        'personel'::text,
        'diger'::text
      ]
    )
  );

create index if not exists idx_fatura_kalemleri_firma_kategori
  on public.fatura_kalemleri using btree (firma_id, kategori);

create index if not exists idx_fatura_kalemleri_fatura_kategori
  on public.fatura_kalemleri using btree (fatura_id, kategori);
