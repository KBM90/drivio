import 'dart:async';
import 'package:drivio_app/common/helpers/error_handler.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverProvider extends ChangeNotifier {
  Driver? _currentDriver;
  Driver? get currentDriver => _currentDriver;

  String? _statusMessage = "";

  String? get statusMessage => _statusMessage;

  Future<void> getDriver(BuildContext context) async {
    try {
      _currentDriver = await DriverService.getDriver();

      // Validate driver status - if on_trip but no active ride, reset to active
      await _validateDriverStatus();

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error fetching driver in DriverProvider: $e");
      handleAppError(context, e);
    }
  }

  /// Validates driver status and fixes inconsistencies
  /// If driver is on_trip but has no active ride, resets to active
  Future<void> _validateDriverStatus() async {
    if (_currentDriver?.status == DriverStatus.onTrip) {
      try {
        // Check if there's an active ride in SharedPreferences
        final currentRideId = await SharedPreferencesHelper().getInt(
          "currentRideId",
        );

        bool shouldReset = false;

        if (currentRideId == null) {
          // No ride ID in SharedPreferences
          shouldReset = true;
        } else {
          // Check if the ride actually exists and belongs to this driver
          try {
            final ride =
                await Supabase.instance.client
                    .from('ride_requests')
                    .select('id, driver_id, status')
                    .eq('id', currentRideId)
                    .maybeSingle();

            if (ride == null) {
              shouldReset = true;
            } else if (ride['driver_id'] != _currentDriver?.id) {
              shouldReset = true;
            } else if (ride['status'] != 'accepted' &&
                ride['status'] != 'arrived' &&
                ride['status'] != 'in_progress') {
              // Only keep driver as on_trip if ride is in active states

              shouldReset = true;
            } else {}
          } catch (e) {
            debugPrint("⚠️ Error checking ride in database: $e");
            // Don't reset on network error
          }
        }

        if (shouldReset) {
          await SharedPreferencesHelper.remove("currentRideId");
          await toggleStatus('active');
        }
      } catch (e) {
        debugPrint("❌ Error validating driver status: $e");
      }
    }
  }

  Future<void> toggleStatus(String status) async {
    switch (status) {
      case 'active':
        _statusMessage = await ChangeStatus().goOnline();
        _currentDriver?.status = DriverStatus.active;
        break;
      case 'on_trip':
        _statusMessage = await ChangeStatus().onTrip();
        _currentDriver?.status = DriverStatus.onTrip;
        break;
      case 'inactive':
        _statusMessage = await ChangeStatus().goOffline();
        _currentDriver?.status = DriverStatus.inactive;
        break;
    }

    notifyListeners();
  }

  Future<void> stopNewRequsts() async {
    try {
      // Check if _currentDriver is null
      if (_currentDriver == null) {
        print('Error: Current driver is not loaded.');
        return; // Or throw an exception, depending on your needs
      }

      String message = await RideRequestService.stopNewRequsts();
      if (message == 'Driver is now unavailable for new requests.') {
        _currentDriver!.acceptNewRequest = 0;
      } else {
        _currentDriver!.acceptNewRequest = 1;
      }
      notifyListeners();
    } catch (e) {
      print('Error stopping new requests: $e');
      // Optionally, notify the UI of the error (e.g., show a snackbar)
      // For now, we don't update _currentDriver if the request fails
    }
  }

  Future<void> acceptNewRequests() async {
    try {
      // Check if _currentDriver is null
      if (_currentDriver == null) {
        print('Error: Current driver is not loaded.');
        return; // Or throw an exception, depending on your needs
      }

      String message = await RideRequestService.acceptNewRequests();
      if (message == 'Driver is now available for new requests.') {
        _currentDriver!.acceptNewRequest = 1;
      } else {
        _currentDriver!.acceptNewRequest = 0;
      }
      notifyListeners();
    } catch (e) {
      print('Error stopping new requests: $e');
      // Optionally, notify the UI of the error (e.g., show a snackbar)
      // For now, we don't update _currentDriver if the request fails
    }
  }
}
