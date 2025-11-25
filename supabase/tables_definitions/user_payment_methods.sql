create table public.user_payment_methods (
  id bigserial not null,
  user_id bigint not null,
  payment_method_id bigint not null,
  details jsonb null,
  is_default boolean null default false,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint user_payment_methods_pkey primary key (id),
  constraint fk_user_payment_methods_payment_method_id foreign KEY (payment_method_id) references payment_methods (id) on delete CASCADE,
  constraint fk_user_payment_methods_user_id foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_user_payment_methods_user_id on public.user_payment_methods using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_user_payment_methods_payment_method_id on public.user_payment_methods using btree (payment_method_id) TABLESPACE pg_default;

create index IF not exists idx_user_payment_methods_is_default on public.user_payment_methods using btree (is_default) TABLESPACE pg_default;

create trigger update_user_payment_methods_updated_at BEFORE
update on user_payment_methods for EACH row
execute FUNCTION update_updated_at_column ();