// Filename: lib/services/firebase_messaging_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/auth_provider.dart';
// To update user status if needed
import 'package:spazigo/main.dart'; // Import main.dart to access navigatorKey

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
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
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
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
          debugPrint('User status updated via FCM: $userId, $newStatus');

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
        debugPrint('App opened from terminated state with message: ${message.messageId}');
        // Handle deep link or specific action based on message.data
      }
    });

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background with message: ${message.messageId}');
      // Navigate to a specific screen based on message.data
    });

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // Save token to backend when user logs in/registers
    // This will be handled in AuthProvider's login/register methods.
  }

  // Corrected function signature for _showNotification
  static void _showNotification(String? title, String? body, GlobalKey<NavigatorState> navigatorKey) {
    // Here you would use flutter_local_notifications package to show actual notifications
    debugPrint('Local Notification: Title: $title, Body: $body');
    // For demonstration, you might want to show a SnackBar
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(title ?? 'Notification'), duration: const Duration(seconds: 3)),
      );
    }
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}