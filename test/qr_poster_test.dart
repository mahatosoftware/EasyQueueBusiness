import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easy_queue_business/core/models/models.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/features/qr/qr_poster_screen.dart';
import 'package:easy_queue_business/features/qr/poster_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PosterPdfService Tests', () {
    test('generatePosterPdfBytes generates a valid PDF document with header', () async {
      final bytes = await PosterPdfService.generatePosterPdfBytes(
        businessName: 'Apex Healthcare Diagnostics',
        branchName: 'North Plaza Branch',
        queueTitle: 'Main Customer Queue',
        checkInUrl: 'https://easyqueue.in/join/biz_apex_care/br_north_plaza?bizName=Apex+Healthcare+Diagnostics',
        category: 'HEALTHCARE',
      );

      expect(bytes, isNotEmpty);
      // Valid PDF documents begin with %PDF-
      final pdfHeader = ascii.decode(bytes.sublist(0, 5));
      expect(pdfHeader, '%PDF-');
    });
  });

  group('QrPosterScreen Tests', () {
    String? mockClipboardText;

    setUp(() {
      mockClipboardText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            mockClipboardText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return mockClipboardText != null ? {'text': mockClipboardText} : null;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final testBusiness = BusinessModel(
      id: 'biz_apex_care',
      ownerId: 'owner_123',
      name: 'Apex Healthcare Diagnostics',
      category: 'HEALTHCARE',
      description: 'Advanced clinical diagnostic center',
    );

    final testBranch = BranchModel(
      id: 'br_north_plaza',
      businessId: 'biz_apex_care',
      name: 'North Plaza Branch',
      code: 'NPB',
      address: '77 Medical Mile Blvd',
      status: 'ACTIVE',
    );

    final testServices = [
      ServiceModel(
        id: 'srv_blood_lab',
        branchId: 'br_north_plaza',
        name: 'Blood & Pathology Lab',
        code: 'BPL',
        estimatedDurationMinutes: 15,
        status: 'ACTIVE',
      ),
    ];

    testWidgets('QrPosterScreen renders prominent Business Name, branch, and encoded QR code', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentBusinessProvider.overrideWithValue(testBusiness),
            selectedBusinessIdProvider.overrideWith((ref) => 'biz_apex_care'),
            selectedBranchIdProvider.overrideWith((ref) => 'br_north_plaza'),
            branchesStreamProvider.overrideWith((ref) => Stream.value([testBranch])),
            servicesStreamProvider.overrideWith((ref) => Stream.value(testServices)),
          ],
          child: const MaterialApp(
            home: QrPosterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Business Name is rendered prominently on poster
      expect(find.text('Apex Healthcare Diagnostics'), findsOneWidget);

      // Verify branch queue subtitle
      expect(find.text('North Plaza Branch • Customer Queue'), findsOneWidget);

      // Verify Call to action
      expect(find.text('SCAN TO JOIN QUEUE'), findsOneWidget);

      // Verify QR Code image is present
      expect(find.byType(QrImageView), findsOneWidget);

      // Verify branding footer
      expect(find.text('Powered by EasyQueue'), findsOneWidget);

      // Tap "Copy Link" and check clipboard data includes business name in query parameters
      await tester.ensureVisible(find.text('Copy Link'));
      await tester.tap(find.text('Copy Link'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockClipboardText, isNotNull);
      expect(mockClipboardText, contains('biz_apex_care'));
      expect(mockClipboardText, contains('br_north_plaza'));
      expect(mockClipboardText, contains('bizName=Apex+Healthcare+Diagnostics'));
      expect(mockClipboardText, contains('branchName=North+Plaza+Branch'));
    });

    testWidgets('Switching to Specific Service updates poster text and QR data', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentBusinessProvider.overrideWithValue(testBusiness),
            selectedBusinessIdProvider.overrideWith((ref) => 'biz_apex_care'),
            selectedBranchIdProvider.overrideWith((ref) => 'br_north_plaza'),
            branchesStreamProvider.overrideWith((ref) => Stream.value([testBranch])),
            servicesStreamProvider.overrideWith((ref) => Stream.value(testServices)),
          ],
          child: const MaterialApp(
            home: QrPosterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Specific Service" segment button
      await tester.tap(find.text('Specific Service'));
      await tester.pumpAndSettle();

      // Poster subtitle updates to service queue
      expect(find.text('Blood & Pathology Lab Queue • North Plaza Branch'), findsOneWidget);

      // Tap "Copy Link" to verify service parameters in URL
      await tester.ensureVisible(find.text('Copy Link'));
      await tester.tap(find.text('Copy Link'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockClipboardText, isNotNull);
      expect(mockClipboardText, contains('service=srv_blood_lab'));
      expect(mockClipboardText, contains('serviceName=Blood+%26+Pathology+Lab'));
    });

    testWidgets('QrPosterScreen provides Export as PDF button and Print Poster option', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentBusinessProvider.overrideWithValue(testBusiness),
            selectedBusinessIdProvider.overrideWith((ref) => 'biz_apex_care'),
            selectedBranchIdProvider.overrideWith((ref) => 'br_north_plaza'),
            branchesStreamProvider.overrideWith((ref) => Stream.value([testBranch])),
            servicesStreamProvider.overrideWith((ref) => Stream.value(testServices)),
          ],
          child: const MaterialApp(
            home: QrPosterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Export as PDF button is present
      expect(find.text('Export as PDF'), findsOneWidget);
      expect(find.text('Print Poster'), findsOneWidget);

      // Tap Export as PDF button
      await tester.ensureVisible(find.text('Export as PDF'));
      await tester.tap(find.text('Export as PDF'));
      await tester.pump(const Duration(milliseconds: 300));

      // SnackBar appears
      expect(find.text('Preparing PDF poster for Apex Healthcare Diagnostics...'), findsOneWidget);
    });
  });
}
