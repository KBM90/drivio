import 'package:drivio_app/common/models/user.dart';
import 'package:drivio_app/common/screens/inbox_page.dart';
import 'package:drivio_app/common/screens/opportunities_page.dart';
import 'package:drivio_app/common/screens/refer_friends_page.dart';
import 'package:drivio_app/common/services/user_services.dart';
import 'package:drivio_app/driver/ui/screens/account_page.dart';
import 'package:drivio_app/driver/ui/screens/driver_profile_page.dart';
import 'package:drivio_app/driver/ui/screens/earning_page.dart';
import 'package:drivio_app/driver/ui/screens/wallet_page.dart';
import 'package:drivio_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await UserService.getPersistanceCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Menu List (Scrollable)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Profile Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to the Profile Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DriverProfilePage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage("assets/profile.png"),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.name ?? "John Doe",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "⭐ 4.97",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(),

                  // Menu Items
                  _buildMenuItem("Inbox", Icons.mail, context, badgeCount: 9),
                  _buildMenuItem("Refer Friends", Icons.group, context),
                  _buildMenuItem(
                    "Opportunities",
                    Icons.work,
                    context,
                    badgeCount: 8,
                  ),
                  _buildMenuItem("Earnings", Icons.attach_money, context),
                  _buildMenuItem("Drivio Pro", Icons.star, context),
                  _buildMenuItem(
                    "Wallet",
                    Icons.account_balance_wallet,
                    context,
                  ),
                  _buildMenuItem("Account", Icons.person, context),

                  const Divider(),

                  _buildMenuItem("Help", Icons.help_outline, context),
                  _buildMenuItem("Learning Center", Icons.school, context),

                  const SizedBox(height: 20), // Space before the button
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    BuildContext context, {
    int? badgeCount,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (badgeCount != null)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Navigate to the InboxPage when tapped
        if (title == "Inbox") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InboxPage()),
          );
        }
        if (title == "Refer Friends") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReferFriendsScreen()),
          );
        }
        if (title == "Opportunities") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OpportunitiesScreen(),
            ),
          );
        }
        if (title == "Earnings") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EarningsScreen()),
          );
        }
        if (title == "Wallet") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WalletScreen()),
          );
        }
        if (title == "Account") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountScreen()),
          );
        }
      },
    );
  }
}
