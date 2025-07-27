class User {
  final String id;
  final String email;
  final String role; // 'lsp', 'msme', 'admin'
  final String status; // 'pending', 'verified', 'rejected'
  final String? company;
  final String? phone;
  final String? fcmToken;
  final String? rejectionReason;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.company,
    this.phone,
    this.fcmToken,
    this.rejectionReason,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      company: json['company'],
      phone: json['phone'],
      fcmToken: json['fcm_token'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'status': status,
      'company': company,
      'phone': phone,
      'fcm_token': fcmToken,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to create a copy with updated FCM token
  User copyWith({
    String? fcmToken,
    String? status,
    String? rejectionReason,
  }) {
    return User(
      id: id,
      email: email,
      role: role,
      status: status ?? this.status,
      company: company,
      phone: phone,
      fcmToken: fcmToken ?? this.fcmToken,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
    );
  }
}
