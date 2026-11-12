import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';

class QueuesScreen extends ConsumerWidget {
  const QueuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEntriesAsync = ref.watch(activeQueueEntriesProvider);
    final completedEntriesAsync = ref.watch(completedQueueEntriesProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Queue Monitor'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Waiting'),
              Tab(text: 'Called'),
              Tab(text: 'Serving'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: activeEntriesAsync.when(
          data: (activeEntries) {
            final waitingList = activeEntries.where((e) => e.status == EntryStatus.waiting).toList();
            final calledList = activeEntries.where((e) => e.status == EntryStatus.called).toList();
            final servingList = activeEntries.where((e) => e.status == EntryStatus.serving).toList();

            return TabBarView(
              children: [
                _buildEntryList(context, ref, waitingList, 'No customers currently waiting in queue.'),
                _buildEntryList(context, ref, calledList, 'No customers currently called.'),
                _buildEntryList(context, ref, servingList, 'No customers currently being served.'),
                completedEntriesAsync.when(
                  data: (history) => _buildEntryList(context, ref, history, 'No completed records today.'),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildEntryList(
    BuildContext context,
    WidgetRef ref,
    List<QueueEntryModel> entries,
    String emptyMessage,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final entry = entries[idx];
        return _QueueEntryTile(entry: entry, rank: idx + 1);
      },
    );
  }
}

class _QueueEntryTile extends ConsumerWidget {
  final QueueEntryModel entry;
  final int rank;

  const _QueueEntryTile({required this.entry, required this.rank});

  void _showTokenActionsBottomSheet(BuildContext context, WidgetRef ref) {
    final counters = ref.read(countersStreamProvider).valueOrNull ?? [];
    final availableCounters = counters.where((c) => c.status == CounterStatus.available).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      entry.tokenNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.customerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${entry.numberOfPeople} person • Status: ${entry.status.toApiString()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.priorityCategory,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              if (entry.phoneNumber != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(entry.phoneNumber!, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.notes!,
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Supervisor Manual Assignment Override (UC-020, UC-021)
              if (entry.status == EntryStatus.waiting) ...[
                const Text(
                  'SUPERVISOR ACTIONS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.touch_app),
                  label: const Text('Manual Assign to Counter'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showManualAssignDialog(context, ref, availableCounters);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Upgrade to VIP Priority'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await FirebaseFirestore.instance.collection('queueEntries').doc(entry.id).update({
                      'priorityCategory': 'VIP',
                      'priorityWeight': 5,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Priority boosted to VIP!')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Token Registration'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await FirebaseFirestore.instance.collection('queueEntries').doc(entry.id).update({
                      'status': 'CANCELLED',
                      'completedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token registration cancelled.')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showManualAssignDialog(BuildContext context, WidgetRef ref, List<CounterModel> availableCounters) {
    if (availableCounters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No counters are currently open and available.')),
      );
      return;
    }

    String selectedCounterId = availableCounters.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Manual Counter Allocation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign token ${entry.tokenNumber} directly to:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCounterId,
                decoration: const InputDecoration(labelText: 'Available Counter', border: OutlineInputBorder()),
                items: availableCounters.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedCounterId = val);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'This overrides the automatic FIFO queue algorithm and calls the customer to this counter immediately.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final bizId = ref.read(selectedBusinessIdProvider);
                final branchId = ref.read(selectedBranchIdProvider);
                final selectedCounter = availableCounters.firstWhere((c) => c.id == selectedCounterId);

                final batch = FirebaseFirestore.instance.batch();

                final entryRef = FirebaseFirestore.instance.collection('queueEntries').doc(entry.id);
                batch.update(entryRef, {
                  'status': 'CALLED',
                  'assignedCounterId': selectedCounter.id,
                  'counterName': selectedCounter.name,
                  'calledAt': FieldValue.serverTimestamp(),
                });

                final counterRef = FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(bizId)
                    .collection('branches')
                    .doc(branchId)
                    .collection('counters')
                    .doc(selectedCounter.id);

                batch.update(counterRef, {
                  'status': 'BUSY',
                  'currentEntryId': entry.id,
                  'currentTokenNumber': entry.tokenNumber,
                });

                await batch.commit();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Token ${entry.tokenNumber} manually assigned to ${selectedCounter.name}!')),
                  );
                }
              },
              child: const Text('Assign Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat.jm().format(entry.joinedAt);

    return Card(
      child: ListTile(
        onTap: () => _showTokenActionsBottomSheet(context, ref),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            entry.tokenNumber,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(entry.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (entry.priorityCategory != 'NORMAL') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.priorityCategory,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          'Joined at $timeStr • ${entry.numberOfPeople} person • Est. ${entry.estimatedWaitMinutes}m wait',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: entry.assignedCounterId != null
            ? Chip(
                backgroundColor: Colors.blue.shade50,
                label: Text(
                  entry.counterName ?? 'Counter',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              )
            : Text(
                '#$rank in line',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
              ),
      ),
    );
  }
}
