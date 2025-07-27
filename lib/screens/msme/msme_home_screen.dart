import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/models/container.dart';
import 'package:spazigo/providers/auth_provider.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/widgets/app_drawer.dart';
import 'package:spazigo/screens/lsp/lsp_dashboard_screen.dart'; // Re-use ContainerCard

class MsmeHomeScreen extends StatefulWidget {
  const MsmeHomeScreen({super.key});

  @override
  State<MsmeHomeScreen> createState() => _MsmeHomeScreenState();
}

class _MsmeHomeScreenState extends State<MsmeHomeScreen> {
  List<ContainerModel> _availableContainers = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter controllers
  final TextEditingController _originFilterController = TextEditingController();
  final TextEditingController _destinationFilterController = TextEditingController();
  final TextEditingController _minPriceFilterController = TextEditingController();
  final TextEditingController _maxPriceFilterController = TextEditingController();
  String? _selectedModalFilter;
  final List<String> _transportModes = ['road', 'rail', 'sea', 'air'];

  @override
  void initState() {
    super.initState();
    _fetchAvailableContainers();
  }

  Future<void> _fetchAvailableContainers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedContainers = await ApiService.getAvailableContainers(
        origin: _originFilterController.text.isNotEmpty ? _originFilterController.text : null,
        destination: _destinationFilterController.text.isNotEmpty ? _destinationFilterController.text : null,
        minPrice: double.tryParse(_minPriceFilterController.text),
        maxPrice: double.tryParse(_maxPriceFilterController.text),
        modal: _selectedModalFilter,
      );
      setState(() {
        _availableContainers = fetchedContainers;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load available containers: $e';
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

    if (user == null || user.role != 'msme' || user.status != 'verified') {
      // Should be handled by router, but as a fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spazigo Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
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
                onPressed: _fetchAvailableContainers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchAvailableContainers,
        child: _availableContainers.isEmpty
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  'No Containers Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or check back later.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _availableContainers.length,
          itemBuilder: (context, index) {
            final container = _availableContainers[index];
            return ContainerCard(container: container); // Re-use the card
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Containers',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _originFilterController,
                decoration: const InputDecoration(
                  labelText: 'Origin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destinationFilterController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceFilterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceFilterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedModalFilter,
                decoration: const InputDecoration(
                  labelText: 'Transport Mode',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select Mode'),
                items: _transportModes.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(mode.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedModalFilter = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _originFilterController.clear();
                      _destinationFilterController.clear();
                      _minPriceFilterController.clear();
                      _maxPriceFilterController.clear();
                      setState(() {
                        _selectedModalFilter = null;
                      });
                      Navigator.pop(context);
                      _fetchAvailableContainers(); // Apply reset filters
                    },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchAvailableContainers(); // Apply filters
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _originFilterController.dispose();
    _destinationFilterController.dispose();
    _minPriceFilterController.dispose();
    _maxPriceFilterController.dispose();
    super.dispose();
  }
}
