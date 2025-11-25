import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:drivio_app/passenger/widgets/passenger_bottom_nav_bar.dart';

class PassengerAccountScreen extends StatelessWidget {
  const PassengerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Profile Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bo P',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.black),
                        SizedBox(width: 4),
                        Text('5.00', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person_outline, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Access Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _QuickAction(icon: Icons.help_outline, label: 'Help'),
                _QuickAction(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet',
                ),
                _QuickAction(icon: Icons.bookmark_border, label: 'Activity'),
              ],
            ),

            const SizedBox(height: 32),

            // Uber One
            const _InfoTile(
              title: 'Uber One',
              subtitle: 'Try free for 1 month',
              trailingIcon: Icons.emoji_events_outlined,
              iconColor: Colors.amber,
            ),

            // Privacy check-up
            const _InfoTile(
              title: 'Privacy check-up',
              subtitle: 'Take an interactive tour of your privacy settings',
              trailingIcon: Icons.assignment_turned_in_outlined,
              iconColor: Colors.blue,
            ),

            // CO2
            const _InfoTile(
              title: 'Estimated CO₂ saved',
              subtitle: '0 g',
              trailingIcon: Icons.eco_outlined,
              iconColor: Colors.green,
            ),

            const SizedBox(height: 16),

            // Family
            const _InfoTile(
              title: 'Family and teenagers',
              subtitle: 'Teenager and adult accounts',
              leadingIcon: Icons.group_outlined,
            ),

            // Settings
            const _InfoTile(
              title: 'Settings',
              leadingIcon: Icons.settings_outlined,
            ),

            ElevatedButton(
              onPressed: () async {
                await AuthService.signOut();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Log out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),

      // Bottom nav
      bottomNavigationBar: const PassengerBottomNavBarWidget(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.black87),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? trailingIcon;
  final Color? iconColor;
  final IconData? leadingIcon;

  const _InfoTile({
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.iconColor,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
          leadingIcon != null ? Icon(leadingIcon, color: Colors.black87) : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing:
          trailingIcon != null
              ? Icon(trailingIcon, color: iconColor ?? Colors.grey, size: 40)
              : null,
    );
  }
}
