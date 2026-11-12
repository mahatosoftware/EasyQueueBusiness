import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  void _showInviteEmployeeDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    EmployeeRole selectedRole = EmployeeRole.counterOperator;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Invite Staff Member',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EmployeeRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Staff Role',
                        border: OutlineInputBorder(),
                      ),
                      items: EmployeeRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.toDisplayString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in name and email')),
                          );
                          return;
                        }

                        final bizId = ref.read(selectedBusinessIdProvider);
                        final branchId = ref.read(selectedBranchIdProvider);

                        await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(bizId)
                            .collection('employees')
                            .add({
                          'businessId': bizId,
                          'branchIds': [branchId],
                          'name': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'phoneNumber': phoneCtrl.text.trim(),
                          'role': selectedRole.toApiString(),
                          'isActive': true,
                          'joinedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invitation sent to staff member!')),
                          );
                        }
                      },
                      child: const Text('Send Invitation', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getRoleBadgeColor(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.owner:
        return Colors.purple;
      case EmployeeRole.branchManager:
        return Colors.blue;
      case EmployeeRole.supervisor:
        return Colors.teal;
      case EmployeeRole.counterOperator:
        return Colors.green;
      case EmployeeRole.receptionist:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & Permissions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Invite Staff'),
        onPressed: _showInviteEmployeeDialog,
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No staff members found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Invite team members to manage counters and queues.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.floatingActionBottomPadding),
            itemCount: employees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final employee = employees[idx];
              final roleColor = _getRoleBadgeColor(employee.role);

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'S',
                      style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          employee.role.toDisplayString(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(employee.email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      if (employee.phoneNumber != null && employee.phoneNumber!.isNotEmpty)
                        Text(employee.phoneNumber!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Switch(
                    value: employee.isActive,
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) async {
                      final bizId = ref.read(selectedBusinessIdProvider);
                      await FirebaseFirestore.instance
                          .collection('businesses')
                          .doc(bizId)
                          .collection('employees')
                          .doc(employee.id)
                          .update({'isActive': val});
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading employees: $err')),
      ),
    );
  }
}
