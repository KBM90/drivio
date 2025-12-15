create table public.car_rental_requests (
  id bigserial not null,
  user_id bigint not null,
  car_rental_id bigint not null,
  start_date date not null,
  end_date date not null,
  total_days integer generated always as (end_date - start_date + 1) stored,
  total_price numeric(10, 2) null,
  status character varying(20) not null default 'pending'::character varying,
  pickup_location geometry(Point, 4326) null,
  dropoff_location geometry(Point, 4326) null,
  notes text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint car_rental_requests_pkey primary key (id),
  constraint car_rental_requests_user_id_fkey foreign key (user_id) references users (id) on delete cascade,
  constraint car_rental_requests_car_rental_id_fkey foreign key (car_rental_id) references provided_car_rentals (id) on delete cascade,
  constraint car_rental_requests_valid_dates check (end_date >= start_date),
  constraint car_rental_requests_status_check check (
    (status)::text = any (
      (
        array[
          'pending'::character varying,
          'confirmed'::character varying,
          'active'::character varying,
          'completed'::character varying,
          'cancelled'::character varying
        ]
      )::text[]
    )
  ),
  constraint car_rental_requests_total_price_positive check ((total_price is null) or (total_price > 0))
) tablespace pg_default;

create index if not exists idx_car_rental_requests_user_id on public.car_rental_requests using btree (user_id) tablespace pg_default;
create index if not exists idx_car_rental_requests_car_rental_id on public.car_rental_requests using btree (car_rental_id) tablespace pg_default;
create index if not exists idx_car_rental_requests_status on public.car_rental_requests using btree (status) tablespace pg_default;
create index if not exists idx_car_rental_requests_dates on public.car_rental_requests using btree (start_date, end_date) tablespace pg_default;
