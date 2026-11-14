import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/core/models/models.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/features/more/more_screen.dart';

void main() {
  testWidgets('MoreScreen displays Business Profile and opens edit dialog', (WidgetTester tester) async {
    final sampleBusiness = BusinessModel(
      id: 'biz-01',
      ownerId: 'u1',
      name: 'City Care Hospital',
      category: 'HEALTHCARE',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentBusinessProvider.overrideWithValue(sampleBusiness),
          currentBranchProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: MoreScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('City Care Hospital'), findsWidgets);
    expect(find.text('Business Profile'), findsOneWidget);

    // Tap on the Business Profile menu tile
    await tester.tap(find.text('Business Profile'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Configure Business Profile'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
