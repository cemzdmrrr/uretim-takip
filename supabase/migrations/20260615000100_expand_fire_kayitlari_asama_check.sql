alter table public.fire_kayitlari
  drop constraint if exists fire_kayitlari_asama_check;

alter table public.fire_kayitlari
  add constraint fire_kayitlari_asama_check
  check (
    asama = any (
      array[
        'orgu'::text,
        'dokuma'::text,
        'konfeksiyon'::text,
        'yikama'::text,
        'nakis'::text,
        'ilik_dugme'::text,
        'utu'::text,
        'paketleme'::text,
        'kayip'::text,
        'diger'::text
      ]
    )
  );
