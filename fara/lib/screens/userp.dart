import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'buyerh.dart';
import 'track_order_page.dart';
import 'package:fara/main.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final String baseUrl = 'http://192.168.255.182:5001';
  Map<String, dynamic> userData = {};
  List orders = [];
  bool isLoading = true;
  String? profileImageUrl;

  Map<String, List> groupedOrders = {
    'All': [],
    'Pending': [],
    'To ship': [],
    'To Receive': [],
    'Delivered': [],
  };

  final Map<String, List<String>> statusFilters = {
    'Pending': ['pending'],
    'To ship': ['preparing to ship', 'package pick-up'],
    'To Receive': ['intransit', 'out for delivery'],
    'Delivered': ['delivered'],
  };

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user_profile/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userData = data['user'];
          profileImageUrl = data['user']['photo_url'];
        });
        await fetchOrders();
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user_orders/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fetchedOrders = data['orders'];

        setState(() {
          orders = fetchedOrders;
          groupedOrders['All'] = fetchedOrders;

          for (var key in statusFilters.keys) {
            groupedOrders[key] = fetchedOrders
                .where((o) => statusFilters[key]!
                    .contains((o['order_status'] ?? '').toString().toLowerCase()))
                .toList();
          }
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Future<void> uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload_profile_picture'));
    request.fields['user_id'] = widget.userId.toString();
    request.files.add(await http.MultipartFile.fromPath('image', pickedFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      setState(() {
        profileImageUrl = data['picture_url'];
      });
    } else {
      print('Failed to upload image');
    }
  }

  String _buildFullName() {
    final first = userData['first_name'] ?? '';
    final middle = userData['middle_name'] ?? '';
    final last = userData['last_name'] ?? '';
    return '$first $middle $last'.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  ImageProvider<Object> _getProfileImage() {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      final filename = profileImageUrl!.split(RegExp(r'[\\/]+')).last;
      return NetworkImage('$baseUrl/static/profile_images/$filename');
    } else {
      return const AssetImage('assets/profile.jpg');
    }
  }

  Widget _buildOrderList(String status) {
    final list = groupedOrders[status] ?? [];
    if (list.isEmpty) return const Center(child: Text('No orders found.'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final order = list[index];
        final imageUrl = order['product_image'] != null
            ? '$baseUrl/${order['product_image']}'.replaceAll('\\', '/')
            : null;

        final price = double.tryParse(order['price'].toString())?.toStringAsFixed(2) ?? '0.00';

        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                )
              : const Icon(Icons.image_not_supported),
          title: Text(
            order['product_name'] ?? 'No product',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${order['color'] ?? ''} - ${order['size'] ?? ''} • ₱$price',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrackOrderPage(orderItemId: order['order_item_id']),
              ),
            );
          },
        );
      },
    );
  }

  void _logout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully'), duration: Duration(seconds: 2)),
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
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BuyerHomePage(userId: widget.userId)),
              );
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.logout, color: Colors.black), onPressed: () => _logout(context)),
            const SizedBox(width: 12),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _getProfileImage(),
                          backgroundColor: Colors.grey[300],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: uploadProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_buildFullName(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Divider(),
                    const TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.black,
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'All'),
                        Tab(text: 'Pending'),
                        Tab(text: 'To ship'),
                        Tab(text: 'To Receive'),
                        Tab(text: 'Delivered'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOrderList('All'),
                          _buildOrderList('Pending'),
                          _buildOrderList('To ship'),
                          _buildOrderList('To Receive'),
                          _buildOrderList('Delivered'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
