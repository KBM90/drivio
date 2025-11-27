create table public.service_providers (
  id bigserial not null,
  user_id bigint not null,
  business_name character varying(255) not null,
  provider_type character varying(50) not null,
  address text null,
  location geometry null,
  rating numeric(3, 2) default 0,
  is_verified boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint service_providers_pkey primary key (id),
  constraint service_providers_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE,
  constraint service_providers_provider_type_check check (
    (
      provider_type = any (
        array[
          'mechanic'::character varying,
          'cleaner'::character varying,
          'electrician'::character varying,
          'insurance'::character varying,
          'other'::character varying
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_service_providers_user_id on public.service_providers using btree (user_id) TABLESPACE pg_default;
create index IF not exists idx_service_providers_location on public.service_providers using gist (location) TABLESPACE pg_default;
create index IF not exists idx_service_providers_provider_type on public.service_providers using btree (provider_type) TABLESPACE pg_default;

create trigger update_service_providers_updated_at BEFORE
update on service_providers for EACH row
execute FUNCTION update_updated_at_column ();
