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
  String _filterStatus = 'all';

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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedBookings = await ApiService.getMSMEBookings();
      if (mounted) {
        setState(() {
          _bookings = fetchedBookings;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to load bookings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Booking> get _filteredBookings {
    if (_filterStatus == 'all') {
      return _bookings;
    } else if (_filterStatus == 'paid' || _filterStatus == 'failed') {
      return _bookings.where((b) => b.paymentStatus == _filterStatus).toList();
    }
    return _bookings.where((b) => b.status == _filterStatus).toList();
  }

  void _startPayment(Booking booking) async {
    final double totalAmount = (booking.containerPrice ?? 0) * booking.weight;
    if (totalAmount <= 0) {
      _showErrorSnackBar('Invalid payment amount.');
      return;
    }
    final int amountInPaise = (totalAmount * 100).toInt();

    try {
      final orderResponse = await ApiService.createRazorpayOrder(booking.id, amountInPaise.toDouble());
      final orderData = orderResponse['data'];

      var options = {
        'key': AppConstants.razorpayKeyId,
        'amount': orderData['amount'],
        'name': 'Spazigo Logistics',
        'description': 'Booking ID: ${booking.id.substring(0, 8)}',
        'order_id': orderData['order_id'],
        'currency': orderData['currency'],
        'prefill': {
          'email': 'customer@example.com',
          'contact': '9876543210'
        },
      };

      _razorpay.open(options);
    } on ApiException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('Error initiating payment: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Successful: ${response.paymentId}')));
    // The backend webhook is the source of truth for payment status.
    // We just refresh the list to get the latest status.
    _fetchBookings();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorSnackBar('Payment Failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                _buildFilterButton('All', 'all'),
                _buildFilterButton('Pending', 'pending'),
                _buildFilterButton('Accepted', 'accepted'),
                _buildFilterButton('Paid', 'paid'),
                _buildFilterButton('Rejected', 'rejected'),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchBookings, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_filteredBookings.isEmpty) {
      return const Center(child: Text('No bookings found with the selected filter.'));
    }
    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredBookings.length,
        itemBuilder: (context, index) => _buildBookingCard(_filteredBookings[index]),
      ),
    );
  }

  Widget _buildFilterButton(String text, String status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => setState(() => _filterStatus = status),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).colorScheme.secondary : null,
          foregroundColor: isSelected ? Colors.white : null,
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
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
                _buildStatusChip(booking),
              ],
            ),
            const Divider(height: 16),
            Text('Product: ${booking.productName}', style: Theme.of(context).textTheme.bodyLarge),
            Text('Weight: ${booking.weight} kg', style: Theme.of(context).textTheme.bodyMedium),
            Text('Route: ${booking.containerOrigin} to ${booking.containerDestination}', style: Theme.of(context).textTheme.bodyMedium),
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
                  child: const Text('Pay Now'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Booking booking) {
    final color = _getStatusColor(booking);
    final text = _getDisplayStatus(booking).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Color _getStatusColor(Booking booking) {
    if (booking.paymentStatus == 'paid') return Colors.green;
    if (booking.paymentStatus == 'failed') return Colors.red;
    switch (booking.status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDisplayStatus(Booking booking) {
    if (booking.paymentStatus == 'paid') return 'Paid';
    if (booking.paymentStatus == 'failed') return 'Payment Failed';
    return booking.status;
  }
}