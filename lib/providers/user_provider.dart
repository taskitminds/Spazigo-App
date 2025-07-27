import 'package:flutter/material.dart';
import 'package:spazigo/models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  // This method is called by ChangeNotifierProxyProvider
  // to update UserProvider when AuthProvider changes.
  void update(User? newUser) {
    if (_user != newUser) {
      _user = newUser;
      notifyListeners();
    }
  }

  // You can add more user-specific state or methods here
  // e.g., update profile details
  void updateProfile({String? company, String? phone}) {
    if (_user != null) {
      _user = _user!.copyWith(
        // Assuming your User model has copyWith for these fields
        // For this example, only FCM token is in copyWith, extend User model for other fields
      );
      notifyListeners();
    }
  }
}
