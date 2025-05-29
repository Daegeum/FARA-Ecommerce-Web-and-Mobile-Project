import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class DeliveryProofPage extends StatefulWidget {
  final Map order;
  final int riderId;

  const DeliveryProofPage({super.key, required this.order, required this.riderId});

  @override
  State<DeliveryProofPage> createState() => _DeliveryProofPageState();
}

class _DeliveryProofPageState extends State<DeliveryProofPage> {
  File? imageFile;
  bool uploading = false;
  final picker = ImagePicker();
  final String baseUrl = 'http://192.168.255.182:5001';

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<void> submitProof() async {
    if (imageFile == null) return;

    setState(() => uploading = true);

    final uri = Uri.parse('$baseUrl/api/mark_delivered');
    final request = http.MultipartRequest('POST', uri)
      ..fields['order_item_id'] = widget.order['order_item_id'].toString()
      ..files.add(await http.MultipartFile.fromPath(
        'proof_image',
        imageFile!.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    final response = await request.send();

    setState(() => uploading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery marked as completed')),
      );
      Navigator.pop(context, true); // Go back and refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload proof')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Proof of Delivery")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.order['product_name'] ?? 'Product',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            imageFile != null
                ? Image.file(imageFile!, height: 200)
                : const Text("No image selected"),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Proof Photo"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploading ? null : submitProof,
              child: uploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Proof"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
