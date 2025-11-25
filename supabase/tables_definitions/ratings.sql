create table public.ratings (
  id bigserial not null,
  rated_user bigint not null,
  rated_by bigint not null,
  rating integer null default 0,
  review text null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint ratings_pkey primary key (id),
  constraint fk_rated_by foreign KEY (rated_by) references users (id) on delete CASCADE,
  constraint fk_rated_user foreign KEY (rated_user) references users (id) on delete CASCADE
) TABLESPACE pg_default;