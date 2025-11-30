import 'dart:io';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/provider/models/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../common/models/provided_service.dart';

class ProvidedServicesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all services, optionally filtered by category and city
  Future<List<ProvidedService>> getServices({
    String? category,
    String? city,
  }) async {
    try {
      await AuthService.ensureValidSession();
      // Build the select query with proper inner join syntax
      String selectQuery = '*, service_images(image_url)';

      // Add service_providers with !inner if we need to filter by city
      if (city != null && city.isNotEmpty) {
        selectQuery += ', service_providers!inner(*, users(phone))';
      } else {
        selectQuery += ', service_providers(*, users(phone))';
      }

      var query = _supabase.from('provided_services').select(selectQuery);

      // Filter by category if provided
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // Normalize city before querying
      if (city != null && city.isNotEmpty) {
        final normalizedCity = OSRMService().normalizeCity(city);
        query = query.eq('service_providers.users.city', normalizedCity);
        debugPrint(
          '🔍 Searching for normalized city: $normalizedCity (original: $city)',
        );
      }

      debugPrint('city: $city');
      debugPrint('selectQuery: $selectQuery');

      final response = await query.order('created_at', ascending: false);

      debugPrint('✅ Got ${(response as List).length} services');

      return (response as List)
          .map((e) => ProvidedService.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching services: $e');
      return [];
    }
  }

  /// Fetch services for a specific provider
  Future<List<ProvidedService>> getProviderServices(int providerId) async {
    try {
      await AuthService.ensureValidSession();
      final response = await _supabase
          .from('provided_services')
          .select(
            '*, service_images(image_url), service_providers(*, users(phone))',
          )
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      if (response == null) return [];

      // Debug: Print raw response to see what data we're getting
      debugPrint('🔍 Raw response from getProviderServices:');
      for (var item in (response as List)) {
        debugPrint('  Service: ${item['name']}');
        debugPrint('  service_providers data: ${item['service_providers']}');
      }

      return (response as List)
          .map((e) => ProvidedService.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching provider services: $e');
      return [];
    }
  }

  /// Fetch all providers, optionally filtered by type
  Future<List<ServiceProvider>> getProviders({String? type}) async {
    try {
      await AuthService.ensureValidSession();
      var query = _supabase
          .from('service_providers')
          .select('*, users(phone, city, name)');

      if (type != null && type.isNotEmpty) {
        query = query.eq('provider_type', type);
      }

      final response = await query.order('rating', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((e) => ServiceProvider.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching providers: $e');
      return [];
    }
  }

  /// Get provider ID for a user
  Future<int?> getProviderIdForUser(int userId) async {
    try {
      await AuthService.ensureValidSession();
      final response =
          await _supabase
              .from('service_providers')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

      return response?['id'] as int?;
    } catch (e) {
      debugPrint('❌ Error getting provider ID: $e');
      return null;
    }
  }

  /// Delete a service
  Future<void> deleteService(int serviceId) async {
    try {
      await AuthService.ensureValidSession();

      // Get service details to check for uploaded images
      final serviceData =
          await _supabase
              .from('provided_services')
              .select('provider_id, service_images(image_url)')
              .eq('id', serviceId)
              .single();

      final images = serviceData['service_images'] as List?;

      // Delete uploaded images from storage (skip default images)
      if (images != null) {
        for (final img in images) {
          final imageUrl = img['image_url'] as String?;
          if (imageUrl != null && !imageUrl.startsWith('default:')) {
            try {
              // Extract path from public URL
              final uri = Uri.parse(imageUrl);
              final pathSegments = uri.pathSegments;
              if (pathSegments.length >= 2) {
                final storagePath = pathSegments
                    .sublist(pathSegments.length - 3)
                    .join('/');
                await _supabase.storage.from('service_images').remove([
                  storagePath,
                ]);
              }
            } catch (e) {
              debugPrint('⚠️ Error deleting image from storage: $e');
            }
          }
        }
      }

      // Delete service (cascade will delete service_images records)
      await _supabase.from('provided_services').delete().eq('id', serviceId);

      debugPrint('✅ Service deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting service: $e');
      rethrow;
    }
  }

  /// Create a new service with image upload or default image
  Future<void> createService({
    required String name,
    required String description,
    required double price,
    required String category,
    File? imageFile,
    String? providerType,
  }) async {
    try {
      await AuthService.ensureValidSession();
      final int? userId = await AuthService.getInternalUserId();
      debugPrint('DEBUG: userId type: ${userId.runtimeType}, value: $userId');

      if (userId == null) throw Exception('User not logged in');

      // 1. Get Provider ID and Type if not provided
      var pType = providerType;
      int pId;

      if (pType == null) {
        final providerResponse =
            await _supabase
                .from('service_providers')
                .select('id, provider_type')
                .eq('user_id', userId)
                .single();
        pId = providerResponse['id'];
        pType = providerResponse['provider_type'];
      } else {
        final providerResponse =
            await _supabase
                .from('service_providers')
                .select('id')
                .eq('user_id', userId)
                .single();
        pId = providerResponse['id'];
      }

      // 2. Insert Service
      final serviceResponse =
          await _supabase
              .from('provided_services')
              .insert({
                'provider_id': pId,
                'name': name,
                'description': description,
                'price': price,
                'category': category,
              })
              .select()
              .single();
      final serviceId = serviceResponse['id'];

      // 3. Handle Image (Upload or Default)
      String imageUrl;
      if (imageFile != null) {
        final imageExtension = imageFile.path.split('.').last;
        final imageName = '${const Uuid().v4()}.$imageExtension';
        final imagePath = '$pId/$serviceId/$imageName';

        await _supabase.storage
            .from('service_images')
            .upload(
              imagePath,
              imageFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );

        imageUrl = _supabase.storage
            .from('service_images')
            .getPublicUrl(imagePath);
        // 4. Insert Image Record
        await _supabase.from('service_images').insert({
          'service_id': serviceId,
          'image_url': imageUrl,
        });
      }
    } catch (e) {
      debugPrint('❌ Error creating service: $e');
      rethrow;
    }
  }

  /// Update an existing service with optional image update
  Future<void> updateService({
    required int serviceId,
    required String name,
    required String description,
    required double price,
    required String category,
    File? newImageFile,
    bool removeCurrentImage = false,
  }) async {
    try {
      await AuthService.ensureValidSession();

      // 1. Update service details
      await _supabase
          .from('provided_services')
          .update({
            'name': name,
            'description': description,
            'price': price,
            'category': category,
          })
          .eq('id', serviceId);

      // 2. Handle image updates
      if (removeCurrentImage || newImageFile != null) {
        // Get current images
        final serviceData =
            await _supabase
                .from('provided_services')
                .select('provider_id, service_images(image_url)')
                .eq('id', serviceId)
                .single();

        final providerId = serviceData['provider_id'];
        final images = serviceData['service_images'] as List?;

        // Delete old uploaded images from storage (skip default images)
        if (images != null) {
          for (final img in images) {
            final imageUrl = img['image_url'] as String?;
            if (imageUrl != null && !imageUrl.startsWith('default:')) {
              try {
                // Extract path from public URL
                final uri = Uri.parse(imageUrl);
                final pathSegments = uri.pathSegments;
                if (pathSegments.length >= 2) {
                  final storagePath = pathSegments
                      .sublist(pathSegments.length - 3)
                      .join('/');
                  await _supabase.storage.from('service_images').remove([
                    storagePath,
                  ]);
                }
              } catch (e) {
                debugPrint('⚠️ Error deleting old image from storage: $e');
              }
            }
          }
        }

        // Delete image records
        await _supabase
            .from('service_images')
            .delete()
            .eq('service_id', serviceId);

        // Upload new image if provided
        if (newImageFile != null) {
          final imageExtension = newImageFile.path.split('.').last;
          final imageName = '${const Uuid().v4()}.$imageExtension';
          final imagePath = '$providerId/$serviceId/$imageName';

          await _supabase.storage
              .from('service_images')
              .upload(
                imagePath,
                newImageFile,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );

          final imageUrl = _supabase.storage
              .from('service_images')
              .getPublicUrl(imagePath);

          // Insert new image record
          await _supabase.from('service_images').insert({
            'service_id': serviceId,
            'image_url': imageUrl,
          });
        }
      }

      debugPrint('✅ Service updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating service: $e');
      rethrow;
    }
  }
}
