create table public.vehicles (
  id bigserial not null,
  driver_id bigint not null,
  car_brand_id bigint not null,
  transport_type_id bigint not null,
  license_plate character varying(255) not null,
  status boolean null default true,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint vehicles_pkey primary key (id),
  constraint vehicles_license_plate_key unique (license_plate),
  constraint fk_vehicles_car_brand_id foreign KEY (car_brand_id) references car_brands (id) on delete CASCADE,
  constraint fk_vehicles_driver_id foreign KEY (driver_id) references users (id) on delete CASCADE,
  constraint fk_vehicles_transport_type_id foreign KEY (transport_type_id) references transport_types (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_vehicles_driver_id on public.vehicles using btree (driver_id) TABLESPACE pg_default;

create index IF not exists idx_vehicles_car_brand_id on public.vehicles using btree (car_brand_id) TABLESPACE pg_default;

create index IF not exists idx_vehicles_transport_type_id on public.vehicles using btree (transport_type_id) TABLESPACE pg_default;

create index IF not exists idx_vehicles_status on public.vehicles using btree (status) TABLESPACE pg_default;

create unique INDEX IF not exists idx_vehicles_license_plate on public.vehicles using btree (license_plate) TABLESPACE pg_default;

create trigger update_vehicles_updated_at BEFORE
update on vehicles for EACH row
execute FUNCTION update_updated_at_column ();