import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/auth_provider.dart';

class AwaitAdminApprovalScreen extends StatelessWidget {
  const AwaitAdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If for some reason the status changes while on this screen
    // (e.g., a background FCM updates the status), redirect.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.isAuthenticated) {
        if (authProvider.currentUser!.status == 'verified') {
          if (authProvider.currentUser!.role == 'lsp') {
            context.go('/lsp-dashboard');
          } else if (authProvider.currentUser!.role == 'msme') {
            context.go('/msme-home');
          }
        } else if (authProvider.currentUser!.status == 'rejected') {
          context.go('/access-denied', extra: authProvider.currentUser!.rejectionReason);
        }
      } else {
        context.go('/login'); // If somehow logged out
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Approval Pending'),
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 20),
              Text(
                'Your account is awaiting admin approval.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'We are reviewing your registration details and documents. This process may take 1-2 business days.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'Current Status: ${authProvider.currentUser?.status?.toUpperCase()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Option to refresh status (or just wait for FCM)
                  authProvider.loadAuthData(); // Re-fetch user data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking for updates...')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await authProvider.logout();
                  context.go('/login');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
