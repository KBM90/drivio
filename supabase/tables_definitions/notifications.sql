create table public.notifications (
  id bigserial not null,
  user_id bigint not null,
  title character varying(255) not null,
  body text not null,
  data jsonb null,
  is_read boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint notifications_pkey primary key (id),
  constraint notifications_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_notifications_user_id on public.notifications using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_notifications_is_read on public.notifications using btree (is_read) TABLESPACE pg_default;

create index IF not exists idx_notifications_user_id_is_read on public.notifications using btree (user_id, is_read) TABLESPACE pg_default;

create index IF not exists idx_notifications_created_at on public.notifications using btree (created_at desc) TABLESPACE pg_default;

create index IF not exists idx_notifications_data on public.notifications using gin (data) TABLESPACE pg_default;

create trigger update_notifications_updated_at BEFORE
update on notifications for EACH row
execute FUNCTION update_updated_at_column ();