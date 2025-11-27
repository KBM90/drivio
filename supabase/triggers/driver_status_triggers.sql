-- Trigger to automatically manage driver online sessions when status changes
-- This trigger starts a new session when driver goes active
-- and ends the session ONLY when driver goes inactive
-- Time continues to accumulate when driver is on_trip

create or replace function manage_driver_online_session()
returns trigger as $$
begin
  -- Driver going online (inactive -> active or on_trip)
  if new.status in ('active', 'on_trip') and old.status = 'inactive' then
    perform start_driver_online_session(new.id);
  end if;

  -- Driver going offline (active or on_trip -> inactive)
  -- Only stop calculating time when driver goes inactive
  if old.status in ('active', 'on_trip') and new.status = 'inactive' then
    perform end_driver_online_session(new.id);
  end if;

  return new;
end;
$$ language plpgsql;

-- Attach trigger to drivers table
create trigger track_driver_online_sessions
after update on drivers
for each row
when (old.status is distinct from new.status)
execute function manage_driver_online_session();
