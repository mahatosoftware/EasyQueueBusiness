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

    final currentBiz = ref.read(currentBusinessProvider);
    final orgCat = OrganizationCategoryManager.findCategory(currentBiz?.category);
    final orgSub = OrganizationCategoryManager.findSubCategory(currentBiz?.category, currentBiz?.subCategory);
    final templates = (orgSub != null && orgSub.defaultServices.isNotEmpty)
        ? orgSub.defaultServices
        : orgCat.defaultServices;
    final displayLabel = orgSub != null
        ? '${orgCat.name} • ${orgSub.name}'
        : orgCat.name;

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
                if (existing == null && templates.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(orgSub?.icon ?? orgCat.icon, size: 16, color: const Color(0xFF1D4ED8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$displayLabel Templates',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: templates.map((tpl) {
                            return ActionChip(
                              avatar: CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB),
                                radius: 9,
                                child: Text(tpl.code, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              label: Text(tpl.name, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setDialogState(() {
                                  nameCtrl.text = tpl.name;
                                  codeCtrl.text = tpl.code;
                                  durationCtrl.text = '${tpl.durationMinutes}';
                                  capacityCtrl.text = '${tpl.maxCapacity}';
                                  allowWalkIn = tpl.allowWalkIn;
                                  supportsPriority = tpl.supportsPriority;
                                  allocationPolicy = tpl.allocationPolicy;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
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
            final currentBiz = ref.watch(currentBusinessProvider);
            final orgCat = OrganizationCategoryManager.findCategory(currentBiz?.category);
            final orgSub = OrganizationCategoryManager.findSubCategory(currentBiz?.category, currentBiz?.subCategory);
            final templates = (orgSub != null && orgSub.defaultServices.isNotEmpty)
                ? orgSub.defaultServices
                : orgCat.defaultServices;
            final displayLabel = orgSub != null
                ? '${orgCat.name} • ${orgSub.name}'
                : orgCat.name;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(orgSub?.icon ?? orgCat.icon, size: 64, color: Colors.blue.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No services configured for $displayLabel.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start with recommended queues tailored for $displayLabel or create a custom service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    if (templates.isNotEmpty) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: Text('Load $displayLabel Services (${templates.length})'),
                        onPressed: () async {
                          final bizId = ref.read(selectedBusinessIdProvider);
                          final branchId = ref.read(selectedBranchIdProvider);
                          if (bizId.isEmpty || branchId.isEmpty) return;

                          final batch = FirebaseFirestore.instance.batch();

                          for (int i = 0; i < templates.length; i++) {
                            final tpl = templates[i];
                            final sId = 'service_${DateTime.now().millisecondsSinceEpoch}_$i';

                            final sRef = FirebaseFirestore.instance
                                .collection('businesses')
                                .doc(bizId)
                                .collection('branches')
                                .doc(branchId)
                                .collection('services')
                                .doc(sId);
                            batch.set(sRef, {
                              'id': sId,
                              'businessId': bizId,
                              'branchId': branchId,
                              'name': tpl.name,
                              'code': tpl.code,
                              'estimatedDurationMinutes': tpl.durationMinutes,
                              'description': tpl.description,
                              'maxQueueCapacity': tpl.maxCapacity,
                              'allowWalkIn': tpl.allowWalkIn,
                              'supportsPriority': tpl.supportsPriority,
                              'allocationPolicy': tpl.allocationPolicy,
                              'status': 'ACTIVE',
                              'isActive': true,
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            final qRef = FirebaseFirestore.instance
                                .collection('businesses')
                                .doc(bizId)
                                .collection('branches')
                                .doc(branchId)
                                .collection('queues')
                                .doc(sId);
                            batch.set(qRef, {
                              'id': sId,
                              'businessId': bizId,
                              'branchId': branchId,
                              'serviceId': sId,
                              'tokenPrefix': tpl.code,
                              'tokenSequenceDate': DateTime.now().toIso8601String().substring(0, 10),
                              'lastTokenNumber': 0,
                              'waitingCount': 0,
                              'calledCount': 0,
                              'servingCount': 0,
                              'completedCount': 0,
                              'status': 'OPEN',
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                          }

                          await batch.commit();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Configured ${templates.length} starter services for $displayLabel!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton(
                      onPressed: () => _showAddServiceDialog(context),
                      child: const Text('Create Custom Service'),
                    ),
                  ],
                ),
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
