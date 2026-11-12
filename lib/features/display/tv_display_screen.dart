import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/queue_providers.dart';

class TvDisplayScreen extends ConsumerStatefulWidget {
  const TvDisplayScreen({super.key});

  @override
  ConsumerState<TvDisplayScreen> createState() => _TvDisplayScreenState();
}

class _TvDisplayScreenState extends ConsumerState<TvDisplayScreen> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEntriesAsync = ref.watch(activeQueueEntriesProvider);
    final currentBusiness = ref.watch(currentBusinessProvider);
    final currentBranch = ref.watch(currentBranchProvider);

    final activeEntries = activeEntriesAsync.valueOrNull ?? [];

    final callingOrServing = activeEntries
        .where((e) => e.status == EntryStatus.called || e.status == EntryStatus.serving)
        .toList();

    final upcoming = activeEntries
        .where((e) => e.status == EntryStatus.waiting)
        .take(12)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy TV background
      body: SafeArea(
        child: Column(
          children: [
            // Top TV Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(AppConstants.logoIconPath, width: 44, height: 44),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentBusiness?.name ?? 'EasyQueue Live Display',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currentBranch != null ? '${currentBranch.name} (${currentBranch.code})' : 'Live Branch Display',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Live Clock
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      DateFormat('hh:mm:ss a').format(_currentTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Exit Display Mode',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Currently Called / Serving Counters
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NOW CALLING / SERVING',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: callingOrServing.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.desk, size: 64, color: Colors.grey.shade700),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No customers currently called.',
                                          style: TextStyle(color: Colors.grey, fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: callingOrServing.length,
                                    itemBuilder: (context, idx) {
                                      final item = callingOrServing[idx];
                                      final isCalled = item.status == EntryStatus.called;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isCalled ? Colors.amber : const Color(0xFF10B981),
                                            width: 2.5,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              item.tokenNumber,
                                              style: TextStyle(
                                                fontSize: 42,
                                                fontWeight: FontWeight.w900,
                                                color: isCalled ? Colors.amber : Colors.white,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.counterName ?? 'Counter',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right Column: Upcoming Tokens
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.queue, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'UPCOMING IN QUEUE',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF334155), height: 24),
                            Expanded(
                              child: upcoming.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Queue is currently empty.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: upcoming.length,
                                      separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 12),
                                      itemBuilder: (context, idx) {
                                        final entry = upcoming[idx];
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '#${idx + 1}',
                                                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  entry.tokenNumber,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '~${entry.estimatedWaitMinutes}m wait',
                                              style: TextStyle(color: Colors.blue.shade300, fontSize: 13),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
