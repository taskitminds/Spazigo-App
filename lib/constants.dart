class AppConstants {
  // Backend Base URL - Use your actual IP when testing on a real device
  static const String baseUrl = 'https://spazigo-app.onrender.com/api'; // For Android Emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // For iOS Simulator/Web
  // static const String baseUrl = 'http://YOUR_LOCAL_IP:5000/api'; // For Physical Device

  // Secure Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String currentUserKey = 'current_user';
  static const String themeModeKey = 'theme_mode';

  // Razorpay Keys (replace with your actual TEST keys)
  static const String razorpayKeyId = 'rzp_test_fILibYLrynbTcm';
  // Note: Key Secret is only for backend.

  // FCM Topics
  static const String lspTopic = 'lsp_notifications';
  static const String msmeTopic = 'msme_notifications';
}