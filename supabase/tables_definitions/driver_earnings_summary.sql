-- Pivot table combining all driver earnings data for efficient querying
-- This table aggregates data from ride_requests, ride_payments, and driver_online_sessions
-- Drop existing table and related objects if they exist
DROP TABLE IF EXISTS public.driver_earnings_summary CASCADE;

-- Drop functions if they exist
DROP FUNCTION IF EXISTS refresh_driver_earnings_summary(bigint, date, date);
DROP FUNCTION IF EXISTS get_driver_current_week_earnings(bigint);

create table public.driver_earnings_summary (
  id bigserial not null,
  driver_id bigint not null,
  period_start date not null,
  period_end date not null,
  total_earnings numeric(10, 2) not null default 0,
  cash_earnings numeric(10, 2) not null default 0,
  bank_transfer_earnings numeric(10, 2) not null default 0,
  other_earnings numeric(10, 2) not null default 0,
  total_trips integer not null default 0,
  completed_trips integer not null default 0,
  total_online_minutes integer not null default 0,
  points integer not null default 0,
  next_payout_date date null,
  next_payout_amount numeric(10, 2) null default 0,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint driver_earnings_summary_pkey primary key (id),
  constraint fk_driver_earnings_summary_driver_id foreign key (driver_id) references drivers (id) on delete cascade,
  constraint driver_earnings_summary_period_check check (period_end >= period_start),
  constraint driver_earnings_summary_unique_driver_period unique (driver_id, period_start, period_end)
) tablespace pg_default;

-- Indexes for efficient querying
create index if not exists idx_driver_earnings_summary_driver_id 
  on public.driver_earnings_summary using btree (driver_id) tablespace pg_default;

create index if not exists idx_driver_earnings_summary_period 
  on public.driver_earnings_summary using btree (period_start, period_end) tablespace pg_default;

create index if not exists idx_driver_earnings_summary_driver_period 
  on public.driver_earnings_summary using btree (driver_id, period_start, period_end) tablespace pg_default;

-- Trigger to update updated_at timestamp
create trigger update_driver_earnings_summary_updated_at before
update on driver_earnings_summary for each row
execute function update_updated_at_column ();

-- Function to refresh driver earnings summary for a specific period
create or replace function refresh_driver_earnings_summary(
  p_driver_id bigint,
  p_period_start date,
  p_period_end date
)
returns void as $$
declare
  v_total_earnings numeric(10, 2);
  v_cash_earnings numeric(10, 2);
  v_bank_transfer_earnings numeric(10, 2);
  v_other_earnings numeric(10, 2);
  v_total_trips integer;
  v_completed_trips integer;
  v_total_online_minutes integer;
  v_points integer;
  v_period_start_ts timestamp;
  v_period_end_ts timestamp;
begin
  -- Convert dates to timestamps for comparison
  v_period_start_ts := p_period_start::timestamp;
  v_period_end_ts := (p_period_end + interval '1 day')::timestamp;

  -- Calculate total earnings from all payment methods
  select 
    coalesce(sum(rp.driver_earnings), 0),
    coalesce(sum(case when pm.name = 'Cash' then rp.driver_earnings else 0 end), 0),
    coalesce(sum(case when pm.name = 'Bank Transfer' then rp.driver_earnings else 0 end), 0),
    coalesce(sum(case when pm.name not in ('Cash', 'Bank Transfer') then rp.driver_earnings else 0 end), 0),
    count(distinct rr.id),
    count(distinct case when rr.status = 'completed' then rr.id end)
  into 
    v_total_earnings,
    v_cash_earnings,
    v_bank_transfer_earnings,
    v_other_earnings,
    v_total_trips,
    v_completed_trips
  from ride_requests rr
  inner join ride_payments rp on rp.ride_request_id = rr.id
  inner join user_payment_methods upm on upm.id = rp.user_payment_method_id
  inner join payment_methods pm on pm.id = upm.payment_method_id
  where rr.driver_id = p_driver_id
    and rr.created_at::date between p_period_start and p_period_end;

  -- Calculate total online time (intersection of session and period)
  -- We look for sessions that overlap with the period
  select 
    coalesce(sum(
      extract(epoch from (
        least(coalesce(session_end, now()), v_period_end_ts) - 
        greatest(session_start, v_period_start_ts)
      )) / 60
    ), 0)::integer
  into v_total_online_minutes
  from driver_online_sessions
  where driver_id = p_driver_id
    and session_start < v_period_end_ts
    and coalesce(session_end, now()) > v_period_start_ts;

  -- Calculate points (same as completed trips for now)
  v_points := v_completed_trips;

  -- Insert or update summary
  insert into driver_earnings_summary (
    driver_id,
    period_start,
    period_end,
    total_earnings,
    cash_earnings,
    bank_transfer_earnings,
    other_earnings,
    total_trips,
    completed_trips,
    total_online_minutes,
    points
  ) values (
    p_driver_id,
    p_period_start,
    p_period_end,
    v_total_earnings,
    v_cash_earnings,
    v_bank_transfer_earnings,
    v_other_earnings,
    v_total_trips,
    v_completed_trips,
    v_total_online_minutes,
    v_points
  )
  on conflict (driver_id, period_start, period_end)
  do update set
    total_earnings = excluded.total_earnings,
    cash_earnings = excluded.cash_earnings,
    bank_transfer_earnings = excluded.bank_transfer_earnings,
    other_earnings = excluded.other_earnings,
    total_trips = excluded.total_trips,
    completed_trips = excluded.completed_trips,
    total_online_minutes = excluded.total_online_minutes,
    points = excluded.points,
    updated_at = now();
end;
$$ language plpgsql;

-- Function to get current week earnings for a driver
create or replace function get_driver_current_week_earnings(p_driver_id bigint)
returns table (
  total_balance numeric,
  cash_earnings numeric,
  bank_transfer_earnings numeric,
  other_earnings numeric,
  total_trips integer,
  online_hours integer,
  online_minutes integer,
  points integer,
  next_payout_date date,
  next_payout_amount numeric
) as $$
declare
  v_week_start date;
  v_week_end date;
begin
  -- Get current week (Monday to Sunday)
  v_week_start := date_trunc('week', current_date)::date;
  v_week_end := (v_week_start + interval '6 days')::date;

  -- Refresh the summary for current week
  perform refresh_driver_earnings_summary(p_driver_id, v_week_start, v_week_end);

  -- Return the summary
  return query
  select 
    des.total_earnings as total_balance,
    des.cash_earnings,
    des.bank_transfer_earnings,
    des.other_earnings,
    des.completed_trips as total_trips,
    (des.total_online_minutes / 60)::integer as online_hours,
    (des.total_online_minutes % 60)::integer as online_minutes,
    des.points,
    des.next_payout_date,
    des.next_payout_amount
  from driver_earnings_summary des
  where des.driver_id = p_driver_id
    and des.period_start = v_week_start
    and des.period_end = v_week_end;
end;
$$ language plpgsql;