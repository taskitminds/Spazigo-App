import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spazigo/constants.dart';
import 'package:spazigo/models/user.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/services/firebase_messaging_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _jwtToken;
  bool _isLoading = true; // Start as true to handle initial load
  String? _errorMessage;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _jwtToken != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    loadAuthData();
  }

  Future<void> loadAuthData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _secureStorage.read(key: AppConstants.jwtTokenKey);
      final userDataString = await _secureStorage.read(key: AppConstants.currentUserKey);

      if (token != null && userDataString != null) {
        _jwtToken = token;
        _currentUser = User.fromJson(json.decode(userDataString));
        ApiService.setToken(token);
      } else {
        await _clearAuthData();
      }
    } catch (e) {
      await _clearAuthData();
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
    ApiService.setToken(token);
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    _jwtToken = null;
    _currentUser = null;
    await _secureStorage.deleteAll();
    ApiService.setToken(null);
  }

  Future<bool> register({
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
      _currentUser = user;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during registration.';
      return false;
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
      final response = await ApiService.login(email, password, fcmToken: fcmToken);
      await _saveAuthData(response['token'], response['user']);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      await _clearAuthData();
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      await _clearAuthData();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _clearAuthData();
    _isLoading = false;
    notifyListeners();
  }

  void updateUserStatus(String userId, String newStatus, {String? rejectionReason}) {
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        status: newStatus,
        rejectionReason: rejectionReason,
      );
      _secureStorage.write(key: AppConstants.currentUserKey, value: json.encode(_currentUser!.toJson()));
      notifyListeners();
    }
  }
}