import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spazigo/models/container.dart';
import 'firebase_options.dart';

// Providers
import 'package:spazigo/providers/auth_provider.dart';
import 'package:spazigo/providers/theme_provider.dart';
import 'package:spazigo/services/firebase_messaging_service.dart';

// Screens
import 'package:spazigo/screens/onboarding_screen.dart';
import 'package:spazigo/screens/auth/login_screen.dart';
import 'package:spazigo/screens/auth/register_role_selection_screen.dart';
import 'package:spazigo/screens/auth/lsp_registration_form_screen.dart';
import 'package:spazigo/screens/auth/msme_registration_form_screen.dart';
import 'package:spazigo/screens/auth/await_admin_approval_screen.dart';
import 'package:spazigo/screens/auth/access_denied_screen.dart';
import 'package:spazigo/screens/lsp/lsp_dashboard_screen.dart';
import 'package:spazigo/screens/msme/msme_home_screen.dart';
import 'package:spazigo/screens/chat/chat_detail_screen.dart';
import 'package:spazigo/screens/chat/chat_list_screen.dart';
import 'package:spazigo/screens/lsp/add_container_screen.dart';
import 'package:spazigo/screens/lsp/lsp_booking_requests_screen.dart';
import 'package:spazigo/screens/lsp/lsp_container_listing_screen.dart';
import 'package:spazigo/screens/msme/book_container_form_screen.dart';
import 'package:spazigo/screens/msme/msme_booking_page.dart';
import 'package:spazigo/screens/profile_screen.dart';
import 'package:spazigo/screens/settings_screen.dart';
import 'package:spazigo/providers/user_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessagingService.initialize(navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) => UserProvider(),
          update: (context, auth, user) {
            user?.update(auth.currentUser);
            return user!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// A simple splash screen to show while the app is loading the auth state.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          redirect: (context, state) {
            if (authProvider.isLoading) {
              return '/splash';
            }

            if (!authProvider.isAuthenticated) {
              return '/onboarding';
            }

            final user = authProvider.currentUser;
            if (user == null) {
              return '/login'; // Should not happen, but a safeguard
            }

            switch (user.status) {
              case 'pending':
                return '/await-approval';
              case 'rejected':
                return '/access-denied';
              case 'verified':
                if (user.role == 'lsp') return '/lsp-dashboard';
                if (user.role == 'msme') return '/msme-home';
                return '/login'; // Fallback for other roles
              default:
                return '/login';
            }
          },
          // This builder is a fallback, the redirect should always catch the user.
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterRoleSelectionScreen(),
        ),
        GoRoute(
          path: '/register-lsp',
          builder: (context, state) => const LspRegistrationFormScreen(),
        ),
        GoRoute(
          path: '/register-msme',
          builder: (context, state) => const MsmeRegistrationFormScreen(),
        ),
        GoRoute(
          path: '/await-approval',
          builder: (context, state) => const AwaitAdminApprovalScreen(),
        ),
        GoRoute(
          path: '/access-denied',
          builder: (context, state) => AccessDeniedScreen(reason: state.extra as String?),
        ),
        GoRoute(
          path: '/lsp-dashboard',
          builder: (context, state) => const LspDashboardScreen(),
        ),
        GoRoute(
          path: '/msme-home',
          builder: (context, state) => const MsmeHomeScreen(),
        ),
        GoRoute(
          path: '/lsp-dashboard/add-container',
          builder: (context, state) => const AddContainerScreen(),
        ),
        GoRoute(
          path: '/lsp-dashboard/containers',
          builder: (context, state) => const LspContainerListingScreen(),
        ),
        GoRoute(
          path: '/lsp-dashboard/booking-requests',
          builder: (context, state) => LspBookingRequestsScreen(containerIdFilter: state.extra as String?),
        ),
        GoRoute(
          path: '/msme-home/book-container-form',
          builder: (context, state) => BookContainerFormScreen(container: state.extra as ContainerModel),
        ),
        GoRoute(
          path: '/msme-bookings',
          builder: (context, state) => const MsmeBookingsPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/chat-list',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/chat/:otherUserId',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ChatDetailScreen(
              otherUserId: state.pathParameters['otherUserId']!,
              containerId: state.uri.queryParameters['containerId'],
              otherUserCompanyName: extra?['other_user_company'],
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.error}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'Spazigo',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}