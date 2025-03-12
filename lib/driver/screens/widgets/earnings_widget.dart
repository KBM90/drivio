import 'package:flutter/material.dart';

class EarningsWidget extends StatefulWidget {
  const EarningsWidget({super.key});

  @override
  _EarningsWidgetState createState() => _EarningsWidgetState();
}

class _EarningsWidgetState extends State<EarningsWidget> {
  bool _isPageViewVisible = false; // To track the visibility of PageView

  // PageController to manage the page view
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isPageViewVisible =
                  !_isPageViewVisible; // Toggle visibility of PageView
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "\$0.00",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        SizedBox(height: 10),
        // Conditionally show the PageView
        if (_isPageViewVisible)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            height: 150,
            width: 300,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            // Height for the page view
            child: PageView(
              controller: _pageController,
              children: [
                // "Today" View
                _buildEarningsPage(
                  title: "Today",
                  route: "route",
                  trips: "0 trips completed",
                  points: "0 points",
                ),
                // "Last Trip" View
                _buildEarningsPage(
                  title: "Last Trip",
                  route: "\$5.99",
                  trips: "UberX",
                  points: "1 point",
                ),
                // "Go Premium" View
                _buildEarningsPage(
                  title: "Uber Pro",
                  points: "128 points",
                  trips: "Earn 172 more points to achieve Gold",
                  route: "See Progress",
                ),
              ],
            ),
          ),
      ],
    );
  }

  // A function to build the individual pages inside the PageView
  Widget _buildEarningsPage({
    required String title,
    required String points,
    required String trips,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Trips: $trips",
            style: TextStyle(color: Colors.black, fontSize: 12),
            textAlign: TextAlign.center,
          ),

          Text(
            "Points: $points",
            style: TextStyle(color: Colors.black, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25),
          Text(
            "View Weekly Summary: $route",
            style: TextStyle(color: Colors.black, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
