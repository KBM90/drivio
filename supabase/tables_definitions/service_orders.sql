-- Table for storing service/product orders placed by drivers
create table public.service_orders (
  id bigserial primary key,
  service_id bigint not null,
  driver_id bigint not null,
  provider_id bigint not null,
  
  -- Order details
  quantity integer default 1 check (quantity > 0),
  notes text null,
  preferred_contact_method varchar(20) default 'phone' check (preferred_contact_method in ('phone', 'whatsapp', 'sms')),
  
  -- Driver info (denormalized for quick access)
  driver_name varchar(255) not null,
  driver_phone varchar(20) not null,
  driver_location geometry(Point, 4326) null,
  
  -- Order status
  status varchar(20) default 'pending' check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
  
  -- Timestamps
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  
  -- Foreign keys
  constraint service_orders_service_id_fkey foreign key (service_id) references provided_services(id) on delete cascade,
  constraint service_orders_driver_id_fkey foreign key (driver_id) references drivers(id) on delete cascade,
  constraint service_orders_provider_id_fkey foreign key (provider_id) references service_providers(id) on delete cascade
) tablespace pg_default;

-- Indexes for performance
create index idx_service_orders_service_id on public.service_orders using btree (service_id) tablespace pg_default;
create index idx_service_orders_driver_id on public.service_orders using btree (driver_id) tablespace pg_default;
create index idx_service_orders_provider_id on public.service_orders using btree (provider_id) tablespace pg_default;
create index idx_service_orders_status on public.service_orders using btree (status) tablespace pg_default;
create index idx_service_orders_created_at on public.service_orders using btree (created_at desc) tablespace pg_default;

-- Trigger to update updated_at timestamp
create trigger update_service_orders_updated_at
  before update on service_orders
  for each row
  execute function update_updated_at_column();
