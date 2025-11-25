create table public.cancelled_ride_requests (
  id bigserial not null,
  ride_request_id bigint null,
  user_id bigint not null,
  reason text not null,
  user_type text not null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint cancelled_ride_requests_pkey primary key (id),
  constraint fk_cancelled_ride_requests_request foreign KEY (ride_request_id) references ride_requests (id) on delete set null,
  constraint fk_cancelled_ride_requests_user foreign KEY (user_id) references users (id) on delete CASCADE,
  constraint cancelled_ride_requests_user_type_check check (
    (
      user_type = any (array['passenger'::text, 'driver'::text])
    )
  )
) TABLESPACE pg_default;