create table public.passengers (
  id bigserial not null,
  user_id bigint not null,
  location geometry null,
  preferences jsonb null,
  driving_distance numeric(10, 2) null default 0,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint passengers_pkey primary key (id),
  constraint passengers_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;