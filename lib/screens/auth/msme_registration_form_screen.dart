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
  State<MsmeRegistrationFormScreen> createState() =>
      _MsmeRegistrationFormScreenState();
}

class _MsmeRegistrationFormScreenState
    extends State<MsmeRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _selectedDocument;
  String? _documentFileName;
  String? _documentMimeType;

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedDocument = File(pickedFile.path);
        _documentFileName = pickedFile.name;
        _documentMimeType = pickedFile.mimeType ?? 'application/octet-stream';
      });
    }
  }

  void _registerMSME() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDocument == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a legal document.')),
        );
        return;
      }

      final authProvider = Provider.of(context, listen: false);

      try {
        final imageBytes = await _selectedDocument!.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        final success = await authProvider.register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: 'msme',
          company: _businessNameController.text.trim(),
          phone: _phoneController.text.trim(),
          base64Document: base64Image,
          documentFileName: _documentFileName!,
          documentMimeType: _documentMimeType!,
        );

        if (mounted && success) {
          context.go('/await-approval');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(authProvider.errorMessage ??
                    'Registration failed. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Failed to process document. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as MSME'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _businessNameController,
                labelText: 'Business Name',
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter business name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 24),
              _buildDocumentPicker(),
              const SizedBox(height: 30),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _registerMSME,
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Account'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPicker() {
    if (_selectedDocument == null) {
      return OutlinedButton.icon(
        onPressed: _pickDocument,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Business Document'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: Theme.of(context).primaryColor),
        ),
      );
    } else {
      return Column(
        children: [
          Text('Document: ${_documentFileName!}'),
          const SizedBox(height: 8),
          Image.file(_selectedDocument!, height: 100, width: 100, fit: BoxFit.cover),
          TextButton(
            onPressed: _pickDocument,
            child: const Text('Change Document'),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}