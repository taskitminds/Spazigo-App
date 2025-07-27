// Filename: lib/screens/msme/msme_booking_page.dart
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:spazigo/constants.dart';
import 'package:spazigo/models/booking.dart';
import 'package:spazigo/services/api_service.dart';

class MsmeBookingsPage extends StatefulWidget {
  const MsmeBookingsPage({super.key});

  @override
  State<MsmeBookingsPage> createState() => _MsmeBookingsPageState();
}

class _MsmeBookingsPageState extends State<MsmeBookingsPage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all', 'pending', 'accepted', 'rejected', 'paid', 'failed'

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedBookings = await ApiService.getMSMEBookings();
      setState(() {
        _bookings = fetchedBookings;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load bookings: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Booking> get _filteredBookings {
    if (_filterStatus == 'all') {
      return _bookings;
    } else if (_filterStatus == 'paid' || _filterStatus == 'failed') {
      // Filter by payment status
      return _bookings.where((b) => b.paymentStatus == _filterStatus).toList();
    }
    // Filter by booking status
    return _bookings.where((b) => b.status == _filterStatus).toList();
  }

  void _startPayment(Booking booking) async {
    try {
      // Calculate amount in paise (assuming price is per unit and weight is in units)
      final double totalAmount = (booking.containerPrice ?? 0) * booking.weight;
      if (totalAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot initiate payment for zero or negative amount.')),
        );
        return;
      }
      final int amountInPaise = (totalAmount * 100).toInt();

      // Pass integer amount directly
      final orderResponse = await ApiService.createRazorpayOrder(booking.id, amountInPaise as double);

      var options = {
        'key': AppConstants.razorpayKeyId,
        'amount': orderResponse['data']['amount'], // Amount comes from Razorpay order
        'name': 'Spazigo Logistics',
        'description': 'Payment for Booking ID: ${booking.id.substring(0, 8)}',
        'order_id': orderResponse['data']['order_id'],
        'currency': orderResponse['data']['currency'],
        'prefill': {
          'email': 'customer@example.com', // Replace with actual user email
          'contact': '9876543210' // Replace with actual user phone
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating payment: $e')),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful: ${response.paymentId}')),
    );
    // Call backend to confirm payment, rely on webhook too
    try {
      // This call to confirmPayment is for immediate UI update. The backend webhook is the source of truth.
      await ApiService.confirmPayment(response.orderId!); // Use orderId if paymentId not directly linked
      _fetchBookings(); // Refresh bookings to reflect payment status
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend update failed after payment: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming payment with backend: $e')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Used: ${response.walletName}')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton('All', 'all'),
                _buildFilterButton('Pending', 'pending'),
                _buildFilterButton('Confirmed', 'accepted'), // Bookings that are accepted
                _buildFilterButton('Paid', 'paid'), // Bookings that are paid
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
                onPressed: _fetchBookings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchBookings,
        child: _filteredBookings.isEmpty
            ? const Center(
          child: Text('No bookings found with selected filter.'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _filteredBookings.length,
          itemBuilder: (context, index) {
            final booking = _filteredBookings[index];
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
                            color: _getStatusColor(booking).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _getDisplayStatus(booking).toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(booking),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('Product: ${booking.productName}', style: Theme.of(context).textTheme.bodyLarge),
                    Text('Weight: ${booking.weight} kg', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Container: ${booking.containerId.substring(0, 8)}', style: Theme.of(context).textTheme.bodyMedium),
                    if (booking.containerOrigin != null && booking.containerDestination != null)
                      Text('Route: ${booking.containerOrigin} to ${booking.containerDestination}', style: Theme.of(context).textTheme.bodyMedium),
                    if (booking.containerDepartureTime != null)
                      Text('Departure: ${_formatDateTime(booking.containerDepartureTime!)}', style: Theme.of(context).textTheme.bodyMedium),
                    if (booking.containerPrice != null)
                      Text('Price/unit: ₹${booking.containerPrice!.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                    if (booking.rejectionReason != null && booking.rejectionReason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Reason: ${booking.rejectionReason}', style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 16),
                    if (booking.status == 'accepted' && booking.paymentStatus == 'pending')
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: () => _startPayment(booking),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('Pay Now'),
                        ),
                      )
                    else if (booking.status == 'accepted' && booking.paymentStatus == 'paid')
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text('Payment Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      )
                    else if (booking.paymentStatus == 'failed')
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text('Payment Failed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  Color _getStatusColor(Booking booking) {
    if (booking.paymentStatus == 'paid') return Colors.green;
    if (booking.paymentStatus == 'failed') return Colors.red;

    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue; // Accepted but not yet paid
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getDisplayStatus(Booking booking) {
    if (booking.paymentStatus == 'paid') return 'Paid';
    if (booking.paymentStatus == 'failed') return 'Payment Failed';
    return booking.status;
  }
}