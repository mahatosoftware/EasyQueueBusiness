import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/queue_providers.dart';
import 'poster_pdf_service.dart';

class QrPosterScreen extends ConsumerStatefulWidget {
  const QrPosterScreen({super.key});

  @override
  ConsumerState<QrPosterScreen> createState() => _QrPosterScreenState();
}

class _QrPosterScreenState extends ConsumerState<QrPosterScreen> {
  String _posterType = 'BRANCH'; // 'BRANCH' | 'SERVICE'
  String? _selectedServiceId;

  @override
  Widget build(BuildContext context) {
    final bizId = ref.watch(selectedBusinessIdProvider);
    final currentBusiness = ref.watch(currentBusinessProvider);
    final branchesAsync = ref.watch(branchesStreamProvider);
    final branches = branchesAsync.valueOrNull ?? [];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);
    final services = servicesAsync.valueOrNull ?? [];

    final currentBranch = branches.where((b) => b.id == selectedBranchId).firstOrNull ?? branches.firstOrNull;

    if (_selectedServiceId == null && services.isNotEmpty) {
      _selectedServiceId = services.first.id;
    }

    final currentService = services.where((s) => s.id == _selectedServiceId).firstOrNull;

    final effectiveBizId = bizId.isNotEmpty ? bizId : (currentBusiness?.id ?? '');
    final effectiveBranchId = (selectedBranchId.isNotEmpty)
        ? selectedBranchId
        : (currentBranch?.id ?? '');

    final businessName = (currentBusiness?.name != null && currentBusiness!.name.trim().isNotEmpty)
        ? currentBusiness.name.trim()
        : 'EasyQueue Business';

    final branchName = (currentBranch?.name != null && currentBranch!.name.trim().isNotEmpty)
        ? currentBranch.name.trim()
        : 'Main Branch';

    // Build the dynamic URL with business and branch names for seamless scanning in EasyQueue
    final Map<String, String> queryParams = {
      'bizName': businessName,
      'branchName': branchName,
    };
    if (_posterType == 'SERVICE' && _selectedServiceId != null) {
      queryParams['service'] = _selectedServiceId!;
      if (currentService != null) {
        queryParams['serviceName'] = currentService.name;
      }
    }

    final checkInUri = Uri(
      scheme: 'https',
      host: 'easyqueue.in',
      path: '/join/$effectiveBizId/$effectiveBranchId',
      queryParameters: queryParams,
    );
    final checkInUrl = checkInUri.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Poster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Link',
            onPressed: () {
              final shareText = 'Join queue at $businessName ($branchName): $checkInUrl';
              Clipboard.setData(ClipboardData(text: shareText));
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
            // Configuration Card
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
                    if (branches.length > 1) ...[
                      DropdownButtonFormField<String>(
                        initialValue: currentBranch?.id,
                        decoration: const InputDecoration(
                          labelText: 'Select Branch',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        items: branches.map((b) {
                          return DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(selectedBranchIdProvider.notifier).state = val;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
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
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Business Logo / Icon
                      if (currentBusiness?.logoUrl != null && currentBusiness!.logoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            currentBusiness.logoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildFallbackLogo(context),
                          ),
                        )
                      else
                        _buildFallbackLogo(context),

                      const SizedBox(height: 14),

                      // Business Name Prominently Featured
                      Text(
                        businessName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Branch / Service Subtitle
                      Text(
                        _posterType == 'BRANCH'
                            ? '$branchName • Customer Queue'
                            : '${currentService?.name ?? "Service"} Queue • $branchName',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      // Scan To Join Queue Callout
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF334155)),
                            SizedBox(width: 6),
                            Text(
                              'SCAN TO JOIN QUEUE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: checkInUrl,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Instructions
                      const Text(
                        'Scan with EasyQueue App or Phone Camera',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take your digital token instantly and track live queue progress from anywhere.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Brand Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              AppConstants.logoIconPath,
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Powered by EasyQueue',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export as PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Preparing PDF poster for $businessName...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  await PosterPdfService.exportPdf(
                    businessName: businessName,
                    branchName: branchName,
                    queueTitle: _posterType == 'BRANCH'
                        ? 'Main Customer Queue'
                        : (currentService?.name ?? 'Service Queue'),
                    checkInUrl: checkInUrl,
                    category: currentBusiness?.category,
                    subCategory: currentBusiness?.subCategory,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to export PDF: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print Poster'),
                    onPressed: () async {
                      try {
                        await PosterPdfService.printPoster(
                          businessName: businessName,
                          branchName: branchName,
                          queueTitle: _posterType == 'BRANCH'
                              ? 'Main Customer Queue'
                              : (currentService?.name ?? 'Service Queue'),
                          checkInUrl: checkInUrl,
                          category: currentBusiness?.category,
                    subCategory: currentBusiness?.subCategory,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to start print: $e')),
                          );
                        }
                      }
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

  Widget _buildFallbackLogo(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.storefront_rounded, size: 30, color: Colors.white),
      ),
    );
  }
}
