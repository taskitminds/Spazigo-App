// Filename: lib/services/firebase_messaging_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/auth_provider.dart';
// To update user status if needed

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // For background messages, updating UI/Providers directly is complex and
  // typically requires isolates or dedicated background services.
  // This example focuses on foreground updates.
}

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      if (message.notification != null) {
        // Show a local notification if needed (using flutter_local_notifications)
        // Pass the navigatorKey to the _showNotification function
        _showNotification(message.notification!.title, message.notification!.body, navigatorKey);
      }

      // Handle specific data, e.g., update user status if admin approves/rejects
      if (message.data['type'] == 'user_status_update') {
        final userId = message.data['user_id'];
        final newStatus = message.data['status'];
        final rejectionReason = message.data['rejection_reason'];

        // Access AuthProvider using the global navigator key's context
        if (navigatorKey.currentContext != null && userId != null && newStatus != null) {
          Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false)
              .updateUserStatus(userId, newStatus, rejectionReason: rejectionReason);

          // Optionally show a SnackBar or AlertDialog in the foreground
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Account Status Updated: $newStatus! ${rejectionReason != null ? 'Reason: $rejectionReason' : ''}'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });

    // Handle initial message when app is opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        // Handle deep link or specific action based on message.data
      }
    });

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Navigate to a specific screen based on message.data
    });

    // Get FCM token
    // Save token to backend when user logs in/registers
    // This will be handled in AuthProvider's login/register methods.
  }

  // Corrected function signature for _showNotification
  static void _showNotification(String? title, String? body, GlobalKey<NavigatorState> navigatorKey) {
    // Here you would use flutter_local_notifications package to show actual notifications
    // For demonstration, you might want to show a SnackBar
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(title ?? 'Notification'), duration: const Duration(seconds: 3)),
      );
    }
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}