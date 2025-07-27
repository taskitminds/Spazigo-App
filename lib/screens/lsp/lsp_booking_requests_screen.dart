import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazigo/models/booking.dart';
import 'package:spazigo/services/api_service.dart';

class LspBookingRequestsScreen extends StatefulWidget {
  final String? containerIdFilter; // Optional filter to view bookings for a specific container

  const LspBookingRequestsScreen({super.key, this.containerIdFilter});

  @override
  State<LspBookingRequestsScreen> createState() => _LspBookingRequestsScreenState();
}

class _LspBookingRequestsScreenState extends State<LspBookingRequestsScreen> {
  List<Booking> _bookingRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all', 'pending', 'accepted', 'rejected'

  @override
  void initState() {
    super.initState();
    _fetchBookingRequests();
  }

  Future<void> _fetchBookingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedBookings = await ApiService.getLSPBookingRequests();
      setState(() {
        _bookingRequests = fetchedBookings;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load booking requests: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Booking> get _filteredBookingRequests {
    List<Booking> filtered = _bookingRequests;

    if (widget.containerIdFilter != null) {
      filtered = filtered.where((b) => b.containerId == widget.containerIdFilter).toList();
    }

    if (_filterStatus == 'all') {
      return filtered;
    }
    return filtered.where((b) => b.status == _filterStatus).toList();
  }

  void _acceptBooking(Booking booking) async {
    try {
      await ApiService.acceptBooking(booking.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted successfully!')),
      );
      _fetchBookingRequests(); // Refresh list
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept booking: $e')),
      );
    }
  }

  void _rejectBooking(Booking booking) async {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reject Booking'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: 'Reason for rejection'),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Reject'),
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Reason cannot be empty.')),
                  );
                  return;
                }
                try {
                  await ApiService.rejectBooking(booking.id, reasonController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking rejected successfully!')),
                  );
                  _fetchBookingRequests(); // Refresh list
                  Navigator.of(dialogContext).pop();
                } on ApiException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rejecting booking: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.containerIdFilter != null ? 'Bookings for ${widget.containerIdFilter!.substring(0, 8)}' : 'Booking Requests'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton('All', 'all'),
                _buildFilterButton('Pending', 'pending'),
                _buildFilterButton('Accepted', 'accepted'),
                _buildFilterButton('Rejected', 'rejected'),
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
                onPressed: _fetchBookingRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchBookingRequests,
        child: _filteredBookingRequests.isEmpty
            ? const Center(
          child: Text('No booking requests found with selected filter.'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _filteredBookingRequests.length,
          itemBuilder: (context, index) {
            final booking = _filteredBookingRequests[index];
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
                          'Booking ID: ${booking.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('MSME: ${booking.msmeCompany ?? booking.msmeEmail}', style: Theme.of(context).textTheme.bodyLarge),
                    Text('Product: ${booking.productName}', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Category: ${booking.category ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Weight: ${booking.weight} kg', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Container: ${booking.containerId.substring(0, 8)}', style: Theme.of(context).textTheme.bodyMedium),
                    if (booking.rejectionReason != null && booking.rejectionReason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Reason: ${booking.rejectionReason}', style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 16),
                    if (booking.status == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _acceptBooking(booking),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Accept'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _rejectBooking(booking),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Reject'),
                          ),
                        ],
                      )
                    else if (booking.status == 'accepted' && booking.paymentStatus == 'pending')
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text('Waiting for MSME payment', style: TextStyle(color: Theme.of(context).primaryColor)),
                      )
                    else if (booking.status == 'accepted' && booking.paymentStatus == 'paid')
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text('Payment Received', style: TextStyle(color: Colors.green)),
                        )
                  ],
                ),
              ),
            );
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
