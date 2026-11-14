import 'package:flutter/material.dart';
import 'business_categories.dart';

/// Representation of a specific organization sub-type (e.g. Dental clinics, RTO offices, Spas).
class OrganizationSubCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final List<String> aliases;
  final bool isCustom;
  final List<ServiceTemplate> defaultServices;

  const OrganizationSubCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.description = '',
    this.aliases = const [],
    this.isCustom = false,
    this.defaultServices = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCustom': isCustom,
    };
  }

  factory OrganizationSubCategory.fromCustomName(String name, {IconData icon = Icons.business_outlined}) {
    final cleanId = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return OrganizationSubCategory(
      id: cleanId.isEmpty ? 'custom_org' : cleanId,
      name: name.trim(),
      icon: icon,
      description: 'Custom organization classification',
      isCustom: true,
      defaultServices: [
        ServiceTemplate(
          name: '${name.trim()} Service',
          code: name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : 'A',
          durationMinutes: 15,
          description: 'Standard queue service for ${name.trim()}',
        ),
      ],
    );
  }
}

/// A top-level Industry / Organization category (A through O) with full sub-category hierarchy.
class OrganizationCategory {
  final String id;
  final String code; // 'A', 'B', 'C', ..., 'O'
  final String name;
  final String description;
  final IconData icon;
  final Color brandColor;
  final List<String> aliases;
  final List<OrganizationSubCategory> subCategories;
  final List<ServiceTemplate> defaultServices;

  const OrganizationCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    this.brandColor = const Color(0xFF2563EB),
    this.aliases = const [],
    required this.subCategories,
    required this.defaultServices,
  });

  /// Retrieve sub-category by ID or name
  OrganizationSubCategory? findSubCategory(String? subCategoryNameOrId) {
    if (subCategoryNameOrId == null || subCategoryNameOrId.trim().isEmpty) return null;
    final clean = subCategoryNameOrId.trim().toLowerCase();

    for (final sub in subCategories) {
      if (sub.id.toLowerCase() == clean || sub.name.toLowerCase() == clean) {
        return sub;
      }
      if (sub.aliases.any((a) => a.toLowerCase() == clean)) {
        return sub;
      }
    }

    // Substring match
    for (final sub in subCategories) {
      if (clean.contains(sub.name.toLowerCase()) || sub.name.toLowerCase().contains(clean)) {
        return sub;
      }
    }

    return null;
  }
}

/// Central manager for dynamic organization category and sub-category management.
class OrganizationCategoryManager {
  // A. Healthcare & Medical
  static const OrganizationCategory healthcare = OrganizationCategory(
    id: 'HEALTHCARE',
    code: 'A',
    name: 'Healthcare & Medical',
    description: 'Hospitals, specialty clinics, dental practices, diagnostic labs, scans & pharmacies',
    icon: Icons.local_hospital_outlined,
    brandColor: Color(0xFFE11D48),
    aliases: ['HEALTH', 'MEDICAL', 'CLINIC_DENTIST', 'DIAGNOSTIC', 'HOSPITAL'],
    defaultServices: [
      ServiceTemplate(name: 'Doctor Consultation', code: 'C', durationMinutes: 15, description: 'Physician / specialist consultation'),
      ServiceTemplate(name: 'Emergency & Triage', code: 'E', durationMinutes: 5, description: 'Immediate trauma and triage intake'),
      ServiceTemplate(name: 'Pharmacy & Medicine', code: 'P', durationMinutes: 8, description: 'Prescription dispensation'),
      ServiceTemplate(name: 'Diagnostic & Lab Sample', code: 'L', durationMinutes: 10, description: 'Blood and diagnostic collection'),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'hospitals',
        name: 'Hospitals',
        icon: Icons.local_hospital_outlined,
        description: 'Multi-speciality hospitals, emergency, surgery & inpatient admissions',
        defaultServices: [
          ServiceTemplate(name: 'Emergency Intake & Triage', code: 'E', durationMinutes: 5),
          ServiceTemplate(name: 'Outpatient OPD Consultation', code: 'O', durationMinutes: 15),
          ServiceTemplate(name: 'Hospital Pharmacy Counter', code: 'P', durationMinutes: 8),
          ServiceTemplate(name: 'Admission, TPA & Billing', code: 'B', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'multi_speciality_clinics',
        name: 'Multi-speciality clinics',
        icon: Icons.medical_services_outlined,
        description: 'Group practices, polyclinics & multi-doctor OPD centers',
        defaultServices: [
          ServiceTemplate(name: 'Specialist Consultation', code: 'S', durationMinutes: 20),
          ServiceTemplate(name: 'General Practitioner OPD', code: 'G', durationMinutes: 15),
          ServiceTemplate(name: 'Nursing & Vital Checks', code: 'N', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'dental_clinics',
        name: 'Dental clinics',
        icon: Icons.health_and_safety_outlined,
        description: 'Dental surgery, cleaning, scaling, orthodontic & implants',
        aliases: ['DENTIST', 'DENTAL'],
        defaultServices: [
          ServiceTemplate(name: 'Dental Checkup & Cleaning', code: 'D', durationMinutes: 30),
          ServiceTemplate(name: 'Tooth Extraction & Procedure', code: 'T', durationMinutes: 40),
          ServiceTemplate(name: 'Root Canal & Consultation', code: 'R', durationMinutes: 35),
          ServiceTemplate(name: 'Follow-up & Dressing', code: 'F', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'diagnostic_laboratories',
        name: 'Diagnostic laboratories',
        icon: Icons.biotech_outlined,
        description: 'Pathology testing, blood analysis, urine cultures & report collection',
        aliases: ['LAB', 'PATHOLOGY'],
        defaultServices: [
          ServiceTemplate(name: 'Blood & Sample Collection', code: 'B', durationMinutes: 10),
          ServiceTemplate(name: 'Routine Pathology', code: 'P', durationMinutes: 10),
          ServiceTemplate(name: 'Report Collection & Query', code: 'R', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'scan_centres',
        name: 'Scan centres',
        icon: Icons.scanner_outlined,
        description: 'MRI, CT scan, ultrasound sonography, PET & digital radiology',
        aliases: ['SCAN', 'RADIOLOGY', 'ULTRASOUND'],
        defaultServices: [
          ServiceTemplate(name: 'Ultrasound & Sonography', code: 'U', durationMinutes: 20),
          ServiceTemplate(name: 'MRI & CT Scan', code: 'M', durationMinutes: 30),
          ServiceTemplate(name: 'Digital X-Ray', code: 'X', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'pharmacies',
        name: 'Pharmacies',
        icon: Icons.medication_outlined,
        description: 'Retail chemist, prescription drugs, health supplements & medical supplies',
        aliases: ['CHEMIST', 'DRUGSTORE'],
        defaultServices: [
          ServiceTemplate(name: 'Prescription Drug Dispensation', code: 'P', durationMinutes: 8),
          ServiceTemplate(name: 'OTC Healthcare Products', code: 'O', durationMinutes: 5),
          ServiceTemplate(name: 'BP & Blood Sugar Vitals', code: 'V', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'eye_clinics',
        name: 'Eye clinics',
        icon: Icons.visibility_outlined,
        description: 'Ophthalmology, vision refractive test, spectacles, cataract & laser care',
        aliases: ['OPTOMETRIST', 'OPHTHALMOLOGY'],
        defaultServices: [
          ServiceTemplate(name: 'Vision Testing & Refraction', code: 'V', durationMinutes: 15),
          ServiceTemplate(name: 'Ophthalmologist Consultation', code: 'O', durationMinutes: 20),
          ServiceTemplate(name: 'Lens & Eyewear Fitting', code: 'L', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'physiotherapy_centres',
        name: 'Physiotherapy centres',
        icon: Icons.accessibility_new_outlined,
        description: 'Physical rehab, spine therapy, sports injury rehabilitation & mobility',
        aliases: ['PHYSIO', 'REHAB'],
        defaultServices: [
          ServiceTemplate(name: 'Physical Therapy & Rehab', code: 'P', durationMinutes: 40),
          ServiceTemplate(name: 'Pain Management & Heat Therapy', code: 'H', durationMinutes: 30),
          ServiceTemplate(name: 'Mobility & Posture Assessment', code: 'M', durationMinutes: 20),
        ],
      ),
      OrganizationSubCategory(
        id: 'veterinary_clinics',
        name: 'Veterinary clinics',
        icon: Icons.pets_outlined,
        description: 'Pet medical consultation, animal vaccination, surgery & pet health',
        aliases: ['VET', 'PET_CLINIC', 'ANIMAL_HOSPITAL'],
        defaultServices: [
          ServiceTemplate(name: 'Pet Doctor Consultation', code: 'P', durationMinutes: 20),
          ServiceTemplate(name: 'Pet Vaccination & Deworming', code: 'V', durationMinutes: 15),
          ServiceTemplate(name: 'Wound Dressing & Grooming', code: 'G', durationMinutes: 25),
        ],
      ),
      OrganizationSubCategory(
        id: 'blood_collection_centres',
        name: 'Blood collection centres',
        icon: Icons.bloodtype_outlined,
        description: 'Blood donation screening, phlebotomy, plasma donation & donor registration',
        aliases: ['BLOOD_BANK', 'PHLEBOTOMY'],
        defaultServices: [
          ServiceTemplate(name: 'Donor Screening & Hemoglobin Test', code: 'S', durationMinutes: 10),
          ServiceTemplate(name: 'Blood Donation Couch', code: 'D', durationMinutes: 20),
          ServiceTemplate(name: 'Refreshment & Donor Certificate', code: 'R', durationMinutes: 10),
        ],
      ),
    ],
  );

  // B. Banking & Financial Services
  static const OrganizationCategory banking = OrganizationCategory(
    id: 'BANKING',
    code: 'B',
    name: 'Banking & Financial Services',
    description: 'Retail banks, NBFCs, microfinance, insurance, loans, cooperatives & currency exchange',
    icon: Icons.account_balance_outlined,
    brandColor: Color(0xFF1E40AF),
    aliases: ['BANK', 'FINANCE', 'FINANCIAL_SERVICES'],
    defaultServices: [
      ServiceTemplate(name: 'Cash Deposit & Withdrawal', code: 'C', durationMinutes: 8),
      ServiceTemplate(name: 'Account Opening & KYC', code: 'A', durationMinutes: 20),
      ServiceTemplate(name: 'Loan & Credit Advisory', code: 'L', durationMinutes: 25),
      ServiceTemplate(name: 'Forex & Remittance', code: 'F', durationMinutes: 15),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'banks',
        name: 'Banks',
        icon: Icons.account_balance_outlined,
        description: 'Commercial banks, retail branch counters, cash handling & customer service',
        defaultServices: [
          ServiceTemplate(name: 'Teller Cash Deposit & Withdrawal', code: 'C', durationMinutes: 8),
          ServiceTemplate(name: 'New Account Opening & KYC', code: 'A', durationMinutes: 20),
          ServiceTemplate(name: 'Passbook & Cheque Services', code: 'P', durationMinutes: 10),
          ServiceTemplate(name: 'Senior Citizen & Priority Banking', code: 'S', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'nbfcs',
        name: 'NBFCs',
        icon: Icons.account_balance_wallet_outlined,
        description: 'Non-banking financial corporations, asset financing & commercial loans',
        aliases: ['NBFC'],
        defaultServices: [
          ServiceTemplate(name: 'Gold Loan Valuation & Disbursal', code: 'G', durationMinutes: 20),
          ServiceTemplate(name: 'Vehicle & Asset Loan Desk', code: 'V', durationMinutes: 25),
          ServiceTemplate(name: 'EMI Repayment & Statement', code: 'E', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'insurance_offices',
        name: 'Insurance offices',
        icon: Icons.security_outlined,
        description: 'Life, health, vehicle, and property insurance policy and claims desks',
        aliases: ['INSURANCE'],
        defaultServices: [
          ServiceTemplate(name: 'Policy Consultation & Issuance', code: 'P', durationMinutes: 25),
          ServiceTemplate(name: 'Insurance Claim Settlement Desk', code: 'C', durationMinutes: 30),
          ServiceTemplate(name: 'Premium Payment & Renewal', code: 'R', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'loan_processing_centres',
        name: 'Loan processing centres',
        icon: Icons.request_quote_outlined,
        description: 'Home loan hubs, personal credit underwriting & mortgage document sanction',
        aliases: ['LOAN_CENTER'],
        defaultServices: [
          ServiceTemplate(name: 'Document Verification & Eligibility', code: 'D', durationMinutes: 20),
          ServiceTemplate(name: 'Loan Agreement & Sanction Letter', code: 'S', durationMinutes: 25),
          ServiceTemplate(name: 'Disbursement & Cheque Handover', code: 'L', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'microfinance_institutions',
        name: 'Microfinance institutions',
        icon: Icons.groups_outlined,
        description: 'SHG group financing, rural credit & small business micro-loans',
        aliases: ['MFI', 'MICROFINANCE'],
        defaultServices: [
          ServiceTemplate(name: 'Group Loan Meeting & Disbursal', code: 'G', durationMinutes: 30),
          ServiceTemplate(name: 'Weekly Installment Collection', code: 'I', durationMinutes: 10),
          ServiceTemplate(name: 'Member Enrollment & Passbook', code: 'M', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'cooperative_societies',
        name: 'Cooperative societies',
        icon: Icons.handshake_outlined,
        description: 'Credit cooperatives, housing society offices & member financial counters',
        aliases: ['COOPERATIVE'],
        defaultServices: [
          ServiceTemplate(name: 'Member Savings Deposit & Loan', code: 'S', durationMinutes: 15),
          ServiceTemplate(name: 'Dividend & Share Clearance', code: 'D', durationMinutes: 12),
          ServiceTemplate(name: 'Membership Application Counter', code: 'M', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'currency_exchange_centres',
        name: 'Currency exchange centres',
        icon: Icons.currency_exchange_outlined,
        description: 'Foreign exchange forex, international travel card & outward remittance',
        aliases: ['FOREX', 'CURRENCY_EXCHANGE'],
        defaultServices: [
          ServiceTemplate(name: 'Foreign Currency Buy & Sell', code: 'F', durationMinutes: 12),
          ServiceTemplate(name: 'International Wire Remittance', code: 'R', durationMinutes: 20),
          ServiceTemplate(name: 'Multi-Currency Travel Card', code: 'T', durationMinutes: 15),
        ],
      ),
    ],
  );

  // C. Government & Public Services
  static const OrganizationCategory government = OrganizationCategory(
    id: 'GOVERNMENT',
    code: 'C',
    name: 'Government & Public Services',
    description: 'RTO, passport seva, municipal offices, Aadhaar centers, tax & public registration',
    icon: Icons.assured_workload_outlined,
    brandColor: Color(0xFF0F766E),
    aliases: ['CIVIC', 'PUBLIC_SECTOR', 'GOVT'],
    defaultServices: [
      ServiceTemplate(name: 'Document Verification', code: 'D', durationMinutes: 15),
      ServiceTemplate(name: 'Certificate & License Issuance', code: 'C', durationMinutes: 20),
      ServiceTemplate(name: 'Public Grievance & Enquiries', code: 'G', durationMinutes: 10),
      ServiceTemplate(name: 'Revenue & Tax Counter', code: 'R', durationMinutes: 15),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'rto_offices',
        name: 'RTO offices',
        icon: Icons.directions_car_filled_outlined,
        description: 'Regional transport offices, learner & driving license, vehicle registration RC',
        aliases: ['RTO', 'TRANSPORT_OFFICE'],
        defaultServices: [
          ServiceTemplate(name: 'Driving License Test & Issuance', code: 'L', durationMinutes: 20),
          ServiceTemplate(name: 'Vehicle RC Registration & Transfer', code: 'R', durationMinutes: 20),
          ServiceTemplate(name: 'Fitness Certificate & Permit Desk', code: 'P', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'passport_service_centres',
        name: 'Passport service centres',
        icon: Icons.menu_book_outlined,
        description: 'Passport Seva Kendra, document scrutiny, biometric verification & granting',
        aliases: ['PASSPORT', 'PSK'],
        defaultServices: [
          ServiceTemplate(name: 'Document Scrutiny (Counter A)', code: 'A', durationMinutes: 15),
          ServiceTemplate(name: 'Biometrics & Photo (Counter B)', code: 'B', durationMinutes: 10),
          ServiceTemplate(name: 'Granting Officer Interview (Counter C)', code: 'C', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'municipal_offices',
        name: 'Municipal offices',
        icon: Icons.location_city_outlined,
        description: 'City municipal corporation, property tax, trade license, birth & death records',
        aliases: ['MUNICIPAL', 'CORPORATION'],
        defaultServices: [
          ServiceTemplate(name: 'Property Tax & Water Bills', code: 'T', durationMinutes: 12),
          ServiceTemplate(name: 'Birth & Death Certificate Counter', code: 'C', durationMinutes: 15),
          ServiceTemplate(name: 'Trade License & Building Permits', code: 'P', durationMinutes: 20),
        ],
      ),
      OrganizationSubCategory(
        id: 'government_hospitals',
        name: 'Government hospitals',
        icon: Icons.local_hospital_outlined,
        description: 'Public health centers, civil hospitals, state medical facilities & free OPD',
        aliases: ['GOVT_HOSPITAL', 'CIVIL_HOSPITAL'],
        defaultServices: [
          ServiceTemplate(name: 'Free General Medicine OPD', code: 'O', durationMinutes: 10),
          ServiceTemplate(name: 'Trauma & Emergency Intake', code: 'E', durationMinutes: 5),
          ServiceTemplate(name: 'Free Government Pharmacy Supply', code: 'P', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'aadhaar_service_centres',
        name: 'Aadhaar service centres',
        icon: Icons.fingerprint_outlined,
        description: 'UIDAI Aadhaar enrollment, biometric iris update, address & phone update',
        aliases: ['AADHAAR', 'UIDAI'],
        defaultServices: [
          ServiceTemplate(name: 'New Aadhaar Enrollment', code: 'N', durationMinutes: 20),
          ServiceTemplate(name: 'Biometric & Photo Update', code: 'B', durationMinutes: 15),
          ServiceTemplate(name: 'Address & Mobile Demographic Update', code: 'D', durationMinutes: 12),
        ],
      ),
      OrganizationSubCategory(
        id: 'registration_offices',
        name: 'Registration offices',
        icon: Icons.app_registration_outlined,
        description: 'Sub-registrar office, land deed registration, marriage certificate & stamp duty',
        aliases: ['REGISTRAR', 'SUB_REGISTRAR'],
        defaultServices: [
          ServiceTemplate(name: 'Property Deed Registration', code: 'P', durationMinutes: 30),
          ServiceTemplate(name: 'Marriage Registration & Signing', code: 'M', durationMinutes: 25),
          ServiceTemplate(name: 'Certified Copy & Valuation Slip', code: 'C', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'tax_offices',
        name: 'Tax offices',
        icon: Icons.receipt_long_outlined,
        description: 'Income Tax, GST Bhavan, commercial tax assessment & public assistance',
        aliases: ['INCOME_TAX', 'GST_OFFICE'],
        defaultServices: [
          ServiceTemplate(name: 'GST Registration & Query Desk', code: 'G', durationMinutes: 20),
          ServiceTemplate(name: 'Assessment & Challan Filing', code: 'A', durationMinutes: 25),
          ServiceTemplate(name: 'PAN & Refund Grievance Cell', code: 'P', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'citizen_service_centres',
        name: 'Citizen service centres',
        icon: Icons.public_outlined,
        description: 'Seva Kendra, CSC centers, e-Mitra, MeeSeva, Suvidha & unified counters',
        aliases: ['CSC', 'SEVA_KENDRA', 'E_MITRA'],
        defaultServices: [
          ServiceTemplate(name: 'Single Window Certificate Application', code: 'C', durationMinutes: 15),
          ServiceTemplate(name: 'Welfare Pension & Scheme Enrollment', code: 'W', durationMinutes: 20),
          ServiceTemplate(name: 'Utility Bill Payment & Form Upload', code: 'U', durationMinutes: 10),
        ],
      ),
    ],
  );

  // D. Personal Care & Wellness
  static const OrganizationCategory personalCare = OrganizationCategory(
    id: 'PERSONAL_CARE',
    code: 'D',
    name: 'Personal Care & Wellness',
    description: 'Hair salons, barbershops, beauty parlours, spas, massage, tattoo & fitness yoga studios',
    icon: Icons.spa_outlined,
    brandColor: Color(0xFFD97706),
    aliases: ['SALON', 'BARBER', 'SPA', 'WELLNESS', 'SALON_BARBER'],
    defaultServices: [
      ServiceTemplate(name: 'Haircut & Styling', code: 'H', durationMinutes: 25),
      ServiceTemplate(name: 'Beard Trim & Shave', code: 'B', durationMinutes: 15),
      ServiceTemplate(name: 'Facial & Skin Care', code: 'F', durationMinutes: 30),
      ServiceTemplate(name: 'Body Massage & Spa', code: 'S', durationMinutes: 45),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'hair_salons',
        name: 'Hair salons',
        icon: Icons.content_cut_outlined,
        description: 'Barber shops, hair styling, beard grooming, hair wash & treatments',
        aliases: ['BARBERSHOP', 'HAIR_SALON'],
        defaultServices: [
          ServiceTemplate(name: 'Haircut & Styling', code: 'H', durationMinutes: 25),
          ServiceTemplate(name: 'Hot Towel Beard Shave & Trim', code: 'B', durationMinutes: 15),
          ServiceTemplate(name: 'Hair Wash & Conditioning', code: 'W', durationMinutes: 15),
          ServiceTemplate(name: 'Hair Color & Keratin', code: 'C', durationMinutes: 45),
        ],
      ),
      OrganizationSubCategory(
        id: 'beauty_parlours',
        name: 'Beauty parlours',
        icon: Icons.face_retouching_natural_outlined,
        description: 'Women beauty parlor, facial, waxing, threading, bridal makeup & skincare',
        aliases: ['BEAUTY_SALON', 'PARLOUR'],
        defaultServices: [
          ServiceTemplate(name: 'Skin Rejuvenating Facial', code: 'F', durationMinutes: 35),
          ServiceTemplate(name: 'Threading & Waxing Counter', code: 'T', durationMinutes: 20),
          ServiceTemplate(name: 'Manicure & Pedicure', code: 'M', durationMinutes: 30),
          ServiceTemplate(name: 'Bridal & Party Makeup', code: 'B', durationMinutes: 60),
        ],
      ),
      OrganizationSubCategory(
        id: 'spas',
        name: 'Spas',
        icon: Icons.hot_tub_outlined,
        description: 'Luxury wellness spa, aromatherapy, body wraps, steam & sauna',
        aliases: ['SPA'],
        defaultServices: [
          ServiceTemplate(name: 'Aromatherapy Full Body Spa', code: 'A', durationMinutes: 60),
          ServiceTemplate(name: 'Steam, Sauna & Jacuzzi', code: 'S', durationMinutes: 30),
          ServiceTemplate(name: 'Detoxifying Body Scrub', code: 'D', durationMinutes: 40),
        ],
      ),
      OrganizationSubCategory(
        id: 'massage_centres',
        name: 'Massage centres',
        icon: Icons.self_improvement_outlined,
        description: 'Deep tissue massage, Swedish massage, foot reflexology & therapeutic relief',
        aliases: ['MASSAGE'],
        defaultServices: [
          ServiceTemplate(name: 'Deep Tissue & Swedish Massage', code: 'M', durationMinutes: 50),
          ServiceTemplate(name: 'Foot Reflexology Lounge', code: 'F', durationMinutes: 30),
          ServiceTemplate(name: 'Head, Neck & Shoulder Relief', code: 'H', durationMinutes: 25),
        ],
      ),
      OrganizationSubCategory(
        id: 'tattoo_studios',
        name: 'Tattoo studios',
        icon: Icons.brush_outlined,
        description: 'Custom tattoo design, body piercing, sterilization & permanent ink artists',
        aliases: ['TATTOO', 'PIERCING'],
        defaultServices: [
          ServiceTemplate(name: 'Tattoo Design Consultation', code: 'C', durationMinutes: 20),
          ServiceTemplate(name: 'Tattoo Inking Session', code: 'T', durationMinutes: 60),
          ServiceTemplate(name: 'Body Piercing & Aftercare', code: 'P', durationMinutes: 20),
        ],
      ),
      OrganizationSubCategory(
        id: 'fitness_centres',
        name: 'Fitness centres',
        icon: Icons.fitness_center_outlined,
        description: 'Gyms, crossfit boxes, personal training assessment & workout facilities',
        aliases: ['GYM', 'FITNESS'],
        defaultServices: [
          ServiceTemplate(name: 'Gym Membership & Facility Tour', code: 'M', durationMinutes: 15),
          ServiceTemplate(name: 'Personal Trainer Body Assessment', code: 'P', durationMinutes: 25),
          ServiceTemplate(name: 'Nutrition & Diet Consultation', code: 'D', durationMinutes: 20),
        ],
      ),
      OrganizationSubCategory(
        id: 'yoga_centres',
        name: 'Yoga centres',
        icon: Icons.sports_gymnastics_outlined,
        description: 'Hatha yoga, meditation, breathwork pranayama & sound healing classes',
        aliases: ['YOGA', 'MEDITATION'],
        defaultServices: [
          ServiceTemplate(name: 'Yoga Class Check-in & Trial', code: 'Y', durationMinutes: 15),
          ServiceTemplate(name: 'Private Meditation & Breathwork', code: 'M', durationMinutes: 30),
          ServiceTemplate(name: 'Holistic Wellness Guidance', code: 'H', durationMinutes: 25),
        ],
      ),
    ],
  );

  // E. Automobile & Repair Services
  static const OrganizationCategory automobile = OrganizationCategory(
    id: 'AUTOMOBILE_REPAIR',
    code: 'E',
    name: 'Automobile & Repair Services',
    description: 'Car service, two-wheeler maintenance, tyre shops, vehicle wash, electronic & mobile repair',
    icon: Icons.directions_car_outlined,
    brandColor: Color(0xFF4B5563),
    aliases: ['VEHICLE_SERVICE', 'AUTOMOTIVE', 'AUTO', 'REPAIR'],
    defaultServices: [
      ServiceTemplate(name: 'Periodic Maintenance Service', code: 'P', durationMinutes: 60),
      ServiceTemplate(name: 'Express Oil & Filter Change', code: 'O', durationMinutes: 20),
      ServiceTemplate(name: 'Wheel Alignment & Balancing', code: 'W', durationMinutes: 30),
      ServiceTemplate(name: 'Vehicle Wash & Detailing', code: 'V', durationMinutes: 25),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'car_service_centres',
        name: 'Car service centres',
        icon: Icons.car_repair_outlined,
        description: 'Authorized 4W car service, engine tune-up, diagnostics & mechanical repair',
        aliases: ['CAR_SERVICE', 'AUTO_WORKSHOP'],
        defaultServices: [
          ServiceTemplate(name: 'Periodic Maintenance Service (PMS)', code: 'P', durationMinutes: 60),
          ServiceTemplate(name: 'Express Oil & Lube Service', code: 'O', durationMinutes: 20),
          ServiceTemplate(name: 'Brake, AC & Suspension Repair', code: 'R', durationMinutes: 45),
        ],
      ),
      OrganizationSubCategory(
        id: 'two_wheeler_service_centres',
        name: 'Two-wheeler service centres',
        icon: Icons.two_wheeler_outlined,
        description: 'Motorcycle, scooter service centers, chain lube, carburetor & electrical',
        aliases: ['BIKE_SERVICE', '2W_SERVICE'],
        defaultServices: [
          ServiceTemplate(name: 'General Bike Service & Tune-up', code: 'S', durationMinutes: 35),
          ServiceTemplate(name: 'Engine Oil & Chain Lube', code: 'O', durationMinutes: 15),
          ServiceTemplate(name: 'Brake Shoe & Electrical Work', code: 'E', durationMinutes: 25),
        ],
      ),
      OrganizationSubCategory(
        id: 'vehicle_inspection_centres',
        name: 'Vehicle inspection centres',
        icon: Icons.fact_check_outlined,
        description: 'PUC emission test, annual vehicle roadworthiness & road safety testing',
        aliases: ['PUC', 'VEHICLE_INSPECTION'],
        defaultServices: [
          ServiceTemplate(name: 'PUC Smoke & Emission Testing', code: 'P', durationMinutes: 10),
          ServiceTemplate(name: 'Roadworthiness & Brake Test', code: 'R', durationMinutes: 20),
          ServiceTemplate(name: 'Fitness Certificate Clearance', code: 'F', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'tyre_shops',
        name: 'Tyre shops',
        icon: Icons.tire_repair_outlined,
        description: 'Laser wheel alignment, 3D balancing, tyre replacement & puncture repair',
        aliases: ['TYRE', 'WHEEL_ALIGNMENT'],
        defaultServices: [
          ServiceTemplate(name: '3D Computerized Wheel Alignment', code: 'W', durationMinutes: 25),
          ServiceTemplate(name: 'Wheel Balancing & Nitrogen Fill', code: 'B', durationMinutes: 20),
          ServiceTemplate(name: 'Tyre Replacement & Puncture', code: 'T', durationMinutes: 20),
        ],
      ),
      OrganizationSubCategory(
        id: 'vehicle_washing_centres',
        name: 'Vehicle washing centres',
        icon: Icons.local_car_wash_outlined,
        description: 'High pressure foam wash, interior vacuuming, ceramic coating & detailing',
        aliases: ['CAR_WASH', 'DETAILING'],
        defaultServices: [
          ServiceTemplate(name: 'High Pressure Exterior Foam Wash', code: 'W', durationMinutes: 25),
          ServiceTemplate(name: 'Interior Deep Vacuum & Dashboard Polish', code: 'I', durationMinutes: 25),
          ServiceTemplate(name: 'Full Body Teflon & Ceramic Detailing', code: 'D', durationMinutes: 60),
        ],
      ),
      OrganizationSubCategory(
        id: 'electronics_repair_centres',
        name: 'Electronics repair centres',
        icon: Icons.tv_outlined,
        description: 'TV repair, microwave, washing machine, audio systems & board diagnostics',
        aliases: ['ELECTRONICS_REPAIR', 'APPLIANCE_REPAIR'],
        defaultServices: [
          ServiceTemplate(name: 'Device Fault Diagnostics & Estimate', code: 'D', durationMinutes: 15),
          ServiceTemplate(name: 'Motherboard & Circuit Repair', code: 'R', durationMinutes: 40),
          ServiceTemplate(name: 'Delivery & Testing Counter', code: 'T', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'mobile_repair_shops',
        name: 'Mobile repair shops',
        icon: Icons.phone_android_outlined,
        description: 'Smartphone screen replacement, battery repair, chip level repair & software',
        aliases: ['MOBILE_REPAIR', 'PHONE_REPAIR'],
        defaultServices: [
          ServiceTemplate(name: 'Screen & Touch Display Replacement', code: 'S', durationMinutes: 30),
          ServiceTemplate(name: 'Battery & Charging Port Repair', code: 'B', durationMinutes: 20),
          ServiceTemplate(name: 'Data Recovery & Software Flash', code: 'D', durationMinutes: 25),
        ],
      ),
    ],
  );

  // F. Food & Hospitality
  static const OrganizationCategory foodHospitality = OrganizationCategory(
    id: 'FOOD_HOSPITALITY',
    code: 'F',
    name: 'Food & Hospitality',
    description: 'Restaurants, cafes, food courts, bakeries, hotels, buffets & cloud kitchen pickup',
    icon: Icons.restaurant_outlined,
    brandColor: Color(0xFFEA580C),
    aliases: ['RESTAURANT', 'FOOD', 'CAFE', 'HOSPITALITY'],
    defaultServices: [
      ServiceTemplate(name: 'Dine-In Table Seating (1-4 Guests)', code: 'T', durationMinutes: 15),
      ServiceTemplate(name: 'Large Group Table (5+ Guests)', code: 'L', durationMinutes: 20),
      ServiceTemplate(name: 'Takeaway & Parcel Pick-up', code: 'P', durationMinutes: 10),
      ServiceTemplate(name: 'Express Counter Order', code: 'O', durationMinutes: 8),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'restaurants',
        name: 'Restaurants',
        icon: Icons.restaurant_outlined,
        description: 'Fine dining, casual dining restaurants, table queues & food takeout',
        defaultServices: [
          ServiceTemplate(name: 'Dine-In Table Allocation (1-4 Guests)', code: 'T', durationMinutes: 15),
          ServiceTemplate(name: 'Family Table (5+ Guests)', code: 'F', durationMinutes: 20),
          ServiceTemplate(name: 'Takeaway Food Parcel Pickup', code: 'P', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'cafes',
        name: 'Cafes',
        icon: Icons.local_cafe_outlined,
        description: 'Coffee shops, artisanal bakeries, beverage counters & bistro seating',
        aliases: ['COFFEE_SHOP'],
        defaultServices: [
          ServiceTemplate(name: 'Coffee & Specialty Beverage Bar', code: 'C', durationMinutes: 6),
          ServiceTemplate(name: 'Cafe Table Seating', code: 'S', durationMinutes: 12),
          ServiceTemplate(name: 'Quick Grab & Go Pastry', code: 'G', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'food_courts',
        name: 'Food courts',
        icon: Icons.fastfood_outlined,
        description: 'Mall food courts, multi-vendor counters, central token collection',
        aliases: ['FOOD_COURT'],
        defaultServices: [
          ServiceTemplate(name: 'Central Order & Token Payment', code: 'O', durationMinutes: 6),
          ServiceTemplate(name: 'Food Ready Pickup Counter', code: 'P', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'bakeries',
        name: 'Bakeries',
        icon: Icons.bakery_dining_outlined,
        description: 'Cake shops, confectionery, fresh bread ovens & custom celebration cakes',
        aliases: ['BAKERY', 'CAKE_SHOP'],
        defaultServices: [
          ServiceTemplate(name: 'Custom Celebration Cake Consultation', code: 'C', durationMinutes: 15),
          ServiceTemplate(name: 'Daily Fresh Bakes & Bread Counter', code: 'B', durationMinutes: 5),
          ServiceTemplate(name: 'Cake Pickup & Packaging', code: 'P', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'hotels',
        name: 'Hotels',
        icon: Icons.hotel_outlined,
        description: 'Hotel reception, check-in, key card issuance, concierge & guest checkout',
        aliases: ['HOTEL', 'RESORT'],
        defaultServices: [
          ServiceTemplate(name: 'Guest Check-in & Key Card Issuance', code: 'C', durationMinutes: 10),
          ServiceTemplate(name: 'Luggage & Concierge Services', code: 'L', durationMinutes: 8),
          ServiceTemplate(name: 'Guest Check-out & Folio Settlement', code: 'B', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'buffet_restaurants',
        name: 'Buffet restaurants',
        icon: Icons.dinner_dining_outlined,
        description: 'Unlimited barbecue buffet, table reservations & live grill stations',
        aliases: ['BUFFET'],
        defaultServices: [
          ServiceTemplate(name: 'Buffet Table Allocation', code: 'B', durationMinutes: 12),
          ServiceTemplate(name: 'Live Grill & Special Order Queue', code: 'G', durationMinutes: 8),
          ServiceTemplate(name: 'Beverage & Dessert Counter', code: 'D', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'cloud_kitchen_pickup_counters',
        name: 'Cloud kitchen pickup counters',
        icon: Icons.delivery_dining_outlined,
        description: 'Delivery rider dispatch, food delivery app handovers & direct customer pickup',
        aliases: ['CLOUD_KITCHEN', 'GHOST_KITCHEN'],
        defaultServices: [
          ServiceTemplate(name: 'Delivery Rider Order Dispatch', code: 'D', durationMinutes: 4),
          ServiceTemplate(name: 'Direct Customer Self-Pickup', code: 'P', durationMinutes: 5),
        ],
      ),
    ],
  );

  // G. Retail & Shopping
  static const OrganizationCategory retailShopping = OrganizationCategory(
    id: 'RETAIL_SHOPPING',
    code: 'G',
    name: 'Retail & Shopping',
    description: 'Supermarkets, malls, jewellery, electronics, mobile stores & customer support desks',
    icon: Icons.shopping_bag_outlined,
    brandColor: Color(0xFF0891B2),
    aliases: ['RETAIL', 'SHOPPING', 'SUPERMARKET'],
    defaultServices: [
      ServiceTemplate(name: 'Express Checkout (<= 10 Items)', code: 'E', durationMinutes: 6),
      ServiceTemplate(name: 'Regular Billing Counter', code: 'B', durationMinutes: 10),
      ServiceTemplate(name: 'Customer Support & Returns', code: 'R', durationMinutes: 12),
      ServiceTemplate(name: 'Product Pickup & Delivery', code: 'P', durationMinutes: 8),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'supermarkets',
        name: 'Supermarkets',
        icon: Icons.shopping_cart_outlined,
        description: 'Grocery supermarkets, department stores, express and bulk billing aisles',
        aliases: ['GROCERY'],
        defaultServices: [
          ServiceTemplate(name: 'Express Lane (Under 10 Items)', code: 'E', durationMinutes: 5),
          ServiceTemplate(name: 'Regular Trolley Billing', code: 'B', durationMinutes: 10),
          ServiceTemplate(name: 'Customer Service & Exchange Desk', code: 'C', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'shopping_malls',
        name: 'Shopping malls',
        icon: Icons.storefront_outlined,
        description: 'Mall customer desk, gift wrapping, loyalty club, lost & found',
        aliases: ['MALL'],
        defaultServices: [
          ServiceTemplate(name: 'Mall Helpdesk & Information', code: 'I', durationMinutes: 6),
          ServiceTemplate(name: 'Loyalty Rewards & Gift Wrapping', code: 'G', durationMinutes: 10),
          ServiceTemplate(name: 'Lost & Found / Security Cell', code: 'S', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'jewellery_stores',
        name: 'Jewellery stores',
        icon: Icons.diamond_outlined,
        description: 'Gold jewellery counters, diamond showroom, bullion valuation & ornament custom design',
        aliases: ['JEWELLERY', 'GOLD_SHOP'],
        defaultServices: [
          ServiceTemplate(name: 'Gold & Diamond Purchase Advisory', code: 'J', durationMinutes: 30),
          ServiceTemplate(name: 'Custom Ornament Design & Sizing', code: 'D', durationMinutes: 25),
          ServiceTemplate(name: 'Old Gold Exchange & Purity Testing', code: 'E', durationMinutes: 20),
        ],
      ),
      OrganizationSubCategory(
        id: 'electronics_stores',
        name: 'Electronics stores',
        icon: Icons.devices_outlined,
        description: 'Consumer electronics, laptops, home appliances, demos & warranty desks',
        aliases: ['ELECTRONICS_STORE'],
        defaultServices: [
          ServiceTemplate(name: 'Product Demo & Tech Consultation', code: 'D', durationMinutes: 20),
          ServiceTemplate(name: 'Billing, Extended Warranty & Insurance', code: 'B', durationMinutes: 15),
          ServiceTemplate(name: 'Product Pickup & Box Opening', code: 'P', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'mobile_stores',
        name: 'Mobile stores',
        icon: Icons.smartphone_outlined,
        description: 'Mobile phone retail, telecom SIM cards, accessories & device financing',
        aliases: ['MOBILE_STORE'],
        defaultServices: [
          ServiceTemplate(name: 'Smartphone Purchase & Data Transfer', code: 'P', durationMinutes: 25),
          ServiceTemplate(name: 'SIM Card, MNP & Plan Activation', code: 'S', durationMinutes: 15),
          ServiceTemplate(name: 'Old Phone Trade-in / Exchange Valuation', code: 'E', durationMinutes: 12),
        ],
      ),
      OrganizationSubCategory(
        id: 'customer_service_desks',
        name: 'Customer service desks',
        icon: Icons.support_agent_outlined,
        description: 'Returns, refunds, product warranty validation, complaint escalation',
        aliases: ['SERVICE_DESK', 'RETURNS'],
        defaultServices: [
          ServiceTemplate(name: 'Returns & Refund Processing', code: 'R', durationMinutes: 10),
          ServiceTemplate(name: 'Warranty Replacement Desk', code: 'W', durationMinutes: 15),
          ServiceTemplate(name: 'Customer Grievance Resolution', code: 'G', durationMinutes: 12),
        ],
      ),
      OrganizationSubCategory(
        id: 'product_collection_counters',
        name: 'Product collection counters',
        icon: Icons.inventory_2_outlined,
        description: 'Click and collect order pickup, catalog fulfillment & warehouse collection',
        aliases: ['COLLECTION_COUNTER', 'CLICK_AND_COLLECT'],
        defaultServices: [
          ServiceTemplate(name: 'Online Order Click & Collect', code: 'C', durationMinutes: 6),
          ServiceTemplate(name: 'Heavy Appliance Warehouse Delivery Gate', code: 'H', durationMinutes: 12),
        ],
      ),
    ],
  );

  // H. Education
  static const OrganizationCategory education = OrganizationCategory(
    id: 'EDUCATION',
    code: 'H',
    name: 'Education',
    description: 'Schools, colleges, universities, coaching institutes, admission, exam & fee desks',
    icon: Icons.school_outlined,
    brandColor: Color(0xFF7C3AED),
    aliases: ['ACADEMIC', 'COLLEGE', 'UNIVERSITY', 'SCHOOL'],
    defaultServices: [
      ServiceTemplate(name: 'Admissions & Document Review', code: 'A', durationMinutes: 20),
      ServiceTemplate(name: 'Fee Payment & Receipts', code: 'F', durationMinutes: 10),
      ServiceTemplate(name: 'Student Counselling & Affairs', code: 'C', durationMinutes: 20),
      ServiceTemplate(name: 'Exam & Certificate Clearance', code: 'E', durationMinutes: 15),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'schools',
        name: 'Schools',
        icon: Icons.backpack_outlined,
        description: 'K-12 schools, parent-teacher inquiry, admission & student record desk',
        defaultServices: [
          ServiceTemplate(name: 'New Student Admission Counseling', code: 'A', durationMinutes: 20),
          ServiceTemplate(name: 'Term Fee Payment Counter', code: 'F', durationMinutes: 10),
          ServiceTemplate(name: 'Transfer Certificate & Report Card', code: 'T', durationMinutes: 12),
        ],
      ),
      OrganizationSubCategory(
        id: 'colleges',
        name: 'Colleges',
        icon: Icons.account_balance_outlined,
        description: 'Undergraduate, postgraduate colleges, department admissions & clearances',
        defaultServices: [
          ServiceTemplate(name: 'Degree Admission & Scrutiny', code: 'A', durationMinutes: 20),
          ServiceTemplate(name: 'College Fee & Scholarship Cell', code: 'F', durationMinutes: 12),
          ServiceTemplate(name: 'Bonafide Certificate & Hall Ticket', code: 'C', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'universities',
        name: 'Universities',
        icon: Icons.school_outlined,
        description: 'Central university campus, convocation, degree certificates, migration & PhD',
        defaultServices: [
          ServiceTemplate(name: 'Convocation & Degree Certificate Desk', code: 'D', durationMinutes: 15),
          ServiceTemplate(name: 'Migration Certificate & Transcripts', code: 'T', durationMinutes: 15),
          ServiceTemplate(name: 'Research & PhD Administration', code: 'R', durationMinutes: 25),
        ],
      ),
      OrganizationSubCategory(
        id: 'coaching_institutes',
        name: 'Coaching institutes',
        icon: Icons.menu_book_outlined,
        description: 'Entrance coaching (JEE, NEET, Civil Services), doubt sessions & test series',
        aliases: ['COACHING', 'TUITION'],
        defaultServices: [
          ServiceTemplate(name: 'Course Enrollment & Batch Allotment', code: 'A', durationMinutes: 18),
          ServiceTemplate(name: 'Faculty 1-on-1 Doubt Clearance', code: 'D', durationMinutes: 15),
          ServiceTemplate(name: 'Study Material & Test Series Desk', code: 'M', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'admission_offices',
        name: 'Admission offices',
        icon: Icons.assignment_ind_outlined,
        description: 'Centralized admission counseling, seat verification & document submission',
        aliases: ['ADMISSION'],
        defaultServices: [
          ServiceTemplate(name: 'Application Verification & Scrutiny', code: 'V', durationMinutes: 15),
          ServiceTemplate(name: 'Counseling & Course Choice Locking', code: 'C', durationMinutes: 25),
          ServiceTemplate(name: 'Seat Allotment Order Issuance', code: 'S', durationMinutes: 12),
        ],
      ),
      OrganizationSubCategory(
        id: 'examination_centres',
        name: 'Examination centres',
        icon: Icons.quiz_outlined,
        description: 'Competitive exams, entrance testing centers, candidate frisking & hall tickets',
        aliases: ['EXAM_CENTER'],
        defaultServices: [
          ServiceTemplate(name: 'Hall Ticket & Biometric Frisking Entry', code: 'E', durationMinutes: 5),
          ServiceTemplate(name: 'Baggage Deposit & Locker Desk', code: 'B', durationMinutes: 5),
          ServiceTemplate(name: 'Disability Scribe & Special Assistance', code: 'S', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'student_counselling_centres',
        name: 'Student counselling centres',
        icon: Icons.psychology_outlined,
        description: 'Career guidance, psychological counselling, study abroad mentoring',
        aliases: ['STUDENT_COUNSELLING'],
        defaultServices: [
          ServiceTemplate(name: 'Career & Higher Study Guidance', code: 'C', durationMinutes: 30),
          ServiceTemplate(name: 'Student Wellness & Stress Counseling', code: 'W', durationMinutes: 40),
          ServiceTemplate(name: 'Study Abroad Visa & Profile Review', code: 'S', durationMinutes: 30),
        ],
      ),
      OrganizationSubCategory(
        id: 'fee_collection_counters',
        name: 'Fee collection counters',
        icon: Icons.payments_outlined,
        description: 'Tuition fees, hostel fees, bus transport & fine payment receipts',
        aliases: ['FEE_COUNTER'],
        defaultServices: [
          ServiceTemplate(name: 'Tuition & Academic Fee Payment', code: 'T', durationMinutes: 8),
          ServiceTemplate(name: 'Hostel & Transport Fee Counter', code: 'H', durationMinutes: 8),
          ServiceTemplate(name: 'Fee Concession & Scholarship Receipt', code: 'S', durationMinutes: 12),
        ],
      ),
    ],
  );

  // I. Transportation & Travel
  static const OrganizationCategory transportation = OrganizationCategory(
    id: 'TRANSPORT_TRAVEL',
    code: 'I',
    name: 'Transportation & Travel',
    description: 'Airports, bus terminals, railway stations, travel agencies, taxis & ticket booking',
    icon: Icons.flight_takeoff_outlined,
    brandColor: Color(0xFF0284C7),
    aliases: ['TRAVEL', 'TRANSPORT', 'LOGISTICS'],
    defaultServices: [
      ServiceTemplate(name: 'Ticket Booking & Reservations', code: 'T', durationMinutes: 10),
      ServiceTemplate(name: 'Check-in & Baggage Drop', code: 'B', durationMinutes: 6),
      ServiceTemplate(name: 'Passenger Assistance Desk', code: 'P', durationMinutes: 8),
      ServiceTemplate(name: 'Cancellations & Refunds', code: 'C', durationMinutes: 10),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'airports',
        name: 'Airports',
        icon: Icons.flight_outlined,
        description: 'Airline check-in counters, baggage drop, boarding gates & transfer desks',
        aliases: ['AIRPORT', 'AIRLINE'],
        defaultServices: [
          ServiceTemplate(name: 'Airline Check-in & Baggage Drop', code: 'B', durationMinutes: 6),
          ServiceTemplate(name: 'Security Check Clearance Line', code: 'S', durationMinutes: 4),
          ServiceTemplate(name: 'Priority & Special Assistance Boarding', code: 'P', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'bus_terminals',
        name: 'Bus terminals',
        icon: Icons.directions_bus_outlined,
        description: 'Interstate bus stations, express ticket counters & parcel booking',
        aliases: ['BUS_STATION', 'BUS_STAND'],
        defaultServices: [
          ServiceTemplate(name: 'Current & Advance Bus Ticket Counter', code: 'T', durationMinutes: 6),
          ServiceTemplate(name: 'Bus Parcel & Cargo Booking', code: 'P', durationMinutes: 10),
          ServiceTemplate(name: 'Enquiry & Concession Pass Desk', code: 'E', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'railway_stations',
        name: 'Railway stations',
        icon: Icons.train_outlined,
        description: 'Train reservation PRS, unreserved ticket UTS, parcel cargo & railway enquiry',
        aliases: ['RAILWAY', 'TRAIN_STATION'],
        defaultServices: [
          ServiceTemplate(name: 'Unreserved Ticket Counter (UTS)', code: 'U', durationMinutes: 4),
          ServiceTemplate(name: 'Passenger Reservation System (PRS)', code: 'P', durationMinutes: 8),
          ServiceTemplate(name: 'Tatkal & Senior Citizen Ticket Desk', code: 'T', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'travel_agencies',
        name: 'Travel agencies',
        icon: Icons.luggage_outlined,
        description: 'Holiday tour operators, international visa agents & flight booking',
        aliases: ['TOUR_OPERATOR'],
        defaultServices: [
          ServiceTemplate(name: 'Custom Holiday Package Consultation', code: 'H', durationMinutes: 25),
          ServiceTemplate(name: 'Tourist Visa Filing Assistance', code: 'V', durationMinutes: 20),
          ServiceTemplate(name: 'Flight & Hotel Reservation Desk', code: 'F', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'taxi_rental_counters',
        name: 'Taxi rental counters',
        icon: Icons.local_taxi_outlined,
        description: 'Prepaid airport taxi booths, self-drive rentals & cab dispatch',
        aliases: ['TAXI', 'CAR_RENTAL'],
        defaultServices: [
          ServiceTemplate(name: 'Prepaid Taxi Booking Booth', code: 'T', durationMinutes: 5),
          ServiceTemplate(name: 'Self-Drive Vehicle Documentation & Handover', code: 'S', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'ticket_booking_offices',
        name: 'Ticket booking offices',
        icon: Icons.confirmation_number_outlined,
        description: 'Ferry tickets, amusement park passes, intercity shuttle bookings',
        aliases: ['TICKET_OFFICE'],
        defaultServices: [
          ServiceTemplate(name: 'Ticket Purchase Counter', code: 'T', durationMinutes: 5),
          ServiceTemplate(name: 'Ticket Cancellation & Refund', code: 'C', durationMinutes: 8),
        ],
      ),
    ],
  );

  // J. Corporate & Professional Services
  static const OrganizationCategory corporate = OrganizationCategory(
    id: 'CORPORATE_PROFESSIONAL',
    code: 'J',
    name: 'Corporate & Professional Services',
    description: 'Corporate offices, IT reception, HR, employee helpdesk, legal, consultancies & coworking',
    icon: Icons.business_center_outlined,
    brandColor: Color(0xFF334155),
    aliases: ['CORPORATE', 'LEGAL', 'OFFICE', 'COWORKING'],
    defaultServices: [
      ServiceTemplate(name: 'Visitor Reception & Badge', code: 'V', durationMinutes: 6),
      ServiceTemplate(name: 'Interviewee & Candidate Check-in', code: 'I', durationMinutes: 8),
      ServiceTemplate(name: 'Employee IT & HR Helpdesk', code: 'H', durationMinutes: 15),
      ServiceTemplate(name: 'Client Meeting & Consultation', code: 'C', durationMinutes: 30),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'corporate_offices',
        name: 'Corporate offices',
        icon: Icons.domain_outlined,
        description: 'Company headquarters, executive visitors, vendor entry & badge issuance',
        defaultServices: [
          ServiceTemplate(name: 'Visitor Badge & Gate Pass', code: 'V', durationMinutes: 5),
          ServiceTemplate(name: 'Vendor & Contractor Sign-in', code: 'S', durationMinutes: 8),
          ServiceTemplate(name: 'Courier & Material Inward Desk', code: 'M', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'it_company_reception',
        name: 'IT company reception',
        icon: Icons.desktop_mac_outlined,
        description: 'Software tech park reception, interview candidates, client delegations & security check',
        aliases: ['TECH_PARK'],
        defaultServices: [
          ServiceTemplate(name: 'Job Interview Candidate Check-in', code: 'I', durationMinutes: 6),
          ServiceTemplate(name: 'Client & Executive Delegation Desk', code: 'C', durationMinutes: 10),
          ServiceTemplate(name: 'Temporary Access Card Issuance', code: 'A', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'hr_departments',
        name: 'HR departments',
        icon: Icons.badge_outlined,
        description: 'Employee onboarding, HR documentation, exit clearance & benefits desk',
        aliases: ['HUMAN_RESOURCES'],
        defaultServices: [
          ServiceTemplate(name: 'New Hire Onboarding & Document Verification', code: 'O', durationMinutes: 25),
          ServiceTemplate(name: 'Exit Interview & Clearance Counter', code: 'E', durationMinutes: 20),
          ServiceTemplate(name: 'Employee Benefits & PF Query', code: 'P', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'employee_helpdesks',
        name: 'Employee helpdesks',
        icon: Icons.contact_support_outlined,
        description: 'Internal IT support, laptop provisioning, facilities & admin desks',
        aliases: ['INTERNAL_HELPDESK'],
        defaultServices: [
          ServiceTemplate(name: 'IT Hardware & Laptop Repair Desk', code: 'I', durationMinutes: 20),
          ServiceTemplate(name: 'Access Card & Biometric Enrollment', code: 'A', durationMinutes: 10),
          ServiceTemplate(name: 'Facilities & Workplace Requests', code: 'F', durationMinutes: 12),
        ],
      ),
      OrganizationSubCategory(
        id: 'legal_offices',
        name: 'Legal offices',
        icon: Icons.gavel_outlined,
        description: 'Advocate chambers, legal consultations, notary stamp & contract signing',
        aliases: ['LAW_FIRM', 'ADVOCATE'],
        defaultServices: [
          ServiceTemplate(name: 'Client Legal Consultation', code: 'C', durationMinutes: 30),
          ServiceTemplate(name: 'Document Notarization & Affidavit', code: 'N', durationMinutes: 15),
          ServiceTemplate(name: 'Contract Review & Signing', code: 'S', durationMinutes: 25),
        ],
      ),
      OrganizationSubCategory(
        id: 'consultancy_firms',
        name: 'Consultancy firms',
        icon: Icons.insights_outlined,
        description: 'Management consultants, accounting, tax auditing & business advisory',
        aliases: ['CONSULTING', 'CA_FIRM'],
        defaultServices: [
          ServiceTemplate(name: 'Financial Audit & Tax Filing Review', code: 'T', durationMinutes: 30),
          ServiceTemplate(name: 'Business Strategy Consultation', code: 'S', durationMinutes: 35),
        ],
      ),
      OrganizationSubCategory(
        id: 'coworking_spaces',
        name: 'Coworking spaces',
        icon: Icons.co_present_outlined,
        description: 'Shared office spaces, hot desk day passes, meeting room access & community',
        aliases: ['COWORKING'],
        defaultServices: [
          ServiceTemplate(name: 'Day Pass & Flexi Desk Booking', code: 'D', durationMinutes: 6),
          ServiceTemplate(name: 'Meeting & Conference Room Check-in', code: 'M', durationMinutes: 6),
          ServiceTemplate(name: 'Community Membership Helpdesk', code: 'C', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'real_estate_offices',
        name: 'Real estate offices',
        icon: Icons.real_estate_agent_outlined,
        description: 'Property sales, builder site visit desks, rental agreements & brokerages',
        aliases: ['REAL_ESTATE', 'PROPERTY'],
        defaultServices: [
          ServiceTemplate(name: 'Property Site Visit Registration', code: 'S', durationMinutes: 15),
          ServiceTemplate(name: 'Buyer Consultation & Floor Plan Review', code: 'B', durationMinutes: 30),
          ServiceTemplate(name: 'Rental Agreement & Key Handover', code: 'R', durationMinutes: 20),
        ],
      ),
    ],
  );

  // K. Utilities & Customer Support
  static const OrganizationCategory utilities = OrganizationCategory(
    id: 'UTILITIES_SUPPORT',
    code: 'K',
    name: 'Utilities & Customer Support',
    description: 'Electricity, water supply, telecom centers, internet ISPs, LPG gas & courier logistics',
    icon: Icons.power_outlined,
    brandColor: Color(0xFFD97706),
    aliases: ['UTILITIES', 'TELECOM', 'COURIER', 'LOGISTICS'],
    defaultServices: [
      ServiceTemplate(name: 'New Service Connection', code: 'N', durationMinutes: 20),
      ServiceTemplate(name: 'Bill Payment Counter', code: 'B', durationMinutes: 6),
      ServiceTemplate(name: 'Complaint & Technical Fault', code: 'C', durationMinutes: 15),
      ServiceTemplate(name: 'Parcel & Courier Booking', code: 'P', durationMinutes: 8),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'electricity_offices',
        name: 'Electricity offices',
        icon: Icons.electric_bolt_outlined,
        description: 'Power distribution board, new meter connection, bill dispute & outage complaints',
        aliases: ['POWER_BOARD', 'ELECTRICITY'],
        defaultServices: [
          ServiceTemplate(name: 'New Power Connection & Load Enhancement', code: 'N', durationMinutes: 20),
          ServiceTemplate(name: 'Electricity Bill Payment Counter', code: 'B', durationMinutes: 6),
          ServiceTemplate(name: 'Meter Fault & Breakdown Complaint', code: 'M', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'water_supply_offices',
        name: 'Water supply offices',
        icon: Icons.water_drop_outlined,
        description: 'Municipal water board, new pipeline connection, sewerage & tanker booking',
        aliases: ['WATER_BOARD'],
        defaultServices: [
          ServiceTemplate(name: 'New Water Pipeline Connection', code: 'N', durationMinutes: 20),
          ServiceTemplate(name: 'Water Bill Payment Counter', code: 'B', durationMinutes: 6),
          ServiceTemplate(name: 'Emergency Water Tanker Booking', code: 'T', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'telecom_service_centres',
        name: 'Telecom service centres',
        icon: Icons.cell_tower_outlined,
        description: 'Mobile operator stores, 5G SIM replacement, eSIM, post-paid bills & plan change',
        aliases: ['TELECOM', 'MOBILE_OPERATOR'],
        defaultServices: [
          ServiceTemplate(name: 'SIM Replacement & eSIM Upgrade', code: 'S', durationMinutes: 12),
          ServiceTemplate(name: 'Postpaid Bill Payment & Tariff Change', code: 'B', durationMinutes: 10),
          ServiceTemplate(name: 'Network & Roaming Support Desk', code: 'N', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'internet_service_providers',
        name: 'Internet service providers',
        icon: Icons.wifi_outlined,
        description: 'Fiber broadband offices, Wi-Fi router exchange, new line installation & tech support',
        aliases: ['ISP', 'BROADBAND'],
        defaultServices: [
          ServiceTemplate(name: 'New Fiber Broadband Connection', code: 'N', durationMinutes: 15),
          ServiceTemplate(name: 'Router Replacement & Hardware Support', code: 'R', durationMinutes: 12),
          ServiceTemplate(name: 'Speed Issue & Fiber Line Complaint', code: 'S', durationMinutes: 15),
        ],
      ),
      OrganizationSubCategory(
        id: 'gas_agencies',
        name: 'Gas agencies',
        icon: Icons.propane_tank_outlined,
        description: 'LPG cylinder distributor, new gas connection KYC, cylinder refill & safety check',
        aliases: ['GAS_AGENCY', 'LPG'],
        defaultServices: [
          ServiceTemplate(name: 'New LPG Gas Connection (KYC)', code: 'N', durationMinutes: 20),
          ServiceTemplate(name: 'Cylinder Refill Booking & Voucher', code: 'R', durationMinutes: 6),
          ServiceTemplate(name: 'Regulator & Pipeline Inspection Request', code: 'I', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'courier_and_logistics_offices',
        name: 'Courier and logistics offices',
        icon: Icons.local_shipping_outlined,
        description: 'Parcel shipping, domestic & international courier booking, parcel pickup point',
        aliases: ['COURIER', 'POST_OFFICE'],
        defaultServices: [
          ServiceTemplate(name: 'Parcel Weighing & Speed Post Booking', code: 'P', durationMinutes: 8),
          ServiceTemplate(name: 'Shipment Self-Pickup Counter', code: 'S', durationMinutes: 6),
          ServiceTemplate(name: 'Tracking & Undelivered Parcel Query', code: 'T', durationMinutes: 10),
        ],
      ),
    ],
  );

  // L. Community & Religious Organizations
  static const OrganizationCategory community = OrganizationCategory(
    id: 'COMMUNITY_RELIGIOUS',
    code: 'L',
    name: 'Community & Religious Organizations',
    description: 'Temples, churches, mosques, community centres, apartment associations, NGOs & blood banks',
    icon: Icons.temple_hindu_outlined,
    brandColor: Color(0xFFB45309),
    aliases: ['RELIGIOUS', 'TEMPLE', 'COMMUNITY', 'NGO'],
    defaultServices: [
      ServiceTemplate(name: 'General Darshan & Entry', code: 'D', durationMinutes: 5),
      ServiceTemplate(name: 'VIP & Special Entry Queue', code: 'V', durationMinutes: 5),
      ServiceTemplate(name: 'Prasadam / Offering Counter', code: 'P', durationMinutes: 6),
      ServiceTemplate(name: 'Community Donation & Receipt', code: 'C', durationMinutes: 10),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'temples',
        name: 'Temples',
        icon: Icons.temple_hindu_outlined,
        description: 'Pilgrimage shrines, daily darshan, special seva booking, archana & prasadam',
        aliases: ['TEMPLE', 'MANDIR'],
        defaultServices: [
          ServiceTemplate(name: 'General Public Darshan Line', code: 'D', durationMinutes: 5),
          ServiceTemplate(name: 'VIP / Sheegra Special Darshan', code: 'V', durationMinutes: 5),
          ServiceTemplate(name: 'Special Seva & Archana Booking', code: 'S', durationMinutes: 10),
          ServiceTemplate(name: 'Laddu & Holy Prasadam Counter', code: 'P', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'churches',
        name: 'Churches',
        icon: Icons.church_outlined,
        description: 'Sunday mass entry, confession booths, prayer requests & parish hall bookings',
        aliases: ['CHURCH'],
        defaultServices: [
          ServiceTemplate(name: 'Sunday Mass & Service Seating', code: 'S', durationMinutes: 10),
          ServiceTemplate(name: 'Confession & Pastoral Guidance', code: 'C', durationMinutes: 15),
          ServiceTemplate(name: 'Parish Registration & Certificates', code: 'P', durationMinutes: 12),
        ],
      ),
      OrganizationSubCategory(
        id: 'mosques',
        name: 'Mosques',
        icon: Icons.mosque_outlined,
        description: 'Daily prayers, Friday Juma entry, Wudu assistance & Ramadan Iftar management',
        aliases: ['MOSQUE', 'MASJID'],
        defaultServices: [
          ServiceTemplate(name: 'Friday Juma Prayer Queue', code: 'J', durationMinutes: 10),
          ServiceTemplate(name: 'Zakat & Community Welfare Counter', code: 'Z', durationMinutes: 10),
          ServiceTemplate(name: 'Iftar & Community Meal Allocation', code: 'I', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'community_centres',
        name: 'Community centres',
        icon: Icons.holiday_village_outlined,
        description: 'Civic community halls, senior citizen clubs, local events & recreation classes',
        aliases: ['COMMUNITY_HALL'],
        defaultServices: [
          ServiceTemplate(name: 'Hall Booking & Event Reservation', code: 'H', durationMinutes: 15),
          ServiceTemplate(name: 'Community Class & Workshop Sign-up', code: 'C', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'apartment_associations',
        name: 'Apartment associations',
        icon: Icons.apartment_outlined,
        description: 'Resident welfare associations (RWA), maintenance desk, gate passes & clubhouse',
        aliases: ['RWA', 'HOUSING_SOCIETY'],
        defaultServices: [
          ServiceTemplate(name: 'Maintenance Fee & Dues Counter', code: 'M', durationMinutes: 8),
          ServiceTemplate(name: 'Move-in / Move-out NOC & Pass', code: 'P', durationMinutes: 12),
          ServiceTemplate(name: 'Clubhouse & Amenity Booking', code: 'C', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'ngos',
        name: 'NGOs',
        icon: Icons.volunteer_activism_outlined,
        description: 'Non-profit foundations, volunteer sign-up, relief distribution & donor desk',
        aliases: ['NON_PROFIT', 'CHARITY'],
        defaultServices: [
          ServiceTemplate(name: 'Beneficiary Intake & Relief Support', code: 'B', durationMinutes: 15),
          ServiceTemplate(name: 'Volunteer Registration Desk', code: 'V', durationMinutes: 12),
          ServiceTemplate(name: 'Tax-Exempt Donation & 80G Receipts', code: 'D', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'blood_donation_centres_comm',
        name: 'Blood donation centres',
        icon: Icons.water_drop_outlined,
        description: 'Community blood donation camps, donor registration & post-donation checkup',
        aliases: ['BLOOD_CAMP'],
        defaultServices: [
          ServiceTemplate(name: 'Donor Health Screening & Vitals', code: 'S', durationMinutes: 10),
          ServiceTemplate(name: 'Blood Donation Bed', code: 'D', durationMinutes: 20),
          ServiceTemplate(name: 'Refreshment & Certificate Counter', code: 'R', durationMinutes: 10),
        ],
      ),
    ],
  );

  // M. Events & Exhibitions
  static const OrganizationCategory eventsExhibitions = OrganizationCategory(
    id: 'EVENTS_EXHIBITIONS',
    code: 'M',
    name: 'Events & Exhibitions',
    description: 'Concerts, festivals, conferences, seminars, trade shows, expos, job fairs & launches',
    icon: Icons.event_available_outlined,
    brandColor: Color(0xFF9333EA),
    aliases: ['EVENTS', 'EXHIBITION', 'CONFERENCE'],
    defaultServices: [
      ServiceTemplate(name: 'Attendee Badge & Registration', code: 'A', durationMinutes: 5),
      ServiceTemplate(name: 'VIP & Media Fast Track', code: 'V', durationMinutes: 4),
      ServiceTemplate(name: 'Security Check & Bag Inspection', code: 'S', durationMinutes: 3),
      ServiceTemplate(name: 'Kit & Merchandise Pickup', code: 'M', durationMinutes: 5),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'concerts',
        name: 'Concerts',
        icon: Icons.music_note_outlined,
        description: 'Live music concerts, box office ticket collection, VIP wristbands & gate queues',
        defaultServices: [
          ServiceTemplate(name: 'Box Office & Ticket Barcode Scan', code: 'B', durationMinutes: 3),
          ServiceTemplate(name: 'VIP Wristband & Lounge Access', code: 'V', durationMinutes: 4),
          ServiceTemplate(name: 'Concert Merchandise Counter', code: 'M', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'music_festivals',
        name: 'Music festivals',
        icon: Icons.festival_outlined,
        description: 'Multi-day music festivals, camping passes, wristband RFID top-up',
        defaultServices: [
          ServiceTemplate(name: 'Festival Wristband RFID Tagging', code: 'W', durationMinutes: 4),
          ServiceTemplate(name: 'Camping Pass & Vehicle Check-in', code: 'C', durationMinutes: 8),
          ServiceTemplate(name: 'Festival Food & Drink Tokens', code: 'F', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'conferences',
        name: 'Conferences',
        icon: Icons.co_present_outlined,
        description: 'Industry summits, corporate conferences, delegate registration kit & badges',
        defaultServices: [
          ServiceTemplate(name: 'Delegate Check-in & Lanyard Kit', code: 'D', durationMinutes: 5),
          ServiceTemplate(name: 'Keynote Seating Allocation', code: 'K', durationMinutes: 5),
          ServiceTemplate(name: 'Speaker & Panelist Registration', code: 'S', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'seminars',
        name: 'Seminars',
        icon: Icons.record_voice_over_outlined,
        description: 'Educational seminars, professional CPD workshops & lecture hall queues',
        defaultServices: [
          ServiceTemplate(name: 'Attendee Entry & Attendance Scan', code: 'A', durationMinutes: 4),
          ServiceTemplate(name: 'Study Materials & Handout Collection', code: 'M', durationMinutes: 5),
          ServiceTemplate(name: 'Certificate of Participation', code: 'C', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'workshops',
        name: 'Workshops',
        icon: Icons.handyman_outlined,
        description: 'Hands-on skill labs, technical workshops, hardware kit distribution',
        defaultServices: [
          ServiceTemplate(name: 'Participant Seat & Lab Workstation', code: 'W', durationMinutes: 6),
          ServiceTemplate(name: 'Hardware Tool & Component Kit', code: 'K', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'trade_shows',
        name: 'Trade shows',
        icon: Icons.storefront_outlined,
        description: 'B2B trade fairs, buyer-seller match lounges, exhibitor check-in',
        defaultServices: [
          ServiceTemplate(name: 'Trade Buyer Badge Printing', code: 'B', durationMinutes: 5),
          ServiceTemplate(name: 'Exhibitor Pass & Booth Setup Entry', code: 'E', durationMinutes: 8),
          ServiceTemplate(name: 'B2B Meeting Lounge Scheduling', code: 'M', durationMinutes: 10),
        ],
      ),
      OrganizationSubCategory(
        id: 'exhibitions',
        name: 'Exhibitions',
        icon: Icons.museum_outlined,
        description: 'Art gallery expos, museum exhibitions, audio guide rentals & catalog desks',
        defaultServices: [
          ServiceTemplate(name: 'Gallery Entry Ticket Validation', code: 'T', durationMinutes: 4),
          ServiceTemplate(name: 'Audio Guide & Headset Counter', code: 'A', durationMinutes: 5),
          ServiceTemplate(name: 'Guided Tour Group Assembly', code: 'G', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'product_launches',
        name: 'Product launches',
        icon: Icons.new_releases_outlined,
        description: 'Media press events, tech product unveiling, demo zone experience',
        defaultServices: [
          ServiceTemplate(name: 'Press & Media VIP Check-in', code: 'P', durationMinutes: 5),
          ServiceTemplate(name: 'Hands-on Demo Experience Queue', code: 'D', durationMinutes: 8),
          ServiceTemplate(name: 'Pre-Order & Goodie Bag Counter', code: 'G', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'job_fairs',
        name: 'Job fairs',
        icon: Icons.work_outline,
        description: 'Campus placement drives, corporate career fairs, resume screening desks',
        defaultServices: [
          ServiceTemplate(name: 'Candidate Registration & Token', code: 'C', durationMinutes: 6),
          ServiceTemplate(name: 'Resume Screening & Skill Check', code: 'R', durationMinutes: 10),
          ServiceTemplate(name: 'Company Interview Cabin Queue', code: 'I', durationMinutes: 15),
        ],
      ),
    ],
  );

  // N. Sports & Entertainment
  static const OrganizationCategory sports = OrganizationCategory(
    id: 'SPORTS_ENTERTAINMENT',
    code: 'N',
    name: 'Sports & Entertainment',
    description: 'Tournaments, stadium entry, marathons, sports trials, fitness contests & cinema premieres',
    icon: Icons.sports_soccer_outlined,
    brandColor: Color(0xFF16A34A),
    aliases: ['SPORTS', 'ENTERTAINMENT', 'STADIUM'],
    defaultServices: [
      ServiceTemplate(name: 'Gate Ticket Scan & Entry', code: 'G', durationMinutes: 3),
      ServiceTemplate(name: 'Athlete & Participant Check-in', code: 'A', durationMinutes: 6),
      ServiceTemplate(name: 'Security & Frisking Line', code: 'S', durationMinutes: 2),
      ServiceTemplate(name: 'Concessions & Refreshments', code: 'C', durationMinutes: 5),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'sports_tournaments',
        name: 'Sports tournaments',
        icon: Icons.emoji_events_outlined,
        description: 'Cricket, football, badminton tournaments, team rosters & court queue',
        defaultServices: [
          ServiceTemplate(name: 'Team Registration & Jersey Check', code: 'T', durationMinutes: 10),
          ServiceTemplate(name: 'Match Court / Field Allocation', code: 'M', durationMinutes: 8),
          ServiceTemplate(name: 'Referee & Official Score Clearance', code: 'S', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'stadium_entry',
        name: 'Stadium entry',
        icon: Icons.stadium_outlined,
        description: 'Cricket stadiums, football arenas, turnstile gates & grandstand queues',
        defaultServices: [
          ServiceTemplate(name: 'Turnstile Barcode Ticket Scan', code: 'T', durationMinutes: 3),
          ServiceTemplate(name: 'Security Frisking & Bag Check', code: 'S', durationMinutes: 2),
          ServiceTemplate(name: 'Hospitality & VIP Box Entry', code: 'V', durationMinutes: 4),
        ],
      ),
      OrganizationSubCategory(
        id: 'marathons',
        name: 'Marathons',
        icon: Icons.directions_run_outlined,
        description: 'City marathons, 10K, half-marathons, bib number collection & baggage drop',
        defaultServices: [
          ServiceTemplate(name: 'Bib Number & Timing Chip Pickup', code: 'B', durationMinutes: 5),
          ServiceTemplate(name: 'Runner Baggage Holding Counter', code: 'D', durationMinutes: 4),
          ServiceTemplate(name: 'Finisher Medal & Refreshment Line', code: 'M', durationMinutes: 4),
        ],
      ),
      OrganizationSubCategory(
        id: 'sports_trials',
        name: 'Sports trials',
        icon: Icons.sports_tennis_outlined,
        description: 'Academy selection trials, athlete physical metrics, scout evaluations',
        defaultServices: [
          ServiceTemplate(name: 'Candidate Physical Measurement', code: 'P', durationMinutes: 8),
          ServiceTemplate(name: 'Field Skill Trial Assessment', code: 'S', durationMinutes: 15),
          ServiceTemplate(name: 'Trial Results & Shortlist Desk', code: 'R', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'fitness_competitions',
        name: 'Fitness competitions',
        icon: Icons.sports_kabaddi_outlined,
        description: 'Bodybuilding, powerlifting meets, athlete weigh-ins & stage queue',
        defaultServices: [
          ServiceTemplate(name: 'Athlete Weigh-in & Category Staging', code: 'W', durationMinutes: 10),
          ServiceTemplate(name: 'Stage Presentation Line-up', code: 'S', durationMinutes: 8),
        ],
      ),
      OrganizationSubCategory(
        id: 'movie_premieres',
        name: 'Movie premieres',
        icon: Icons.movie_outlined,
        description: 'Red carpet film premieres, multiplex screening auditoriums & fan zones',
        defaultServices: [
          ServiceTemplate(name: 'Red Carpet & Celebrity Check-in', code: 'R', durationMinutes: 5),
          ServiceTemplate(name: 'Auditorium Seating & Ticket Line', code: 'A', durationMinutes: 4),
          ServiceTemplate(name: 'Popcorn & Gourmet Concession Bar', code: 'P', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'public_entertainment_events',
        name: 'Public entertainment events',
        icon: Icons.attractions_outlined,
        description: 'Carnivals, magic shows, amusement rides & stand-up comedy venues',
        defaultServices: [
          ServiceTemplate(name: 'Venue Entry & Wristband Check', code: 'E', durationMinutes: 3),
          ServiceTemplate(name: 'Amusement Ride Queue Counter', code: 'R', durationMinutes: 5),
          ServiceTemplate(name: 'Snack & Souvenir Desk', code: 'S', durationMinutes: 5),
        ],
      ),
    ],
  );

  // O. Social & Religious Events
  static const OrganizationCategory socialEvents = OrganizationCategory(
    id: 'SOCIAL_EVENTS',
    code: 'O',
    name: 'Social & Religious Events',
    description: 'Weddings, receptions, family gatherings, religious festivals, darshan & community meals',
    icon: Icons.celebration_outlined,
    brandColor: Color(0xFFC026D3),
    aliases: ['WEDDING', 'DARSHAN', 'FESTIVAL', 'FEAST'],
    defaultServices: [
      ServiceTemplate(name: 'Guest Welcome & Registration', code: 'W', durationMinutes: 4),
      ServiceTemplate(name: 'Stage Photo & Greeting Queue', code: 'P', durationMinutes: 4),
      ServiceTemplate(name: 'Dining & Feast Hall Seating', code: 'D', durationMinutes: 6),
      ServiceTemplate(name: 'Return Gift & Prasadam Desk', code: 'G', durationMinutes: 4),
    ],
    subCategories: [
      OrganizationSubCategory(
        id: 'weddings',
        name: 'Weddings',
        icon: Icons.favorite_border_outlined,
        description: 'Wedding ceremony, guest welcome, stage photo line & dining hall allocation',
        defaultServices: [
          ServiceTemplate(name: 'Guest Welcome & Tilak Desk', code: 'W', durationMinutes: 3),
          ServiceTemplate(name: 'Bride & Groom Stage Photo Line', code: 'P', durationMinutes: 4),
          ServiceTemplate(name: 'Wedding Banquet Dining Queue', code: 'D', durationMinutes: 8),
          ServiceTemplate(name: 'Gift & Keepsake Handover', code: 'G', durationMinutes: 4),
        ],
      ),
      OrganizationSubCategory(
        id: 'receptions',
        name: 'Receptions',
        icon: Icons.celebration_outlined,
        description: 'Wedding reception, cocktail evenings, couple greeting stage queue',
        defaultServices: [
          ServiceTemplate(name: 'Couple Greeting & Photo Queue', code: 'G', durationMinutes: 4),
          ServiceTemplate(name: 'Buffet Dinner Seating Allocation', code: 'D', durationMinutes: 6),
          ServiceTemplate(name: 'Guestbook & Memory Keepsake', code: 'M', durationMinutes: 3),
        ],
      ),
      OrganizationSubCategory(
        id: 'birthday_parties',
        name: 'Birthday parties',
        icon: Icons.cake_outlined,
        description: 'Kids birthday celebrations, magic show seating, return gift line',
        defaultServices: [
          ServiceTemplate(name: 'Kids Activity & Game Counter', code: 'K', durationMinutes: 5),
          ServiceTemplate(name: 'Snack & Birthday Cake Table', code: 'C', durationMinutes: 5),
          ServiceTemplate(name: 'Return Gift Goodie Bag Line', code: 'G', durationMinutes: 3),
        ],
      ),
      OrganizationSubCategory(
        id: 'family_gatherings',
        name: 'Family gatherings',
        icon: Icons.groups_outlined,
        description: 'Family reunions, anniversary celebrations & milestone functions',
        defaultServices: [
          ServiceTemplate(name: 'Welcome & Seating Allocation', code: 'W', durationMinutes: 4),
          ServiceTemplate(name: 'Family Photograph Line', code: 'P', durationMinutes: 4),
          ServiceTemplate(name: 'Community Lunch / Dinner Batch', code: 'D', durationMinutes: 6),
        ],
      ),
      OrganizationSubCategory(
        id: 'community_celebrations',
        name: 'Community celebrations',
        icon: Icons.people_outline,
        description: 'Diwali melas, New Year galas, cultural celebrations & society meets',
        defaultServices: [
          ServiceTemplate(name: 'Resident Registration & Wristband', code: 'R', durationMinutes: 4),
          ServiceTemplate(name: 'Cultural Program Auditorium Entry', code: 'C', durationMinutes: 5),
          ServiceTemplate(name: 'Community Feast Token Line', code: 'F', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'religious_festivals',
        name: 'Religious festivals',
        icon: Icons.festival_outlined,
        description: 'Ganesh Utsav, Durga Puja, Eid milan, Christmas fairs, procession lines',
        defaultServices: [
          ServiceTemplate(name: 'Pandal & Deity Darshan Line', code: 'D', durationMinutes: 4),
          ServiceTemplate(name: 'Bhog / Holy Offering Distribution', code: 'B', durationMinutes: 5),
          ServiceTemplate(name: 'Aarti & Special Puja Queue', code: 'P', durationMinutes: 5),
        ],
      ),
      OrganizationSubCategory(
        id: 'darshan_management',
        name: 'Darshan management',
        icon: Icons.temple_hindu_outlined,
        description: 'Tirupati/shrine style queue complexes, sheegra darshan, divyang & token slotting',
        aliases: ['DARSHAN', 'SLOTTED_DARSHAN', 'SHRINE_QUEUE'],
        defaultServices: [
          ServiceTemplate(name: 'General Free Darshan Compartment', code: 'G', durationMinutes: 4),
          ServiceTemplate(name: 'Sheegra (Express) Darshan Pass', code: 'S', durationMinutes: 4),
          ServiceTemplate(name: 'Divyang & Senior Citizen Darshan', code: 'D', durationMinutes: 5),
          ServiceTemplate(name: 'Prasadam / Holy Laddu Counter', code: 'L', durationMinutes: 4),
        ],
      ),
      OrganizationSubCategory(
        id: 'community_meals',
        name: 'Community meals',
        icon: Icons.soup_kitchen_outlined,
        description: 'Langar, Annadanam, communal dining halls, batch allocation & volunteer counters',
        aliases: ['LANGAR', 'ANNADANAM', 'COMMUNITY_KITCHEN'],
        defaultServices: [
          ServiceTemplate(name: 'Dining Hall Batch Token Line', code: 'B', durationMinutes: 4),
          ServiceTemplate(name: 'Meal Plate & Seating Queue', code: 'M', durationMinutes: 5),
          ServiceTemplate(name: 'Drinking Water & Seva Counter', code: 'S', durationMinutes: 4),
        ],
      ),
    ],
  );

  /// Master list of all 15 default organization categories (A through O).
  static const List<OrganizationCategory> defaultCategories = [
    healthcare,          // A
    banking,             // B
    government,          // C
    personalCare,        // D
    automobile,          // E
    foodHospitality,     // F
    retailShopping,      // G
    education,           // H
    transportation,      // I
    corporate,           // J
    utilities,           // K
    community,           // L
    eventsExhibitions,   // M
    sports,              // N
    socialEvents,        // O
  ];

  /// Find organization category by ID, code, or alias (case-insensitive).
  static OrganizationCategory findCategory(String? key) {
    if (key == null || key.trim().isEmpty) return healthcare;
    final clean = key.trim().toUpperCase();

    // Direct match on ID or Code
    for (final cat in defaultCategories) {
      if (cat.id == clean || cat.code == clean) return cat;
      if (cat.aliases.any((a) => a.toUpperCase() == clean)) return cat;
    }

    // Substring checks
    if (clean.contains('HEALTH') || clean.contains('CLINIC') || clean.contains('DENT') || clean.contains('HOSPITAL') || clean.contains('MEDIC')) return healthcare;
    if (clean.contains('BANK') || clean.contains('FINANC') || clean.contains('LOAN') || clean.contains('INSUR')) return banking;
    if (clean.contains('GOV') || clean.contains('CIVIC') || clean.contains('MUNICIPAL') || clean.contains('RTO') || clean.contains('AADHAAR')) return government;
    if (clean.contains('SALON') || clean.contains('BARBER') || clean.contains('SPA') || clean.contains('WELLNESS') || clean.contains('FITNESS')) return personalCare;
    if (clean.contains('AUTO') || clean.contains('VEHICLE') || clean.contains('CAR') || clean.contains('TYRE') || clean.contains('REPAIR')) return automobile;
    if (clean.contains('RESTAURANT') || clean.contains('FOOD') || clean.contains('CAFE') || clean.contains('HOTEL') || clean.contains('BUFFET') || clean.contains('BAKE')) return foodHospitality;
    if (clean.contains('RETAIL') || clean.contains('SHOP') || clean.contains('SUPERMARKET') || clean.contains('MALL') || clean.contains('JEWEL')) return retailShopping;
    if (clean.contains('EDU') || clean.contains('SCHOOL') || clean.contains('COLLEGE') || clean.contains('UNIV') || clean.contains('COACH')) return education;
    if (clean.contains('TRAVEL') || clean.contains('TRANSPORT') || clean.contains('AIRPORT') || clean.contains('RAIL') || clean.contains('BUS') || clean.contains('TAXI')) return transportation;
    if (clean.contains('CORP') || clean.contains('LEGAL') || clean.contains('HR') || clean.contains('COWORK') || clean.contains('OFFICE')) return corporate;
    if (clean.contains('UTIL') || clean.contains('ELECTRIC') || clean.contains('WATER') || clean.contains('TELECOM') || clean.contains('GAS') || clean.contains('COURIER')) return utilities;
    if (clean.contains('TEMPLE') || clean.contains('CHURCH') || clean.contains('MOSQUE') || clean.contains('COMMUNITY') || clean.contains('NGO')) return community;
    if (clean.contains('CONCERT') || clean.contains('FESTIVAL') || clean.contains('CONFERENCE') || clean.contains('EXHIB') || clean.contains('EVENT')) return eventsExhibitions;
    if (clean.contains('SPORT') || clean.contains('STADIUM') || clean.contains('MARATHON') || clean.contains('TOURNAMENT') || clean.contains('MOVIE')) return sports;
    if (clean.contains('WEDDING') || clean.contains('DARSHAN') || clean.contains('RECEPTION') || clean.contains('FEAST') || clean.contains('BIRTHDAY') || clean.contains('SOCIAL')) return socialEvents;

    return healthcare;
  }

  /// Find sub-category within a category or across all categories
  static OrganizationSubCategory? findSubCategory(String? categoryKey, String? subCategoryKey) {
    if (subCategoryKey == null || subCategoryKey.trim().isEmpty) return null;

    if (categoryKey != null && categoryKey.isNotEmpty) {
      final cat = findCategory(categoryKey);
      final sub = cat.findSubCategory(subCategoryKey);
      if (sub != null) return sub;
    }

    // Search across all categories
    for (final cat in defaultCategories) {
      final sub = cat.findSubCategory(subCategoryKey);
      if (sub != null) return sub;
    }

    return OrganizationSubCategory.fromCustomName(subCategoryKey);
  }

  /// Search across all categories and sub-categories
  static List<OrganizationSubCategory> search(String query) {
    if (query.trim().isEmpty) {
      return defaultCategories.expand((c) => c.subCategories).toList();
    }
    final q = query.trim().toLowerCase();
    final results = <OrganizationSubCategory>[];

    for (final cat in defaultCategories) {
      for (final sub in cat.subCategories) {
        if (sub.name.toLowerCase().contains(q) ||
            sub.description.toLowerCase().contains(q) ||
            cat.name.toLowerCase().contains(q) ||
            sub.aliases.any((a) => a.toLowerCase().contains(q))) {
          results.add(sub);
        }
      }
    }

    return results;
  }
}
