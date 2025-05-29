import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class TrackOrderPage extends StatefulWidget {
  final int orderItemId;

  const TrackOrderPage({Key? key, required this.orderItemId}) : super(key: key);

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  final String baseUrl = 'http://192.168.255.182:5001';
  List<dynamic> trackingSteps = [];
  bool loading = true;

  File? selectedMedia;
  String? mediaType; // 'image' or 'video'

  @override
  void initState() {
    super.initState();
    fetchTracking();
  }

  Future<void> fetchTracking() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/order_tracking/${widget.orderItemId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            trackingSteps = data['tracking'];
          });
        }
      }
    } catch (e) {
      debugPrint('Tracking error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery); // change to pickVideo for videos
    if (file == null) return;

    final ext = path.extension(file.path).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png'].contains(ext);
    final isVideo = ['.mp4', '.mov', '.avi'].contains(ext);

    if (!isImage && !isVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported file type')),
      );
      return;
    }

    setState(() {
      selectedMedia = File(file.path);
      mediaType = isImage ? 'image' : 'video';
    });
  }

  Future<void> _submitReview(double rating, String review) async {
    try {
      final uri = Uri.parse('$baseUrl/api/submit_review');
      final request = http.MultipartRequest('POST', uri)
        ..fields['order_item_id'] = widget.orderItemId.toString()
        ..fields['rating'] = rating.toInt().toString()
        ..fields['review'] = review;

      if (selectedMedia != null) {
        request.files.add(await http.MultipartFile.fromPath('media', selectedMedia!.path));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          selectedMedia = null;
          mediaType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while submitting review')),
      );
    }
  }

  void _showReviewDialog() {
    double rating = 3;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How would you rate the product?'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => rating = index + 1.0),
                    );
                  }),
                ),
                TextField(
                  controller: reviewController,
                  decoration: const InputDecoration(labelText: 'Write a review'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                if (selectedMedia != null)
                  Text("Selected ${mediaType == 'video' ? 'video' : 'image'}: ${path.basename(selectedMedia!.path)}"),
                TextButton.icon(
                  onPressed: _pickMedia,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach Photo/Video'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitReview(rating, reviewController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = trackingSteps.isNotEmpty &&
        (trackingSteps.first['status']?.toString().toLowerCase() == 'delivered');

    return Scaffold(
      appBar: AppBar(title: const Text('Track Package')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: trackingSteps.isEmpty
                      ? const Center(child: Text('No tracking updates found.'))
                      : ListView.builder(
                          itemCount: trackingSteps.length,
                          itemBuilder: (context, index) {
                            final step = trackingSteps[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Icon(
                                        index == 0 ? Icons.check_circle : Icons.radio_button_checked,
                                        color: index == 0 ? Colors.green : Colors.grey,
                                      ),
                                      if (index != trackingSteps.length - 1)
                                        Container(height: 50, width: 2, color: Colors.grey),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step['status'],
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        if (step['timestamp'] != null)
                                          Text(step['timestamp']),
                                        if (step['changed_by'] != null)
                                          Text("Updated by: ${step['changed_by']}"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (isDelivered)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showReviewDialog,
                      icon: const Icon(Icons.star),
                      label: const Text('Rate Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
