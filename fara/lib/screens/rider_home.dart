import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fara/main.dart';
import 'package:fara/screens/delivery_proof.dart';
import 'package:fara/screens/rsdetails.dart';
import 'package:fara/screens/rider_profile_page.dart';

class RiderHomePage extends StatefulWidget {
  final int riderId;
  const RiderHomePage({Key? key, required this.riderId}) : super(key: key);

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PickupListTab(riderId: widget.riderId),
      ForDeliveriesTab(riderId: widget.riderId),
      RiderProfilePage(riderId: widget.riderId),
    ];
  }

  void _logout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Courier Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Pick Up"),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: "Deliveries"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class PickupListTab extends StatefulWidget {
  final int riderId;
  const PickupListTab({super.key, required this.riderId});

  @override
  State<PickupListTab> createState() => _PickupListTabState();
}

class _PickupListTabState extends State<PickupListTab> {
  final String baseUrl = 'http://192.168.255.182:5001';
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rider_to_ship_orders?rider_id=${widget.riderId}'),
      );
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() => orders = data['orders']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> markAsPickedUp(int orderItemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/update_order_status'),
      body: {
        'order_item_id': orderItemId.toString(),
        'status': 'Out for Delivery',
        'rider_id': widget.riderId.toString(),
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked as Out for Delivery')),
      );
      fetchOrders();
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${data['message']}')),
      );
    }
  }

  void confirmRejection(int orderItemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              rejectOrder(orderItemId);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> rejectOrder(int orderItemId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reject_order_item'),
        body: {'order_item_id': orderItemId.toString()},
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected')),
        );
        fetchOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void goToDetails(int orderItemId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response = await http.get(
      Uri.parse('$baseUrl/api/order_item_details?order_item_id=$orderItemId'),
    );
    Navigator.pop(context);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShippingDetailsPage(details: result['data']),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (orders.isEmpty) return const Center(child: Text("No orders for pick-up."));

    return RefreshIndicator(
      onRefresh: fetchOrders,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return InkWell(
            onTap: () => goToDetails(order['order_item_id']),
            child: Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '$baseUrl/${order['product_image']}'.replaceAll('\\', '/'),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['product_name'] ?? 'No name', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${order['color']} - ${order['size']}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => markAsPickedUp(order['order_item_id']),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                                child: const Text("Picked Up"),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => confirmRejection(order['order_item_id']),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text("Reject"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ForDeliveriesTab extends StatefulWidget {
  final int riderId;
  const ForDeliveriesTab({super.key, required this.riderId});

  @override
  State<ForDeliveriesTab> createState() => _ForDeliveriesTabState();
}

class _ForDeliveriesTabState extends State<ForDeliveriesTab> {
  final String baseUrl = 'http://192.168.255.182:5001';
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/rider_out_for_delivery_orders?rider_id=${widget.riderId}'));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() => orders = data['orders']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void goToDetails(int orderItemId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response = await http.get(
      Uri.parse('$baseUrl/api/order_item_details?order_item_id=$orderItemId'),
    );
    Navigator.pop(context);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShippingDetailsPage(details: result['data']),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (orders.isEmpty) return const Center(child: Text("No orders out for delivery."));

    return RefreshIndicator(
      onRefresh: fetchOrders,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return InkWell(
            onTap: () => goToDetails(order['order_item_id']),
            child: Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '$baseUrl/${order['product_image']}'.replaceAll('\\', '/'),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                  ),
                ),
                title: Text(order['product_name'] ?? 'No name'),
                subtitle: Text('${order['color']} - ${order['size']}'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryProofPage(
                          order: order,
                          riderId: widget.riderId,
                        ),
                      ),
                    );
                    if (result == true) fetchOrders();
                  },
                  child: const Text("Delivered"),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
