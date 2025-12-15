import 'package:drivio_app/common/models/crash_report.dart';
import 'package:drivio_app/driver/providers/crash_report_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrashReportScreen extends StatefulWidget {
  final int? rideId;

  const CrashReportScreen({super.key, this.rideId});

  @override
  State<CrashReportScreen> createState() => _CrashReportScreenState();
}

class _CrashReportScreenState extends State<CrashReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrashReportProvider>().getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Crash'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Consumer<CrashReportProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Emergency Contacts Section
                _buildEmergencySection(provider),
                const SizedBox(height: 24),

                // Location Section
                _buildLocationSection(provider),
                const SizedBox(height: 24),

                // Severity Section
                _buildSeveritySection(provider),
                const SizedBox(height: 24),

                // Details Section
                _buildDetailsSection(provider),
                const SizedBox(height: 24),

                // Photos Section
                _buildPhotosSection(provider),
                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencySection(CrashReportProvider provider) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to call emergency services immediately',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.dialEmergency('190'),
                    icon: const Icon(Icons.local_police, size: 20),
                    label: const Text(
                      '190\nPolice',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.dialEmergency('177'),
                    icon: const Icon(Icons.security, size: 20),
                    label: const Text(
                      '177\nGendarmerie',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.dialEmergency('150'),
                    icon: const Icon(Icons.local_hospital, size: 20),
                    label: const Text(
                      '150\nAmbulance',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.dialEmergency('5050'),
                    icon: const Icon(Icons.local_shipping, size: 20),
                    label: const Text(
                      '5050\nHighway',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(CrashReportProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoadingLocation)
              const Center(child: CircularProgressIndicator())
            else if (provider.hasLocation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.address ?? 'Location captured',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.latitude!.toStringAsFixed(6)}, ${provider.longitude!.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              )
            else
              TextButton.icon(
                onPressed: provider.getCurrentLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Getting Location'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeveritySection(CrashReportProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crash Severity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<CrashSeverity>(
              segments: const [
                ButtonSegment(
                  value: CrashSeverity.minor,
                  label: Text('Minor'),
                  icon: Icon(Icons.info_outline),
                ),
                ButtonSegment(
                  value: CrashSeverity.moderate,
                  label: Text('Moderate'),
                  icon: Icon(Icons.warning_amber),
                ),
                ButtonSegment(
                  value: CrashSeverity.severe,
                  label: Text('Severe'),
                  icon: Icon(Icons.error_outline),
                ),
              ],
              selected: {provider.severity},
              onSelectionChanged: (Set<CrashSeverity> selected) {
                provider.setSeverity(selected.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(CrashReportProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crash Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe what happened...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: provider.setDescription,
            ),
            const SizedBox(height: 16),

            // Injuries
            CheckboxListTile(
              title: const Text('Injuries Reported'),
              value: provider.injuriesReported,
              onChanged:
                  (value) => provider.setInjuriesReported(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // Police Notified
            CheckboxListTile(
              title: const Text('Police Notified'),
              value: provider.policeNotified,
              onChanged: (value) => provider.setPoliceNotified(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // Vehicles Involved
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Vehicles Involved:'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed:
                      provider.vehiclesInvolved > 1
                          ? () => provider.setVehiclesInvolved(
                            provider.vehiclesInvolved - 1,
                          )
                          : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${provider.vehiclesInvolved}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed:
                      () => provider.setVehiclesInvolved(
                        provider.vehiclesInvolved + 1,
                      ),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection(CrashReportProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.pickPhotos,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                  ),
                ),
              ],
            ),
            if (provider.selectedPhotos.isNotEmpty) ...[
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: provider.selectedPhotos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        provider.selectedPhotos[index],
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => provider.removePhoto(index),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(CrashReportProvider provider) {
    return ElevatedButton(
      onPressed:
          provider.isSubmitting || !provider.hasLocation
              ? null
              : () async {
                final report = await provider.submitReport(
                  rideId: widget.rideId,
                );

                if (mounted && report != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Crash report submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } else if (mounted && provider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      child:
          provider.isSubmitting
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : const Text(
                'Submit Crash Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
    );
  }
}
