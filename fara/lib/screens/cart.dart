import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'checkout.dart';

class CartPage extends StatefulWidget {
  final int userId;

  const CartPage({Key? key, required this.userId}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final String baseUrl = 'http://192.168.255.182:5001';
  List<dynamic> cartItems = [];
  Set<int> selectedCartIds = {};
  bool isLoading = true;
  bool isUpdating = false;
  String errorMessage = '';
  double totalAmount = 0.0;
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      selectedCartIds.clear();
      selectAll = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_cart_items/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            cartItems = List.from(data['cart_items']);
            totalAmount = _calculateTotalAmount();
          });
        } else {
          setState(() => errorMessage = data['message'] ?? 'Cart is empty.');
        }
      } else {
        setState(() => errorMessage = 'Failed to fetch cart items. HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  double _calculateTotalAmount() {
    return cartItems.fold(0.0, (sum, item) {
      if (selectedCartIds.contains(item['cart_id'])) {
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        final qty = int.tryParse(item['cart_quantity'].toString()) ?? 1;
        return sum + (price * qty);
      }
      return sum;
    });
  }

  Future<void> _removeItemFromCart(int cartId) async {
    setState(() => isUpdating = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/remove_from_cart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cart_id': cartId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            cartItems.removeWhere((item) => item['cart_id'] == cartId);
            selectedCartIds.remove(cartId);
            totalAmount = _calculateTotalAmount();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Future<void> _updateItemQuantity(int cartId, int quantity) async {
    setState(() => isUpdating = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/update_cart_item'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cart_id': cartId, 'quantity': quantity}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          await _fetchCartItems();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Widget _buildSelectAllCheckbox() {
    return CheckboxListTile(
      title: const Text('Select All'),
      value: selectAll,
      onChanged: (value) {
        setState(() {
          selectAll = value ?? false;
          if (selectAll) {
            selectedCartIds = cartItems.map<int>((item) => item['cart_id']).toSet();
          } else {
            selectedCartIds.clear();
          }
          totalAmount = _calculateTotalAmount();
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final cartId = item['cart_id'];
    final cartQuantity = item['cart_quantity'] ?? 1;
    final availableQuantity = item['variation_quantity'] ?? 0;
    final imagePath = item['image_path'] != null ? '$baseUrl/${item['image_path']}' : null;
    final price = double.tryParse(item['price'].toString()) ?? 0.0;
    final totalPrice = price * cartQuantity;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selectedCartIds.contains(cartId),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedCartIds.add(cartId);
                  } else {
                    selectedCartIds.remove(cartId);
                  }
                  totalAmount = _calculateTotalAmount();
                  selectAll = selectedCartIds.length == cartItems.length;
                });
              },
            ),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imagePath != null
                      ? Image.network(
                          imagePath,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 70),
                        )
                      : const Icon(Icons.image, size: 70),
                ),
                const SizedBox(height: 4),
                Text('Available: $availableQuantity', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['product_name'] ?? 'Item',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text('₱${price.toStringAsFixed(2)} x $cartQuantity = ₱${totalPrice.toStringAsFixed(2)}'),
                  Text('Size: ${item['size'] ?? '-'}'),
                  Text('Color: ${item['color'] ?? '-'}'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Qty:'),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: isUpdating || cartQuantity <= 1
                            ? null
                            : () => _updateItemQuantity(cartId, cartQuantity - 1),
                      ),
                      Text('$cartQuantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (isUpdating) return;
                          if (cartQuantity >= availableQuantity) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Max stock reached')),
                            );
                            return;
                          }
                          _updateItemQuantity(cartId, cartQuantity + 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isUpdating ? null : () => _removeItemFromCart(cartId),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = cartItems.where((item) => selectedCartIds.contains(item['cart_id'])).toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(221, 255, 255, 255),
        elevation: 0,
        centerTitle: true,
        title: const Text('Your Cart', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCartItems,
              child: cartItems.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Text(
                            errorMessage.isNotEmpty ? errorMessage : 'Your cart is empty',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ListView(
                          children: [
                            _buildSelectAllCheckbox(),
                            ...cartItems.map<Widget>((item) => _buildCartItem(item)).toList(),
                          ],
                        ),
                        if (isUpdating)
                          const Positioned.fill(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
            ),
      bottomNavigationBar: selectedCartIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${selectedItems.length}):',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '₱${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final Map<String, int> variationQuantityMap = {};
                          for (var item in selectedItems) {
                            final key = '${item['product_id']}_${item['size']}_${item['color']}';
                            final qty = int.tryParse(item['cart_quantity'].toString()) ?? 1;
                            variationQuantityMap[key] = (variationQuantityMap[key] ?? 0) + qty;
                          }

                          final List<String> exceededItems = [];
                          for (var entry in variationQuantityMap.entries) {
                            final parts = entry.key.split('_');
                            final productId = parts[0];
                            final size = parts[1];
                            final color = parts[2];
                            final item = selectedItems.firstWhere(
                              (e) => e['product_id'].toString() == productId && e['size'] == size && e['color'] == color,
                            );
                            final available = int.tryParse(item['variation_quantity'].toString()) ?? 0;
                            if (entry.value > available) {
                              exceededItems.add('${item['product_name']} (Size: $size, Color: $color)');
                            }
                          }

                          if (exceededItems.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stock limit exceeded for:\n${exceededItems.join(', ')}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutPage(
                                cartItems: selectedItems,
                                userId: widget.userId,
                                totalAmount: totalAmount,
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text('Check out', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
