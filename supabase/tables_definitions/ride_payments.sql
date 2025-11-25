create table public.ride_payments (
  id bigserial not null,
  user_payment_method_id bigint not null,
  amount numeric(10, 2) not null,
  payment_status character varying(20) null default 'pending'::character varying,
  currency character varying(3) null default 'Dirham'::character varying,
  transaction_id character varying(255) null,
  payment_date timestamp with time zone null,
  commission_percentage numeric(5, 2) null default 20.00,
  driver_earnings numeric(10, 2) not null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint ride_payments_pkey primary key (id),
  constraint fk_ride_payments_user_payment_method_id foreign KEY (user_payment_method_id) references user_payment_methods (id) on delete CASCADE,
  constraint ride_payments_payment_status_check check (
    (
      (payment_status)::text = any (
        (
          array[
            'pending'::character varying,
            'completed'::character varying,
            'failed'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_ride_payments_user_payment_method_id on public.ride_payments using btree (user_payment_method_id) TABLESPACE pg_default;

create index IF not exists idx_ride_payments_transaction_id on public.ride_payments using btree (transaction_id) TABLESPACE pg_default;

create index IF not exists idx_ride_payments_payment_status on public.ride_payments using btree (payment_status) TABLESPACE pg_default;

create index IF not exists idx_ride_payments_payment_date on public.ride_payments using btree (payment_date) TABLESPACE pg_default;

create trigger update_ride_payments_updated_at BEFORE
update on ride_payments for EACH row
execute FUNCTION update_updated_at_column ();