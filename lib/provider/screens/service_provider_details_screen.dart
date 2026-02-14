import 'package:drivio_app/provider/models/service_provider.dart';
import 'package:drivio_app/provider/services/service_provider_services.dart';
import 'package:flutter/material.dart';

class ServiceProviderDetailsScreen extends StatefulWidget {
  final int providerId;

  const ServiceProviderDetailsScreen({
    super.key,
    required this.providerId,
  });

  @override
  State<ServiceProviderDetailsScreen> createState() =>
      _ServiceProviderDetailsScreenState();
}

class _ServiceProviderDetailsScreenState
    extends State<ServiceProviderDetailsScreen> {
  ServiceProvider? _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    try {
      final service = ServiceProviderService();
      final provider = await service.getProviderById(widget.providerId);
      if (mounted) {
        setState(() {
          _provider = provider;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading service provider details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Provider'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _provider == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text('Provider not found'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadProvider,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          (_provider!.businessName.isNotEmpty
                                  ? _provider!.businessName[0]
                                  : 'P')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _provider!.businessName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Text(
                          _provider!.providerType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoTile(
                        icon: Icons.star,
                        title: 'Rating',
                        value:
                            _provider!.rating > 0 ? _provider!.rating.toStringAsFixed(1) : 'No ratings yet',
                      ),
                      _buildInfoTile(
                        icon: Icons.location_city,
                        title: 'City',
                        value: _provider!.city ?? 'Unknown',
                      ),
                      if (_provider!.address != null)
                        _buildInfoTile(
                          icon: Icons.location_on,
                          title: 'Address',
                          value: _provider!.address!,
                        ),
                      _buildInfoTile(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: _provider!.phone ?? 'Not available',
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

