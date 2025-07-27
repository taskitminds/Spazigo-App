// Filename: lib/screens/auth/msme_registration_form_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/auth_provider.dart';
import 'package:spazigo/widgets/custom_text_field.dart';

class MsmeRegistrationFormScreen extends StatefulWidget {
  const MsmeRegistrationFormScreen({super.key});

  @override
  State<MsmeRegistrationFormScreen> createState() => _MsmeRegistrationFormScreenState();
}

class _MsmeRegistrationFormScreenState extends State<MsmeRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _productTypeController = TextEditingController();
  final TextEditingController _warehouseAddressController = TextEditingController();

  File? _selectedDocument;
  String? _documentFileName;
  String? _documentMimeType; // Added to store actual MIME type

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedDocument = File(pickedFile.path);
        _documentFileName = pickedFile.name;
        _documentMimeType = pickedFile.mimeType; // Use the actual MIME type from XFile
      });
    }
  }

  void _registerMSME() async {
    if (_formKey.currentState!.validate() && _selectedDocument != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        List<int> imageBytes = await _selectedDocument!.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        await authProvider.register(
          email: _emailController.text,
          password: _passwordController.text,
          role: 'msme',
          company: _businessNameController.text, // Using business name as company
          phone: _phoneController.text,
          base64Document: base64Image,
          documentFileName: _documentFileName!,
          documentMimeType: _documentMimeType ?? 'application/octet-stream', // Use the stored MIME type, with fallback
        );

        if (authProvider.currentUser != null) {
          context.go('/await-approval');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage ?? 'Registration failed.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read document: $e')),
        );
      }
    } else if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a legal document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as MSME'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: true,
                  validator: (value) => value!.length < 6 ? 'Password too short' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _businessNameController,
                  labelText: 'Business Name',
                  validator: (value) => value!.isEmpty ? 'Enter business name' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _gstinController,
                  labelText: 'GSTIN',
                  validator: (value) => value!.isEmpty ? 'Enter GSTIN' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _productTypeController,
                  labelText: 'Product Type (e.g., Electronics, Textiles)',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _warehouseAddressController,
                  labelText: 'Warehouse Address',
                  //maxLines: 3,
                ),
                const SizedBox(height: 24),
                _selectedDocument == null
                    ? ElevatedButton.icon(
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Legal Document'),
                )
                    : Column(
                  children: [
                    Text('Document Selected: ${_documentFileName!}'),
                    TextButton(
                      onPressed: _pickDocument,
                      child: const Text('Change Document'),
                    ),
                    if (_selectedDocument!.path.toLowerCase().endsWith('.jpg') ||
                        _selectedDocument!.path.toLowerCase().endsWith('.jpeg') ||
                        _selectedDocument!.path.toLowerCase().endsWith('.png'))
                      Image.file(_selectedDocument!, height: 100, width: 100),
                  ],
                ),
                const SizedBox(height: 30),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _registerMSME,
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Register MSME Account'),
                      ),
                    );
                  },
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
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _productTypeController.dispose();
    _warehouseAddressController.dispose();
    super.dispose();
  }
}