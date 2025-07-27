import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/auth_provider.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String? reason;
  const AccessDeniedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If status changes again (e.g., re-verified by admin after review), redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.isAuthenticated && authProvider.currentUser!.status == 'verified') {
        if (authProvider.currentUser!.role == 'lsp') {
          context.go('/lsp-dashboard');
        } else if (authProvider.currentUser!.role == 'msme') {
          context.go('/msme-home');
        }
      } else if (!authProvider.isAuthenticated || authProvider.currentUser!.status == 'pending') {
        // Should not happen if coming from rejected, but a safety fallback
        context.go('/login');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                'Account Access Denied',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Unfortunately, your account verification request was denied by the administrator.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Reason:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  reason!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Provide contact information (email, phone, support link)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact support at support@spazigo.com')),
                  );
                  // TODO: Implement actual contact functionality
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Contact Admin'),
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
