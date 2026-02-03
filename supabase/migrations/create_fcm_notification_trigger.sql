-- This trigger function will be called when a new notification is inserted
-- It prepares the notification data for the Edge Function
-- The actual FCM sending will be handled by a Database Webhook (configured in Supabase Dashboard)

create or replace function public.notify_fcm_on_insert()
returns trigger
language plpgsql
security definer
as $$
begin
  -- This function just validates that the notification was inserted
  -- The actual FCM notification will be sent via Database Webhook
  -- configured in Supabase Dashboard to call the send-fcm-notification Edge Function
  
  raise log 'New notification created for user_id: %, title: %', new.user_id, new.title;
  
  return new;
end;
$$;

-- Create trigger on notifications table
drop trigger if exists on_notification_created on public.notifications;

create trigger on_notification_created
  after insert on public.notifications
  for each row
  execute function public.notify_fcm_on_insert();

-- ============================================================================
-- IMPORTANT: Database Webhook Setup Required
-- ============================================================================
-- Since we can't use ALTER DATABASE in Supabase, we'll use Database Webhooks instead.
-- 
-- Follow these steps in Supabase Dashboard:
-- 1. Go to Database > Webhooks
-- 2. Click "Create a new hook"
-- 3. Configure:
--    - Name: "Send FCM Notification"
--    - Table: notifications
--    - Events: INSERT
--    - Type: HTTP Request
--    - Method: POST
--    - URL: https://YOUR-PROJECT.supabase.co/functions/v1/send-fcm-notification
--    - HTTP Headers:
--        Authorization: Bearer YOUR-SERVICE-ROLE-KEY
--        Content-Type: application/json
-- 4. Click "Create webhook"
--
-- The webhook will automatically call your Edge Function whenever a notification is inserted.
-- ============================================================================
