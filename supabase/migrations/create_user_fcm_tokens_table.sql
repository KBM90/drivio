-- Create user_fcm_tokens table to store Firebase Cloud Messaging tokens
create table if not exists public.user_fcm_tokens (
  id bigserial primary key,
  user_id bigint not null references public.users(id) on delete cascade,
  fcm_token text not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(user_id) -- One token per user (will be updated on refresh)
);

-- Create index for faster lookups
create index if not exists idx_user_fcm_tokens_user_id on public.user_fcm_tokens(user_id);

-- Enable RLS
alter table public.user_fcm_tokens enable row level security;

-- Policy: Users can only read/update their own tokens
create policy "Users can manage their own FCM tokens"
  on public.user_fcm_tokens
  for all
  using (
    user_id in (
      select id from public.users where user_id = auth.uid()
    )
  );

-- Grant permissions
grant all on public.user_fcm_tokens to authenticated;
grant usage, select on sequence public.user_fcm_tokens_id_seq to authenticated;
