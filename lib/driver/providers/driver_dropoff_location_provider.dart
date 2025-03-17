import 'package:drivio_app/common/constants/pusher.dart';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:latlong2/latlong.dart';

class DriverDropOffLocationProvider with ChangeNotifier {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  LatLng? dropoffLocation;
  final int driverId;

  DriverDropOffLocationProvider({required this.driverId}) {
    _initializePusher(driverId);
  }

  void _initializePusher(int driverId) async {
    try {
      await _pusher.init(
        apiKey: PusherConstants.app_id,
        cluster: PusherConstants.cluster,
        onConnectionStateChange: (String currentState, String? previousState) {
          debugPrint(
            "Pusher connection state changed: $previousState → $currentState",
          );
        },
        onError: (String message, int? code, dynamic e) {
          debugPrint("Pusher error: $message (code: $code) exception: $e");
        },
      );

      await _pusher.subscribe(
        channelName: "private-driver.$driverId",
        onEvent: (event) {
          debugPrint("Pusher event received: ${event.eventName}");

          try {
            final Map<String, dynamic> data =
                event.data as Map<String, dynamic>;

            final double lat = double.parse(
              data['dropoff_location']['lat'].toString(),
            );
            final double lng = double.parse(
              data['dropoff_location']['lng'].toString(),
            );

            dropoffLocation = LatLng(lat, lng);
            notifyListeners();
          } catch (e) {
            debugPrint("Error parsing dropoff location: $e");
          }
        },
      );

      await _pusher.connect();
    } catch (e) {
      debugPrint("Pusher initialization error: $e");
    }
  }

  @override
  void dispose() {
    _pusher.unsubscribe(channelName: "private-driver.$driverId");
    _pusher.disconnect();
    super.dispose();
  }
}
