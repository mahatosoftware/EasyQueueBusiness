import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/core/models/models.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/features/branches/branches_screen.dart';

void main() {
  testWidgets('BranchesScreen renders empty state and opens Add Branch dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BranchesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('Branch Management'), findsOneWidget);

    // Verify Add button in AppBar or empty state
    expect(find.byIcon(Icons.add), findsWidgets);

    // Tap Add button
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    // Verify dialog fields
    expect(find.text('Add New Branch'), findsOneWidget);
    expect(find.text('Branch Name *'), findsOneWidget);
    expect(find.text('Create Branch'), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Add New Branch'), findsNothing);
  });

  testWidgets('BranchesScreen renders branches list and opens Edit Branch dialog', (WidgetTester tester) async {
    final testBranch = BranchModel(
      id: 'branch_1',
      businessId: 'biz_1',
      name: 'Downtown Facility',
      code: 'DT01',
      address: '123 Main Street',
      contactNumber: '9876543210',
      status: 'ACTIVE',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchesStreamProvider.overrideWith((ref) => Stream.value([testBranch])),
        ],
        child: const MaterialApp(
          home: BranchesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify branch item rendered
    expect(find.text('Downtown Facility'), findsOneWidget);
    expect(find.text('123 Main Street • Code: DT01'), findsOneWidget);

    // Verify edit button exists
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    // Tap edit button
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Verify Edit dialog opened with pre-populated values
    expect(find.text('Edit Branch Details'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Downtown Facility'), findsWidgets);
    expect(find.text('DT01'), findsWidgets);
    expect(find.text('123 Main Street'), findsWidgets);
    expect(find.text('9876543210'), findsWidgets);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Branch Details'), findsNothing);
  });
}
