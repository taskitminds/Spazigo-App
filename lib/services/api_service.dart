import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:spazigo/constants.dart';
import 'package:spazigo/models/booking.dart';
import 'package:spazigo/models/container.dart';
import 'package:spazigo/models/message.dart';
import 'package:spazigo/models/user.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: Status Code $statusCode - $message';
}

class ApiService {
  static String? _jwtToken;

  static void setToken(String? token) {
    _jwtToken = token;
  }

  static Map<String, String> _getHeaders({bool requireAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (requireAuth && _jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final Map<String, dynamic> responseBody;
    try {
      responseBody = json.decode(response.body);
    } catch (e) {
      throw ApiException('Invalid server response.', response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw ApiException(
        responseBody['message'] ?? 'An unknown error occurred.',
        response.statusCode,
      );
    }
  }

  static Future<T> _performRequest<T>(
      Future<http.Response> Function() request,
      T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await request();
      final data = await _handleResponse(response);
      return fromJson(data);
    } on SocketException {
      throw ApiException('Could not connect to the server. Please check your internet connection.', 503);
    } on http.ClientException {
      throw ApiException('A network error occurred. Please try again.', 500);
    }
    // ApiException is already handled, rethrow it
    // Other exceptions will be caught as generic errors
  }

  // --- Auth Endpoints ---
  static Future<User> register({
    required String email,
    required String password,
    required String role,
    required String company,
    required String phone,
    required String base64Document,
    required String documentFileName,
    required String documentMimeType,
    String? fcmToken,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/register');
    final response = await _performRequest(
            () => http.post(
          uri,
          headers: _getHeaders(requireAuth: false),
          body: json.encode({
            'email': email,
            'password': password,
            'role': role,
            'company': company,
            'phone': phone,
            'document': base64Document,
            'document_file_name': documentFileName,
            'document_mimetype': documentMimeType,
            'fcm_token': fcmToken,
          }),
        ),
            (json) => User.fromJson(json['data']['user'])
    );
    return response;
  }

  static Future<Map<String, dynamic>> login(String email, String password, {String? fcmToken}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/login');
    final response = await http.post(
      uri,
      headers: _getHeaders(requireAuth: false),
      body: json.encode({'email': email, 'password': password, 'fcm_token': fcmToken}),
    );
    final data = await _handleResponse(response);
    return {
      'token': data['token'],
      'user': User.fromJson(data['data']['user']),
    };
  }

  // --- Container Endpoints ---
  static Future<List<ContainerModel>> getLSPContainers() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/containers');
    final data = await _performRequest(() => http.get(uri, headers: _getHeaders()), (json) => json);
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
    final data = await _performRequest(() => http.get(uri, headers: _getHeaders(requireAuth: false)), (json) => json);
    return (data['data']['containers'] as List)
        .map((json) => ContainerModel.fromJson(json))
        .toList();
  }

  // --- Booking Endpoints ---
  static Future<List<Booking>> getMSMEBookings() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/msme');
    final data = await _performRequest(() => http.get(uri, headers: _getHeaders()), (json) => json);
    return (data['data']['bookings'] as List)
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  static Future<List<Booking>> getLSPBookingRequests() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/lsp');
    final data = await _performRequest(() => http.get(uri, headers: _getHeaders()), (json) => json);
    return (data['data']['bookings'] as List)
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  static Future<Booking> requestBooking(Map<String, dynamic> bookingData) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings');
    final data = await _performRequest(() => http.post(uri, headers: _getHeaders(), body: json.encode(bookingData)), (json) => json);
    return Booking.fromJson(data['data']['booking']);
  }

  // --- Payment Endpoints ---
  static Future<Map<String, dynamic>> createRazorpayOrder(String bookingId, double amount) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/payments/create-order');
    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: json.encode({'bookingId': bookingId, 'amount': amount.toInt()}),
    );
    return await _handleResponse(response);
  }

  // --- Chat Endpoints ---
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/chat/conversations');
    final data = await _performRequest(() => http.get(uri, headers: _getHeaders()), (json) => json);
    return List<Map<String, dynamic>>.from(data['data']['conversations']);
  }

  static Future<List<Message>> getMessagesWithUser(String otherUserId, {String? containerId}) async {
    final queryParams = <String, String>{};
    if (containerId != null) queryParams['container_id'] = containerId;

    final uri = Uri.parse('${AppConstants.baseUrl}/chat/$otherUserId').replace(queryParameters: queryParams);
    final data = await _performRequest(() => http.get(uri, headers: _getHeaders()), (json) => json);
    return (data['data']['messages'] as List)
        .map((json) => Message.fromJson(json))
        .toList();
  }

  static Future<void> sendMessage(String receiverId, String message, {String? containerId}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/chat');
    await _performRequest(() => http.post(uri, headers: _getHeaders(), body: json.encode({
      'receiver_id': receiverId,
      'message': message,
      'container_id': containerId,
    })), (json) => json);
  }

  // Placeholder methods for other API calls, implement similarly
  static Future<void> createContainer(Map<String, dynamic> containerData) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/containers');
    await _performRequest(() => http.post(uri, headers: _getHeaders(), body: json.encode(containerData)), (json) => json);
  }

  static Future<void> updateContainerSpace(String id, double newSpaceLeft) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/containers/$id');
    await _performRequest(() => http.patch(uri, headers: _getHeaders(), body: json.encode({'space_left': newSpaceLeft})), (json) => json);
  }

  static Future<void> acceptBooking(String bookingId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/accept');
    await _performRequest(() => http.patch(uri, headers: _getHeaders()), (json) => json);
  }

  static Future<void> rejectBooking(String bookingId, String reason) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/reject');
    await _performRequest(() => http.patch(uri, headers: _getHeaders(), body: json.encode({'reason': reason})), (json) => json);
  }

  static Future<void> confirmPayment(String bookingId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/pay');
    await _performRequest(() => http.patch(uri, headers: _getHeaders()), (json) => json);
  }
}