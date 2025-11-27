-- Table to track driver online/offline sessions for accurate online time calculation
create table public.driver_online_sessions (
  id bigserial not null,
  driver_id bigint not null,
  session_start timestamp with time zone not null default now(),
  session_end timestamp with time zone null,
  total_duration_minutes integer null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint driver_online_sessions_pkey primary key (id),
  constraint fk_driver_online_sessions_driver_id foreign key (driver_id) references drivers (id) on delete cascade,
  constraint driver_online_sessions_valid_duration check (
    (session_end is null) or (session_end >= session_start)
  )
) tablespace pg_default;

-- Indexes for efficient querying
create index if not exists idx_driver_online_sessions_driver_id 
  on public.driver_online_sessions using btree (driver_id) tablespace pg_default;

create index if not exists idx_driver_online_sessions_session_start 
  on public.driver_online_sessions using btree (session_start desc) tablespace pg_default;

create index if not exists idx_driver_online_sessions_active 
  on public.driver_online_sessions using btree (driver_id, session_end) 
  tablespace pg_default
  where session_end is null;

-- Trigger to update updated_at timestamp
create trigger update_driver_online_sessions_updated_at before
update on driver_online_sessions for each row
execute function update_updated_at_column ();

-- Function to calculate session duration when session ends
create or replace function calculate_session_duration()
returns trigger as $$
begin
  if new.session_end is not null and old.session_end is null then
    new.total_duration_minutes := extract(epoch from (new.session_end - new.session_start)) / 60;
  end if;
  return new;
end;
$$ language plpgsql;

-- Trigger to automatically calculate duration when session ends
create trigger calculate_driver_session_duration before
update on driver_online_sessions for each row
execute function calculate_session_duration ();

-- Function to start a new online session
create or replace function start_driver_online_session(p_driver_id bigint)
returns bigint as $$
declare
  v_session_id bigint;
begin
  -- End any existing open sessions for this driver
  update driver_online_sessions
  set session_end = now()
  where driver_id = p_driver_id and session_end is null;
  
  -- Create new session
  insert into driver_online_sessions (driver_id, session_start)
  values (p_driver_id, now())
  returning id into v_session_id;
  
  return v_session_id;
end;
$$ language plpgsql;


