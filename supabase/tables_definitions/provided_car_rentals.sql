create table public.provided_car_rentals (
  id bigserial not null,
  car_renter_id bigint not null,
  car_brand_id bigint not null,
  year integer null,
  color text null,
  plate_number text null,
  location geometry(Point, 4326) null,
  city text not null,
  daily_price numeric(10, 2) not null,
  features jsonb null,
  images jsonb null,
  is_available boolean null default true,
  unavailable_from timestamp with time zone null,
  unavailable_until timestamp with time zone null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint provided_car_rentals_pkey primary key (id),
  constraint provided_car_rentals_car_renter_id_fkey foreign key (car_renter_id) references car_renters (id) on delete cascade,
  constraint provided_car_rentals_car_brand_id_fkey foreign key (car_brand_id) references car_brands (id) on delete restrict,
  constraint provided_car_rentals_plate_number_key unique (plate_number),
  constraint provided_car_rentals_daily_price_positive check (daily_price > 0),
  constraint provided_car_rentals_year_valid check ((year is null) or ((year >= 1900) and (year <= 2100)))
) tablespace pg_default;

create index if not exists idx_provided_car_rentals_car_renter_id on public.provided_car_rentals using btree (car_renter_id) tablespace pg_default;
create index if not exists idx_provided_car_rentals_city on public.provided_car_rentals using btree (city) tablespace pg_default;
create index if not exists idx_provided_car_rentals_is_available on public.provided_car_rentals using btree (is_available) tablespace pg_default;
create index if not exists idx_provided_car_rentals_location on public.provided_car_rentals using gist (location) tablespace pg_default;
create index if not exists idx_provided_car_rentals_daily_price on public.provided_car_rentals using btree (daily_price) tablespace pg_default;
create index if not exists idx_provided_car_rentals_unavailable_dates on public.provided_car_rentals using btree (unavailable_from, unavailable_until) tablespace pg_default;
