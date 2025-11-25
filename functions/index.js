const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

exports.sendNotification = onDocumentUpdated(
    "ride_requests/{rideId}",
    async (event) => {
      const newData = event.data.after.data();
      const prevData = event.data.before.data();

      // Only send if status actually changed
      if (prevData.status !== newData.status) {
        console.log(
            `🔔 Status changed from ${prevData.status} to ${newData.status}`
        );

        const userId = newData.userId;
        const driverName = newData.driverName || "Your driver";
        const newStatus = newData.status;

        try {
          const userDoc = await db.collection("users").doc(userId).get();
          if (!userDoc.exists) {
            console.log("⚠️ User not found");
            return;
          }

          const fcmToken = userDoc.data().fcmToken;
          if (!fcmToken) {
            console.log("⚠️ User FCM token missing");
            return;
          }

          // Customize notification based on status
          let title = "Ride Update";
          let body = `Your ride status: ${newStatus}`;

          if (newStatus === "arrived") {
            title = "Driver Arrived! 🚗";
            body = `${driverName} has arrived at your location.`;
          } else if (newStatus === "on_the_way") {
            title = "Driver On The Way! 🚕";
            body = `${driverName} is on the way to pick you up.`;
          } else if (newStatus === "accepted") {
            title = "Ride Accepted! ✅";
            body = `${driverName} accepted your ride request.`;
          } else if (newStatus === "completed") {
            title = "Ride Completed! 🎉";
            body = "Thank you for riding with us!";
          } else if (newStatus === "cancelled") {
            title = "Ride Cancelled ❌";
            body = "Your ride has been cancelled.";
          }

          const message = {
            notification: {
              title: title,
              body: body,
            },
            data: {
              rideId: event.params.rideId,
              status: newStatus,
              type: "status_change",
              driverName: driverName,
            },
            token: fcmToken,
          };

          const response = await messaging.send(message);
          console.log("✅ Notification sent:", response);
        } catch (error) {
          console.error("❌ Error sending notification:", error);
        }
      }
    }
);