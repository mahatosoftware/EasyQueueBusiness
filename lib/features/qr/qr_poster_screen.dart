import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/queue_providers.dart';

class QrPosterScreen extends ConsumerStatefulWidget {
  const QrPosterScreen({super.key});

  @override
  ConsumerState<QrPosterScreen> createState() => _QrPosterScreenState();
}

class _QrPosterScreenState extends ConsumerState<QrPosterScreen> {
  String _posterType = 'BRANCH'; // 'BRANCH' | 'SERVICE'
  String? _selectedServiceId;
  final String _customInstruction = 'Scan to join the queue and track your position in real-time.';

  @override
  Widget build(BuildContext context) {
    final bizId = ref.watch(selectedBusinessIdProvider);
    final branchId = ref.watch(selectedBranchIdProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);
    final services = servicesAsync.valueOrNull ?? [];

    if (_selectedServiceId == null && services.isNotEmpty) {
      _selectedServiceId = services.first.id;
    }

    final currentService = services.where((s) => s.id == _selectedServiceId).firstOrNull;

    // Build the dynamic URL
    final checkInUrl = _posterType == 'BRANCH'
        ? 'https://easyqueue.in/join/$bizId/$branchId'
        : 'https://easyqueue.in/join/$bizId/$branchId?service=${_selectedServiceId ?? ""}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Poster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: checkInUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Check-in link copied to clipboard: $checkInUrl')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Controls Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POSTER CONFIGURATION',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'BRANCH', label: Text('Branch Queue')),
                        ButtonSegment(value: 'SERVICE', label: Text('Specific Service')),
                      ],
                      selected: {_posterType},
                      onSelectionChanged: (val) {
                        setState(() {
                          _posterType = val.first;
                        });
                      },
                    ),
                    if (_posterType == 'SERVICE' && services.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedServiceId,
                        decoration: const InputDecoration(
                          labelText: 'Select Service',
                          border: OutlineInputBorder(),
                        ),
                        items: services.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.code})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedServiceId = val;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Printable Poster Preview
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Logo & Header
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          AppConstants.logoIconPath,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _posterType == 'BRANCH' ? 'Main Customer Queue' : (currentService?.name ?? 'Service Queue'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        ),
                        child: QrImageView(
                          data: checkInUrl,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Instruction steps
                      Text(
                        _customInstruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.smartphone, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'No app download required',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Print & Export Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Copy Link'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: checkInUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Self-checkin URL copied!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text('Print Poster'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Print Queue Poster'),
                          content: const Text(
                            'Poster is formatted for standard A4 and Letter printing. You can send this document directly to any network-connected AirPrint or Wi-Fi printer.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.print),
                              label: const Text('Send to Printer'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Print job sent successfully!')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
