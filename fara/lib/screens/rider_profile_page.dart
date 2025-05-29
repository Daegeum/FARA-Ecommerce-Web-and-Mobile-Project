import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiderProfilePage extends StatefulWidget {
  final int riderId;
  const RiderProfilePage({super.key, required this.riderId});

  @override
  State<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  final String baseUrl = 'http://192.168.255.182:5001';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController barangayController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAddress();
  }

  Future<void> loadAddress() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/get_rider_address?rider_id=${widget.riderId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        streetController.text = address['street'] ?? '';
        barangayController.text = address['barangay'] ?? '';
        cityController.text = address['city'] ?? '';
        provinceController.text = address['province'] ?? '';
        regionController.text = address['region'] ?? '';
      }
    } catch (e) {
      debugPrint('Failed to load rider address: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      'rider_id': widget.riderId,
      'street': streetController.text.trim(),
      'barangay': barangayController.text.trim(),
      'city': cityController.text.trim(),
      'province': provinceController.text.trim(),
      'region': regionController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/save_rider_address'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving address: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Address')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    buildField('Street', streetController),
                    buildField('Barangay', barangayController),
                    buildField('City', cityController),
                    buildField('Province', provinceController),
                    buildField('Region', regionController),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: saveAddress,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Address'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}
