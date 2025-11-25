create table public.payment_methods (
  id bigserial not null,
  name character varying(255) not null,
  requires_details boolean null default true,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint payment_methods_pkey primary key (id),
  constraint payment_methods_name_key unique (name)
) TABLESPACE pg_default;