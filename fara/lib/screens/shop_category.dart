import 'package:flutter/material.dart';

class ShopCategoryPage extends StatelessWidget {
  const ShopCategoryPage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Suits & Blazers', 'icon': Icons.checkroom},
    {'name': 'Casual Shirts & Pants', 'icon': Icons.shopping_bag},
    {'name': 'Outerwear & Jackets', 'icon': Icons.ac_unit},
    {'name': 'Activewear & Fitness Gear', 'icon': Icons.sports_handball},
    {'name': 'Shoes & Accessories', 'icon': Icons.sports_basketball},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildCategoryTile(context, categories[index]),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Categories', style: TextStyle(color: Colors.black)),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Map<String, dynamic> category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Icon(category['icon'], color: Colors.black),
        ),
        title: Text(
          category['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () {
          // TODO: Navigate to filtered product list based on selected category
        },
      ),
    );
  }
}