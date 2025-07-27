import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spazigo/models/container.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/widgets/custom_text_field.dart';

class BookContainerFormScreen extends StatefulWidget {
  final ContainerModel container;

  const BookContainerFormScreen({super.key, required this.container});

  @override
  State<BookContainerFormScreen> createState() => _BookContainerFormScreenState();
}

class _BookContainerFormScreenState extends State<BookContainerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  File? _productImage;
  String? _imageFileName;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _productImage = File(pickedFile.path);
        _imageFileName = pickedFile.name;
      });
    }
  }

  void _requestBooking() async {
    if (_formKey.currentState!.validate() && _productImage != null) {
      final requestedWeight = double.tryParse(_weightController.text);

      if (requestedWeight == null || requestedWeight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid positive weight.')),
        );
        return;
      }
      if (requestedWeight > widget.container.spaceLeft) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requested weight exceeds available space.')),
        );
        return;
      }

      try {
        List<int> imageBytes = await _productImage!.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        final bookingData = {
          'container_id': widget.container.id,
          'product_name': _productNameController.text,
          'category': _categoryController.text,
          'weight': requestedWeight,
          'image_url': base64Image, // Sending base64, backend should store as URL
        };

        await ApiService.requestBooking(bookingData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent successfully!')),
        );
        context.pop(); // Go back after booking
        context.go('/msme-bookings'); // Navigate to bookings page
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send booking request: $e')),
        );
      }
    } else if (_productImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Container'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Container Details:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('From: ${widget.container.origin} To: ${widget.container.destination}'),
                Text('Space Left: ${widget.container.spaceLeft} units'),
                Text('Price per Unit: ₹${widget.container.price.toStringAsFixed(2)}'),
                const SizedBox(height: 20),
                Text(
                  'Your Product Details:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _productNameController,
                  labelText: 'Product Name',
                  validator: (value) => value!.isEmpty ? 'Enter product name' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _categoryController,
                  labelText: 'Product Category (optional)',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _weightController,
                  labelText: 'Weight (units)',
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0
                      ? 'Enter valid positive weight'
                      : null,
                ),
                const SizedBox(height: 24),
                _productImage == null
                    ? ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Upload Product Image'),
                )
                    : Column(
                  children: [
                    Text('Image Selected: ${_imageFileName!}'),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Change Image'),
                    ),
                    Image.file(_productImage!, height: 150, fit: BoxFit.cover),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestBooking,
                    child: const Text('Request Booking'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _categoryController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}