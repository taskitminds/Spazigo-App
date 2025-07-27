import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spazigo/constants.dart';
import 'package:spazigo/models/user.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/services/firebase_messaging_service.dart'; // For FCM token

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _jwtToken;
  bool _isLoading = false;
  String? _errorMessage;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _jwtToken != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get jwtToken => _jwtToken;

  AuthProvider() {
    loadAuthData(); // Load auth data on provider initialization
  }

  Future<void> loadAuthData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.init(); // Initialize ApiService to load token
      _jwtToken = ApiService.token;

      if (_jwtToken != null) {
        final userDataString = await _secureStorage.read(key: AppConstants.currentUserKey);
        if (userDataString != null) {
          _currentUser = User.fromJson(json.decode(userDataString));
        }
      }
    } catch (e) {
      debugPrint('Error loading auth data: $e');
      _errorMessage = 'Failed to load session.';
      _currentUser = null;
      _jwtToken = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAuthData(String token, User user) async {
    _jwtToken = token;
    _currentUser = user;
    await _secureStorage.write(key: AppConstants.jwtTokenKey, value: token);
    await _secureStorage.write(key: AppConstants.currentUserKey, value: json.encode(user.toJson()));
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
    required String company,
    required String phone,
    required String base64Document,
    required String documentFileName,
    required String documentMimeType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fcmToken = await FirebaseMessagingService.getToken();
      final user = await ApiService.register(
        email: email,
        password: password,
        role: role,
        company: company,
        phone: phone,
        base64Document: base64Document,
        documentFileName: documentFileName,
        documentMimeType: documentMimeType,
        fcmToken: fcmToken,
      );
      // Registration successful, but no login yet (awaiting admin approval)
      _currentUser = user; // Set current user to pending state
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fcmToken = await FirebaseMessagingService.getToken();
      final user = await ApiService.login(email, password, fcmToken: fcmToken);
      await _saveAuthData(ApiService.token!, user); // Save token and user data
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _currentUser = null;
      _jwtToken = null;
      await ApiService.deleteToken(); // Clear token on failed login
      await _secureStorage.delete(key: AppConstants.currentUserKey);
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _currentUser = null;
      _jwtToken = null;
      await ApiService.deleteToken(); // Clear token on failed login
      await _secureStorage.delete(key: AppConstants.currentUserKey);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.deleteToken();
      _currentUser = null;
      _jwtToken = null;
      await _secureStorage.delete(key: AppConstants.currentUserKey);
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to update user status after admin approval/rejection (e.g., via FCM)
  void updateUserStatus(String userId, String newStatus, {String? rejectionReason}) {
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        status: newStatus,
        rejectionReason: rejectionReason,
      );
      // Also update in secure storage
      _secureStorage.write(key: AppConstants.currentUserKey, value: json.encode(_currentUser!.toJson()));
      notifyListeners();
    }
  }
}
