import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';
import '../auth/auth_service.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key});

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  void _showAddBranchDialog(BuildContext context) => _showBranchDialog(context);

  void _showBranchDialog(BuildContext context, [BranchModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.contactNumber ?? '');
    final formKey = GlobalKey<FormState>();
    String selectedStatus = existing?.status ?? 'ACTIVE';
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Add New Branch' : 'Edit Branch Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Branch Name *',
                      hintText: 'e.g. Mysuru Central',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter branch name';
                      }
                      if (val.trim().length > 120) {
                        return 'Branch name cannot exceed 120 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Branch Code',
                      hintText: 'e.g. MYS01 (auto-generated if empty)',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().length > 20) {
                        return 'Branch code cannot exceed 20 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'e.g. 100ft Road, Indiranagar',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().length > 300) {
                        return 'Address cannot exceed 300 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().length > 30) {
                        return 'Phone number cannot exceed 30 characters';
                      }
                      return null;
                    },
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.tune_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                        DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim().isNotEmpty
                            ? codeCtrl.text.trim().toUpperCase()
                            : (name.length >= 3 ? name.substring(0, 3).toUpperCase() : 'BR');
                        final address = addressCtrl.text.trim().isNotEmpty
                            ? addressCtrl.text.trim()
                            : '$name Facility';

                        if (existing != null) {
                          // UPDATE EXISTING BRANCH
                          String bizId = existing.businessId;
                          if (bizId.isEmpty) {
                            bizId = ref.read(selectedBusinessIdProvider);
                          }
                          if (bizId.isEmpty) {
                            final currentBiz = ref.read(currentBusinessProvider);
                            if (currentBiz != null) bizId = currentBiz.id;
                          }

                          if (bizId.isEmpty) {
                            throw Exception('Could not resolve active business. Please sign in again.');
                          }

                          final branchRef = FirebaseFirestore.instance
                              .collection('businesses')
                              .doc(bizId)
                              .collection('branches')
                              .doc(existing.id);

                          final updateData = <String, dynamic>{
                            'name': name,
                            'code': code,
                            'address': address,
                            'contactNumber': phoneCtrl.text.trim(),
                            'status': selectedStatus,
                            'updatedAt': FieldValue.serverTimestamp(),
                          };

                          await branchRef.update(updateData);

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Branch "$name" updated successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } else {
                          // CREATE NEW BRANCH
                          // 1. Resolve business ID safely
                          String bizId = ref.read(selectedBusinessIdProvider);
                          if (bizId.isEmpty) {
                            final currentBiz = ref.read(currentBusinessProvider);
                            if (currentBiz != null) bizId = currentBiz.id;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          if (bizId.isEmpty && user != null) {
                            // Check user profile for defaultBusinessId
                            try {
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();
                              if (userDoc.exists) {
                                final profileBizId = userDoc.data()?['defaultBusinessId'] as String?;
                                if (profileBizId != null && profileBizId.isNotEmpty) {
                                  bizId = profileBizId;
                                }
                              }
                            } catch (_) {}

                            // If still empty, check owned businesses
                            if (bizId.isEmpty) {
                              final snap = await FirebaseFirestore.instance
                                  .collection('businesses')
                                  .where('ownerId', isEqualTo: user.uid)
                                  .limit(1)
                                  .get();
                              if (snap.docs.isNotEmpty) {
                                bizId = snap.docs.first.id;
                              } else {
                                final auth = ref.read(authServiceProvider);
                                bizId = await auth.createProductionBusiness(
                                  businessName: user.displayName ?? 'My Organization',
                                );
                              }
                            }
                            ref.read(selectedBusinessIdProvider.notifier).state = bizId;
                          }

                          if (bizId.isEmpty) {
                            throw Exception('Could not resolve active business. Please sign in again.');
                          }

                          final branchId = 'branch_${DateTime.now().millisecondsSinceEpoch}';

                          final batch = FirebaseFirestore.instance.batch();

                          // Create Branch Document
                          final branchRef = FirebaseFirestore.instance
                              .collection('businesses')
                              .doc(bizId)
                              .collection('branches')
                              .doc(branchId);

                          batch.set(branchRef, {
                            'id': branchId,
                            'businessId': bizId,
                            'name': name,
                            'code': code,
                            'address': address,
                            if (phoneCtrl.text.trim().isNotEmpty) 'contactNumber': phoneCtrl.text.trim(),
                            'status': 'ACTIVE',
                            'createdAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          // Create Default Service for the new branch
                          const serviceId = 'service_1';
                          final serviceRef = branchRef.collection('services').doc(serviceId);
                          batch.set(serviceRef, {
                            'id': serviceId,
                            'branchId': branchId,
                            'businessId': bizId,
                            'name': 'General Service',
                            'code': 'A',
                            'estimatedDurationMinutes': 15,
                            'status': 'ACTIVE',
                            'isActive': true,
                            'createdAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          // Create Default Counter for the new branch
                          const counterId = 'counter_1';
                          final counterRef = branchRef.collection('counters').doc(counterId);
                          final uid = user?.uid;
                          batch.set(counterRef, {
                            'id': counterId,
                            'branchId': branchId,
                            'businessId': bizId,
                            'counterNumber': 1,
                            'name': 'Counter 1',
                            'displayLabel': 'Counter 1',
                            'supportedServiceIds': [serviceId],
                            'assignedOperatorIds': uid != null ? [uid] : [],
                            'status': 'AVAILABLE',
                            'createdAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          await batch.commit();

                          // Update Member's assigned branches so owner/manager has immediate access
                          if (uid != null) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('businesses')
                                  .doc(bizId)
                                  .collection('members')
                                  .doc(uid)
                                  .set({
                                'assignedBranchIds': FieldValue.arrayUnion([branchId]),
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                            } catch (_) {}
                          }

                          // Switch active branch to the newly created branch
                          ref.read(selectedBranchIdProvider.notifier).state = branchId;

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Branch "$name" created successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          if (e is FirebaseException && e.code == 'permission-denied') {
                            errorMessage = 'Permission Denied: Only Business Owners and Managers can modify branches. '
                                'If you are an owner, please ensure the updated Firestore Security Rules have been deployed.';
                          } else {
                            errorMessage = e.toString().replaceFirst('Exception: ', '');
                          }
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(existing == null ? 'Create Branch' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesStreamProvider);
    final activeBranchId = ref.watch(selectedBranchIdProvider);
    final currentBusiness = ref.watch(currentBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Branch Management'),
            if (currentBusiness != null)
              Text(
                currentBusiness.name,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Branch',
            onPressed: () => _showAddBranchDialog(context),
          ),
        ],
      ),
      body: branchesAsync.when(
        data: (branches) {
          if (branches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No branches found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first branch to organize queues and counters.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddBranchDialog(context),
                    label: const Text('Add First Branch'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.floatingActionBottomPadding),
            itemCount: branches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final branch = branches[idx];
              final isCurrent = branch.id == activeBranchId;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isCurrent ? Theme.of(context).colorScheme.primary : const Color(0xFFE2E8F0),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () => _showBranchDialog(context, branch),
                  leading: CircleAvatar(
                    backgroundColor: isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                    foregroundColor: isCurrent ? Colors.white : Colors.black87,
                    child: Text(branch.code.isNotEmpty ? branch.code : 'B'),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          branch.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('CURRENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      if (branch.status != 'ACTIVE') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: branch.status == 'CLOSED' ? Colors.red.shade100 : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            branch.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: branch.status == 'CLOSED' ? Colors.red.shade800 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    branch.address.isNotEmpty
                        ? '${branch.address} • Code: ${branch.code}'
                        : 'Code: ${branch.code} • Status: ${branch.status}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent)
                        const Icon(Icons.check_circle, color: Color(0xFF10B981))
                      else
                        OutlinedButton(
                          onPressed: () {
                            ref.read(selectedBranchIdProvider.notifier).state = branch.id;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Switched to ${branch.name}')),
                            );
                          },
                          child: const Text('Switch'),
                        ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Branch',
                        onPressed: () => _showBranchDialog(context, branch),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error loading branches: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(branchesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBranchDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Branch'),
      ),
    );
  }
}
