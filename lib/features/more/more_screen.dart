import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/queue_providers.dart';
import '../auth/auth_service.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBusiness = ref.watch(currentBusinessProvider);
    final currentBranch = ref.watch(currentBranchProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: AppConstants.bottomNavPadding),
        children: [
          // Business Profile Header Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        AppConstants.logoIconPath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentBusiness?.name ?? 'My Business',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentBranch != null ? '${currentBranch.name} • ${currentBranch.code}' : (user?.email ?? 'Active Session'),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              user?.email ?? 'BUSINESS OWNER',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            backgroundColor: const Color(0xFFEFF6FF),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          _buildSectionHeader('BRANCH & SERVICE SETUP'),
          _buildMenuTile(
            context,
            icon: Icons.store_outlined,
            title: 'Branch Management',
            subtitle: 'Manage branches, operating hours & holidays',
            onTap: () => context.push('/branches'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.room_service_outlined,
            title: 'Service Catalog',
            subtitle: 'Configure services, priority rules & durations',
            onTap: () => context.push('/services'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.desktop_windows_outlined,
            title: 'Counter Configuration',
            subtitle: 'Multi-service routing & auto-allocation policies',
            onTap: () => context.go('/counters'),
          ),

          const SizedBox(height: 12),
          _buildSectionHeader('HARDWARE & INTEGRATIONS'),
          _buildMenuTile(
            context,
            icon: Icons.qr_code_2,
            title: 'QR Code Posters',
            subtitle: 'Generate & print QR codes for branch & services',
            onTap: () => context.push('/qr'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.tv,
            title: 'Queue Display Screens',
            subtitle: 'Pair TV and public displays with pairing code',
            onTap: () => context.push('/display'),
          ),

          const SizedBox(height: 12),
          _buildSectionHeader('TEAM & OPERATIONS'),
          _buildMenuTile(
            context,
            icon: Icons.event_available_outlined,
            title: 'Appointments & Scheduling',
            subtitle: 'Manage time slots, upcoming bookings & fast check-in',
            onTap: () => context.push('/appointments'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.people_outline,
            title: 'Employee Management',
            subtitle: 'Invite staff, assign roles and counter permissions',
            onTap: () => context.push('/employees'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.bar_chart_outlined,
            title: 'Reports & Analytics',
            subtitle: 'Waiting times, peak hours and counter efficiency',
            onTap: () => context.push('/reports'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.history,
            title: 'Audit Logs',
            subtitle: 'Full traceability of tokens, calls and state changes',
            onTap: () => context.push('/audit'),
          ),

          const SizedBox(height: 12),
          _buildSectionHeader('BILLING & ACCOUNT'),
          _buildMenuTile(
            context,
            icon: Icons.credit_card_outlined,
            title: 'Subscription & Limits',
            subtitle: 'Manage plan, counter limits & invoices',
            onTap: () => context.push('/subscription'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'App version 1.0.0 (${AppConstants.packageName})',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out from EasyQueue Business?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authServiceProvider).signOut();
              }
            },
            color: Colors.red,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
