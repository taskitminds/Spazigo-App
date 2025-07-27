class ContainerModel {
  final String id;
  final String lspId;
  final String? lspCompany; // Added for available containers view
  final String origin;
  final String destination;
  final List<String> routes;
  final double spaceTotal;
  final double spaceLeft;
  final double price;
  final String modal; // 'road', 'rail', 'sea', 'air'
  final DateTime bookingDeadline;
  final DateTime departureTime;
  final String status; // 'active', 'expired', 'full'
  final DateTime createdAt;

  ContainerModel({
    required this.id,
    required this.lspId,
    this.lspCompany,
    required this.origin,
    required this.destination,
    required this.routes,
    required this.spaceTotal,
    required this.spaceLeft,
    required this.price,
    required this.modal,
    required this.bookingDeadline,
    required this.departureTime,
    required this.status,
    required this.createdAt,
  });

  factory ContainerModel.fromJson(Map<String, dynamic> json) {
    return ContainerModel(
      id: json['id'],
      lspId: json['lsp_id'],
      lspCompany: json['lsp_company'],
      origin: json['origin'],
      destination: json['destination'],
      routes: List<String>.from(json['routes'] ?? []),
      spaceTotal: (json['space_total'] as num).toDouble(),
      spaceLeft: (json['space_left'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      modal: json['modal'],
      bookingDeadline: DateTime.parse(json['deadline']),
      departureTime: DateTime.parse(json['departure_time']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lsp_id': lspId,
      'origin': origin,
      'destination': destination,
      'routes': routes,
      'space_total': spaceTotal,
      'space_left': spaceLeft,
      'price': price,
      'modal': modal,
      'deadline': bookingDeadline.toIso8601String(),
      'departure_time': departureTime.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
