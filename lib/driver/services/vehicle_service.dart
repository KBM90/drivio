import 'dart:io';
import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/driver/models/vehicle.dart';
import 'package:drivio_app/driver/models/vehicle_document.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class VehicleService {
  static final _supabase = Supabase.instance.client;

  /// Get the driver's vehicle with car brand details
  static Future<Vehicle?> getDriverVehicle() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        debugPrint('❌ Driver ID not found');
        return null;
      }

      // Ensure session is valid
      await AuthService.ensureValidSession();

      final response =
          await _supabase
              .from('vehicles')
              .select('''
            *,
            car_brands (
              id,
              company,
              model,
              thumbnail_image,
              category
            )
          ''')
              .eq('driver_id', driverId)
              .maybeSingle();

      if (response == null) {
        debugPrint('ℹ️ No vehicle found for driver $driverId');
        return null;
      }

      return Vehicle.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching driver vehicle: $e');
      rethrow;
    }
  }

  /// Update vehicle information
  static Future<void> updateVehicle({
    required int vehicleId,
    required int carBrandId,
    required String color,
    String? licensePlate,
  }) async {
    try {
      await AuthService.ensureValidSession();
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        debugPrint('❌ Driver ID not found');
        return;
      }

      final updateData = {
        'car_brand_id': carBrandId,
        'color': color,
        'driver_id': driverId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (licensePlate != null) {
        updateData['license_plate'] = licensePlate;
      }

      await _supabase.from('vehicles').update(updateData).eq('id', vehicleId);
    } catch (e) {
      debugPrint('❌ Error updating vehicle: $e');
      rethrow;
    }
  }

  /// Create a new vehicle for the driver
  static Future<Vehicle> createVehicle({
    required int carBrandId,
    required String licensePlate,
    required String color,
    int transportTypeId = 1, // Default to car
  }) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver ID not found');
      }

      await AuthService.ensureValidSession();

      final response =
          await _supabase
              .from('vehicles')
              .insert({
                'driver_id': driverId,
                'car_brand_id': carBrandId,
                'transport_type_id': transportTypeId,
                'license_plate': licensePlate,
                'color': color,
                'status': true,
              })
              .select('''
            *,
            car_brands (
              id,
              company,
              model,
              thumbnail_image,
              category
            )
          ''')
              .single();

      return Vehicle.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating vehicle: $e');
      rethrow;
    }
  }

  /// Upload vehicle image to Supabase Storage
  static Future<String?> uploadVehicleImage(XFile imageFile) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver ID not found');
      }

      final file = File(imageFile.path);
      final fileName =
          'vehicle_${driverId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'vehicles/$fileName';

      await _supabase.storage.from('vehicle_images').upload(path, file);

      final publicUrl = _supabase.storage
          .from('vehicle_images')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading vehicle image: $e');
      rethrow;
    }
  }

  /// Save vehicle image reference to database
  static Future<void> saveVehicleImage({
    required int vehicleId,
    required String imagePath,
  }) async {
    try {
      await AuthService.ensureValidSession();

      await _supabase.from('vehicle_images').insert({
        'vehicle_id': vehicleId,
        'image_path': imagePath,
      });
    } catch (e) {
      debugPrint('❌ Error saving vehicle image reference: $e');
      rethrow;
    }
  }

  /// Get all car brands grouped by company
  static Future<Map<String, List<CarBrand>>> getCarBrands() async {
    try {
      await AuthService.ensureValidSession();

      final response = await _supabase
          .from('car_brands')
          .select()
          .eq('category', 'car')
          .order('company')
          .order('model');

      final brands =
          (response as List).map((json) => CarBrand.fromJson(json)).toList();

      // Group by company
      final Map<String, List<CarBrand>> grouped = {};
      for (var brand in brands) {
        if (!grouped.containsKey(brand.company)) {
          grouped[brand.company] = [];
        }
        grouped[brand.company]!.add(brand);
      }

      return grouped;
    } catch (e) {
      debugPrint('❌ Error fetching car brands: $e');
      rethrow;
    }
  }

  /// Get models for a specific company
  static Future<List<CarBrand>> getCarModels(String company) async {
    try {
      await AuthService.ensureValidSession();

      final response = await _supabase
          .from('car_brands')
          .select()
          .eq('company', company)
          .eq('category', 'car')
          .order('model');

      return (response as List).map((json) => CarBrand.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching car models: $e');
      rethrow;
    }
  }

  /// Get predefined car colors
  static List<String> getCarColors() {
    return [
      'White',
      'Black',
      'Silver',
      'Gray',
      'Red',
      'Blue',
      'Brown',
      'Green',
      'Beige',
      'Orange',
      'Gold',
      'Yellow',
      'Purple',
    ];
  }
  // ... existing code ...

  /// Get documents for a vehicle
  static Future<List<VehicleDocument>> getVehicleDocuments(
    int vehicleId,
  ) async {
    try {
      await AuthService.ensureValidSession();

      final response = await _supabase
          .from('vehicle_documents')
          .select('''
            *,
            document_images (
              image_path
            )
          ''')
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => VehicleDocument.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching vehicle documents: $e');
      rethrow;
    }
  }

  /// Upload document image
  static Future<int> uploadDocumentImage(XFile imageFile) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) throw Exception('User ID not found');

      final file = File(imageFile.path);
      final fileName =
          'doc_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'documents/$fileName';

      await _supabase.storage.from('vehicle_images').upload(path, file);

      final publicUrl = _supabase.storage
          .from('vehicle_images')
          .getPublicUrl(path);

      // Save to document_images table
      final response =
          await _supabase
              .from('document_images')
              .insert({'image_path': publicUrl})
              .select()
              .single();

      return response['id'] as int;
    } catch (e) {
      debugPrint('❌ Error uploading document image: $e');
      rethrow;
    }
  }

  /// Add a new vehicle document
  static Future<void> addVehicleDocument({
    required int vehicleId,
    required String documentName,
    required String documentType,
    required DateTime expiringDate,
    required int imageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await AuthService.ensureValidSession();

      await _supabase.from('vehicle_documents').insert({
        'vehicle_id': vehicleId,
        'document_name': documentName,
        'document_type': documentType,
        'expiring_date': expiringDate.toIso8601String(),
        'image_id': imageId,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('❌ Error adding vehicle document: $e');
      rethrow;
    }
  }

  /// Delete a vehicle document
  static Future<void> deleteVehicleDocument(int documentId) async {
    try {
      await AuthService.ensureValidSession();
      await _supabase.from('vehicle_documents').delete().eq('id', documentId);
    } catch (e) {
      debugPrint('❌ Error deleting vehicle document: $e');
      rethrow;
    }
  }
}
