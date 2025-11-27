-- Function to end the current online session
create or replace function end_driver_online_session(p_driver_id bigint)
returns void as $$
begin
  update driver_online_sessions
  set session_end = now()
  where driver_id = p_driver_id and session_end is null;
end;
$$ language plpgsql;