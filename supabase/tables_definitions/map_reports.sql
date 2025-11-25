create table public.map_reports (
  id bigserial not null,
  report_type character varying(50) not null,
  point_location geometry null,
  route_points jsonb null,
  user_id bigint null,
  status character varying(20) not null default 'Active'::character varying,
  description text null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint map_reports_pkey primary key (id),
  constraint map_reports_user_id_fkey foreign KEY (user_id) references users (id) on delete set null,
  constraint map_reports_report_type_check check (
    (
      (report_type)::text = any (
        (
          array[
            'accident'::character varying,
            'traffic'::character varying,
            'roadblock'::character varying,
            'construction'::character varying,
            'hazard'::character varying,
            'police'::character varying,
            'other'::character varying
          ]
        )::text[]
      )
    )
  ),
  constraint map_reports_status_check check (
    (
      (status)::text = any (
        (
          array[
            'Active'::character varying,
            'Resolved'::character varying,
            'Pending'::character varying,
            'Inactive'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_map_reports_user_id on public.map_reports using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_map_reports_report_type on public.map_reports using btree (report_type) TABLESPACE pg_default;

create index IF not exists idx_map_reports_status on public.map_reports using btree (status) TABLESPACE pg_default;

create index IF not exists idx_map_reports_point_location on public.map_reports using gist (point_location) TABLESPACE pg_default;

create trigger update_map_reports_updated_at BEFORE
update on map_reports for EACH row
execute FUNCTION update_updated_at_column ();