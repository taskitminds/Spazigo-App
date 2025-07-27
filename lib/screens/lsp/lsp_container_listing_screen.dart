import 'package:flutter/material.dart';
import 'package:spazigo/models/container.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/screens/lsp/lsp_dashboard_screen.dart'; // Re-use ContainerCard

class LspContainerListingScreen extends StatefulWidget {
  const LspContainerListingScreen({super.key});

  @override
  State<LspContainerListingScreen> createState() => _LspContainerListingScreenState();
}

class _LspContainerListingScreenState extends State<LspContainerListingScreen> {
  List<ContainerModel> _containers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all', 'active', 'expired', 'full'

  @override
  void initState() {
    super.initState();
    _fetchContainers();
  }

  Future<void> _fetchContainers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedContainers = await ApiService.getLSPContainers();
      setState(() {
        _containers = fetchedContainers;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load containers: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ContainerModel> get _filteredContainers {
    if (_filterStatus == 'all') {
      return _containers;
    }
    return _containers.where((c) => c.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Containers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton('All', 'all'),
                _buildFilterButton('Active', 'active'),
                _buildFilterButton('Expired', 'expired'),
                _buildFilterButton('Full', 'full'),
              ],
            ),
          ),
        ),
      ),
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
                onPressed: _fetchContainers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchContainers,
        child: _filteredContainers.isEmpty
            ? const Center(
          child: Text('No containers found with selected filter.'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _filteredContainers.length,
          itemBuilder: (context, index) {
            final container = _filteredContainers[index];
            return ContainerCard(container: container, isLSPView: true, onUpdate: _fetchContainers);
          },
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, String status) {
    final bool isSelected = _filterStatus == status;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filterStatus = status;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).colorScheme.secondary : null,
        foregroundColor: isSelected ? Colors.white : null,
        elevation: isSelected ? 4 : 0,
      ),
      child: Text(text),
    );
  }
}
