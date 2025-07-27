import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/user_provider.dart';
import 'package:spazigo/services/api_service.dart'; // Assuming a method for updating profile

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  // Add other controllers for editable fields (e.g., GSTIN, address etc.)

  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _companyController.text = user.company ?? '';
      _phoneController.text = user.phone ?? '';
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      _errorMessage = null; // Clear error message when toggling edit mode
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Dummy call for now, as ApiService doesn't have a direct user profile update endpoint
      // You would implement a PATCH /api/users/:id endpoint on backend for this
      // await ApiService.updateUserProfile(
      //   company: _companyController.text,
      //   phone: _phoneController.text,
      // );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully (dummy)!')),
      );

      // In a real scenario, you'd refresh the user in AuthProvider/UserProvider
      // Provider.of<UserProvider>(context, listen: false).updateProfile(
      //   company: _companyController.text,
      //   phone: _phoneController.text,
      // );

      setState(() {
        _isEditing = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User data not available.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isLoading ? null : (_isEditing ? _saveProfile : _toggleEdit),
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _isLoading ? null : _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child: Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileField('Email', user.email, editable: false),
            _buildProfileField('Role', user.role.toUpperCase(), editable: false),
            _buildProfileField('Status', user.status.toUpperCase(), editable: false),
            if (user.rejectionReason != null && user.rejectionReason!.isNotEmpty)
              _buildProfileField('Rejection Reason', user.rejectionReason!, editable: false, textColor: Colors.red),
            _buildProfileField('Company Name', user.company, controller: _companyController, editable: _isEditing),
            _buildProfileField('Phone', user.phone, controller: _phoneController, editable: _isEditing, keyboardType: TextInputType.phone),
            // Add more fields here as per your User model and requirements
            // e.g., GSTIN, Address, Fleet Details, etc.
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
      String label,
      String? value, {
        TextEditingController? controller,
        bool editable = false,
        TextInputType keyboardType = TextInputType.text,
        Color? textColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          if (editable)
            TextField(
              controller: controller,
              enabled: editable,
              keyboardType: keyboardType,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
            )
          else
            Text(
              value ?? 'N/A',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
