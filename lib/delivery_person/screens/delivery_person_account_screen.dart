import 'package:drivio_app/common/models/user.dart' as app_user;
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/constants/routes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DeliveryPersonAccountScreen extends StatefulWidget {
  const DeliveryPersonAccountScreen({super.key});

  @override
  State<DeliveryPersonAccountScreen> createState() =>
      _DeliveryPersonAccountScreenState();
}

class _DeliveryPersonAccountScreenState
    extends State<DeliveryPersonAccountScreen> {
  app_user.User? _user;
  bool _isLoading = true;
  DateTime? _birthday; // To store birthday separately if not in User model

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return;

      final data =
          await Supabase.instance.client
              .from('users')
              .select()
              .eq('user_id', userId)
              .single();

      // Check if birthday/birth_date exists in the response
      // Assuming column name might be 'birth_date' or similar
      if (data.containsKey('birth_date') && data['birth_date'] != null) {
        _birthday = DateTime.tryParse(data['birth_date']);
      }

      setState(() {
        _user = app_user.User.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // 1. Profile Picture
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _user!.profileImagePath != null
                              ? NetworkImage(_user!.profileImagePath!)
                              : null,
                      child:
                          _user!.profileImagePath == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                    ),
                    const SizedBox(height: 20),

                    // 2. Name
                    _buildInfoTile(
                      icon: Icons.person_outline,
                      title: 'Name',
                      value: _user!.name,
                    ),
                    const Divider(),

                    // 3. Phone
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: _user!.phone ?? 'Not provided',
                    ),
                    const Divider(),

                    // 4. Email
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: _user!.email,
                    ),
                    const Divider(),

                    // 5. Sex (Gender)
                    _buildInfoTile(
                      icon: Icons.male, // Or appropriate gender icon
                      title: 'Sex',
                      value: _user!.sexe ?? 'Not specified',
                    ),
                    const Divider(),

                    // 6. Birthday
                    _buildInfoTile(
                      icon: Icons.cake_outlined,
                      title: 'Birthday',
                      value:
                          _birthday != null
                              ? DateFormat('MMM d, yyyy').format(_birthday!)
                              : 'Not provided',
                    ),
                    const Divider(),

                    const SizedBox(height: 40),

                    // 7. Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Logout'),
                      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
