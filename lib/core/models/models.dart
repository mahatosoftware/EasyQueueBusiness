import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

enum CounterStatus { closed, available, busy, paused, onBreak, offline, maintenance }

extension CounterStatusX on CounterStatus {
  static CounterStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'AVAILABLE':
        return CounterStatus.available;
      case 'BUSY':
        return CounterStatus.busy;
      case 'PAUSED':
        return CounterStatus.paused;
      case 'BREAK':
        return CounterStatus.onBreak;
      case 'OFFLINE':
        return CounterStatus.offline;
      case 'MAINTENANCE':
        return CounterStatus.maintenance;
      case 'CLOSED':
      default:
        return CounterStatus.closed;
    }
  }

  String toApiString() {
    switch (this) {
      case CounterStatus.available:
        return 'AVAILABLE';
      case CounterStatus.busy:
        return 'BUSY';
      case CounterStatus.paused:
        return 'PAUSED';
      case CounterStatus.onBreak:
        return 'BREAK';
      case CounterStatus.offline:
        return 'OFFLINE';
      case CounterStatus.maintenance:
        return 'MAINTENANCE';
      case CounterStatus.closed:
        return 'CLOSED';
    }
  }
}

enum EntryStatus { waiting, called, serving, completed, skipped, noShow, transferred, cancelled }

extension EntryStatusX on EntryStatus {
  static EntryStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CALLED':
        return EntryStatus.called;
      case 'SERVING':
        return EntryStatus.serving;
      case 'COMPLETED':
        return EntryStatus.completed;
      case 'SKIPPED':
        return EntryStatus.skipped;
      case 'NO_SHOW':
        return EntryStatus.noShow;
      case 'TRANSFERRED':
        return EntryStatus.transferred;
      case 'CANCELLED':
        return EntryStatus.cancelled;
      case 'WAITING':
      default:
        return EntryStatus.waiting;
    }
  }

  String toApiString() {
    switch (this) {
      case EntryStatus.called:
        return 'CALLED';
      case EntryStatus.serving:
        return 'SERVING';
      case EntryStatus.completed:
        return 'COMPLETED';
      case EntryStatus.skipped:
        return 'SKIPPED';
      case EntryStatus.noShow:
        return 'NO_SHOW';
      case EntryStatus.transferred:
        return 'TRANSFERRED';
      case EntryStatus.cancelled:
        return 'CANCELLED';
      case EntryStatus.waiting:
        return 'WAITING';
    }
  }
}

class BusinessModel {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String? subCategory;
  final String? description;
  final String? logoUrl;
  final String? email;
  final String? phoneNumber;
  final String? contactNumber;
  final String? country;
  final String? timeZone;
  final bool isPublic;
  final String status;

  OrganizationCategory get orgCategory => OrganizationCategoryManager.findCategory(category);
  OrganizationSubCategory? get orgSubCategory => OrganizationCategoryManager.findSubCategory(category, subCategory);

  BusinessCategoryInfo get categoryInfo => BusinessCategories.find(category);
  String get categoryDisplayName => orgCategory.name;
  String get subCategoryDisplayName => subCategory ?? (orgCategory.subCategories.isNotEmpty ? orgCategory.subCategories.first.name : '');
  String get fullCategoryDisplayName => (subCategory != null && subCategory!.trim().isNotEmpty)
      ? '${orgCategory.name} • ${subCategory!.trim()}'
      : orgCategory.name;

  BusinessModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    this.subCategory,
    this.description,
    this.logoUrl,
    this.email,
    this.phoneNumber,
    this.contactNumber,
    this.country,
    this.timeZone,
    this.isPublic = true,
    this.status = 'ACTIVE',
  });

  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BusinessModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'GENERAL',
      subCategory: data['subCategory'] ?? data['subcategory'],
      description: data['description'],
      logoUrl: data['logoUrl'],
      email: data['email'],
      phoneNumber: data['phoneNumber'] ?? data['contactNumber'],
      contactNumber: data['contactNumber'],
      country: data['country'],
      timeZone: data['timeZone'] ?? data['timezone'],
      isPublic: data['isPublic'] ?? true,
      status: data['status'] ?? 'ACTIVE',
    );
  }
}

class BranchModel {
  final String id;
  final String businessId;
  final String name;
  final String code;
  final String address;
  final String? contactNumber;
  final String status;

  BranchModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.code,
    this.address = '',
    this.contactNumber,
    required this.status,
  });

  factory BranchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BranchModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? data['phoneNumber'],
      status: data['status'] ?? 'ACTIVE',
    );
  }
}

class ServiceModel {
  final String id;
  final String branchId;
  final String name;
  final String code;
  final int estimatedDurationMinutes;
  final String status;

  ServiceModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.code,
    required this.estimatedDurationMinutes,
    required this.status,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceModel(
      id: doc.id,
      branchId: data['branchId'] ?? '',
      name: data['name'] ?? '',
      code: data['code'] ?? 'Q',
      estimatedDurationMinutes: data['estimatedDurationMinutes'] ?? 10,
      status: data['status'] ?? 'ACTIVE',
    );
  }
}

class CounterModel {
  final String id;
  final String branchId;
  final String name;
  final int counterNumber;
  final String displayLabel;
  final List<String> supportedServiceIds;
  final List<String> assignedOperatorIds;
  final CounterStatus status;
  final String? currentEntryId;
  final String? currentTokenNumber;
  final DateTime? serviceStartedAt;
  final bool autoAllocationEnabled;

  CounterModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.counterNumber,
    required this.displayLabel,
    required this.supportedServiceIds,
    required this.assignedOperatorIds,
    required this.status,
    this.currentEntryId,
    this.currentTokenNumber,
    this.serviceStartedAt,
    this.autoAllocationEnabled = true,
  });

  factory CounterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CounterModel(
      id: doc.id,
      branchId: data['branchId'] ?? '',
      name: data['name'] ?? 'Counter',
      counterNumber: data['counterNumber'] ?? 1,
      displayLabel: data['displayLabel'] ?? '',
      supportedServiceIds: List<String>.from(data['supportedServiceIds'] ?? []),
      assignedOperatorIds: List<String>.from(data['assignedOperatorIds'] ?? []),
      status: CounterStatusX.fromString(data['status'] ?? 'CLOSED'),
      currentEntryId: data['currentEntryId'],
      currentTokenNumber: data['currentTokenNumber'],
      serviceStartedAt: (data['serviceStartedAt'] as Timestamp?)?.toDate(),
      autoAllocationEnabled: data['autoAllocationEnabled'] ?? true,
    );
  }
}

class QueueEntryModel {
  final String id;
  final String businessId;
  final String branchId;
  final String serviceId;
  final String tokenNumber;
  final String customerName;
  final String? phoneNumber;
  final int numberOfPeople;
  final String priorityCategory;
  final int priorityWeight;
  final EntryStatus status;
  final String? assignedCounterId;
  final String? counterName;
  final String? operatorName;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final int recallCount;
  final int estimatedWaitMinutes;
  final String? notes;

  QueueEntryModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.serviceId,
    required this.tokenNumber,
    required this.customerName,
    this.phoneNumber,
    required this.numberOfPeople,
    required this.priorityCategory,
    required this.priorityWeight,
    required this.status,
    this.assignedCounterId,
    this.counterName,
    this.operatorName,
    required this.joinedAt,
    this.calledAt,
    this.recallCount = 0,
    required this.estimatedWaitMinutes,
    this.notes,
  });

  factory QueueEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final cust = data['customer'] as Map<String, dynamic>? ?? {};

    return QueueEntryModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      branchId: data['branchId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      tokenNumber: data['tokenNumber'] ?? '',
      customerName: cust['name'] ?? 'Walk-in Customer',
      phoneNumber: cust['phoneNumber'],
      numberOfPeople: cust['numberOfPeople'] ?? 1,
      priorityCategory: data['priorityCategory'] ?? 'NORMAL',
      priorityWeight: data['priorityWeight'] ?? 1,
      status: EntryStatusX.fromString(data['status'] ?? 'WAITING'),
      assignedCounterId: data['assignedCounterId'],
      counterName: data['counterName'],
      operatorName: data['operatorName'],
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
      recallCount: data['recallCount'] ?? 0,
      estimatedWaitMinutes: data['estimatedWaitMinutes'] ?? 10,
      notes: cust['notes'],
    );
  }
}

enum EmployeeRole { owner, branchManager, supervisor, counterOperator, receptionist }

extension EmployeeRoleX on EmployeeRole {
  static EmployeeRole fromString(String val) {
    switch (val.toUpperCase()) {
      case 'OWNER':
        return EmployeeRole.owner;
      case 'BRANCH_MANAGER':
      case 'MANAGER':
        return EmployeeRole.branchManager;
      case 'SUPERVISOR':
        return EmployeeRole.supervisor;
      case 'RECEPTIONIST':
        return EmployeeRole.receptionist;
      case 'COUNTER_OPERATOR':
      case 'OPERATOR':
      default:
        return EmployeeRole.counterOperator;
    }
  }

  String toDisplayString() {
    switch (this) {
      case EmployeeRole.owner:
        return 'Business Owner';
      case EmployeeRole.branchManager:
        return 'Branch Manager';
      case EmployeeRole.supervisor:
        return 'Supervisor';
      case EmployeeRole.counterOperator:
        return 'Counter Operator';
      case EmployeeRole.receptionist:
        return 'Receptionist';
    }
  }

  String toApiString() {
    switch (this) {
      case EmployeeRole.owner:
        return 'OWNER';
      case EmployeeRole.branchManager:
        return 'BRANCH_MANAGER';
      case EmployeeRole.supervisor:
        return 'SUPERVISOR';
      case EmployeeRole.counterOperator:
        return 'COUNTER_OPERATOR';
      case EmployeeRole.receptionist:
        return 'RECEPTIONIST';
    }
  }
}

class StaffMemberModel {
  final String id;
  final String businessId;
  final List<String> branchIds;
  final String name;
  final String email;
  final String? phoneNumber;
  final EmployeeRole role;
  final String? assignedCounterId;
  final bool isActive;
  final DateTime joinedAt;

  StaffMemberModel({
    required this.id,
    required this.businessId,
    required this.branchIds,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.assignedCounterId,
    this.isActive = true,
    required this.joinedAt,
  });

  factory StaffMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StaffMemberModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      branchIds: List<String>.from(data['branchIds'] ?? []),
      name: data['name'] ?? 'Staff Member',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      role: EmployeeRoleX.fromString(data['role'] ?? 'COUNTER_OPERATOR'),
      assignedCounterId: data['assignedCounterId'],
      isActive: data['isActive'] ?? true,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

enum AppointmentStatus { scheduled, checkedIn, cancelled, noShow }

extension AppointmentStatusX on AppointmentStatus {
  static AppointmentStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CHECKED_IN':
        return AppointmentStatus.checkedIn;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      case 'NO_SHOW':
        return AppointmentStatus.noShow;
      case 'SCHEDULED':
      default:
        return AppointmentStatus.scheduled;
    }
  }

  String toApiString() {
    switch (this) {
      case AppointmentStatus.checkedIn:
        return 'CHECKED_IN';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.noShow:
        return 'NO_SHOW';
      case AppointmentStatus.scheduled:
        return 'SCHEDULED';
    }
  }
}

class AppointmentModel {
  final String id;
  final String businessId;
  final String branchId;
  final String serviceId;
  final String serviceName;
  final String customerName;
  final String phoneNumber;
  final DateTime scheduledTime;
  final AppointmentStatus status;
  final String? tokenNumber;
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.serviceId,
    required this.serviceName,
    required this.customerName,
    required this.phoneNumber,
    required this.scheduledTime,
    required this.status,
    this.tokenNumber,
    this.notes,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppointmentModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      branchId: data['branchId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? 'General Service',
      customerName: data['customerName'] ?? 'Appointment Customer',
      phoneNumber: data['phoneNumber'] ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AppointmentStatusX.fromString(data['status'] ?? 'SCHEDULED'),
      tokenNumber: data['tokenNumber'],
      notes: data['notes'],
    );
  }
}

class AuditLogModel {
  final String id;
  final String businessId;
  final String branchId;
  final String action;
  final String? tokenNumber;
  final String? counterName;
  final String? operatorName;
  final String details;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.action,
    this.tokenNumber,
    this.counterName,
    this.operatorName,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLogModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      branchId: data['branchId'] ?? '',
      action: data['action'] ?? 'OPERATION',
      tokenNumber: data['tokenNumber'],
      counterName: data['counterName'],
      operatorName: data['operatorName'],
      details: data['details'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class SubscriptionPlanModel {
  final String name;
  final String code;
  final String priceMonthly;
  final int maxBranches;
  final int maxCounters;
  final int maxMonthlyTokens;
  final List<String> features;
  final bool isCurrent;

  const SubscriptionPlanModel({
    required this.name,
    required this.code,
    required this.priceMonthly,
    required this.maxBranches,
    required this.maxCounters,
    required this.maxMonthlyTokens,
    required this.features,
    this.isCurrent = false,
  });
}
