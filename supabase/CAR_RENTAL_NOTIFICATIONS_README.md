# Car Rental Booking Notification System

This directory contains SQL triggers that automatically send push notifications to car renters when users book their cars.

## 📋 Overview

The notification system uses database triggers to automatically notify car renters about new bookings:

1. **New Booking Created** - When a user books a car for rental

## 🚀 Installation

### Run the Trigger Migration

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file: `migrations/create_car_rental_notification_triggers.sql`
4. Copy and paste the entire content into the SQL editor
5. Click **Run** to execute

## ✅ Verification

After running the SQL, verify the trigger is created by running this query:

```sql
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE event_object_table = 'car_rental_requests'
ORDER BY trigger_name;
```

You should see:
- `trigger_notify_car_renter_on_new_booking`

## 🔔 How It Works

### Database Triggers
When a new booking is inserted into the `car_rental_requests` table, the trigger:
1. Detects the new booking
2. Fetches the car renter's `user_id` by joining through `provided_car_rentals` → `car_renters` → `users`
3. Fetches the car brand name and user name for a personalized notification
4. Inserts a notification record into the `notifications` table

### Real-time Delivery
The Flutter app listens to the `notifications` table via Supabase real-time subscriptions:
1. When a new notification is inserted, the app receives it instantly
2. `NotificationService` displays a local push notification on the car renter's device
3. The notification appears in the system tray with sound and vibration (based on user preferences)

## 📱 Notification Details

### New Booking Created
- **Title:** 🚗 New Car Rental Booking!
- **Body:** [User Name] has booked your [Car Brand Model] from [Start Date] to [End Date]
- **Data:** `{ type: 'car_rental_booking', car_rental_request_id: X, car_rental_id: Y, user_id: Z, start_date: ..., end_date: ..., total_price: ... }`

## 🔧 Maintenance

### Updating Triggers
To update the trigger, simply re-run the SQL file. The `CREATE OR REPLACE FUNCTION` and `DROP TRIGGER IF EXISTS` statements ensure safe updates.

### Disabling Triggers
To temporarily disable the trigger:
```sql
ALTER TABLE car_rental_requests DISABLE TRIGGER trigger_notify_car_renter_on_new_booking;
```

To re-enable:
```sql
ALTER TABLE car_rental_requests ENABLE TRIGGER trigger_notify_car_renter_on_new_booking;
```

### Removing Triggers
To permanently remove the trigger:
```sql
DROP TRIGGER IF EXISTS trigger_notify_car_renter_on_new_booking ON car_rental_requests;
DROP FUNCTION IF EXISTS notify_car_renter_on_new_booking();
```

## 🐛 Troubleshooting

### Notifications Not Appearing
1. Check if trigger is enabled:
   ```sql
   SELECT * FROM information_schema.triggers WHERE event_object_table = 'car_rental_requests';
   ```

2. Check if notifications are being created:
   ```sql
   SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10;
   ```

3. Verify the car renter's `user_id` is correct:
   ```sql
   SELECT cr.id, cr.user_id, u.name 
   FROM car_renters cr 
   JOIN users u ON cr.user_id = u.id 
   WHERE cr.id = [car_renter_id];
   ```

4. Check Flutter app logs for real-time subscription status

### Testing Triggers
You can manually test the trigger by inserting a booking:
```sql
INSERT INTO car_rental_requests (user_id, car_rental_id, start_date, end_date, total_price)
VALUES ([user_id], [car_rental_id], '2026-02-01', '2026-02-05', 200.00);
```

Then check if a notification was created:
```sql
SELECT * FROM notifications WHERE data->>'car_rental_request_id' = '[request_id]';
```

## 📝 Notes

- The trigger uses `SECURITY DEFINER` to bypass Row Level Security (RLS) policies
- The trigger only fires on INSERT operations (new bookings)
- The `data` field contains JSON metadata for potential future use (e.g., deep linking)
- Notifications are marked as unread by default (`is_read = false`)
