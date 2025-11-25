create table public.car_brands (
  id bigserial not null,
  company character varying(255) not null,
  model character varying(255) not null,
  thumbnail_image text null,
  category character varying(20) null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint car_brands_pkey primary key (id),
  constraint car_brands_category_check check (
    (
      (category)::text = any (
        (
          array[
            'car'::character varying,
            'motorcycle'::character varying,
            'jet'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;