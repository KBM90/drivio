create table public.driver_payouts (
  id bigserial not null,
  driver_id bigint not null,
  payout_amount numeric(10, 2) not null,
  remaining_balance numeric(10, 2) not null,
  payment_method character varying(20) null,
  payout_status character varying(20) null default 'pending'::character varying,
  transaction_id character varying(255) null,
  payout_date timestamp with time zone null,
  notes text null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint driver_payouts_pkey primary key (id),
  constraint fk_driver_payouts_driver_id foreign KEY (driver_id) references users (id) on delete CASCADE,
  constraint driver_payouts_payment_method_check check (
    (
      (payment_method)::text = any (
        (
          array[
            'cash'::character varying,
            'card'::character varying,
            'wallet'::character varying
          ]
        )::text[]
      )
    )
  ),
  constraint driver_payouts_payout_status_check check (
    (
      (payout_status)::text = any (
        (
          array[
            'pending'::character varying,
            'processed'::character varying,
            'failed'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_driver_payouts_driver_id on public.driver_payouts using btree (driver_id) TABLESPACE pg_default;

create index IF not exists idx_driver_payouts_payout_status on public.driver_payouts using btree (payout_status) TABLESPACE pg_default;

create index IF not exists idx_driver_payouts_transaction_id on public.driver_payouts using btree (transaction_id) TABLESPACE pg_default;

create index IF not exists idx_driver_payouts_payout_date on public.driver_payouts using btree (payout_date) TABLESPACE pg_default;

create trigger update_driver_payouts_updated_at BEFORE
update on driver_payouts for EACH row
execute FUNCTION update_updated_at_column ();