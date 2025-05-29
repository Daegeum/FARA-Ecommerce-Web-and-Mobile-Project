import 'package:flutter/material.dart';

class ShippingDetailsPage extends StatelessWidget {
  final Map details;

  const ShippingDetailsPage({super.key, required this.details});

  String buildAddress(Map o) {
    final parts = [
      o['street'],
      o['barangay'],
      o['city'],
      o['province'],
      o['region']
    ];

    return parts
        .map((x) => x?.toString().trim())
        .where((x) => x != null && x.isNotEmpty)
        .join(', ');
  }

  String getFullName(Map o) {
    final first = o['first_name'] ?? '';
    final middle = o['middle_name'] ?? '';
    final last = o['last_name'] ?? '';
    return '$first $middle $last'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final recipient = getFullName(details);
    final hasRecipient = recipient.isNotEmpty;
    final contact = (details['contact_number']?.toString().trim().isNotEmpty ?? false)
        ? details['contact_number']
        : 'N/A';

    final address = buildAddress(details);
    final hasAddress = address.trim().isNotEmpty;

    final price = double.tryParse(details['price'].toString()) ?? 0.0;
    final shippingFee = 59.0; // Forced to always be 59 pesos
    final total = price + shippingFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Recipient Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Recipient Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(hasRecipient ? recipient : 'No recipient info', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Contact: $contact'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Shipping Address
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Shipping Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      hasAddress ? address : 'No shipping address found',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Product Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Product Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(details['product_name'] ?? 'Product'),
                    Text('Size: ${details['size'] ?? '-'}'),
                    Text('Color: ${details['color'] ?? '-'}'),
                    Text('Qty: ${details['quantity'] ?? '1'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Payment Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Price: ₱${price.toStringAsFixed(2)}"),
                    Text("Shipping Fee: ₱${shippingFee.toStringAsFixed(2)}"),
                    const Divider(height: 20),
                    Text("Total: ₱${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
