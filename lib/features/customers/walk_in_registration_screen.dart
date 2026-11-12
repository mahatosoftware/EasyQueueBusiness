import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/queue_providers.dart';
import '../../core/services/functions_service.dart';

class WalkInRegistrationScreen extends ConsumerStatefulWidget {
  const WalkInRegistrationScreen({super.key});

  @override
  ConsumerState<WalkInRegistrationScreen> createState() => _WalkInRegistrationScreenState();
}

class _WalkInRegistrationScreenState extends ConsumerState<WalkInRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedServiceId;
  String _selectedPriority = 'NORMAL';
  int _peopleCount = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final fn = ref.read(functionsServiceProvider);
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);

    try {
      final res = await fn.joinQueue(
        businessId: bizId,
        branchId: branchId,
        serviceId: _selectedServiceId!,
        customerName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        numberOfPeople: _peopleCount,
        priorityCategory: _selectedPriority,
        source: 'WALK_IN',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog(
          tokenNumber: res['tokenNumber'] ?? 'Q001',
          position: res['positionInQueue'] ?? 1,
          estWait: res['estimatedWaitMinutes'] ?? 10,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate token: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog({
    required String tokenNumber,
    required int position,
    required int estWait,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('Token Generated!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tokenNumber,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Queue Position: #$position', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Estimated Wait: ~$estWait mins', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              height: 120,
              child: QrImageView(
                data: 'https://easyqueue.in/ticket/$tokenNumber',
                version: QrVersions.auto,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Scan to track live queue status on phone', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _nameController.clear();
              _phoneController.clear();
              _notesController.clear();
            },
            child: const Text('Done & Print Ticket'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Walk-in Customer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, AppConstants.bottomNavPadding),
          children: [
            // Service Selector
            const Text(
              'Select Service *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No active services in this branch. Please create services first.'),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedServiceId ?? (services.isNotEmpty ? services.first.id : null),
                  items: services.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.code}) • ~${s.estimatedDurationMinutes}m'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedServiceId = val),
                  decoration: const InputDecoration(hintText: 'Choose a service'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),

            // Customer Name
            const Text('Customer Name *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. John Doe',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),

            // Phone Number
            const Text('Mobile Number (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. +91 9876543210',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Number of people
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Number of People', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.remove),
                      onPressed: _peopleCount > 1 ? () => setState(() => _peopleCount--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_peopleCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.outlined(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _peopleCount++),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Priority Category
            const Text('Priority Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPriorityChip('NORMAL', 'Standard'),
                _buildPriorityChip('SENIOR_CITIZEN', 'Senior Citizen'),
                _buildPriorityChip('PREGNANT', 'Pregnant'),
                _buildPriorityChip('DISABILITY', 'Person with Disability'),
                _buildPriorityChip('VIP', 'VIP'),
                _buildPriorityChip('EMERGENCY', 'Emergency Case'),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            const Text('Notes / Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional instructions or reason'),
            ),
            const SizedBox(height: 28),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Token & Print', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String key, String label) {
    final isSelected = _selectedPriority == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedPriority = key);
      },
    );
  }
}
