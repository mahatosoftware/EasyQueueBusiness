import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/queue_providers.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _selectedFilter = 'ALL';

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CALL_NEXT':
        return Icons.campaign;
      case 'START_SERVICE':
        return Icons.play_arrow;
      case 'COMPLETE_SERVICE':
        return Icons.check_circle;
      case 'RECALL':
        return Icons.volume_up;
      case 'NO_SHOW':
        return Icons.person_off;
      case 'SKIP':
        return Icons.skip_next;
      case 'TRANSFER':
        return Icons.swap_horiz;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CALL_NEXT':
        return Colors.blue;
      case 'START_SERVICE':
        return Colors.teal;
      case 'COMPLETE_SERVICE':
        return Colors.green;
      case 'RECALL':
        return Colors.amber.shade800;
      case 'NO_SHOW':
        return Colors.orange.shade800;
      case 'SKIP':
        return Colors.red;
      case 'TRANSFER':
        return Colors.purple;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auditLogsAsync = ref.watch(auditLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Audit Trail'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Events'),
                const SizedBox(width: 8),
                _buildFilterChip('CALL_NEXT', 'Calls'),
                const SizedBox(width: 8),
                _buildFilterChip('COMPLETE_SERVICE', 'Completions'),
                const SizedBox(width: 8),
                _buildFilterChip('NO_SHOW', 'No-Shows'),
                const SizedBox(width: 8),
                _buildFilterChip('TRANSFER', 'Transfers'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: auditLogsAsync.when(
              data: (logs) {
                final filtered = _selectedFilter == 'ALL'
                    ? logs
                    : logs.where((l) => l.action.toUpperCase() == _selectedFilter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No audit events found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Operations performed by operators and managers are logged here in real time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final log = filtered[idx];
                    final timeStr = DateFormat.jm().format(log.timestamp);
                    final dateStr = DateFormat('MMM d').format(log.timestamp);
                    final icon = _getActionIcon(log.action);
                    final color = _getActionColor(log.action);

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.action,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: color,
                                        ),
                                      ),
                                      Text(
                                        '$dateStr $timeStr',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (log.tokenNumber != null)
                                    Text(
                                      'Token: ${log.tokenNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  if (log.counterName != null || log.operatorName != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${log.counterName ?? "Counter"} • Operator: ${log.operatorName ?? "Staff"}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                  if (log.details.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      log.details,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading audit logs: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }
}
