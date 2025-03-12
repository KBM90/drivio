import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

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
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage("assets/profile.png"),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Joseph",
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

                  const Divider(),

                  // Menu Items
                  _buildMenuItem("Inbox", Icons.mail, badgeCount: 9),
                  _buildMenuItem("Refer Friends", Icons.group),
                  _buildMenuItem("Opportunities", Icons.work, badgeCount: 8),
                  _buildMenuItem("Earnings", Icons.attach_money),
                  _buildMenuItem("Uber Pro", Icons.star),
                  _buildMenuItem("Wallet", Icons.account_balance_wallet),
                  _buildMenuItem("Account", Icons.person),

                  const Divider(),

                  _buildMenuItem("Help", Icons.help_outline),
                  _buildMenuItem("Learning Center", Icons.school),

                  const SizedBox(height: 20), // Space before the button
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {},
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

  Widget _buildMenuItem(String title, IconData icon, {int? badgeCount}) {
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
        // Handle menu item taps
      },
    );
  }
}
