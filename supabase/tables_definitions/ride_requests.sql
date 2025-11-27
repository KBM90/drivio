create table public.ride_requests (
  id bigserial not null,
  passenger_id bigint not null,
  driver_id bigint null,
  transport_type_id bigint not null,
  payment_method_id bigint not null,
  status character varying(20) not null default 'pending'::character varying,
  price numeric(10, 2) not null,
  pickup_location geometry not null,
  dropoff_location geometry not null,
  preferences jsonb null,
  distance numeric(5, 2) not null,
  duration numeric not null,
  requested_at timestamp with time zone null,
  accepted_at timestamp with time zone null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  qr_code character varying(255) null,
  qr_code_scanned boolean null default false,
  cancellation_reason text null,
  constraint ride_requests_pkey primary key (id),
  constraint ride_requests_driver_id_fkey foreign KEY (driver_id) references drivers (id) on delete set null,
  constraint ride_requests_transport_type_id_fkey foreign KEY (transport_type_id) references transport_types (id) on delete CASCADE,
  constraint ride_requests_passenger_id_fkey foreign KEY (passenger_id) references passengers (id) on delete CASCADE,
  constraint ride_requests_payment_method_id_fkey foreign KEY (payment_method_id) references payment_methods (id) on delete CASCADE,
  constraint ride_requests_accepted_after_requested check (
    (
      (accepted_at is null)
      or (requested_at is null)
      or (accepted_at >= requested_at)
    )
  ),
  constraint ride_requests_distance_positive check ((distance > (0)::numeric)),
  constraint ride_requests_price_positive check ((price > (0)::numeric)),
  constraint ride_requests_duration_positive check ((duration > (0)::numeric)),
  constraint ride_requests_status_check check (
    (
      (status)::text = any (
        (
          array[
            'pending'::character varying,
            'accepted'::character varying,
            'in_progress'::character varying,
            'completed'::character varying,
            'cancelled_by_driver'::character varying,
            'arrived'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_passenger_id on public.ride_requests using btree (passenger_id) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_driver_id on public.ride_requests using btree (driver_id) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_status on public.ride_requests using btree (status) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_passenger_status on public.ride_requests using btree (passenger_id, status) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_driver_status on public.ride_requests using btree (driver_id, status) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_created_at on public.ride_requests using btree (created_at desc) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_pickup_location on public.ride_requests using gist (pickup_location) TABLESPACE pg_default;

create index IF not exists idx_ride_requests_dropoff_location on public.ride_requests using gist (dropoff_location) TABLESPACE pg_default;

create trigger notify_drivers_on_new_ride_request
after INSERT on ride_requests for EACH row when (new.status::text = 'pending'::text)
execute FUNCTION notify_nearby_drivers ();

create trigger set_ride_requests_accepted_at BEFORE
update on ride_requests for EACH row
execute FUNCTION set_accepted_at ();

create trigger set_ride_requests_requested_at BEFORE INSERT on ride_requests for EACH row
execute FUNCTION set_requested_at ();

create trigger update_ride_requests_updated_at BEFORE
update on ride_requests for EACH row
execute FUNCTION update_updated_at_column ();