import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/provider/services/provided_services_service.dart';
import 'package:flutter/material.dart';
import '../../common/models/provided_service.dart';
import 'edit_service_screen.dart';

class MyServicesScreen extends StatefulWidget {
  final Function(VoidCallback)? onRefreshCallback;

  const MyServicesScreen({super.key, this.onRefreshCallback});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  final ProvidedServicesService _servicesService = ProvidedServicesService();
  List<ProvidedService> _services = [];
  bool _isLoading = true;
  int? _providerId;

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_loadServices);
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) {
        debugPrint('❌ User ID is null');
        return;
      }

      // Get provider ID from service_providers table
      final providerData = await _servicesService.getProviderIdForUser(userId);
      if (providerData == null) {
        debugPrint('❌ Provider not found');
        return;
      }

      _providerId = providerData;
      final services = await _servicesService.getProviderServices(_providerId!);

      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading services: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteService(ProvidedService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Service'),
            content: Text('Are you sure you want to delete "${service.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _servicesService.deleteService(service.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service deleted successfully')),
          );
          _loadServices();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting service: $e')));
        }
      }
    }
  }

  Widget _buildServiceImage(String? imageUrl) {
    // Handle null or empty imageUrl
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 100,
        width: 100,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    // Check if it's an asset path
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        height: 100,
        width: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Failed to load asset: $imageUrl');
          debugPrint('   Error: $error');
          return Container(
            height: 100,
            width: 100,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 40, color: Colors.grey),
          );
        },
      );
    }

    // Otherwise, it's a network URL
    return Image.network(
      imageUrl,
      height: 100,
      width: 100,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) => Container(
            height: 100,
            width: 100,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No services yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first service',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];

          String imageUrl;
          if (service.imageUrls!.isNotEmpty) {
            imageUrl = service.imageUrls!.first;
          } else {
            // Convert category to snake_case for file name (e.g., "Brake Service" -> "brake_service")
            final categoryFileName =
                service.category
                    ?.toLowerCase()
                    .replaceAll(' ', '_')
                    .replaceAll(RegExp(r'[^a-z0-9_]'), '') ??
                'default';
            final providerType = service.providerType ?? 'other';
            imageUrl = 'assets/services/$providerType/$categoryFileName.png';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildServiceImage(imageUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (service.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              service.category!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${service.price} ${service.currency}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EditServiceScreen(
                                            service: service,
                                          ),
                                    ),
                                  );
                                  // Reload services if edit was successful
                                  if (result == true) {
                                    _loadServices();
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteService(service),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
