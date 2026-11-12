import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  void _showAddServiceDialog(BuildContext context, [ServiceModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final durationCtrl = TextEditingController(text: '${existing?.estimatedDurationMinutes ?? 10}');
    final capacityCtrl = TextEditingController(text: '100');
    bool allowWalkIn = true;
    bool supportsPriority = true;
    String allocationPolicy = 'FIFO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Create New Service' : 'Edit Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Service Name (e.g. Cardiology, X-Ray)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        maxLength: 3,
                        decoration: const InputDecoration(
                          labelText: 'Prefix Code',
                          hintText: 'e.g. B',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (mins)',
                          hintText: '10',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Queue Capacity',
                    hintText: '100 (0 for unlimited)',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow Walk-in Customers', style: TextStyle(fontSize: 14)),
                  value: allowWalkIn,
                  onChanged: (val) => setDialogState(() => allowWalkIn = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Priority Categories', style: TextStyle(fontSize: 14)),
                  value: supportsPriority,
                  onChanged: (val) => setDialogState(() => supportsPriority = val),
                ),
                const SizedBox(height: 8),
                const Text('Allocation Policy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: allocationPolicy,
                  items: const [
                    DropdownMenuItem(value: 'FIFO', child: Text('First-In First-Out (Standard)')),
                    DropdownMenuItem(value: 'LEAST_BUSY', child: Text('Least Busy Counter')),
                    DropdownMenuItem(value: 'ROUND_ROBIN', child: Text('Round Robin')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => allocationPolicy = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final bizId = ref.read(selectedBusinessIdProvider);
                final branchId = ref.read(selectedBranchIdProvider);
                final serviceId = existing?.id ?? 'service_${DateTime.now().millisecondsSinceEpoch}';

                await FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(bizId)
                    .collection('branches')
                    .doc(branchId)
                    .collection('services')
                    .doc(serviceId)
                    .set({
                  'id': serviceId,
                  'businessId': bizId,
                  'branchId': branchId,
                  'name': name,
                  'code': codeCtrl.text.trim().isEmpty ? 'Q' : codeCtrl.text.trim().toUpperCase(),
                  'estimatedDurationMinutes': int.tryParse(durationCtrl.text.trim()) ?? 10,
                  'maxQueueCapacity': int.tryParse(capacityCtrl.text.trim()) ?? 100,
                  'allowWalkIn': allowWalkIn,
                  'supportsPriority': supportsPriority,
                  'allocationPolicy': allocationPolicy,
                  'status': 'ACTIVE',
                  'updatedAt': FieldValue.serverTimestamp(),
                  if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // Initialize Queue for this service
                await FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(bizId)
                    .collection('branches')
                    .doc(branchId)
                    .collection('queues')
                    .doc(serviceId)
                    .set({
                  'id': serviceId,
                  'businessId': bizId,
                  'branchId': branchId,
                  'serviceId': serviceId,
                  'tokenPrefix': codeCtrl.text.trim().isEmpty ? 'Q' : codeCtrl.text.trim().toUpperCase(),
                  'tokenSequenceDate': DateTime.now().toIso8601String().substring(0, 10),
                  'lastTokenNumber': 0,
                  'waitingCount': 0,
                  'calledCount': 0,
                  'servingCount': 0,
                  'completedCount': 0,
                  'status': 'OPEN',
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Service "$name" saved!')),
                  );
                }
              },
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Service',
            onPressed: () => _showAddServiceDialog(context),
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.room_service_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No services configured for this branch.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showAddServiceDialog(context),
                    child: const Text('Create First Service'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final service = services[idx];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      service.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Prefix: ${service.code} • Est. Duration: ${service.estimatedDurationMinutes}m • Status: ${service.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showAddServiceDialog(context, service),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
