-- Table for storing service/product orders placed by any user (drivers, car renters, passengers, etc.)
create table public.service_orders (
  id bigserial primary key,
  
  -- Service and provider (nullable for custom orders)
  service_id bigint null,
  provider_id bigint null,
  
  -- Requester (any user who places the order)
  requester_user_id bigint not null,
  
  -- Custom order fields (for orders without a specific service)
  custom_service_name varchar(255) null,
  category varchar(100) null,
  
  -- Order details
  quantity integer default 1 check (quantity > 0),
  notes text null,
  preferred_contact_method varchar(20) default 'phone' check (preferred_contact_method in ('phone', 'whatsapp', 'sms')),
  
  -- Requester info (denormalized for quick access)
  requester_name varchar(255) not null,
  requester_phone varchar(20) not null,
  requester_location geometry(Point, 4326) null,
  
  -- Order status
  status varchar(20) default 'pending' check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
  
  -- Timestamps
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  
  -- Foreign keys
  constraint service_orders_service_id_fkey foreign key (service_id) references provided_services(id) on delete cascade,
  constraint service_orders_provider_id_fkey foreign key (provider_id) references service_providers(id) on delete cascade,
  constraint service_orders_requester_user_id_fkey foreign key (requester_user_id) references users(id) on delete cascade,
  
  -- Validation: Either service_id+provider_id OR custom_service_name+category must be provided
  constraint service_orders_order_type_check check (
    (service_id is not null and provider_id is not null) or
    (custom_service_name is not null and category is not null)
  )
) tablespace pg_default;

-- Indexes for performance
create index idx_service_orders_service_id on public.service_orders using btree (service_id) tablespace pg_default;
create index idx_service_orders_provider_id on public.service_orders using btree (provider_id) tablespace pg_default;
create index idx_service_orders_requester_user_id on public.service_orders using btree (requester_user_id) tablespace pg_default;
create index idx_service_orders_status on public.service_orders using btree (status) tablespace pg_default;
create index idx_service_orders_created_at on public.service_orders using btree (created_at desc) tablespace pg_default;

-- Trigger to update updated_at timestamp
create trigger update_service_orders_updated_at
  before update on service_orders
  for each row
  execute function update_updated_at_column();
