import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/auth_provider.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/widgets/app_drawer.dart';
import 'package:spazigo/models/container.dart';
import 'package:spazigo/widgets/custom_text_field.dart'; // Import ContainerModel

class LspDashboardScreen extends StatefulWidget {
  const LspDashboardScreen({super.key});

  @override
  State<LspDashboardScreen> createState() => _LspDashboardScreenState();
}

class _LspDashboardScreenState extends State<LspDashboardScreen> {
  int _totalActiveContainers = 0;
  int _totalBookings = 0; // This will count accepted bookings
  List<ContainerModel> _activeContainers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final containers = await ApiService.getLSPContainers();
      final bookings = await ApiService.getLSPBookingRequests(); // Fetch all booking requests

      setState(() {
        _activeContainers = containers.where((c) => c.status == 'active').toList();
        _totalActiveContainers = _activeContainers.length;
        _totalBookings = bookings.where((b) => b.status == 'accepted').length; // Count accepted bookings
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null || user.role != 'lsp' || user.status != 'verified') {
      // Should be handled by router, but as a fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LSP Dashboard'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user.company ?? 'LSP'}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDashboardCards(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Containers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.go('/lsp-dashboard/containers');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _activeContainers.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No active containers registered yet.'),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeContainers.length,
                itemBuilder: (context, index) {
                  final container = _activeContainers[index];
                  return ContainerCard(container: container, isLSPView: true, onUpdate: _fetchDashboardData);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/lsp-dashboard/add-container');
        },
        label: const Text('Add New Container'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashboardCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Containers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalActiveContainers',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Bookings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalBookings',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable Container Card Widget
class ContainerCard extends StatelessWidget {
  final ContainerModel container;
  final bool isLSPView; // true for LSP's own containers, false for MSME available list
  final VoidCallback? onUpdate; // Callback to refresh data if something changes

  const ContainerCard({
    super.key,
    required this.container,
    this.isLSPView = false,
    this.onUpdate,
  });

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Container ID: ${container.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: container.status == 'active'
                        ? Colors.green.withOpacity(0.2)
                        : (container.status == 'expired' ? Colors.red.withOpacity(0.2) : Colors.amber.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    container.status.toUpperCase(),
                    style: TextStyle(
                      color: container.status == 'active'
                          ? Colors.green
                          : (container.status == 'expired' ? Colors.red : Colors.amber),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text('From: ${container.origin}', style: Theme.of(context).textTheme.bodyLarge),
            Text('To: ${container.destination}', style: Theme.of(context).textTheme.bodyLarge),
            if (container.routes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Routes: ${container.routes.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
            Text('Modal: ${container.modal}', style: Theme.of(context).textTheme.bodyMedium),
            Text('Price: ₹${container.price.toStringAsFixed(2)} /unit', style: Theme.of(context).textTheme.bodyMedium),
            Text('Total Space: ${container.spaceTotal} units', style: Theme.of(context).textTheme.bodyMedium),
            Text('Space Left: ${container.spaceLeft} units', style: Theme.of(context).textTheme.bodyMedium),
            Text('Departure: ${_formatDateTime(container.departureTime)}', style: Theme.of(context).textTheme.bodyMedium),
            Text('Booking Deadline: ${_formatDateTime(container.bookingDeadline)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red)),
            const SizedBox(height: 16),
            if (!isLSPView) // For MSME view, show Book button and Chat
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: container.status != 'active' || container.spaceLeft <= 0
                        ? null // Disable if not active or full
                        : () {
                      context.push('/msme-home/book-container-form', extra: container);
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Book Container'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      // Navigate to chat with LSP for this container
                      context.push('/chat/${container.lspId}?containerId=${container.id}', extra: {
                        'other_user_company': container.lspCompany ?? 'LSP', // Pass LSP company name
                        'container_id': container.id,
                      });
                    },
                  ),
                ],
              )
            else // For LSP view, show options like Edit/View Bookings
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // This is a simplified action. For real edit, navigate to edit form.
                  TextButton.icon(
                    onPressed: () {
                      _showUpdateSpaceDialog(context, container);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Space'),
                  ),
                  // More actions for LSP like viewing bookings for this specific container
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to a filtered booking requests screen for this container
                      context.go('/lsp-dashboard/booking-requests', extra: container.id);
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Bookings'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showUpdateSpaceDialog(BuildContext context, ContainerModel container) {
    final TextEditingController _spaceController = TextEditingController(text: container.spaceLeft.toString());
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Update Space Left'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Space Left: ${container.spaceLeft} units'),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _spaceController,
                labelText: 'New Space Left',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter new space';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  if (double.parse(value) < 0 || double.parse(value) > container.spaceTotal) {
                    return 'Space must be between 0 and ${container.spaceTotal}';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                final newSpace = double.tryParse(_spaceController.text);
                if (newSpace != null) {
                  try {
                    await ApiService.updateContainerSpace(container.id, newSpace);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Space updated successfully!')),
                    );
                    onUpdate?.call(); // Refresh data on parent widget
                    Navigator.of(dialogContext).pop();
                  } on ApiException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating space: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
