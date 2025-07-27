class Booking {
  final String id;
  final String containerId;
  final String msmeId;
  final String? msmeEmail; // Added for LSP view
  final String? msmeCompany; // Added for LSP view
  final String productName;
  final String? category;
  final double weight;
  final String? imageUrl;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? rejectionReason;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime createdAt;

  final String? containerOrigin; // For MSME's view
  final String? containerDestination; // For MSME's view
  final DateTime? containerDepartureTime; // For MSME's view
  final double? containerPrice; // For MSME's view

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
      containerOrigin: json['origin'], // From JOIN in backend
      containerDestination: json['destination'], // From JOIN in backend
      containerDepartureTime: json['departure_time'] != null ? DateTime.parse(json['departure_time']) : null, // From JOIN in backend
      containerPrice: json['price'] != null ? (json['price'] as num).toDouble() : null, // From JOIN in backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'container_id': containerId,
      'msme_id': msmeId,
      'product_name': productName,
      'category': category,
      'weight': weight,
      'image_url': imageUrl,
      'status': status,
      'payment_status': paymentStatus,
      'rejection_reason': rejectionReason,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Booking copyWith({
    String? status,
    String? paymentStatus,
    String? rejectionReason,
    String? razorpayOrderId,
    String? razorpayPaymentId,
  }) {
    return Booking(
      id: id,
      containerId: containerId,
      msmeId: msmeId,
      msmeEmail: msmeEmail,
      msmeCompany: msmeCompany,
      productName: productName,
      category: category,
      weight: weight,
      imageUrl: imageUrl,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      createdAt: createdAt,
      containerOrigin: containerOrigin,
      containerDestination: containerDestination,
      containerDepartureTime: containerDepartureTime,
      containerPrice: containerPrice,
    );
  }
}
