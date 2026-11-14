import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';
import '../auth/auth_service.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBusiness = ref.watch(currentBusinessProvider);
    final currentBranch = ref.watch(currentBranchProvider);
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: AppConstants.bottomNavPadding),
        children: [
          // Business Profile Header Card (Tappable to configure)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showEditBusinessDialog(context, ref, currentBusiness),
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentBusiness?.name ?? 'My Business',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.edit_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentBranch != null
                                  ? '${currentBranch.name} • ${currentBranch.code}'
                                  : (user?.email ?? 'Active Session'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              avatar: Icon(
                                currentBusiness?.orgCategory.icon ?? Icons.business,
                                size: 14,
                                color: const Color(0xFF2563EB),
                              ),
                              label: Text(
                                currentBusiness?.fullCategoryDisplayName ?? 'BUSINESS OWNER',
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
          ),
          const SizedBox(height: 8),

          _buildSectionHeader('BUSINESS & SETUP'),
          _buildMenuTile(
            context,
            icon: Icons.category_outlined,
            title: 'Organization Category Management',
            subtitle: 'Browse 15 industry groups, 100+ types & queue templates',
            onTap: () => context.push('/categories'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.business_outlined,
            title: 'Business Profile',
            subtitle: 'Configure business name, industry category & details',
            onTap: () => _showEditBusinessDialog(context, ref, currentBusiness),
          ),
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

  void _showEditBusinessDialog(BuildContext context, WidgetRef ref, BusinessModel? currentBusiness) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentBusiness?.name ?? '');

    OrganizationCategory currentOrgCat = OrganizationCategoryManager.findCategory(currentBusiness?.category);
    final initialOrgSub = OrganizationCategoryManager.findSubCategory(currentBusiness?.category, currentBusiness?.subCategory);

    String selectedCategory = currentOrgCat.id;
    String selectedSubCategory = initialOrgSub?.name ?? (currentOrgCat.subCategories.isNotEmpty ? currentOrgCat.subCategories.first.name : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableSubCats = currentOrgCat.subCategories;
          final validSubCategory = availableSubCats.any((s) => s.name == selectedSubCategory)
              ? selectedSubCategory
              : (availableSubCats.isNotEmpty ? availableSubCats.first.name : '');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Configure Business Profile'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your business name appears across TV displays, customer tickets, receipts, and SMS notifications.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        hintText: 'e.g. Apex Diagnostics & Clinics',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 15 Master Categories Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Industry Category (A - O)',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: OrganizationCategoryManager.defaultCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: cat.brandColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(cat.code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cat.brandColor)),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(cat.icon, size: 16, color: cat.brandColor),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final newCat = OrganizationCategoryManager.findCategory(val);
                          setModalState(() {
                            currentOrgCat = newCat;
                            selectedCategory = newCat.id;
                            selectedSubCategory = newCat.subCategories.isNotEmpty ? newCat.subCategories.first.name : '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Cascading Organization Sub-Category Dropdown
                    if (availableSubCats.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey('subcat_${currentOrgCat.id}'),
                        initialValue: validSubCategory,
                        decoration: const InputDecoration(
                          labelText: 'Organization Type / Sub-Category',
                          prefixIcon: Icon(Icons.subdirectory_arrow_right),
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: availableSubCats
                            .map((sub) => DropdownMenuItem(
                                  value: sub.name,
                                  child: Row(
                                    children: [
                                      Icon(sub.icon, size: 16, color: Colors.grey.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          sub.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedSubCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Open 100+ Category & Queue Manager', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/categories');
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);

                  final newName = nameCtrl.text.trim();
                  final String? bizId = currentBusiness?.id ?? ref.read(selectedBusinessIdProvider);

                  if (bizId != null && bizId.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('businesses').doc(bizId).update({
                      'name': newName,
                      'category': selectedCategory,
                      'subCategory': validSubCategory,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await user.updateDisplayName(newName);
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                        'displayName': newName,
                      }, SetOptions(merge: true));
                    }
                  } catch (_) {}

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Business profile updated to "$newName"!')),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
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
