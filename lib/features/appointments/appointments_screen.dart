import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';
import '../../core/services/functions_service.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _handleCheckIn(AppointmentModel apt) async {
    setState(() => _isLoading = true);
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      final res = await fn.joinQueue(
        businessId: bizId,
        branchId: branchId,
        serviceId: apt.serviceId,
        customerName: apt.customerName,
        phoneNumber: apt.phoneNumber,
        numberOfPeople: 1,
        priorityCategory: 'APPOINTMENT',
        source: 'APPOINTMENT',
        notes: 'Pre-scheduled appointment at ${DateFormat.jm().format(apt.scheduledTime)}',
      );

      final token = res['tokenNumber'] ?? 'A-000';

      // Update Firestore appointment document
      await FirebaseFirestore.instance.collection('appointments').doc(apt.id).update({
        'status': 'CHECKED_IN',
        'tokenNumber': token,
        'checkedInAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Checked In!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer ${apt.customerName} has been assigned token:'),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      token,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Token is placed in the active queue with Appointment Priority weight.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking in: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateAppointmentDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();
    TimeOfDay pickedTime = TimeOfDay.now();
    String? selectedServiceId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final services = ref.read(servicesStreamProvider).valueOrNull ?? [];
            if (selectedServiceId == null && services.isNotEmpty) {
              selectedServiceId = services.first.id;
            }

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
                      'Book New Appointment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (services.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedServiceId,
                        decoration: const InputDecoration(
                          labelText: 'Select Service',
                          border: OutlineInputBorder(),
                        ),
                        items: services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) => setModalState(() => selectedServiceId = val),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(DateFormat('MMM d, yyyy').format(pickedDate)),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: pickedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (d != null) setModalState(() => pickedDate = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(pickedTime.format(context)),
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: pickedTime,
                              );
                              if (t != null) setModalState(() => pickedTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter customer name')),
                          );
                          return;
                        }

                        final scheduledDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        final bizId = ref.read(selectedBusinessIdProvider);
                        final branchId = ref.read(selectedBranchIdProvider);
                        final sName = services.where((s) => s.id == selectedServiceId).firstOrNull?.name ?? 'General Service';

                        await FirebaseFirestore.instance.collection('appointments').add({
                          'businessId': bizId,
                          'branchId': branchId,
                          'serviceId': selectedServiceId ?? 's1',
                          'serviceName': sName,
                          'customerName': nameCtrl.text.trim(),
                          'phoneNumber': phoneCtrl.text.trim(),
                          'scheduledTime': Timestamp.fromDate(scheduledDateTime),
                          'status': 'SCHEDULED',
                          'notes': notesCtrl.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appointment booked successfully!')),
                          );
                        }
                      },
                      child: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filter Date',
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (d != null) {
                setState(() => _selectedDate = d);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
        onPressed: _showCreateAppointmentDialog,
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No appointments scheduled',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + New Booking to schedule an appointment.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
            itemCount: appointments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final apt = appointments[idx];
              final timeFormatted = DateFormat.jm().format(apt.scheduledTime);
              final dateFormatted = DateFormat('MMM d').format(apt.scheduledTime);
              final isCheckedIn = apt.status == AppointmentStatus.checkedIn;
              final isCancelled = apt.status == AppointmentStatus.cancelled;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isCheckedIn ? Colors.green.shade300 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$dateFormatted, $timeFormatted',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                apt.serviceName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCheckedIn
                                  ? Colors.green.shade50
                                  : isCancelled
                                      ? Colors.red.shade50
                                      : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              apt.status.toApiString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCheckedIn
                                  ? Colors.green.shade800
                                  : isCancelled
                                      ? Colors.red.shade800
                                      : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            apt.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (apt.phoneNumber.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(apt.phoneNumber, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ],
                      ),
                      if (apt.notes != null && apt.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Note: ${apt.notes}',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (apt.tokenNumber != null) ...[
                            Text(
                              'Token: ${apt.tokenNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                          ],
                          if (apt.status == AppointmentStatus.scheduled) ...[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('appointments').doc(apt.id).update({
                                  'status': 'CANCELLED',
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Check In'),
                              onPressed: _isLoading ? null : () => _handleCheckIn(apt),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading appointments: $err')),
      ),
    );
  }
}
