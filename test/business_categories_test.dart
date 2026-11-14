import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/core/constants/app_constants.dart';
import 'package:easy_queue_business/core/models/models.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/features/auth/sign_in_screen.dart';
import 'package:easy_queue_business/features/more/more_screen.dart';
import 'package:easy_queue_business/features/categories/organization_category_screen.dart';

void main() {
  group('Organization Category Management - Master Categories (A through O)', () {
    test('All 15 default master categories A through O are fully supported', () {
      final categories = OrganizationCategoryManager.defaultCategories;
      expect(categories.length, 15);

      final codes = categories.map((c) => c.code).toList();
      expect(codes, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O']);

      expect(categories[0].name, 'Healthcare & Medical');
      expect(categories[1].name, 'Banking & Financial Services');
      expect(categories[2].name, 'Government & Public Services');
      expect(categories[3].name, 'Personal Care & Wellness');
      expect(categories[4].name, 'Automobile & Repair Services');
      expect(categories[5].name, 'Food & Hospitality');
      expect(categories[6].name, 'Retail & Shopping');
      expect(categories[7].name, 'Education');
      expect(categories[8].name, 'Transportation & Travel');
      expect(categories[9].name, 'Corporate & Professional Services');
      expect(categories[10].name, 'Utilities & Customer Support');
      expect(categories[11].name, 'Community & Religious Organizations');
      expect(categories[12].name, 'Events & Exhibitions');
      expect(categories[13].name, 'Sports & Entertainment');
      expect(categories[14].name, 'Social & Religious Events');
    });

    test('Category A: Healthcare & Medical sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('HEALTHCARE');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Hospitals',
        'Multi-speciality clinics',
        'Dental clinics',
        'Diagnostic laboratories',
        'Scan centres',
        'Pharmacies',
        'Eye clinics',
        'Physiotherapy centres',
        'Veterinary clinics',
        'Blood collection centres',
      ]));
    });

    test('Category B: Banking & Financial Services sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('BANKING');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Banks',
        'NBFCs',
        'Insurance offices',
        'Loan processing centres',
        'Microfinance institutions',
        'Cooperative societies',
        'Currency exchange centres',
      ]));
    });

    test('Category C: Government & Public Services sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('GOVERNMENT');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'RTO offices',
        'Passport service centres',
        'Municipal offices',
        'Government hospitals',
        'Aadhaar service centres',
        'Registration offices',
        'Tax offices',
        'Citizen service centres',
      ]));
    });

    test('Category D: Personal Care & Wellness sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('PERSONAL_CARE');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Hair salons',
        'Beauty parlours',
        'Spas',
        'Massage centres',
        'Tattoo studios',
        'Fitness centres',
        'Yoga centres',
      ]));
    });

    test('Category E: Automobile & Repair Services sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('AUTOMOBILE_REPAIR');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Car service centres',
        'Two-wheeler service centres',
        'Vehicle inspection centres',
        'Tyre shops',
        'Vehicle washing centres',
        'Electronics repair centres',
        'Mobile repair shops',
      ]));
    });

    test('Category F: Food & Hospitality sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('FOOD_HOSPITALITY');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Restaurants',
        'Cafes',
        'Food courts',
        'Bakeries',
        'Hotels',
        'Buffet restaurants',
        'Cloud kitchen pickup counters',
      ]));
    });

    test('Category G: Retail & Shopping sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('RETAIL_SHOPPING');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Supermarkets',
        'Shopping malls',
        'Jewellery stores',
        'Electronics stores',
        'Mobile stores',
        'Customer service desks',
        'Product collection counters',
      ]));
    });

    test('Category H: Education sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('EDUCATION');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Schools',
        'Colleges',
        'Universities',
        'Coaching institutes',
        'Admission offices',
        'Examination centres',
        'Student counselling centres',
        'Fee collection counters',
      ]));
    });

    test('Category I: Transportation & Travel sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('TRANSPORT_TRAVEL');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Airports',
        'Bus terminals',
        'Railway stations',
        'Travel agencies',
        'Taxi rental counters',
        'Ticket booking offices',
      ]));
    });

    test('Category J: Corporate & Professional Services sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('CORPORATE_PROFESSIONAL');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Corporate offices',
        'IT company reception',
        'HR departments',
        'Employee helpdesks',
        'Legal offices',
        'Consultancy firms',
        'Coworking spaces',
        'Real estate offices',
      ]));
    });

    test('Category K: Utilities & Customer Support sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('UTILITIES_SUPPORT');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Electricity offices',
        'Water supply offices',
        'Telecom service centres',
        'Internet service providers',
        'Gas agencies',
        'Courier and logistics offices',
      ]));
    });

    test('Category L: Community & Religious Organizations sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('COMMUNITY_RELIGIOUS');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Temples',
        'Churches',
        'Mosques',
        'Community centres',
        'Apartment associations',
        'NGOs',
        'Blood donation centres',
      ]));
    });

    test('Category M: Events & Exhibitions sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('EVENTS_EXHIBITIONS');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Concerts',
        'Music festivals',
        'Conferences',
        'Seminars',
        'Workshops',
        'Trade shows',
        'Exhibitions',
        'Product launches',
        'Job fairs',
      ]));
    });

    test('Category N: Sports & Entertainment sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('SPORTS_ENTERTAINMENT');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Sports tournaments',
        'Stadium entry',
        'Marathons',
        'Sports trials',
        'Fitness competitions',
        'Movie premieres',
        'Public entertainment events',
      ]));
    });

    test('Category O: Social & Religious Events sub-categories verification', () {
      final cat = OrganizationCategoryManager.findCategory('SOCIAL_EVENTS');
      final names = cat.subCategories.map((s) => s.name).toList();

      expect(names, containsAll([
        'Weddings',
        'Receptions',
        'Birthday parties',
        'Family gatherings',
        'Community celebrations',
        'Religious festivals',
        'Darshan management',
        'Community meals',
      ]));
    });

    test('Search capability filters across all categories and sub-categories', () {
      final dentalMatches = OrganizationCategoryManager.search('dental');
      expect(dentalMatches.any((s) => s.name == 'Dental clinics'), isTrue);

      final rtoMatches = OrganizationCategoryManager.search('rto');
      expect(rtoMatches.any((s) => s.name == 'RTO offices'), isTrue);

      final darshanMatches = OrganizationCategoryManager.search('darshan');
      expect(darshanMatches.any((s) => s.name == 'Darshan management'), isTrue);

      final airportMatches = OrganizationCategoryManager.search('airport');
      expect(airportMatches.any((s) => s.name == 'Airports'), isTrue);

      final weddingMatches = OrganizationCategoryManager.search('wedding');
      expect(weddingMatches.any((s) => s.name == 'Weddings'), isTrue);
    });

    test('Dynamic custom sub-category creation works properly', () {
      final customSub = OrganizationSubCategory.fromCustomName('Drone Repair Academy');
      expect(customSub.isCustom, isTrue);
      expect(customSub.name, 'Drone Repair Academy');
      expect(customSub.defaultServices.isNotEmpty, isTrue);
      expect(customSub.defaultServices.first.name, 'Drone Repair Academy Service');
    });

    test('BusinessModel resolves category and subcategory seamlessly', () {
      final biz = BusinessModel(
        id: 'b1',
        ownerId: 'u1',
        name: 'Apex Temple Trust',
        category: 'COMMUNITY_RELIGIOUS',
        subCategory: 'Temples',
      );
      expect(biz.categoryDisplayName, 'Community & Religious Organizations');
      expect(biz.subCategoryDisplayName, 'Temples');
      expect(biz.fullCategoryDisplayName, 'Community & Religious Organizations • Temples');
    });
  });

  group('UI Integration Tests for Organization Category Management', () {
    testWidgets('Sign Up screen provides Category (A-O) and cascading Organization Type', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInScreen(),
          ),
        ),
      );

      // Switch to sign up mode
      await tester.ensureVisible(find.text('New business? Create an Account'));
      await tester.tap(find.text('New business? Create an Account'));
      await tester.pumpAndSettle();

      // Verify category dropdown exists
      expect(find.text('Industry / Business Category (A - O)'), findsOneWidget);
      expect(find.text('Organization Type'), findsOneWidget);
    });

    testWidgets('MoreScreen displays Organization Category Management tile and full category badge', (WidgetTester tester) async {
      final templeBiz = BusinessModel(
        id: 'b101',
        ownerId: 'u1',
        name: 'Tirupati Seva Trust',
        category: 'SOCIAL_EVENTS',
        subCategory: 'Darshan management',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentBusinessProvider.overrideWithValue(templeBiz),
            currentBranchProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: MoreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Social & Religious Events • Darshan management'), findsOneWidget);
      expect(find.text('Organization Category Management'), findsOneWidget);
    });

    testWidgets('OrganizationCategoryScreen renders search bar, category browser & bottom action bar', (WidgetTester tester) async {
      final dentalBiz = BusinessModel(
        id: 'b202',
        ownerId: 'u1',
        name: 'City Dental Care',
        category: 'HEALTHCARE',
        subCategory: 'Dental clinics',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentBusinessProvider.overrideWithValue(dentalBiz),
            selectedBusinessIdProvider.overrideWith((ref) => 'b202'),
            selectedBranchIdProvider.overrideWith((ref) => 'br202'),
          ],
          child: const MaterialApp(
            home: OrganizationCategoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header & search box
      expect(find.text('Organization Category Management'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify A-O categories list exists
      expect(find.text('Healthcare & Medical'), findsWidgets);
      expect(find.text('Banking & Financial Services'), findsWidgets);

      // Verify bottom action bar buttons
      expect(find.text('Save to Profile'), findsOneWidget);
      expect(find.text('Apply & Auto-Provision Queues'), findsOneWidget);
    });
  });
}
