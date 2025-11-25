import 'package:drivio_app/passenger/modals/delivery_details_modal.dart';
import 'package:flutter/material.dart';

class DeliveryCategoriesView extends StatelessWidget {
  const DeliveryCategoriesView({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Colors.orange},
    {'name': 'Medicament', 'icon': Icons.medical_services, 'color': Colors.red},
    {'name': 'Clothes', 'icon': Icons.checkroom, 'color': Colors.blue},
    {
      'name': 'Groceries',
      'icon': Icons.local_grocery_store,
      'color': Colors.green,
    },
    {'name': 'Documents', 'icon': Icons.description, 'color': Colors.grey},
    {'name': 'Other', 'icon': Icons.category, 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder:
                    (context) => DeliveryDetailsModal(
                      category: category['name'] as String,
                    ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      size: 32,
                      color: category['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
