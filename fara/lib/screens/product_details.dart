import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fara/screens/checkout.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map product;
  final int userId;

  const ProductDetailsPage({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final String baseUrl = 'http://192.168.255.182:5001';
  List variations = [];
  Map? selectedVariation;
  bool isLoadingVariations = true;
  List reviews = [];
  bool isLoadingReviews = true;
  int quantity = 1;
  String errorMessage = '';
  final TextEditingController commentController = TextEditingController();
  double selectedRating = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.product['id'] != null) {
      fetchVariations();
      fetchReviews();
    } else {
      setState(() {
        errorMessage = 'Invalid product ID.';
        isLoadingVariations = false;
      });
    }
  }

  Future<void> fetchVariations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/product_variations/${widget.product['id']}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            variations = data['variations'];
            selectedVariation = variations.isNotEmpty ? variations[0] : null;
          });
        } else {
          setState(() => errorMessage = 'No variations available.');
        }
      } else {
        setState(() => errorMessage = 'Failed to fetch variations (status: ${response.statusCode})');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      setState(() => isLoadingVariations = false);
    }
  }

  Future<void> fetchReviews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/product_reviews/${widget.product['id']}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            reviews = data['reviews'];
          });
        }
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      setState(() => isLoadingReviews = false);
    }
  }

  Future<void> addToCart() async {
    if (selectedVariation == null) return;

    final cartItem = {
      'user_id': widget.userId,
      'product_id': widget.product['id'],
      'quantity': quantity,
      'size': selectedVariation!['size'],
      'color': selectedVariation!['color'],
      'price': selectedVariation!['price'] ?? widget.product['price'],
      'image_path': selectedVariation!['image_path'] ?? widget.product['image'],
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/add_to_cart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cartItem),
      );

      final data = json.decode(response.body);
      final isSuccess = response.statusCode == 200 && data['status'] == 'success';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess
                ? 'Added to cart: ${_formatVariationName(selectedVariation!)}'
                : 'Failed: ${data['message'] ?? 'Unknown error'}',
          ),
          backgroundColor: isSuccess ? Colors.black : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void buyNow() {
    if (selectedVariation == null) return;

    final price = double.tryParse(selectedVariation!['price'].toString()) ?? 0.0;
    final total = price * quantity;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          userId: widget.userId,
          product: widget.product,
          variation: selectedVariation!,
          quantity: quantity,
          totalAmount: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getProductImageUrl();
    final displayPrice = _formatPrice(selectedVariation?['price'] ?? widget.product['price']);
    final maxStock = selectedVariation?['quantity'] ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(imageUrl),
                _buildProductTitle(),
                const SizedBox(height: 8),
                _buildProductPrice(displayPrice),
                _buildStockInfo(),
                const SizedBox(height: 16),
                _buildDescriptionSection(),
                const SizedBox(height: 24),
                _buildVariationsSection(),
                const SizedBox(height: 24),
                _buildQuantitySelector(maxStock),
                const SizedBox(height: 24),
                _buildAddToCartButton(),
                const SizedBox(height: 24),
                _buildReviewsSection(),
                const SizedBox(height: 24),
                _buildCommentSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(String imageUrl) => Hero(
        tag: widget.product['id'].toString(),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 300,
            color: Colors.grey,
            child: const Icon(Icons.broken_image, size: 100, color: Colors.white),
          ),
        ),
      );

  Widget _buildProductTitle() => Text(
        widget.product['name'] ?? 'No Name',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      );

  Widget _buildProductPrice(String price) => Text(
        '₱$price',
        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
      );

  Widget _buildStockInfo() {
    final stock = selectedVariation?['quantity'];
    return stock != null
        ? Text('Stock: $stock', style: const TextStyle(color: Colors.white70))
        : const SizedBox.shrink();
  }

  Widget _buildDescriptionSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            widget.product['description'] ?? 'No description available.',
            style: const TextStyle(fontSize: 16, color: Colors.white60, height: 1.5),
          ),
        ],
      );

  Widget _buildVariationsSection() {
    if (isLoadingVariations) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    } else if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.redAccent)));
    } else if (variations.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Variations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map>(
                value: selectedVariation,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: Colors.grey[900],
                items: variations.map<DropdownMenuItem<Map>>((variation) {
                  return DropdownMenuItem<Map>(
                    value: variation,
                    child: Text(_formatVariationName(variation), style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedVariation = value;
                    quantity = 1;
                  });
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return const Text('No variations available.', style: TextStyle(color: Colors.white54));
    }
  }

  Widget _buildQuantitySelector(int maxStock) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$quantity', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: quantity < maxStock ? () => setState(() => quantity++) : null,
              ),
            ],
          ),
        ],
      );

  Widget _buildAddToCartButton() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: selectedVariation == null ? null : addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Add to Cart', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: selectedVariation == null ? null : buyNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      );

  Widget _buildReviewsSection() {
    if (isLoadingReviews) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (reviews.isEmpty) {
      return const Text('No reviews yet.', style: TextStyle(color: Colors.white54));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        ...reviews.map((review) {
          return Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⭐ ${review['rating']}', style: const TextStyle(color: Colors.orange, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(review['review_text'] ?? '', style: const TextStyle(color: Colors.white)),
                  if (review['media_url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: review['media_type'] == 'image'
                          ? Image.network('$baseUrl/${review['media_url']}', height: 100)
                          : const Text('Video review', style: TextStyle(color: Colors.white70)),
                    ),
                  const SizedBox(height: 4),
                  Text(review['created_at'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Leave a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Rating:', style: TextStyle(color: Colors.white70)),
            const SizedBox(width: 8),
            DropdownButton<double>(
              value: selectedRating,
              dropdownColor: Colors.grey[900],
              items: [5, 4, 3, 2, 1].map((e) => DropdownMenuItem(value: e.toDouble(), child: Text('$e ★', style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedRating = val);
              },
            ),
          ],
        ),
        TextField(
          controller: commentController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Write your review...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submission not implemented.')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Submit Review'),
        ),
      ],
    );
  }

  String _getProductImageUrl() {
    final path = (selectedVariation?['image_path'] ?? widget.product['image'])?.toString() ?? '';
    final cleanPath = path.replaceAll('\\', '/');
    return '$baseUrl/static/uploads/${cleanPath.split('/').last}';
  }

  String _formatVariationName(Map variation) {
    final size = variation['size'] ?? '';
    final color = variation['color'] ?? '';
    if (size.isNotEmpty && color.isNotEmpty) return 'Size: $size | Color: $color';
    if (size.isNotEmpty) return 'Size: $size';
    if (color.isNotEmpty) return 'Color: $color';
    return 'Default';
  }

  String _formatPrice(dynamic price) {
    try {
      return double.parse(price.toString()).toStringAsFixed(2);
    } catch (_) {
      return '0.00';
    }
  }
}
