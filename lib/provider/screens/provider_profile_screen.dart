import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/provider/models/service_provider.dart';
import 'package:drivio_app/provider/services/service_provider_services.dart';
import 'package:flutter/material.dart';
import '../../common/screens/login_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  ServiceProvider? _provider;
  bool _isLoading = true;

  // Track which field is currently being edited
  String? _editingField;
  final TextEditingController _editController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId != null) {
        final service = ServiceProviderService();
        final provider = await service.getProviderProfile(userId);
        if (mounted) {
          setState(() {
            _provider = provider;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _startEditing(String field, String currentValue) {
    setState(() {
      _editingField = field;
      _editController.text = currentValue;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingField = null;
      _editController.clear();
    });
  }

  Future<void> _saveField(String field) async {
    if (_provider == null) return;

    setState(() => _isSaving = true);

    try {
      final service = ServiceProviderService();
      final newValue = _editController.text.trim();

      // Prepare all values, replacing the edited one
      String businessName = _provider!.businessName;
      String phone = _provider!.phone ?? '';
      String city = _provider!.city ?? '';
      String email = AuthService.currentUser?.email ?? '';

      switch (field) {
        case 'businessName':
          businessName = newValue;
          break;
        case 'phone':
          phone = newValue;
          break;
        case 'city':
          city = newValue;
          break;
        case 'email':
          email = newValue;
          break;
      }

      await service.updateProviderProfile(
        userId: _provider!.userId,
        businessName: businessName,
        phone: phone,
        city: city,
        email: email,
      );

      await _fetchProfile(); // Refresh data
      _cancelEditing();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_provider == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load profile'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProfile,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _signOut, child: const Text('Sign Out')),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Avatar Placeholder
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Name (Read-only for now as it's usually fixed or edited differently)
            Text(
              _provider!.name ?? 'No Name',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Provider Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
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
            const SizedBox(height: 32),

            // Details Section
            _buildEditableTile(
              icon: Icons.email,
              title: 'Email',
              value: AuthService.currentUser?.email ?? 'N/A',
              fieldKey: 'email',
            ),
            _buildEditableTile(
              icon: Icons.phone,
              title: 'Phone',
              value: _provider!.phone ?? 'N/A',
              fieldKey: 'phone',
            ),
            _buildEditableTile(
              icon: Icons.location_city,
              title: 'City',
              value: _provider!.city ?? 'N/A',
              fieldKey: 'city',
            ),
            _buildEditableTile(
              icon: Icons.business,
              title: 'Business Name',
              value: _provider!.businessName,
              fieldKey: 'businessName',
            ),

            const SizedBox(height: 40),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTile({
    required IconData icon,
    required String title,
    required String value,
    required String fieldKey,
  }) {
    final isEditing = _editingField == fieldKey;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child:
            isEditing
                ? ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.blue),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                  subtitle: TextFormField(
                    controller: _editController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed:
                            _isSaving ? null : () => _saveField(fieldKey),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _cancelEditing,
                      ),
                    ],
                  ),
                )
                : ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.grey.shade700),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  subtitle: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onPressed: () => _startEditing(fieldKey, value),
                  ),
                ),
      ),
    );
  }
}
