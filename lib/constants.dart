class AppConstants {
  // Backend Base URL
  // Use your local IP for Android emulator/physical device if running Node.js locally
  // e.g., 'http://192.168.1.5:5000/api'
  static const String baseUrl = 'http://localhost:5000/api'; // For iOS simulator/web

  // Secure Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String currentUserKey = 'current_user';
  static const String themeModeKey = 'theme_mode';

  // Razorpay Keys (replace with your test/live keys)
  static const String razorpayKeyId = 'rzp_test_YOUR_RAZORPAY_KEY_ID';
  // Note: Key Secret is only for backend, not for frontend.

  // FCM Topics (if you use them for broad notifications)
  static const String lspTopic = 'lsp_notifications';
  static const String msmeTopic = 'msme_notifications';
}
