create table public.messages (
  id bigserial not null,
  chat_id character varying(255) not null,
  sender_id bigint not null,
  receiver_id bigint not null,
  message text not null,
  timestamp timestamp with time zone null default CURRENT_TIMESTAMP,
  is_read boolean null default false,
  sender_name character varying(255) null,
  sender_role character varying(50) null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint messages_pkey primary key (id),
  constraint fk_messages_chat_id foreign KEY (chat_id) references chats (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_messages_chat_id on public.messages using btree (chat_id) TABLESPACE pg_default;

create index IF not exists idx_messages_sender_id on public.messages using btree (sender_id) TABLESPACE pg_default;

create index IF not exists idx_messages_receiver_id on public.messages using btree (receiver_id) TABLESPACE pg_default;

create index IF not exists idx_messages_timestamp on public.messages using btree ("timestamp" desc) TABLESPACE pg_default;

create index IF not exists idx_messages_is_read on public.messages using btree (is_read) TABLESPACE pg_default
where
  (is_read = false);

create index IF not exists idx_messages_chat_timestamp on public.messages using btree (chat_id, "timestamp" desc) TABLESPACE pg_default;

create index IF not exists idx_messages_unread_by_receiver on public.messages using btree (receiver_id, chat_id, is_read) TABLESPACE pg_default
where
  (is_read = false);

create trigger update_messages_updated_at BEFORE
update on messages for EACH row
execute FUNCTION update_updated_at_column ();