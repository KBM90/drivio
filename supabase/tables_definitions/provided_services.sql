create table public.provided_services (
  id bigserial not null,
  provider_id bigint not null,
  name character varying(255) not null,
  description text null,
  price numeric(10, 2) not null,
  currency character varying(10) default 'MAD',
  category character varying(50) null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint provided_services_pkey primary key (id),
  constraint provided_services_provider_id_fkey foreign KEY (provider_id) references service_providers (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_provided_services_provider_id on public.provided_services using btree (provider_id) TABLESPACE pg_default;
create index IF not exists idx_provided_services_category on public.provided_services using btree (category) TABLESPACE pg_default;

create trigger update_provided_services_updated_at BEFORE
update on provided_services for EACH row
execute FUNCTION update_updated_at_column ();
