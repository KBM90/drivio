create table public.vehicle_images (
  id bigserial not null,
  vehicle_id bigint not null,
  image_path character varying(255) not null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint vehicle_images_pkey primary key (id),
  constraint fk_vehicle_images_vehicle_id foreign KEY (vehicle_id) references vehicles (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_vehicle_images_vehicle_id on public.vehicle_images using btree (vehicle_id) TABLESPACE pg_default;

create trigger update_vehicle_images_updated_at BEFORE
update on vehicle_images for EACH row
execute FUNCTION update_updated_at_column ();