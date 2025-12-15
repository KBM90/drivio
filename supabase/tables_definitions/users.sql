create table public.users (
  id bigserial not null,
  name character varying(255) not null,
  email character varying(255) not null,
  phone character varying(255) null,
  sexe character varying(10) null,
  city character varying(255) null,
  country_code character varying(10) null,
  language character varying(10) null,
  country character varying(255) null,
  role text not null,
  profile_image_path text null,
  banned boolean null default false,
  email_verified_at timestamp with time zone null,
  is_verified boolean not null default false,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  user_id uuid null,
  constraint users_pkey primary key (id),
  constraint users_email_key unique (email),
  constraint users_phone_key unique (phone),
  constraint unique_user_id unique (user_id),
  constraint users_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE,
  constraint users_role_check check (
    (
      role = any (
        array[
          'passenger'::text,
          'driver'::text,
          'courtier'::text,
          'provider'::text,
          'admin'::text,
          'carrenter'::text,
          'deliveryperson'::text
        ]
      )
    )
  ),
  constraint users_sexe_check check (
    (
      (sexe)::text = any (
        (
          array[
            'male'::character varying,
            'female'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_users_user_id on public.users using btree (user_id) TABLESPACE pg_default;

create index IF not exists users_role_index on public.users using btree (role) TABLESPACE pg_default;

create index IF not exists users_city_index on public.users using btree (city) TABLESPACE pg_default;

create index IF not exists users_banned_index on public.users using btree (banned) TABLESPACE pg_default;

create trigger update_users_updated_at BEFORE
update on users for EACH row
execute FUNCTION update_updated_at_column ();