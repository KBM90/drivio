import 'package:flutter/material.dart';

class SearchButton extends StatelessWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(Icons.search, color: Colors.black),
        onPressed: () {
          _showSearchModal(context);
        },
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 1, // Adjust to fit content
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.arrow_back),
                    hintText: "Search for places",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Destination Filter Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Destination Filter",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Not filtering trips\n2 uses available today",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Switch(value: false, onChanged: (value) {}),
                  ],
                ),
                Divider(),

                // Home Destination
                ListTile(
                  leading: Icon(Icons.home, color: Colors.black),
                  title: Text("Home"),
                  subtitle: Text("Rosedale Center"),
                  trailing: Icon(Icons.edit, color: Colors.black),
                ),
                Divider(),

                // Nearby Places
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNearbyPlace(Icons.wc, "Restrooms"),
                    _buildNearbyPlace(Icons.restaurant, "Food"),
                    _buildNearbyPlace(Icons.local_gas_station, "Gas"),
                    _buildNearbyPlace(Icons.bolt, "Chargers"),
                    _buildNearbyPlace(Icons.card_giftcard, "Rewards"),
                  ],
                ),
                Divider(),

                // Suggested Places
                Expanded(
                  child: ListView(
                    children: [
                      _buildPlaceItem(
                        "Rosedale Center",
                        "1595 Highway 36 W, Roseville, MN",
                      ),
                      _buildPlaceItem(
                        "Costco",
                        "3311 Broadway St NE, Minneapolis, MN, US",
                      ),
                      _buildPlaceItem(
                        "The Home Depot",
                        "1520 New Brighton Blvd, Minneapolis, MN, US",
                      ),
                      _buildPlaceItem(
                        "W Minneapolis - The Foshay",
                        "Minneapolis, MN, US",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNearbyPlace(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(icon, color: Colors.black),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPlaceItem(String title, String subtitle) {
    return ListTile(
      leading: Icon(Icons.location_on, color: Colors.black),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
