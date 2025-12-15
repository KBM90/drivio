# Ride Request Notification System

This directory contains SQL triggers that automatically send push notifications to passengers when their ride status changes.

## 📋 Overview

The notification system uses database triggers to automatically notify passengers about important ride events:

1. **Ride Accepted** - When a driver accepts the ride request
2. **Driver Arrived** - When the driver arrives at pickup location (handled in Flutter code)
3. **Trip Completed** - When the trip is completed
4. **Ride Cancelled** - When the driver cancels the ride

## 🚀 Installation

### Option 1: Run All Triggers at Once (Recommended)

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file: `migrations/create_ride_notification_triggers.sql`
4. Copy and paste the entire content into the SQL editor
5. Click **Run** to execute

### Option 2: Run Individual Trigger Files

Run each file separately in the Supabase SQL editor:

1. `functions/notify_passenger_on_ride_accepted.sql`
2. `functions/notify_passenger_on_trip_completed.sql`
3. `functions/notify_passenger_on_ride_cancelled.sql` (included in comprehensive file)

## ✅ Verification

After running the SQL, verify the triggers are created by running this query:

```sql
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE event_object_table = 'ride_requests'
ORDER BY trigger_name;
```

You should see:
- `trigger_notify_passenger_on_ride_accepted`
- `trigger_notify_passenger_on_trip_completed`
- `trigger_notify_passenger_on_ride_cancelled`

## 🔔 How It Works

### Database Triggers
When a ride request status changes in the `ride_requests` table, the corresponding trigger:
1. Detects the status change
2. Fetches the passenger's `user_id`
3. Inserts a notification record into the `notifications` table

### Real-time Delivery
The Flutter app listens to the `notifications` table via Supabase real-time subscriptions:
1. When a new notification is inserted, the app receives it instantly
2. `NotificationService` displays a local push notification on the passenger's device
3. The notification appears in the system tray with sound and vibration (based on user preferences)

## 📱 Notification Details

### Ride Accepted
- **Title:** ✅ Ride Accepted!
- **Body:** [Driver Name] has accepted your ride request and is on the way!
- **Data:** `{ type: 'ride_accepted', ride_request_id: X, driver_id: Y }`

### Driver Arrived
- **Title:** 🚗 Driver has arrived!
- **Body:** Your driver is waiting at the pickup location.
- **Data:** `{ type: 'driver_arrived', ride_request_id: X }`

### Trip Completed
- **Title:** 🎉 Trip Completed!
- **Body:** Your trip has been completed. Thank you for riding with us!
- **Data:** `{ type: 'trip_completed', ride_request_id: X, driver_id: Y, price: Z }`

### Ride Cancelled
- **Title:** ❌ Ride Cancelled
- **Body:** Your driver has cancelled the ride. Please request a new ride.
- **Data:** `{ type: 'ride_cancelled', ride_request_id: X, driver_id: Y }`

## 🔧 Maintenance

### Updating Triggers
To update a trigger, simply re-run the SQL file. The `CREATE OR REPLACE FUNCTION` and `DROP TRIGGER IF EXISTS` statements ensure safe updates.

### Disabling Triggers
To temporarily disable a trigger:
```sql
ALTER TABLE ride_requests DISABLE TRIGGER trigger_notify_passenger_on_ride_accepted;
```

To re-enable:
```sql
ALTER TABLE ride_requests ENABLE TRIGGER trigger_notify_passenger_on_ride_accepted;
```

### Removing Triggers
To permanently remove a trigger:
```sql
DROP TRIGGER IF EXISTS trigger_notify_passenger_on_ride_accepted ON ride_requests;
DROP FUNCTION IF EXISTS notify_passenger_on_ride_accepted();
```

## 🐛 Troubleshooting

### Notifications Not Appearing
1. Check if triggers are enabled:
   ```sql
   SELECT * FROM information_schema.triggers WHERE event_object_table = 'ride_requests';
   ```

2. Check if notifications are being created:
   ```sql
   SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10;
   ```

3. Verify the passenger's `user_id` is correct:
   ```sql
   SELECT p.id, p.user_id, u.name 
   FROM passengers p 
   JOIN users u ON p.user_id = u.id 
   WHERE p.id = [passenger_id];
   ```

4. Check Flutter app logs for real-time subscription status

### Testing Triggers
You can manually test triggers by updating a ride request status:
```sql
UPDATE ride_requests 
SET status = 'accepted', driver_id = [driver_id]
WHERE id = [ride_request_id];
```

Then check if a notification was created:
```sql
SELECT * FROM notifications WHERE data->>'ride_request_id' = '[ride_request_id]';
```

## 📝 Notes

- All triggers use `SECURITY DEFINER` to bypass Row Level Security (RLS) policies
- Triggers only fire when the status actually changes (prevents duplicate notifications)
- The `data` field contains JSON metadata for potential future use (e.g., deep linking)
- Notifications are marked as unread by default (`is_read = false`)
