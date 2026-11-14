import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';
import '../../core/services/functions_service.dart';
import 'create_counter_dialog.dart';

class OperatorWorkspaceScreen extends ConsumerStatefulWidget {
  final String counterId;

  const OperatorWorkspaceScreen({super.key, required this.counterId});

  @override
  ConsumerState<OperatorWorkspaceScreen> createState() => _OperatorWorkspaceScreenState();
}

class _OperatorWorkspaceScreenState extends ConsumerState<OperatorWorkspaceScreen> {
  bool _isLoading = false;
  Timer? _serviceTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _serviceTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _serviceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleCallNext(CounterModel counter) async {
    setState(() => _isLoading = true);
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      final res = await fn.callNextCustomer(
        businessId: bizId,
        branchId: branchId,
        counterId: counter.id,
      );

      if (mounted) {
        if (res['hasCustomer'] == true) {
          final entry = res['entry'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Called customer token ${entry['tokenNumber']}!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'No customers waiting.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartService(String entryId) async {
    setState(() => _isLoading = true);
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      await fn.startServing(
        businessId: bizId,
        branchId: branchId,
        counterId: widget.counterId,
        entryId: entryId,
      );
      _elapsedSeconds = 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service started! Timer running.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCompleteService(String entryId) async {
    setState(() => _isLoading = true);
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      await fn.completeService(
        businessId: bizId,
        branchId: branchId,
        counterId: widget.counterId,
        entryId: entryId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service completed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRecall(String entryId) async {
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      await fn.recallCustomer(
        businessId: bizId,
        branchId: branchId,
        counterId: widget.counterId,
        entryId: entryId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer recall announcement triggered!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleNoShow(String entryId) async {
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      await fn.markCustomerNoShow(
        businessId: bizId,
        branchId: branchId,
        counterId: widget.counterId,
        entryId: entryId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token marked as No-Show.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleToggleCounterStatus(String action, [String? reason]) async {
    setState(() => _isLoading = true);
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      await fn.toggleCounterStatus(
        action: action,
        businessId: bizId,
        branchId: branchId,
        counterId: widget.counterId,
        reason: reason,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSkipDialog(String entryId) {
    String selectedReason = 'Customer not ready';
    String requeuePolicy = 'END_OF_QUEUE';
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Skip Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select reason for skipping:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: const [
                  DropdownMenuItem(value: 'Customer not ready', child: Text('Customer not ready')),
                  DropdownMenuItem(value: 'Missing documents', child: Text('Missing documents')),
                  DropdownMenuItem(value: 'Customer stepped away', child: Text('Customer stepped away')),
                  DropdownMenuItem(value: 'Special assistance needed', child: Text('Special assistance needed')),
                  DropdownMenuItem(value: 'Other reason', child: Text('Other reason')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Requeue Policy:'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'END_OF_QUEUE', label: Text('End of Line')),
                  ButtonSegment(value: 'CLOSE_AS_SKIPPED', label: Text('Drop Token')),
                ],
                selected: {requeuePolicy},
                onSelectionChanged: (val) => setModalState(() => requeuePolicy = val.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final fn = ref.read(functionsServiceProvider);
                  final bizId = ref.read(selectedBusinessIdProvider);
                  final branchId = ref.read(selectedBranchIdProvider);
                  await fn.skipCustomer(
                    businessId: bizId,
                    branchId: branchId,
                    counterId: widget.counterId,
                    entryId: entryId,
                    reason: selectedReason,
                    requeuePolicy: requeuePolicy,
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text('Customer skipped: $selectedReason')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error skipping: $e'), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDialog(QueueEntryModel entry) {
    final services = ref.read(servicesStreamProvider).valueOrNull ?? [];
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other services available for transfer.')),
      );
      return;
    }

    String selectedServiceId = services.first.id;
    final reasonCtrl = TextEditingController(text: 'Referred for subsequent service');
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Transfer Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transfer token ${entry.tokenNumber} (${entry.customerName}) to:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedServiceId,
                decoration: const InputDecoration(labelText: 'Target Service', border: OutlineInputBorder()),
                items: services.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.code})'))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedServiceId = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Transfer Reason', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final fn = ref.read(functionsServiceProvider);
                  final bizId = ref.read(selectedBusinessIdProvider);
                  final branchId = ref.read(selectedBranchIdProvider);
                  await fn.transferCustomer(
                    businessId: bizId,
                    sourceBranchId: branchId,
                    sourceCounterId: widget.counterId,
                    sourceEntryId: entry.id,
                    targetServiceId: selectedServiceId,
                    transferReason: reasonCtrl.text.trim(),
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text('Token ${entry.tokenNumber} transferred successfully!')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error transferring: $e'), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Transfer Token'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotesDialog(QueueEntryModel entry) {
    final notesCtrl = TextEditingController(text: entry.notes ?? '');
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Customer Notes - ${entry.tokenNumber}'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter observation, prescription, or operational notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('queueEntries').doc(entry.id).update({
                'customer.notes': notesCtrl.text.trim(),
              });
              messenger.showSnackBar(
                const SnackBar(content: Text('Customer notes updated!')),
              );
            },
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  void _showHandoverDialog(CounterModel counter) {
    final employees = ref.read(employeesStreamProvider).valueOrNull ?? [];
    String? selectedEmployeeName = employees.isNotEmpty ? employees.first.name : 'Operator';
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Shift Handover'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hand over ${counter.name} to another operator:'),
              const SizedBox(height: 12),
              if (employees.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedEmployeeName,
                  decoration: const InputDecoration(labelText: 'Incoming Operator', border: OutlineInputBorder()),
                  items: employees.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(),
                  onChanged: (val) => setModalState(() => selectedEmployeeName = val),
                )
              else
                const Text('No other staff members found. Invite staff in Settings > Employee Management.'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final bizId = ref.read(selectedBusinessIdProvider);
                final branchId = ref.read(selectedBranchIdProvider);
                await FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(bizId)
                    .collection('branches')
                    .doc(branchId)
                    .collection('counters')
                    .doc(counter.id)
                    .update({
                  'currentOperatorName': selectedEmployeeName,
                });
                messenger.showSnackBar(
                  SnackBar(content: Text('Counter handed over to $selectedEmployeeName')),
                );
              },
              child: const Text('Confirm Handover'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersStreamProvider);
    final activeEntriesAsync = ref.watch(activeQueueEntriesProvider);
    final completedEntriesAsync = ref.watch(completedQueueEntriesProvider);

    final counter = countersAsync.valueOrNull?.where((c) => c.id == widget.counterId).firstOrNull;

    if (counter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Operator Workspace')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final servedTodayCount = completedEntriesAsync.valueOrNull
            ?.where((e) => e.assignedCounterId == widget.counterId && e.status == EntryStatus.completed)
            .length ??
        0;

    // Current entry if active
    final currentEntry = activeEntriesAsync.valueOrNull?.where((e) => e.id == counter.currentEntryId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              counter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${counter.status.toApiString()} • $servedTodayCount served today',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: _getStatusColor(counter.status)),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'OPEN') _handleToggleCounterStatus('OPEN');
              if (val == 'PAUSE') _handleToggleCounterStatus('PAUSE', 'Operator Break');
              if (val == 'RESUME') _handleToggleCounterStatus('RESUME');
              if (val == 'CLOSE') _handleToggleCounterStatus('CLOSE');
              if (val == 'HANDOVER') _showHandoverDialog(counter);
              if (val == 'CONFIGURE') showCreateCounterDialog(context, ref, counter);
            },
            itemBuilder: (ctx) => [
              if (counter.status == CounterStatus.closed)
                const PopupMenuItem(value: 'OPEN', child: Text('Open Counter')),
              if (counter.status == CounterStatus.available)
                const PopupMenuItem(value: 'PAUSE', child: Text('Pause Counter (Break)')),
              if (counter.status == CounterStatus.paused)
                const PopupMenuItem(value: 'RESUME', child: Text('Resume Counter')),
              if (counter.status != CounterStatus.closed)
                const PopupMenuItem(value: 'CLOSE', child: Text('Close Counter')),
              const PopupMenuItem(value: 'HANDOVER', child: Text('Shift Handover')),
              const PopupMenuItem(value: 'CONFIGURE', child: Text('Configure Counter & Services')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Active Token Card or Idle Card
                  if (counter.currentTokenNumber != null && currentEntry != null) ...[
                    _buildActiveTokenCard(currentEntry),
                  ] else if (counter.status == CounterStatus.closed) ...[
                    _buildClosedCard(),
                  ] else if (counter.status == CounterStatus.paused) ...[
                    _buildPausedCard(),
                  ] else ...[
                    _buildIdleCard(counter),
                  ],

                  const Spacer(),

                  // Bottom Action Dock
                  if (counter.currentTokenNumber != null && currentEntry != null) ...[
                    if (currentEntry.status == EntryStatus.called) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              icon: const Icon(Icons.volume_up),
                              label: const Text('Recall'),
                              onPressed: () => _handleRecall(currentEntry.id),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                foregroundColor: Colors.orange.shade800,
                              ),
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Skip'),
                              onPressed: () => _showSkipDialog(currentEntry.id),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                foregroundColor: Colors.red,
                              ),
                              icon: const Icon(Icons.person_off),
                              label: const Text('No-Show'),
                              onPressed: () => _handleNoShow(currentEntry.id),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Start Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        onPressed: () => _handleStartService(currentEntry.id),
                      ),
                    ] else if (currentEntry.status == EntryStatus.serving) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Transfer'),
                              onPressed: () => _showTransferDialog(currentEntry),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              icon: const Icon(Icons.note_alt_outlined),
                              label: const Text('Notes'),
                              onPressed: () => _showNotesDialog(currentEntry),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.statusAvailable,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              onPressed: () => _handleCompleteService(currentEntry.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else if (counter.status == CounterStatus.available) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      icon: const Icon(Icons.notifications_active, size: 28),
                      label: const Text('Call Next Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleCallNext(counter),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildActiveTokenCard(QueueEntryModel entry) {
    final isServing = entry.status == EntryStatus.serving;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isServing ? AppConstants.statusAvailable : Colors.blue, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isServing ? AppConstants.statusAvailable.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isServing ? 'NOW SERVING' : 'CALLED - AWAITING ARRIVAL',
                style: TextStyle(
                  color: isServing ? AppConstants.statusAvailable : Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                entry.tokenNumber,
                style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.customerName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (entry.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.phoneNumber!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Priority: ${entry.priorityCategory}',
                style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            if (isServing) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Service Time: ${_formatDuration(_elapsedSeconds)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFeatures: []),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdleCard(CounterModel counter) {
    final allServices = ref.watch(servicesStreamProvider).valueOrNull ?? [];
    final supportedServiceNames = counter.supportedServiceIds.isEmpty
        ? 'All branch services'
        : allServices
            .where((s) => counter.supportedServiceIds.contains(s.id))
            .map((s) => s.name)
            .join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: AppConstants.statusAvailable),
            const SizedBox(height: 12),
            const Text(
              'Counter Available',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ready for next customer. Tap "Call Next Customer" below to call the highest priority waiting token.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.room_service_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Services: ${supportedServiceNames.isNotEmpty ? supportedServiceNames : "All"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => showCreateCounterDialog(context, ref, counter),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Counter Closed',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open this counter from the top-right menu to start accepting queue allocations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleToggleCounterStatus('OPEN'),
              child: const Text('Open Counter Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.pause_circle_outline, size: 72, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Counter Paused (On Break)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This counter is currently not receiving automatic customer allocations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleToggleCounterStatus('RESUME'),
              child: const Text('Resume Counter'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CounterStatus status) {
    switch (status) {
      case CounterStatus.available:
        return AppConstants.statusAvailable;
      case CounterStatus.busy:
        return Colors.blue;
      case CounterStatus.paused:
      case CounterStatus.onBreak:
        return Colors.orange;
      case CounterStatus.closed:
      default:
        return Colors.grey;
    }
  }
}
