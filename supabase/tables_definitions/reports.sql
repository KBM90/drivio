create table public.reports (
  id bigserial not null,
  reported_by bigint not null,
  reported_user bigint not null,
  reason character varying(50) not null default 'other'::character varying,
  details text null,
  status character varying(20) not null default 'pending'::character varying,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint reports_pkey primary key (id),
  constraint reports_reported_by_fkey foreign KEY (reported_by) references users (id) on delete CASCADE,
  constraint reports_reported_user_fkey foreign KEY (reported_user) references users (id) on delete CASCADE,
  constraint reports_reason_check check (
    (
      (reason)::text = any (
        (
          array[
            'reckless_driving'::character varying,
            'overcharging'::character varying,
            'rude_behavior'::character varying,
            'vehicle_condition'::character varying,
            'route_issue'::character varying,
            'unsafe_experience'::character varying,
            'ride_cancellation'::character varying,
            'payment_issue'::character varying,
            'harassment'::character varying,
            'discrimination'::character varying,
            'property_damage'::character varying,
            'no_show'::character varying,
            'drunk_or_disorderly'::character varying,
            'unfair_rating'::character varying,
            'other'::character varying
          ]
        )::text[]
      )
    )
  ),
  constraint reports_status_check check (
    (
      (status)::text = any (
        (
          array[
            'pending'::character varying,
            'resolved'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;