create table public.service_images (
  id bigserial not null,
  service_id bigint not null,
  image_url text not null,
  created_at timestamp with time zone default now(),
  constraint service_images_pkey primary key (id),
  constraint service_images_service_id_fkey foreign KEY (service_id) references provided_services (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_service_images_service_id on public.service_images using btree (service_id) TABLESPACE pg_default;
