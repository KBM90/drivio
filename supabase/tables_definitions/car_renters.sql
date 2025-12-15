create table public.car_renters (
  id bigserial not null,
  user_id bigint not null,
  business_name text null,
  location geometry(Point, 4326) null,
  city text null,
  rating numeric(3, 2) null default 5.0,
  total_cars integer null default 0,
  is_verified boolean null default false,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint car_renters_pkey primary key (id),
  constraint car_renters_user_id_fkey foreign key (user_id) references users (id) on delete cascade,
  constraint car_renters_rating_check check ((rating >= 0) and (rating <= 5))
) tablespace pg_default;

create index if not exists idx_car_renters_user_id on public.car_renters using btree (user_id) tablespace pg_default;
create index if not exists idx_car_renters_city on public.car_renters using btree (city) tablespace pg_default;
create index if not exists idx_car_renters_location on public.car_renters using gist (location) tablespace pg_default;
