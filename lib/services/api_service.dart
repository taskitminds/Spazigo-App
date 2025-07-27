import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spazigo/constants.dart';
import 'package:spazigo/models/booking.dart';
import 'package:spazigo/models/container.dart';
import 'package:spazigo/models/message.dart';
import 'package:spazigo/models/user.dart';

// Custom Exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() {
    return 'ApiException: Status Code $statusCode - $message';
  }
}

class ApiService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static String? _jwtToken;

  // Initialize token from secure storage
  static Future<void> init() async {
    _jwtToken = await _secureStorage.read(key: AppConstants.jwtTokenKey);
  }

  static String? get token => _jwtToken;

  static Future<void> saveToken(String token) async {
    _jwtToken = token;
    await _secureStorage.write(key: AppConstants.jwtTokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    _jwtToken = null;
    await _secureStorage.delete(key: AppConstants.jwtTokenKey);
  }

  static Map<String, String> _getHeaders({bool requireAuth = false, String? contentType}) {
    final headers = <String, String>{};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    } else {
      headers['Content-Type'] = 'application/json';
    }
    if (requireAuth && _jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final Map<String, dynamic> responseBody = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw ApiException(
        responseBody['message'] ?? 'An unknown error occurred.',
        response.statusCode,
      );
    }
  }

  // Auth Endpoints
  static Future<User> register({
    required String email,
    required String password,
    required String role,
    required String company,
    required String phone,
    required String base64Document, // For document content
    required String documentFileName,
    required String documentMimeType,
    String? fcmToken,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/register');
    final response = await http.post(
      uri,
      headers: _getHeaders(contentType: 'application/json'),
      body: json.encode({
        'email': email,
        'password': password,
        'role': role,
        'company': company,
        'phone': phone,
        'document': base64Document, // Send base64 string
        'document_file_name': documentFileName,
        'document_mimetype': documentMimeType,
        'fcm_token': fcmToken,
      }),
    );
    final data = await _handleResponse(response);
    return User.fromJson(data['data']['user']);
  }


  static Future<User> login(String email, String password, {String? fcmToken}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/login');
    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password, 'fcm_token': fcmToken}),
    );
    final data = await _handleResponse(response);
    await saveToken(data['token']);
    return User.fromJson(data['data']['user']);
  }

  // LSP Container Endpoints
  static Future<Map<String, dynamic>> createContainer(Map<String, dynamic> containerData) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/containers');
    final response = await http.post(
      uri,
      headers: _getHeaders(requireAuth: true),
      body: json.encode(containerData),
    );
    return _handleResponse(response);
  }

  static Future<List<ContainerModel>> getLSPContainers() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/containers');
    final response = await http.get(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return (data['data']['containers'] as List)
        .map((json) => ContainerModel.fromJson(json))
        .toList();
  }

  static Future<List<ContainerModel>> getAvailableContainers({
    String? origin, String? destination, double? minPrice, double? maxPrice, String? modal
  }) async {
    final queryParams = <String, String>{};
    if (origin != null) queryParams['origin'] = origin;
    if (destination != null) queryParams['destination'] = destination;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (modal != null) queryParams['modal'] = modal;

    final uri = Uri.parse('${AppConstants.baseUrl}/containers/available').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: _getHeaders(), // No auth required for public list
    );
    final data = await _handleResponse(response);
    return (data['data']['containers'] as List)
        .map((json) => ContainerModel.fromJson(json))
        .toList();
  }

  static Future<Map<String, dynamic>> updateContainerSpace(String id, double newSpaceLeft) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/containers/$id');
    final response = await http.patch(
      uri,
      headers: _getHeaders(requireAuth: true),
      body: json.encode({'space_left': newSpaceLeft}),
    );
    return _handleResponse(response);
  }

  // Booking Endpoints (MSME & LSP)
  static Future<Booking> requestBooking(Map<String, dynamic> bookingData) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings');
    final response = await http.post(
      uri,
      headers: _getHeaders(requireAuth: true),
      body: json.encode(bookingData),
    );
    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<List<Booking>> getMSMEBookings() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/msme');
    final response = await http.get(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return (data['data']['bookings'] as List)
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  static Future<List<Booking>> getLSPBookingRequests() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/lsp');
    final response = await http.get(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return (data['data']['bookings'] as List)
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  static Future<Booking> acceptBooking(String bookingId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/accept');
    final response = await http.patch(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<Booking> rejectBooking(String bookingId, String reason) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/reject');
    final response = await http.patch(
      uri,
      headers: _getHeaders(requireAuth: true),
      body: json.encode({'reason': reason}),
    );
    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<Booking> confirmPayment(String bookingId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/pay');
    final response = await http.patch(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  // Payment Endpoints (Razorpay)
  static Future<Map<String, dynamic>> createRazorpayOrder(String bookingId, double amountInPaise) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/payments/create-order');
    final response = await http.post(
      uri,
      headers: _getHeaders(requireAuth: true),
      body: json.encode({'bookingId': bookingId, 'amount': amountInPaise.toInt()}), // Amount in paise
    );
    return _handleResponse(response);
  }

  // Admin Endpoints
  static Future<List<User>> getPendingUsers() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/admin/pending-users');
    final response = await http.get(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return (data['data']['users'] as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  static Future<User> verifyUser(String userId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/admin/verify/$userId');
    final response = await http.patch(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return User.fromJson(data['data']['user']);
  }

  static Future<User> rejectUser(String userId, String reason) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/admin/reject/$userId');
    final response = await http.patch(
      uri,
      headers: _getHeaders(requireAuth: true),
      body: json.encode({'reason': reason}),
    );
    final data = await _handleResponse(response);
    return User.fromJson(data['data']['user']);
  }

  // Chat Endpoints
  static Future<Map<String, dynamic>> sendMessage(String receiverId, String message, {String? containerId}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/chat');
    final response = await http.post(
      uri,
      headers: _getHeaders(requireAuth: true),
      body: json.encode({
        'receiver_id': receiverId,
        'message': message,
        'container_id': containerId,
      }),
    );
    return _handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/chat/conversations');
    final response = await http.get(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data']['conversations']);
  }

  static Future<List<Message>> getMessagesWithUser(String otherUserId, {String? containerId}) async {
    final queryParams = <String, String>{};
    if (containerId != null) queryParams['container_id'] = containerId;

    final uri = Uri.parse('${AppConstants.baseUrl}/chat/$otherUserId').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: _getHeaders(requireAuth: true),
    );
    final data = await _handleResponse(response);
    // Note: The backend returns a plain list of messages, not Firestore specific format
    return (data['data']['messages'] as List)
        .map((json) => Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      containerId: json['container_id'],
      timestamp: DateTime.parse(json['timestamp']),
    ))
        .toList();
  }
}
