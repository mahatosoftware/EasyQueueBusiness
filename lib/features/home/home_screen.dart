import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countersAsync = ref.watch(countersStreamProvider);
    final activeEntriesAsync = ref.watch(activeQueueEntriesProvider);
    final completedEntriesAsync = ref.watch(completedQueueEntriesProvider);

    final waitingCount = activeEntriesAsync.valueOrNull?.where((e) => e.status == EntryStatus.waiting).length ?? 0;
    final servingCount = activeEntriesAsync.valueOrNull?.where((e) => e.status == EntryStatus.serving || e.status == EntryStatus.called).length ?? 0;
    final completedCount = completedEntriesAsync.valueOrNull?.where((e) => e.status == EntryStatus.completed).length ?? 0;

    final counters = countersAsync.valueOrNull ?? [];
    final activeCountersCount = counters.where((c) => c.status == CounterStatus.available || c.status == CounterStatus.busy).length;

    final currentBusiness = ref.watch(currentBusinessProvider);
    final currentBranch = ref.watch(currentBranchProvider);

    final hasError = countersAsync.hasError || activeEntriesAsync.hasError || completedEntriesAsync.hasError;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(AppConstants.logoIconPath, fit: BoxFit.cover),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentBusiness?.name ?? AppConstants.appName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  currentBranch?.name ?? 'Main Branch',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tv),
            tooltip: 'Queue TV Display Mode',
            onPressed: () => context.push('/display'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(countersStreamProvider);
          ref.invalidate(activeQueueEntriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
          children: [
            if (hasError) ...[
              Card(
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.amber.shade900),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Authentication & Permissions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const Text(
                              'Sign in to access your business queues and counters.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Live Status KPI Cards
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Waiting',
                    value: '$waitingCount',
                    icon: Icons.people_outline,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Serving',
                    value: '$servingCount',
                    icon: Icons.person_pin,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Active Counters',
                    value: '$activeCountersCount/${counters.length}',
                    icon: Icons.desktop_windows,
                    color: AppConstants.statusAvailable,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Served Today',
                    value: '$completedCount',
                    icon: Icons.check_circle_outline,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Walk-in'),
                    onPressed: () => context.go('/customers/walk-in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Counter Cockpit'),
                    onPressed: () => context.go('/counters'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Appointments'),
                    onPressed: () => context.push('/appointments'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('QR Poster'),
                    onPressed: () => context.push('/qr'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live Counter Overview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Counter Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/counters'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            countersAsync.when(
              data: (counterList) {
                if (counterList.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.desktop_access_disabled, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('No counters configured for this branch.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.go('/more'),
                            child: const Text('Configure Counters'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: counterList.map((c) => _CounterTile(counter: c)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading counters: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  final CounterModel counter;

  const _CounterTile({required this.counter});

  Color _getStatusColor() {
    switch (counter.status) {
      case CounterStatus.available:
        return AppConstants.statusAvailable;
      case CounterStatus.busy:
        return AppConstants.statusBusy;
      case CounterStatus.paused:
      case CounterStatus.onBreak:
        return AppConstants.statusPaused;
      case CounterStatus.closed:
      case CounterStatus.offline:
      case CounterStatus.maintenance:
        return AppConstants.statusClosed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(
            '${counter.counterNumber}',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          counter.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          counter.currentTokenNumber != null
              ? 'Serving: ${counter.currentTokenNumber}'
              : 'Status: ${counter.status.toApiString()}',
          style: TextStyle(
            color: counter.currentTokenNumber != null ? Colors.blue.shade700 : Colors.grey.shade600,
            fontWeight: counter.currentTokenNumber != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            counter.status.toApiString(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
        onTap: () {
          context.push('/counters/workspace/${counter.id}');
        },
      ),
    );
  }
}
