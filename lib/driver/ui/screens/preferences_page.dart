import 'package:drivio_app/driver/models/driver_preferences.dart';
import 'package:drivio_app/driver/services/driver_preferences_service.dart';
import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final DriverPreferencesService _preferencesService =
      DriverPreferencesService();

  // Service selections
  bool _isConnectChecked = true;
  bool _isDrivioXChecked = false;
  bool _isDeliveriesChecked = false;
  bool _isMusicChecked = false;

  // Trip filters
  bool _teenRequestsEnabled = false;
  double _rangeInKm = 10.0; // Default 10 km
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0); // 6:00 AM
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  bool _passengerWithPetsEnabled = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      // Load preferences and range separately
      final results = await Future.wait([
        _preferencesService.loadPreferences(),
        _preferencesService.loadRange(),
      ]);

      final prefs = results[0] as DriverPreferences?;
      final range = results[1] as double;

      if (prefs != null && mounted) {
        setState(() {
          // Load services
          _isConnectChecked = prefs.intercityEnabled;
          _isDrivioXChecked = prefs.drivioXEnabled;
          _isDeliveriesChecked = prefs.deliveriesEnabled;
          _isMusicChecked = prefs.smokingEnabled;

          // Load trip filters
          _teenRequestsEnabled = prefs.teenRequestsEnabled;
          _rangeInKm = range; // Load from drivers.range field
          _startTime = TimeOfDay(
            hour: prefs.startTimeHour,
            minute: prefs.startTimeMinute,
          );
          _endTime = TimeOfDay(
            hour: prefs.endTimeHour,
            minute: prefs.endTimeMinute,
          );
          _passengerWithPetsEnabled = prefs.passengerWithPetsEnabled;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPreferences() async {
    final success = await _preferencesService.resetPreferences();

    if (success && mounted) {
      setState(() {
        // Reset services to defaults
        _isConnectChecked = true;
        _isDrivioXChecked = false;
        _isDeliveriesChecked = false;
        _isMusicChecked = false;

        // Reset trip filters to defaults
        _teenRequestsEnabled = false;
        _rangeInKm = 10.0;
        _startTime = const TimeOfDay(hour: 6, minute: 0);
        _endTime = const TimeOfDay(hour: 22, minute: 0);
        _passengerWithPetsEnabled = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences reset to default'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reset preferences'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePreferences() async {
    final preferences = DriverPreferences(
      intercityEnabled: _isConnectChecked,
      drivioXEnabled: _isDrivioXChecked,
      deliveriesEnabled: _isDeliveriesChecked,
      smokingEnabled: _isMusicChecked,
      teenRequestsEnabled: _teenRequestsEnabled,
      startTimeHour: _startTime.hour,
      startTimeMinute: _startTime.minute,
      endTimeHour: _endTime.hour,
      endTimeMinute: _endTime.minute,
      passengerWithPetsEnabled: _passengerWithPetsEnabled,
    );

    final success = await _preferencesService.savePreferences(
      preferences,
      range: _rangeInKm, // Save range separately to drivers.range field
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Preferences saved successfully'
                : 'Failed to save preferences',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _selectTimeRange(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtering trips based on preferences',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Services Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'See more',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 5,
                        childAspectRatio: 1.2,
                        children: [
                          _buildServiceItem(
                            title: 'Intercity',
                            icon: Icons.alt_route,
                            isChecked: _isConnectChecked,
                            onChanged:
                                (value) =>
                                    setState(() => _isConnectChecked = value!),
                          ),
                          _buildServiceItem(
                            title: 'DrivioX',
                            icon: Icons.directions_car,
                            isChecked: _isDrivioXChecked,
                            onChanged:
                                (value) =>
                                    setState(() => _isDrivioXChecked = value!),
                          ),
                          _buildServiceItem(
                            title: 'Deliveries',
                            icon: Icons.delivery_dining,
                            isChecked: _isDeliveriesChecked,
                            onChanged:
                                (value) => setState(
                                  () => _isDeliveriesChecked = value!,
                                ),
                          ),
                          _buildServiceItem(
                            title: 'Smoking',
                            icon: Icons.smoking_rooms,
                            isChecked: _isMusicChecked,
                            onChanged:
                                (value) =>
                                    setState(() => _isMusicChecked = value!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Trip Filters Section
                      const Text(
                        'Trip filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Teen requests
                      _switchListTile(
                        title: "Teen requests",
                        ischecked: _teenRequestsEnabled,
                        onChanged:
                            (value) =>
                                setState(() => _teenRequestsEnabled = value!),
                      ),

                      // Range in km
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Range',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${_rangeInKm.toStringAsFixed(0)} km',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _rangeInKm,
                                min: 1,
                                max: 50,
                                divisions: 49,
                                label: '${_rangeInKm.toStringAsFixed(0)} km',
                                onChanged: (value) {
                                  setState(() => _rangeInKm = value);
                                },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Time range
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Time range',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () => _selectTimeRange(context, true),
                                      icon: const Icon(
                                        Icons.access_time,
                                        size: 18,
                                      ),
                                      label: Text(_formatTimeOfDay(_startTime)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'to',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () =>
                                              _selectTimeRange(context, false),
                                      icon: const Icon(
                                        Icons.access_time,
                                        size: 18,
                                      ),
                                      label: Text(_formatTimeOfDay(_endTime)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Passenger with pets
                      _switchListTile(
                        title: "Passenger with pets",
                        ischecked: _passengerWithPetsEnabled,
                        onChanged:
                            (value) => setState(
                              () => _passengerWithPetsEnabled = value!,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Reset Button
                      Center(
                        child: OutlinedButton(
                          onPressed: _resetPreferences,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Reset to defaults',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildServiceItem({
    required String title,
    required IconData icon,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Checkbox(
                  value: isChecked,
                  onChanged: onChanged,
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchListTile({
    required String title,
    required bool ischecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: ischecked,
        onChanged: onChanged,
        activeThumbColor: Colors.blue,
      ),
    );
  }
}
