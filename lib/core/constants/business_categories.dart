import 'package:flutter/material.dart';

/// Predefined service template for specific business industries.
class ServiceTemplate {
  final String name;
  final String code;
  final int durationMinutes;
  final String description;
  final int maxCapacity;
  final bool allowWalkIn;
  final bool supportsPriority;
  final String allocationPolicy;

  const ServiceTemplate({
    required this.name,
    required this.code,
    required this.durationMinutes,
    this.description = '',
    this.maxCapacity = 100,
    this.allowWalkIn = true,
    this.supportsPriority = true,
    this.allocationPolicy = 'FIFO',
  });
}

/// Metadata and service templates for an industry category.
class BusinessCategoryInfo {
  final String id;
  final String displayName;
  final String subtitle;
  final String marketPriority;
  final int marketRank;
  final IconData icon;
  final List<String> aliases;
  final String clientCategoryName;
  final List<ServiceTemplate> defaultServices;

  const BusinessCategoryInfo({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.marketPriority,
    required this.marketRank,
    required this.icon,
    this.aliases = const [],
    required this.clientCategoryName,
    required this.defaultServices,
  });
}

/// Central registry of supported business industries and queue templates.
class BusinessCategories {
  // 1. Small clinics and dentists (Target: Very High, Rank 1)
  static const BusinessCategoryInfo clinicDentist = BusinessCategoryInfo(
    id: 'CLINIC_DENTIST',
    displayName: 'Small Clinics & Dentists',
    subtitle: 'Dental clinics, general physicians, pediatricians & outpatient OPD practices',
    marketPriority: 'Very High',
    marketRank: 1,
    icon: Icons.medical_services_outlined,
    aliases: ['CLINIC', 'DENTIST', 'DENTAL', 'CLINICS_DENTISTS', 'DENTAL_CLINIC', 'DOCTOR'],
    clientCategoryName: 'clinic',
    defaultServices: [
      ServiceTemplate(
        name: 'Doctor Consultation',
        code: 'C',
        durationMinutes: 15,
        description: 'General OPD, follow-up, or pediatric doctor consultation',
      ),
      ServiceTemplate(
        name: 'Dental Checkup & Cleaning',
        code: 'D',
        durationMinutes: 30,
        description: 'Teeth examination, scaling, prophylaxis, and oral hygiene review',
      ),
      ServiceTemplate(
        name: 'Tooth Extraction & Procedures',
        code: 'T',
        durationMinutes: 40,
        description: 'Minor dental surgery, root canal, cavity filling, or extraction',
      ),
      ServiceTemplate(
        name: 'Follow-up & Dressing',
        code: 'F',
        durationMinutes: 10,
        description: 'Routine post-treatment review, stitches check, and wound dressing',
      ),
    ],
  );

  // 2. Diagnostic centres (Target: Very High, Rank 2)
  static const BusinessCategoryInfo diagnostic = BusinessCategoryInfo(
    id: 'DIAGNOSTIC',
    displayName: 'Diagnostic Centres & Labs',
    subtitle: 'Pathology labs, imaging, MRI, CT scan, ultrasound & report collection',
    marketPriority: 'Very High',
    marketRank: 2,
    icon: Icons.biotech_outlined,
    aliases: ['DIAGNOSTICS', 'LAB', 'PATHOLOGY', 'SCAN_CENTRE', 'DIAGNOSTIC_CENTER', 'LABORATORY'],
    clientCategoryName: 'diagnostic',
    defaultServices: [
      ServiceTemplate(
        name: 'Blood & Sample Collection',
        code: 'B',
        durationMinutes: 10,
        description: 'Fasting blood tests, urine samples & routine pathology phlebotomy',
      ),
      ServiceTemplate(
        name: 'Ultrasound & Sonography',
        code: 'U',
        durationMinutes: 20,
        description: 'Abdominal, pelvic, obstetric, and Doppler sonography scans',
      ),
      ServiceTemplate(
        name: 'X-Ray & Radiology',
        code: 'X',
        durationMinutes: 15,
        description: 'Chest, bone, joint, and dental digital X-ray imaging',
      ),
      ServiceTemplate(
        name: 'Report Collection & Query',
        code: 'R',
        durationMinutes: 5,
        description: 'Test result collection counter and lab doctor consultation',
      ),
    ],
  );

  // 3. Salons and barber shops (Target: High, Rank 3)
  static const BusinessCategoryInfo salonBarber = BusinessCategoryInfo(
    id: 'SALON_BARBER',
    displayName: 'Salons & Barber Shops',
    subtitle: 'Men\'s barbershops, beauty salons, hair stylists, grooming lounges & spas',
    marketPriority: 'High',
    marketRank: 3,
    icon: Icons.content_cut_outlined,
    aliases: ['SALON', 'BARBER', 'SALON_SPA', 'BARBERSHOP', 'HAIR_SALON', 'BEAUTY_PARLOUR'],
    clientCategoryName: 'salon',
    defaultServices: [
      ServiceTemplate(
        name: 'Haircut & Styling',
        code: 'H',
        durationMinutes: 25,
        description: 'Professional haircut, hair wash, blowdry, and styling',
      ),
      ServiceTemplate(
        name: 'Beard Trim & Shave',
        code: 'B',
        durationMinutes: 15,
        description: 'Hot towel straight razor shave, mustache & beard grooming',
      ),
      ServiceTemplate(
        name: 'Hair Color & Spa',
        code: 'C',
        durationMinutes: 45,
        description: 'Hair coloring, highlights, keratin treatments & deep conditioning',
      ),
      ServiceTemplate(
        name: 'Facial & Skin Grooming',
        code: 'F',
        durationMinutes: 30,
        description: 'Skin cleansing, face massage, tan removal & threading',
      ),
    ],
  );

  // 4. Vehicle service centres (Target: High, Rank 4)
  static const BusinessCategoryInfo vehicleService = BusinessCategoryInfo(
    id: 'VEHICLE_SERVICE',
    displayName: 'Vehicle Service Centres',
    subtitle: 'Auto workshops, 2W/4W authorized service, oil change, tyre & car care',
    marketPriority: 'High',
    marketRank: 4,
    icon: Icons.directions_car_outlined,
    aliases: ['AUTOMOTIVE', 'VEHICLE', 'AUTO_SERVICE', 'CAR_SERVICE', 'GARAGE', 'WORKSHOP'],
    clientCategoryName: 'automotive',
    defaultServices: [
      ServiceTemplate(
        name: 'Periodic Maintenance Service',
        code: 'P',
        durationMinutes: 60,
        description: 'Scheduled manufacturer maintenance check & 40-point safety inspection',
      ),
      ServiceTemplate(
        name: 'Express Oil & Filter Change',
        code: 'O',
        durationMinutes: 20,
        description: 'Quick engine oil, oil filter, air filter replacement & fluid top-up',
      ),
      ServiceTemplate(
        name: 'Wheel Alignment & Balancing',
        code: 'W',
        durationMinutes: 30,
        description: 'Computerized 3D wheel alignment, tyre balancing & rotation',
      ),
      ServiceTemplate(
        name: 'Vehicle Wash & Detailing',
        code: 'V',
        durationMinutes: 25,
        description: 'Exterior high-pressure foam wash, vacuuming & interior wipe down',
      ),
      ServiceTemplate(
        name: 'Mechanical & Electrical Repair',
        code: 'R',
        durationMinutes: 45,
        description: 'Brake pad replacement, battery test, AC service & diagnostic check',
      ),
    ],
  );

  // 5. Restaurants and food outlets (Target: Medium–High, Rank 5)
  static const BusinessCategoryInfo restaurant = BusinessCategoryInfo(
    id: 'RESTAURANT',
    displayName: 'Restaurants & Food Outlets',
    subtitle: 'Dine-in restaurants, cafes, food courts, quick service (QSR) & takeaway',
    marketPriority: 'Medium–High',
    marketRank: 5,
    icon: Icons.restaurant_outlined,
    aliases: ['FOOD_OUTLET', 'CAFE', 'DINE_IN', 'QSR', 'FAST_FOOD', 'FOOD'],
    clientCategoryName: 'restaurant',
    defaultServices: [
      ServiceTemplate(
        name: 'Dine-In Table Seating (1-4 Guests)',
        code: 'T',
        durationMinutes: 15,
        description: 'Table seating queue for individuals, couples, and small groups',
      ),
      ServiceTemplate(
        name: 'Large Group Table (5+ Guests)',
        code: 'L',
        durationMinutes: 20,
        description: 'Dining table allocation for large family parties and groups',
      ),
      ServiceTemplate(
        name: 'Takeaway & Parcel Pick-up',
        code: 'P',
        durationMinutes: 10,
        description: 'Self-pickup counter for takeaway food parcels and online orders',
      ),
      ServiceTemplate(
        name: 'Express Counter Order',
        code: 'O',
        durationMinutes: 8,
        description: 'Quick service ordering counter and bill settlement',
      ),
    ],
  );

  // 6. Government offices (Target: High, Rank 6)
  static const BusinessCategoryInfo government = BusinessCategoryInfo(
    id: 'GOVERNMENT',
    displayName: 'Government Offices',
    subtitle: 'Civic centers, passport/visa seva, RTO transport, municipal & public counters',
    marketPriority: 'High',
    marketRank: 6,
    icon: Icons.account_balance_outlined,
    aliases: ['PUBLIC_SECTOR', 'CIVIC', 'MUNICIPAL', 'GOVT'],
    clientCategoryName: 'government',
    defaultServices: [
      ServiceTemplate(
        name: 'Document Verification',
        code: 'D',
        durationMinutes: 15,
        description: 'Original certificates, identity proofs & application dossier review',
      ),
      ServiceTemplate(
        name: 'Certificate & License Issuance',
        code: 'C',
        durationMinutes: 20,
        description: 'Birth/caste certificates, driving license, registration certificates',
      ),
      ServiceTemplate(
        name: 'Public Grievance & Enquiries',
        code: 'G',
        durationMinutes: 10,
        description: 'Citizen complaint desk, RTI requests, and public information center',
      ),
      ServiceTemplate(
        name: 'Revenue & Tax Counter',
        code: 'R',
        durationMinutes: 15,
        description: 'Property tax collection, challan deposit & municipal fee payments',
      ),
    ],
  );

  // 7. Banks & Financial Institutions (Rank 7)
  static const BusinessCategoryInfo banking = BusinessCategoryInfo(
    id: 'BANKING',
    displayName: 'Banks & Financial Institutions',
    subtitle: 'Retail bank branches, credit unions, loan centers, forex & customer support',
    marketPriority: 'Enterprise',
    marketRank: 7,
    icon: Icons.account_balance_wallet_outlined,
    aliases: ['BANK', 'FINANCE', 'FINANCIAL', 'CREDIT_UNION'],
    clientCategoryName: 'bank',
    defaultServices: [
      ServiceTemplate(
        name: 'Cash Deposit & Withdrawal',
        code: 'C',
        durationMinutes: 8,
        description: 'Teller counter for cash transactions, deposits, and withdrawal slips',
      ),
      ServiceTemplate(
        name: 'Account Opening & KYC',
        code: 'A',
        durationMinutes: 20,
        description: 'Savings/current account opening, KYC re-verification & debit card issues',
      ),
      ServiceTemplate(
        name: 'Loans & Credit Advisory',
        code: 'L',
        durationMinutes: 25,
        description: 'Personal, auto, home loan applications and mortgage consultation',
      ),
      ServiceTemplate(
        name: 'Forex & Remittance Desk',
        code: 'F',
        durationMinutes: 15,
        description: 'Foreign exchange currency, demand drafts & international transfers',
      ),
      ServiceTemplate(
        name: 'Senior Citizen & Priority Desk',
        code: 'P',
        durationMinutes: 10,
        description: 'Dedicated priority banking counter for senior citizens and pensioners',
      ),
    ],
  );

  // 7b. Large Hospitals & Medical Centres (Rank 7)
  static const BusinessCategoryInfo hospital = BusinessCategoryInfo(
    id: 'HOSPITAL',
    displayName: 'Large Hospitals & Medical Centres',
    subtitle: 'Multi-specialty hospitals, triage, emergency, OPD wings, inpatient & billing',
    marketPriority: 'Enterprise',
    marketRank: 7,
    icon: Icons.local_hospital_outlined,
    aliases: ['HEALTHCARE', 'MEDICAL_CENTER', 'HOSPITALS'],
    clientCategoryName: 'hospital',
    defaultServices: [
      ServiceTemplate(
        name: 'Emergency & Triage Intake',
        code: 'E',
        durationMinutes: 5,
        description: 'Immediate trauma, critical care triage and emergency admissions',
      ),
      ServiceTemplate(
        name: 'Outpatient Consultation (OPD)',
        code: 'O',
        durationMinutes: 15,
        description: 'General medicine, pediatric, ENT, and orthopedic OPD consultations',
      ),
      ServiceTemplate(
        name: 'Specialist Clinic',
        code: 'S',
        durationMinutes: 20,
        description: 'Cardiology, oncology, neurology & super-specialist consultations',
      ),
      ServiceTemplate(
        name: 'Hospital Pharmacy Counter',
        code: 'P',
        durationMinutes: 8,
        description: 'Inpatient and outpatient prescription drug dispensation',
      ),
      ServiceTemplate(
        name: 'Admission, Billing & Insurance',
        code: 'B',
        durationMinutes: 15,
        description: 'Cashless TPA insurance desk, bed allocation & final discharge billing',
      ),
    ],
  );

  // 8. Retail & Supermarkets
  static const BusinessCategoryInfo retail = BusinessCategoryInfo(
    id: 'RETAIL',
    displayName: 'Retail Stores & Supermarkets',
    subtitle: 'Supermarkets, department stores, electronics repair & checkout queues',
    marketPriority: 'Medium',
    marketRank: 8,
    icon: Icons.shopping_bag_outlined,
    aliases: ['SUPERMARKET', 'SHOPPING', 'STORE'],
    clientCategoryName: 'retail',
    defaultServices: [
      ServiceTemplate(
        name: 'Billing & Checkout Counter',
        code: 'B',
        durationMinutes: 8,
        description: 'Express and regular barcode billing and payment counter',
      ),
      ServiceTemplate(
        name: 'Customer Support & Returns',
        code: 'R',
        durationMinutes: 12,
        description: 'Product exchange, returns processing, and warranty service requests',
      ),
    ],
  );

  // 9. Education & Institutes
  static const BusinessCategoryInfo education = BusinessCategoryInfo(
    id: 'EDUCATION',
    displayName: 'Educational Institutes',
    subtitle: 'Universities, colleges, student admissions, fee counters & counseling',
    marketPriority: 'Medium',
    marketRank: 9,
    icon: Icons.school_outlined,
    aliases: ['COLLEGE', 'UNIVERSITY', 'SCHOOL', 'INSTITUTE'],
    clientCategoryName: 'all',
    defaultServices: [
      ServiceTemplate(
        name: 'Admissions & Document Review',
        code: 'A',
        durationMinutes: 20,
        description: 'Student admission counseling, merit verification & enrollment desk',
      ),
      ServiceTemplate(
        name: 'Fees & Accounts Counter',
        code: 'F',
        durationMinutes: 10,
        description: 'Tuition fee payments, scholarship clearance & receipt issuance',
      ),
    ],
  );

  // 10. General & Other Businesses
  static const BusinessCategoryInfo general = BusinessCategoryInfo(
    id: 'GENERAL',
    displayName: 'General Organization',
    subtitle: 'Standard queue management for any office, reception, or customer desk',
    marketPriority: 'Standard',
    marketRank: 10,
    icon: Icons.store_outlined,
    aliases: ['OTHER', 'DEFAULT'],
    clientCategoryName: 'all',
    defaultServices: [
      ServiceTemplate(
        name: 'General Service',
        code: 'A',
        durationMinutes: 15,
        description: 'Standard visitor reception and customer assistance counter',
      ),
    ],
  );

  /// All supported industry categories in ranked/priority order.
  static const List<BusinessCategoryInfo> all = [
    clinicDentist,
    diagnostic,
    salonBarber,
    vehicleService,
    restaurant,
    government,
    banking,
    hospital,
    retail,
    education,
    general,
  ];

  /// Find category info by key or alias (case-insensitive).
  static BusinessCategoryInfo find(String? keyOrAlias) {
    if (keyOrAlias == null || keyOrAlias.trim().isEmpty) {
      return general;
    }
    final clean = keyOrAlias.trim().toUpperCase();

    for (final cat in all) {
      if (cat.id == clean) return cat;
      if (cat.aliases.any((alias) => alias.toUpperCase() == clean)) return cat;
    }

    // Secondary substring match
    if (clean.contains('CLINIC') || clean.contains('DENT')) return clinicDentist;
    if (clean.contains('DIAGNOSTIC') || clean.contains('LAB') || clean.contains('PATHOLOGY')) return diagnostic;
    if (clean.contains('SALON') || clean.contains('BARBER') || clean.contains('SPA')) return salonBarber;
    if (clean.contains('VEHICLE') || clean.contains('AUTO') || clean.contains('CAR') || clean.contains('GARAGE')) return vehicleService;
    if (clean.contains('RESTAURANT') || clean.contains('FOOD') || clean.contains('CAFE')) return restaurant;
    if (clean.contains('GOV')) return government;
    if (clean.contains('BANK') || clean.contains('FINANC')) return banking;
    if (clean.contains('HOSPITAL') || clean.contains('HEALTH')) return hospital;
    if (clean.contains('RETAIL') || clean.contains('SHOP')) return retail;
    if (clean.contains('EDU') || clean.contains('SCHOOL') || clean.contains('COLLEGE')) return education;

    return general;
  }
}
