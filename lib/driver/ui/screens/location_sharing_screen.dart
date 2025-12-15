import 'package:drivio_app/driver/providers/location_sharing_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocationSharingScreen extends StatefulWidget {
  final String? rideId;
  final String? driverName;

  const LocationSharingScreen({super.key, this.rideId, this.driverName});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationSharingProvider>().initializeSharing(
        rideId: widget.rideId,
        driverName: widget.driverName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow My Ride')),
      body: Consumer<LocationSharingProvider>(
        builder: (context, provider, child) {
          if (provider.currentPosition == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                _buildInfoCard(provider),
                const SizedBox(height: 24),

                // Share Buttons
                _buildShareButtons(provider),

                const SizedBox(height: 24),

                // Preview Message
                _buildMessagePreview(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(LocationSharingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Share Your Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Share your real-time location with family and friends. Choose how you want to share:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButtons(LocationSharingProvider provider) {
    return Column(
      children: [
        // WhatsApp Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _shareViaWhatsApp(provider),
            icon: const Icon(Icons.message, size: 24),
            label: const Text(
              'Share via WhatsApp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // SMS Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _shareViaSMS(provider),
            icon: const Icon(Icons.sms, size: 24),
            label: const Text(
              'Share via SMS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Other Apps Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _shareViaOtherApps(provider),
            icon: const Icon(Icons.share, size: 24),
            label: const Text(
              'Share via Other Apps',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagePreview(LocationSharingProvider provider) {
    final message = provider.generateMessage();
    if (message == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  'Message Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareViaWhatsApp(LocationSharingProvider provider) async {
    final success = await provider.shareViaWhatsAppDirect();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to share'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareViaSMS(LocationSharingProvider provider) async {
    final success = await provider.shareViaSMSDirect();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening SMS...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to share'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareViaOtherApps(LocationSharingProvider provider) async {
    final success = await provider.shareViaOtherApps();

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to share'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
