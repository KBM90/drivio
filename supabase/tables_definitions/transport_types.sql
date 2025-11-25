create table public.transport_types (
  id bigserial not null,
  name character varying(255) not null,
  description text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint transport_types_pkey primary key (id)
) TABLESPACE pg_default;