-- Table for storing custom service/product requests from drivers
-- These are requests for services not currently listed in provided_services
create table public.custom_service_requests (
  id bigserial primary key,
  driver_id bigint not null,
  
  -- Custom service details
  service_name varchar(255) not null,
  category varchar(50) not null check (category in ('Mechanic', 'Cleaner', 'Electrician', 'Insurance', 'Other')),
  description text not null,
  
  -- Request details
  quantity integer default 1 check (quantity > 0),
  notes text null,
  preferred_contact_method varchar(20) default 'phone' check (preferred_contact_method in ('phone', 'whatsapp', 'sms')),
  
  -- Driver info (denormalized for quick access)
  driver_name varchar(255) not null,
  driver_phone varchar(20) not null,
  driver_location geometry(Point, 4326) null,
  
  -- Request status
  status varchar(20) default 'pending' check (status in ('pending', 'contacted', 'fulfilled', 'cancelled')),
  
  -- Timestamps
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  
  -- Foreign keys
  constraint custom_service_requests_driver_id_fkey foreign key (driver_id) references drivers(id) on delete cascade
) tablespace pg_default;

-- Indexes for performance
create index idx_custom_service_requests_driver_id on public.custom_service_requests using btree (driver_id) tablespace pg_default;
create index idx_custom_service_requests_category on public.custom_service_requests using btree (category) tablespace pg_default;
create index idx_custom_service_requests_status on public.custom_service_requests using btree (status) tablespace pg_default;
create index idx_custom_service_requests_created_at on public.custom_service_requests using btree (created_at desc) tablespace pg_default;

-- Trigger to update updated_at timestamp
create trigger update_custom_service_requests_updated_at
  before update on custom_service_requests
  for each row
  execute function update_updated_at_column();
