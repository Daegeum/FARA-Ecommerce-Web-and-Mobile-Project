import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckoutPage extends StatefulWidget {
  final List? cartItems;       // for cart-based checkout
  final Map? product;          // for buy now
  final Map? variation;        // for buy now
  final int quantity;          // for buy now
  final int userId;
  final double totalAmount;

  const CheckoutPage({
    Key? key,
    this.cartItems,
    this.product,
    this.variation,
    this.quantity = 1,
    required this.userId,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<String, dynamic>? address;
  bool isLoading = true;
  bool isPlacingOrder = false;

  bool get isBuyNow => widget.product != null && widget.variation != null;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    final url = Uri.parse('http://192.168.255.182:5001/api/get_shipping_address/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => address = data['address']);
        }
      }
    } catch (e) {
      debugPrint('Address fetch error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _placeOrder() async {
    if (isPlacingOrder) return;
    setState(() => isPlacingOrder = true);

    final Uri url = Uri.parse(isBuyNow
        ? 'http://192.168.255.182:5001/api/place_single_order'
        : 'http://192.168.255.182:5001/api/place_order');

    final body = isBuyNow
        ? {
            'user_id': widget.userId,
            'product_id': widget.product!['id'],
            'variation_id': widget.variation!['id'],
            'quantity': widget.quantity,
            'payment_method': 'cod',
          }
        : {
            'user_id': widget.userId,
            'cart_ids': widget.cartItems!.map((item) => item['cart_id']).toList(),
            'payment_method': 'cod',
          };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final isJson = response.headers['content-type']?.contains('application/json') ?? false;
      if (!isJson) throw Exception("Expected JSON but got HTML");

      final data = json.decode(response.body);
      setState(() => isPlacingOrder = false);

      if (data['status'] == 'success') {
        final trackingList = data['trackings'] ?? [];

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Order Placed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your order was placed successfully!'),
                const SizedBox(height: 12),
                if (trackingList.isNotEmpty)
                  ...trackingList.map<Widget>((item) {
                    return Text(
                      'Product ID ${item['product_id']} → ${item['tracking_number']}',
                      style: const TextStyle(fontSize: 14),
                    );
                  }).toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to place order')),
        );
      }
    } catch (e) {
      setState(() => isPlacingOrder = false);
      debugPrint('Order error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error. Please try again.')),
      );
    }
  }

  Widget _buildAddressSection() {
    if (address == null) {
      return const Text(
        'No address found.',
        style: TextStyle(color: Colors.redAccent, fontSize: 14),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Name: ${address!['first_name']} ${address!['last_name']}'),
          Text('Contact: ${address!['contact_number']}'),
          Text('Street: ${address!['street']}'),
          Text('Barangay: ${address!['barangay']}'),
          Text('City: ${address!['city']}'),
          Text('Province: ${address!['province']}'),
          Text('Region: ${address!['region']}'),
        ],
      ),
    );
  }

  Widget _buildBuyNowItem() {
    final imagePath = widget.variation!['image_path'] ?? widget.product!['image'];
    final price = double.tryParse(widget.variation!['price'].toString()) ?? 0.0;

    return Card(
      child: ListTile(
        leading: Image.network(
          'http://192.168.255.182:5001/$imagePath',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        ),
        title: Text(widget.product!['name']),
        subtitle: Text(
          'Qty: ${widget.quantity} | Size: ${widget.variation!['size']} | Color: ${widget.variation!['color']}',
        ),
        trailing: Text('₱${(price * widget.quantity).toStringAsFixed(2)}'),
      ),
    );
  }

  Widget _buildCartItems() {
    return Column(
      children: widget.cartItems!.map((item) {
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        final qty = int.tryParse(item['cart_quantity'].toString()) ?? 1;
        return Card(
          child: ListTile(
            leading: Image.network(
              'http://192.168.255.182:5001/${item['image_path']}',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
            title: Text(item['product_name'] ?? ''),
            subtitle: Text('Qty: $qty | Size: ${item['size']} | Color: ${item['color']}'),
            trailing: Text('₱${(price * qty).toStringAsFixed(2)}'),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildAddressSection(),
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                  const ListTile(
                    leading: Radio(value: true, groupValue: true, onChanged: null),
                    title: Text('Cash on Delivery'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Selected Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  isBuyNow ? _buildBuyNowItem() : _buildCartItems(),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total Amount: ₱${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isPlacingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Place Order', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
