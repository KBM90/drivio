create table public.wallets (
  id bigserial not null,
  user_id bigint not null,
  balance numeric(10, 2) not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint wallets_pkey primary key (id),
  constraint wallets_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE,
  constraint wallets_balance_check check ((balance >= (0)::numeric))
) TABLESPACE pg_default;

create unique INDEX IF not exists wallets_user_id_unique on public.wallets using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_wallets_balance on public.wallets using btree (balance) TABLESPACE pg_default;

create trigger update_wallets_updated_at BEFORE
update on wallets for EACH row
execute FUNCTION update_updated_at_column ();