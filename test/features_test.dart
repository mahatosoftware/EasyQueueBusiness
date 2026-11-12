import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/core/constants/app_constants.dart';
import 'package:easy_queue_business/core/models/models.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/features/reports/reports_screen.dart';
import 'package:easy_queue_business/features/subscription/subscription_screen.dart';
import 'package:easy_queue_business/features/qr/qr_poster_screen.dart';
import 'package:easy_queue_business/features/appointments/appointments_screen.dart';

void main() {
  testWidgets('ReportsScreen renders KPIs and counter throughput', (WidgetTester tester) async {
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
              name: 'Consultation',
              code: 'C',
              estimatedDurationMinutes: 15,
              status: 'ACTIVE',
            ),
          ])),
          activeQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
          completedQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Reports & Analytics'), findsOneWidget);
    expect(find.text('Tokens Served'), findsOneWidget);
    expect(find.text('Avg Wait Time'), findsOneWidget);
    expect(find.text('COUNTER EFFICIENCY'), findsOneWidget);
    expect(find.text('Counter 1'), findsOneWidget);
  });

  testWidgets('SubscriptionScreen displays plan tiers and quota limits', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          countersStreamProvider.overrideWith((ref) => Stream.value([])),
          branchesStreamProvider.overrideWith((ref) => Stream.value([])),
          completedQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: SubscriptionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Subscription & Usage Limits'), findsOneWidget);
    expect(find.text('Professional Tier'), findsOneWidget);
    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('Growth'), findsOneWidget);
    expect(find.text('Enterprise'), findsOneWidget);
  });

  testWidgets('QrPosterScreen renders preview and toggle', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          servicesStreamProvider.overrideWith((ref) => Stream.value([
            ServiceModel(
              id: 's1',
              branchId: 'b1',
              name: 'Diagnostics',
              code: 'D',
              estimatedDurationMinutes: 10,
              status: 'ACTIVE',
            ),
          ])),
        ],
        child: const MaterialApp(
          home: QrPosterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('QR Code Poster'), findsOneWidget);
    expect(find.text('Branch Queue'), findsOneWidget);
    expect(find.text('Specific Service'), findsOneWidget);
    expect(find.text('Print Poster'), findsOneWidget);
  });

  testWidgets('AppointmentsScreen displays empty state when no appointments exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsStreamProvider.overrideWith((ref) => Stream.value([])),
          servicesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: AppointmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('No appointments scheduled'), findsOneWidget);
    expect(find.text('New Booking'), findsOneWidget);
  });

  testWidgets('Screens have navigation padding applied to scrollable views', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          countersStreamProvider.overrideWith((ref) => Stream.value([])),
          servicesStreamProvider.overrideWith((ref) => Stream.value([])),
          activeQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
          completedQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final singleChildScrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(singleChildScrollView.padding, const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding));
  });
}
