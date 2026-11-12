import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';

void showCreateCounterDialog(BuildContext context, WidgetRef ref, [CounterModel? existing]) {
  final services = ref.read(servicesStreamProvider).valueOrNull ?? [];
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final numCtrl = TextEditingController(text: '${existing?.counterNumber ?? (ref.read(countersStreamProvider).valueOrNull?.length ?? 0) + 1}');
  final displayLabelCtrl = TextEditingController(text: existing?.displayLabel ?? '');

  final selectedServices = List<String>.from(existing?.supportedServiceIds ?? []);
  if (selectedServices.isEmpty && existing == null && services.isNotEmpty) {
    // By default for new counters, support all services in the branch
    selectedServices.addAll(services.map((s) => s.id));
  }

  bool autoAllocation = existing?.autoAllocationEnabled ?? true;
  int priority = 1;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Configure New Counter' : 'Edit Counter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: numCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'No.'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Counter Name (e.g. Window 1)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: displayLabelCtrl,
                decoration: const InputDecoration(labelText: 'Display Label (e.g. Desk A - Cashier)'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Supported Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (services.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedServices.clear();
                              selectedServices.addAll(services.map((s) => s.id));
                            });
                          },
                          child: const Text('All', style: TextStyle(fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedServices.clear();
                            });
                          },
                          child: const Text('Clear', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                selectedServices.isEmpty
                    ? 'No specific services selected: counter will serve ALL branch services.'
                    : 'Counter will prioritize tickets from ${selectedServices.length} selected services.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              if (services.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No services found in branch. Create services first.'),
                )
              else
                ...services.map((svc) {
                  final isChecked = selectedServices.contains(svc.id);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${svc.name} (${svc.code})'),
                    value: isChecked,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedServices.add(svc.id);
                        } else {
                          selectedServices.remove(svc.id);
                        }
                      });
                    },
                  );
                }),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-Allocation Engine', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Allow system to automatically push waiting tokens to this counter', style: TextStyle(fontSize: 11)),
                value: autoAllocation,
                onChanged: (val) => setDialogState(() => autoAllocation = val),
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
              final counterId = existing?.id ?? 'counter_${DateTime.now().millisecondsSinceEpoch}';
              final uid = FirebaseAuth.instance.currentUser?.uid;

              await FirebaseFirestore.instance
                  .collection('businesses')
                  .doc(bizId)
                  .collection('branches')
                  .doc(branchId)
                  .collection('counters')
                  .doc(counterId)
                  .set({
                'id': counterId,
                'businessId': bizId,
                'branchId': branchId,
                'name': name,
                'counterNumber': int.tryParse(numCtrl.text.trim()) ?? 1,
                'displayLabel': displayLabelCtrl.text.trim().isEmpty ? name : displayLabelCtrl.text.trim(),
                'supportedServiceIds': selectedServices,
                'assignedOperatorIds': uid != null ? [uid] : [],
                'status': existing?.status.toApiString() ?? 'AVAILABLE',
                'maxSimultaneousCapacity': 1,
                'autoAllocationEnabled': autoAllocation,
                'allocationPriority': priority,
                'lastHeartbeatAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Counter "$name" saved successfully!')),
                );
              }
            },
            child: Text(existing == null ? 'Create Counter' : 'Save Changes'),
          ),
        ],
      ),
    ),
  );
}
