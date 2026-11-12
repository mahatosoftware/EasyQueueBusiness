import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/main.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/core/models/models.dart';

void main() {
  testWidgets('EasyQueueBusinessApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          countersStreamProvider.overrideWith((ref) => Stream.value([
            CounterModel(
              id: 'c1',
              branchId: 'b1',
              name: 'Counter 1',
              counterNumber: 1,
              displayLabel: 'Counter 1',
              supportedServiceIds: ['s1'],
              assignedOperatorIds: ['op1'],
              status: CounterStatus.available,
            ),
          ])),
          servicesStreamProvider.overrideWith((ref) => Stream.value([
            ServiceModel(
              id: 's1',
              branchId: 'b1',
              name: 'General Service',
              code: 'G',
              estimatedDurationMinutes: 10,
              status: 'ACTIVE',
            ),
          ])),
          activeQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
          completedQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const EasyQueueBusinessApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EasyQueueBusinessApp), findsOneWidget);
    expect(find.text('EasyQueue Business'), findsOneWidget);
  });
}
