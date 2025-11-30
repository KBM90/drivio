-- Migration to fix online time calculation logic
-- This updates the refresh_driver_earnings_summary function to correctly calculate
-- online time by considering only the intersection of the session and the requested period.

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
