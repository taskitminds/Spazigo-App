import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spazigo/providers/auth_provider.dart';
import 'package:spazigo/providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  user?.company ?? 'Spazigo User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Role: ${user?.role?.toUpperCase() ?? ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(user?.role == 'lsp' ? 'LSP Dashboard' : 'MSME Home'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              if (user?.role == 'lsp') {
                context.go('/lsp-dashboard');
              } else if (user?.role == 'msme') {
                context.go('/msme-home');
              }
            },
          ),
          if (user?.role == 'lsp') ...[
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('My Containers'),
              onTap: () {
                Navigator.pop(context);
                context.go('/lsp-dashboard/containers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Booking Requests'),
              onTap: () {
                Navigator.pop(context);
                context.go('/lsp-dashboard/booking-requests');
              },
            ),
          ],
          if (user?.role == 'msme') ...[
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('My Bookings'),
              onTap: () {
                Navigator.pop(context);
                context.go('/msme-bookings');
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            onTap: () {
              Navigator.pop(context);
              context.go('/chat-list');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Help & Support page
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Privacy Policy page
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await authProvider.logout();
              context.go('/login'); // Navigate to login after logout
            },
          ),
        ],
      ),
    );
  }
}
