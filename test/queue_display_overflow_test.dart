import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/core/models/models.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/features/display/tv_display_screen.dart';
import 'package:easy_queue_business/features/queues/queues_screen.dart';

void main() {
  final List<QueueEntryModel> sampleActiveEntries = [
    QueueEntryModel(
      id: 'e1',
      businessId: 'biz1',
      branchId: 'b1',
      serviceId: 's1',
      tokenNumber: 'VIP-9999-LONG',
      customerName: 'Very Long Customer Full Name With Extra Characters And Details',
      phoneNumber: '+1-555-123-4567-Ext-8899',
      numberOfPeople: 4,
      priorityCategory: 'VIP_SENIOR',
      priorityWeight: 5,
      status: EntryStatus.called,
      assignedCounterId: 'c1',
      counterName: 'Counter 1 - Super Comprehensive Consultation Desk With Extended Label',
      joinedAt: DateTime(2026, 11, 12, 10, 30),
      calledAt: DateTime(2026, 11, 12, 10, 45),
      estimatedWaitMinutes: 25,
    ),
    QueueEntryModel(
      id: 'e2',
      businessId: 'biz1',
      branchId: 'b1',
      serviceId: 's1',
      tokenNumber: 'A-102',
      customerName: 'Alice Regular Customer',
      numberOfPeople: 1,
      priorityCategory: 'NORMAL',
      priorityWeight: 1,
      status: EntryStatus.serving,
      assignedCounterId: 'c2',
      counterName: 'Desk 2',
      joinedAt: DateTime(2026, 11, 12, 10, 32),
      estimatedWaitMinutes: 10,
    ),
    QueueEntryModel(
      id: 'e3',
      businessId: 'biz1',
      branchId: 'b1',
      serviceId: 's1',
      tokenNumber: 'EXP-404-WAITING',
      customerName: 'Bob Waiting Customer With Long Name',
      numberOfPeople: 2,
      priorityCategory: 'NORMAL',
      priorityWeight: 1,
      status: EntryStatus.waiting,
      joinedAt: DateTime(2026, 11, 12, 10, 35),
      estimatedWaitMinutes: 18,
    ),
  ];

  testWidgets('TvDisplayScreen renders on compact mobile phone screen (360x640) without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeQueueEntriesProvider.overrideWith((ref) => Stream.value(sampleActiveEntries)),
          currentBusinessProvider.overrideWith(
            (ref) => BusinessModel(
              id: 'biz1',
              name: 'Enterprise Healthcare & Medical Diagnostics Center International',
              category: 'Healthcare',
              ownerId: 'u1',
            ),
          ),
          currentBranchProvider.overrideWith(
            (ref) => BranchModel(
              id: 'b1',
              businessId: 'biz1',
              name: 'Downtown Main Flagship Diagnostic & Medical Branch',
              code: 'HQ-DOWNTOWN-01',
              address: '100 Main St',
              status: 'ACTIVE',
            ),
          ),
        ],
        child: const MaterialApp(
          home: TvDisplayScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('NOW CALLING / SERVING'), findsOneWidget);
    expect(find.text('UPCOMING IN QUEUE'), findsOneWidget);
    expect(find.text('VIP-9999-LONG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TvDisplayScreen renders on full HD TV screen (1920x1080) without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeQueueEntriesProvider.overrideWith((ref) => Stream.value(sampleActiveEntries)),
          currentBusinessProvider.overrideWith(
            (ref) => BusinessModel(
              id: 'biz1',
              name: 'Global Enterprise Solutions',
              category: 'Banking',
              ownerId: 'u1',
            ),
          ),
          currentBranchProvider.overrideWith(
            (ref) => BranchModel(
              id: 'b1',
              businessId: 'biz1',
              name: 'Central Financial Branch',
              code: 'CFB-01',
              address: '500 Wall St',
              status: 'ACTIVE',
            ),
          ),
        ],
        child: const MaterialApp(
          home: TvDisplayScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('NOW CALLING / SERVING'), findsOneWidget);
    expect(find.text('UPCOMING IN QUEUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('QueuesScreen renders on narrow phone screen (320x568) without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeQueueEntriesProvider.overrideWith((ref) => Stream.value(sampleActiveEntries)),
          completedQueueEntriesProvider.overrideWith((ref) => Stream.value([])),
          countersStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: QueuesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Live Queue Monitor'), findsOneWidget);
    expect(find.text('EXP-404-WAITING'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
