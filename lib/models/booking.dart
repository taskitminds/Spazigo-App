class Booking {
  final String id;
  final String containerId;
  final String msmeId;
  final String? msmeEmail;
  final String? msmeCompany;
  final String productName;
  final String? category;
  final double weight;
  final String? imageUrl;
  final String status;
  final String paymentStatus;
  final String? rejectionReason;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime createdAt;
  final String? containerOrigin;
  final String? containerDestination;
  final DateTime? containerDepartureTime;
  final double? containerPrice;

  Booking({
    required this.id,
    required this.containerId,
    required this.msmeId,
    this.msmeEmail,
    this.msmeCompany,
    required this.productName,
    this.category,
    required this.weight,
    this.imageUrl,
    required this.status,
    required this.paymentStatus,
    this.rejectionReason,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.createdAt,
    this.containerOrigin,
    this.containerDestination,
    this.containerDepartureTime,
    this.containerPrice,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      containerId: json['container_id'],
      msmeId: json['msme_id'],
      msmeEmail: json['msme_email'],
      msmeCompany: json['msme_company'],
      productName: json['product_name'],
      category: json['category'],
      weight: (json['weight'] as num).toDouble(),
      imageUrl: json['image_url'],
      status: json['status'],
      paymentStatus: json['payment_status'],
      rejectionReason: json['rejection_reason'],
      razorpayOrderId: json['razorpay_order_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      createdAt: DateTime.parse(json['created_at']),
      containerOrigin: json['origin'],
      containerDestination: json['destination'],
      containerDepartureTime: json['departure_time'] != null ? DateTime.parse(json['departure_time']) : null,
      containerPrice: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }
}