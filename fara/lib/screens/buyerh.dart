import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart.dart';
import 'package:fara/screens/product_details.dart';
import 'package:fara/screens/userp.dart';

class BuyerHomePage extends StatefulWidget {
  final int userId;

  const BuyerHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  List products = [];
  List filteredProducts = [];
  bool isLoading = true;
  String error = '';
  String? profileImageUrl;
  final TextEditingController searchController = TextEditingController();
  final String baseUrl = 'http://192.168.255.182:5001';

  final List<Map<String, dynamic>> categories = [
    {'name': 'Suits & Blazers', 'icon': Icons.checkroom},
    {'name': 'Casual Shirts & Pants', 'icon': Icons.shopping_bag},
    {'name': 'Outerwear & Jackets', 'icon': Icons.ac_unit},
    {'name': 'Activewear & Fitness Gear', 'icon': Icons.sports_handball},
    {'name': 'Shoes & Accessories', 'icon': Icons.sports_basketball},
    {'name': 'Grooming Products', 'icon': Icons.spa},
  ];

  @override
  void initState() {
    super.initState();
    fetchUserProfile(); // Get user picture from DB
    fetchProducts();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/user_profile/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileImageUrl = data['user']['photo_url'];
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/buyer_home'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            products = data['products'];
            filteredProducts = products;
            isLoading = false;
          });
        } else {
          _setError('Failed to load products');
        }
      } else {
        _setError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Connection error: $e');
    }
  }

  void _setError(String message) {
    setState(() {
      error = message;
      isLoading = false;
    });
  }

  void _searchProducts(String query) {
    final searchLower = query.toLowerCase();
    final results = products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final description = product['description']?.toString().toLowerCase() ?? '';
      return name.contains(searchLower) || description.contains(searchLower);
    }).toList();

    setState(() {
      filteredProducts = results;
    });
  }

  void _filterByCategory(String categoryName) {
    setState(() {
      filteredProducts = products
          .where((product) =>
              (product['category']?.toString().toLowerCase() ?? '') ==
              categoryName.toLowerCase())
          .toList();
    });
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: fetchProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(userId: widget.userId),
              ),
            );
            fetchUserProfile(); // Refresh profile image on return
          },
          child: CircleAvatar(
            radius: 24,
            backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                ? NetworkImage('$baseUrl/${profileImageUrl!.replaceAll('\\', '/')}')
                : const AssetImage('assets/profile.jpg'),
            backgroundColor: Colors.grey[800],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      hintText: 'Search products',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onChanged: _searchProducts,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartPage(userId: widget.userId)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.black, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget buildCategoryList() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              _filterByCategory(category['name']);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category['icon'], size: 30, color: Colors.black),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 80,
                  child: Text(
                    category['name'],
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 50),
          child: Text(
            'No products found.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final imageUrl = '$baseUrl/static/uploads/${product['image']}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsPage(
                  product: product,
                  userId: widget.userId,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${product['price']}',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : error.isNotEmpty
                ? Center(child: _buildError())
                : RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.grey[800],
                    onRefresh: () async {
                      await fetchProducts();
                      await fetchUserProfile();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 20),
                          _buildSectionHeader('Categories'),
                          const SizedBox(height: 12),
                          buildCategoryList(),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                filteredProducts = products;
                              });
                            },
                            child: const Text('Show All', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Available Products'),
                          const SizedBox(height: 12),
                          _buildProductGrid(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
