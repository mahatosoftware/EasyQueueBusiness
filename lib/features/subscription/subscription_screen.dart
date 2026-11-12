import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static const List<SubscriptionPlanModel> plans = [
    SubscriptionPlanModel(
      name: 'Starter',
      code: 'STARTER',
      priceMonthly: 'Free',
      maxBranches: 1,
      maxCounters: 2,
      maxMonthlyTokens: 500,
      features: [
        '1 Branch location',
        'Up to 2 active counters',
        'Basic queue display mode',
        'Walk-in customer registration',
        'Community support',
      ],
      isCurrent: false,
    ),
    SubscriptionPlanModel(
      name: 'Growth',
      code: 'GROWTH',
      priceMonthly: '₹1,499/mo',
      maxBranches: 3,
      maxCounters: 8,
      maxMonthlyTokens: 3000,
      features: [
        'Up to 3 branch locations',
        'Up to 8 active counters',
        'Multi-service auto-allocation engine',
        'Full HD TV Queue Display with voice chime',
        'Appointment booking & check-in',
        'Exportable CSV & daily reports',
      ],
      isCurrent: false,
    ),
    SubscriptionPlanModel(
      name: 'Professional',
      code: 'PRO',
      priceMonthly: '₹3,999/mo',
      maxBranches: 10,
      maxCounters: 25,
      maxMonthlyTokens: 15000,
      features: [
        'Up to 10 branch locations',
        'Up to 25 active counters',
        'Priority category rule weights',
        'Dynamic wait time prediction',
        'Multi-role employee permissions',
        'Unlimited TV display screens',
        'Full operational audit trail',
        'Priority 24/7 support',
      ],
      isCurrent: true,
    ),
    SubscriptionPlanModel(
      name: 'Enterprise',
      code: 'ENTERPRISE',
      priceMonthly: 'Custom',
      maxBranches: 999,
      maxCounters: 999,
      maxMonthlyTokens: 999999,
      features: [
        'Unlimited branches & counters',
        'Dedicated Cloud Firestore instance',
        'Custom domain & white-label kiosk',
        'Custom SMS & WhatsApp gateway',
        'SLA guarantee & Dedicated account manager',
      ],
      isCurrent: false,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countersAsync = ref.watch(countersStreamProvider);
    final branchesAsync = ref.watch(branchesStreamProvider);
    final completedAsync = ref.watch(completedQueueEntriesProvider);

    final countersCount = countersAsync.valueOrNull?.length ?? 0;
    final branchesCount = branchesAsync.valueOrNull?.length ?? 0;
    final tokensUsed = completedAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Usage Limits'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Plan & Quota Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ACTIVE PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 2),
                            Text('Professional Tier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Quota 1: Counters
                    _buildQuotaProgress(
                      context,
                      label: 'Counters Provisioned',
                      used: countersCount,
                      max: 25,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 14),

                    // Quota 2: Branches
                    _buildQuotaProgress(
                      context,
                      label: 'Branch Locations',
                      used: branchesCount,
                      max: 10,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 14),

                    // Quota 3: Tokens
                    _buildQuotaProgress(
                      context,
                      label: 'Monthly Tokens Served',
                      used: tokensUsed,
                      max: 15000,
                      color: AppConstants.statusAvailable,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Available Plans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Plan Cards
            ...plans.map((p) => _buildPlanCard(context, p)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaProgress(
    BuildContext context, {
    required String label,
    required int used,
    required int max,
    required Color color,
  }) {
    final ratio = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('$used / $max', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlanModel plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: plan.isCurrent ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: plan.isCurrent ? Theme.of(context).colorScheme.primary : const Color(0xFFE2E8F0),
          width: plan.isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  plan.priceMonthly,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: plan.isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Current Plan'),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Switch to ${plan.name} Plan'),
                            content: Text(
                              'Upgrade to the ${plan.name} tier (${plan.priceMonthly}) to expand your branch and counter limits with full multi-service auto-allocation.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Plan upgrade to ${plan.name} processed!')),
                                  );
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text('Select ${plan.name}'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
