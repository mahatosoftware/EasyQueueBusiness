import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';
import 'create_counter_dialog.dart';

class CountersScreen extends ConsumerStatefulWidget {
  const CountersScreen({super.key});

  @override
  ConsumerState<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends ConsumerState<CountersScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Counters'),
                const SizedBox(width: 8),
                _buildFilterChip('AVAILABLE', 'Available'),
                const SizedBox(width: 8),
                _buildFilterChip('BUSY', 'Serving (Busy)'),
                const SizedBox(width: 8),
                _buildFilterChip('PAUSED', 'Paused'),
                const SizedBox(width: 8),
                _buildFilterChip('CLOSED', 'Closed'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Counters List
          Expanded(
            child: countersAsync.when(
              data: (counters) {
                final filtered = counters.where((c) {
                  if (_selectedFilter == 'ALL') return true;
                  return c.status.toApiString() == _selectedFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.desktop_windows_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No counters match filter "$_selectedFilter"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.floatingActionBottomPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.88,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final counter = filtered[idx];
                    return _CounterCard(counter: counter);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open new counter dialog or wizard
          _showCreateCounterDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Counter'),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filterKey);
      },
    );
  }

  void _showCreateCounterDialog(BuildContext context) {
    showCreateCounterDialog(context, ref);
  }
}

class _CounterCard extends ConsumerWidget {
  final CounterModel counter;

  const _CounterCard({required this.counter});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor();

    return InkWell(
      onTap: () {
        context.push('/counters/workspace/${counter.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: counter.status == CounterStatus.busy ? Colors.blue.shade300 : const Color(0xFFE2E8F0),
            width: counter.status == CounterStatus.busy ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Text(
                      '${counter.counterNumber}',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => showCreateCounterDialog(context, ref, counter),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.settings_outlined, size: 16, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                counter.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                counter.supportedServiceIds.isEmpty
                    ? 'All Services'
                    : '${counter.supportedServiceIds.length} Services Supported',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (counter.currentTokenNumber != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CURRENT TOKEN',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      Text(
                        counter.currentTokenNumber!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      counter.status.toApiString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
