-- Database function to trigger Edge Function when new car rental request is created
create or replace function public.notify_car_rental_request()
returns trigger
language plpgsql
security definer
as $$
declare
  car_renter_user_id bigint;
  car_info jsonb;
begin
  -- Get the car renter's user_id from the car rental
  select cr.user_id, 
         jsonb_build_object(
           'car_brand', cb.company || ' ' || cb.model,
           'daily_price', pcr.daily_price,
           'start_date', new.start_date,
           'end_date', new.end_date,
           'total_price', new.total_price
         )
  into car_renter_user_id, car_info
  from provided_car_rentals pcr
  join car_renters cr on cr.id = pcr.car_renter_id
  left join car_brands cb on cb.id = pcr.car_brand_id
  where pcr.id = new.car_rental_id;

  -- Insert notification into database (this will trigger the Edge Function)
  insert into public.notifications (user_id, title, body, data, is_read)
  values (
    car_renter_user_id,
    'New Car Rental Request',
    'You have a new rental request for ' || (car_info->>'car_brand'),
    jsonb_build_object(
      'type', 'car_rental_request',
      'request_id', new.id,
      'car_info', car_info
    ),
    false
  );

  return new;
end;
$$;

-- Create trigger on car_rental_requests table
drop trigger if exists on_car_rental_request_created on public.car_rental_requests;

create trigger on_car_rental_request_created
  after insert on public.car_rental_requests
  for each row
  execute function public.notify_car_rental_request();
