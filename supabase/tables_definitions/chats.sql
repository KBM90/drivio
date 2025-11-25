create table public.chats (
  id character varying(255) not null,
  participants bigint[] not null,
  last_message text null,
  last_message_time timestamp with time zone null,
  last_sender_id bigint null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint chats_pkey primary key (id)
) TABLESPACE pg_default;

create index IF not exists idx_chats_participants on public.chats using gin (participants) TABLESPACE pg_default;

create index IF not exists idx_chats_updated_at on public.chats using btree (updated_at desc) TABLESPACE pg_default;

create trigger update_chats_updated_at BEFORE
update on chats for EACH row
execute FUNCTION update_updated_at_column ();