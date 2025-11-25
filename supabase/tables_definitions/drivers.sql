create table public.drivers (
  id bigserial not null,
  user_id bigint not null,
  location geometry null,
  dropoff_location geometry null,
  preferences jsonb null,
  driving_distance numeric(10, 2) null default 0,
  status character varying(20) not null default 'inactive'::character varying,
  acceptnewrequest boolean null default true,
  range double precision null default (5.0)::double precision,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint drivers_pkey primary key (id),
  constraint drivers_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE,
  constraint drivers_status_check check (
    (
      (status)::text = any (
        (
          array[
            'active'::character varying,
            'inactive'::character varying,
            'on_trip'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;