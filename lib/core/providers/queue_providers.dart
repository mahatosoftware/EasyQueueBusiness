import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return Stream.value(null);
  }
});

/// Streams all businesses owned by the current authenticated user
final userBusinessesStreamProvider = StreamProvider.autoDispose<List<BusinessModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<BusinessModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .where('ownerId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => BusinessModel.fromFirestore(d)).toList())
      .handleError((_) => <BusinessModel>[]);
});

/// Direct profile fallback that retrieves the user's default business ID
final userProfileDefaultBusinessProvider = FutureProvider.autoDispose<String?>((ref) async {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) return null;
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data()?['defaultBusinessId'] as String?;
    }
  } catch (_) {}
  return null;
});

/// Selected Business ID - automatically defaults to the user's primary business
final selectedBusinessIdProvider = StateProvider<String>((ref) {
  ref.listen<AsyncValue<List<BusinessModel>>>(userBusinessesStreamProvider, (prev, next) {
    final list = next.valueOrNull ?? [];
    if (ref.controller.state.isEmpty && list.isNotEmpty) {
      ref.controller.state = list.first.id;
    }
  });

  ref.listen<AsyncValue<String?>>(userProfileDefaultBusinessProvider, (prev, next) {
    final defId = next.valueOrNull;
    if (ref.controller.state.isEmpty && defId != null && defId.isNotEmpty) {
      ref.controller.state = defId;
    }
  });

  final businesses = ref.watch(userBusinessesStreamProvider).valueOrNull ?? [];
  if (businesses.isNotEmpty) return businesses.first.id;

  final profileDefault = ref.watch(userProfileDefaultBusinessProvider).valueOrNull;
  if (profileDefault != null && profileDefault.isNotEmpty) return profileDefault;

  return '';
});

/// Current active Business object
final currentBusinessProvider = Provider<BusinessModel?>((ref) {
  final bizId = ref.watch(selectedBusinessIdProvider);
  final businesses = ref.watch(userBusinessesStreamProvider).valueOrNull ?? [];
  if (bizId.isNotEmpty) {
    final match = businesses.where((b) => b.id == bizId).firstOrNull;
    if (match != null) return match;
  }
  return businesses.firstOrNull;
});

/// Streams all branches for the currently selected business
final branchesStreamProvider = StreamProvider.autoDispose<List<BranchModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<BranchModel>[]);
  }

  var bizId = ref.watch(selectedBusinessIdProvider);
  if (bizId.isEmpty) {
    final currentBiz = ref.watch(currentBusinessProvider);
    if (currentBiz != null) bizId = currentBiz.id;
  }
  if (bizId.isEmpty) {
    return Stream.value(<BranchModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(bizId)
      .collection('branches')
      .snapshots()
      .map((snap) => snap.docs.map((d) => BranchModel.fromFirestore(d)).toList());
});

/// Selected Branch ID - automatically defaults to the first branch of the selected business
final selectedBranchIdProvider = StateProvider<String>((ref) {
  ref.listen<AsyncValue<List<BranchModel>>>(branchesStreamProvider, (prev, next) {
    final list = next.valueOrNull ?? [];
    if (ref.controller.state.isEmpty && list.isNotEmpty) {
      ref.controller.state = list.first.id;
    }
  });
  final branches = ref.watch(branchesStreamProvider).valueOrNull ?? [];
  return branches.isNotEmpty ? branches.first.id : '';
});

/// Current active Branch object
final currentBranchProvider = Provider<BranchModel?>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  final branches = ref.watch(branchesStreamProvider).valueOrNull ?? [];
  if (branchId.isNotEmpty) {
    final match = branches.where((b) => b.id == branchId).firstOrNull;
    if (match != null) return match;
  }
  return branches.firstOrNull;
});

final countersStreamProvider = StreamProvider.autoDispose<List<CounterModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<CounterModel>[]);
  }

  final bizId = ref.watch(selectedBusinessIdProvider);
  final branchId = ref.watch(selectedBranchIdProvider);
  if (bizId.isEmpty || branchId.isEmpty) {
    return Stream.value(<CounterModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(bizId)
      .collection('branches')
      .doc(branchId)
      .collection('counters')
      .orderBy('counterNumber')
      .snapshots()
      .map((snap) => snap.docs.map((d) => CounterModel.fromFirestore(d)).toList());
});

final servicesStreamProvider = StreamProvider.autoDispose<List<ServiceModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<ServiceModel>[]);
  }

  final bizId = ref.watch(selectedBusinessIdProvider);
  final branchId = ref.watch(selectedBranchIdProvider);
  if (bizId.isEmpty || branchId.isEmpty) {
    return Stream.value(<ServiceModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(bizId)
      .collection('branches')
      .doc(branchId)
      .collection('services')
      .snapshots()
      .map((snap) => snap.docs.map((d) => ServiceModel.fromFirestore(d)).toList());
});

final activeQueueEntriesProvider = StreamProvider.autoDispose<List<QueueEntryModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<QueueEntryModel>[]);
  }

  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId.isEmpty) {
    return Stream.value(<QueueEntryModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('queueEntries')
      .where('branchId', isEqualTo: branchId)
      .where('status', whereIn: ['WAITING', 'CALLED', 'SERVING'])
      .orderBy('priorityWeight', descending: true)
      .orderBy('joinedAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((d) => QueueEntryModel.fromFirestore(d)).toList());
});

final completedQueueEntriesProvider = StreamProvider.autoDispose<List<QueueEntryModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<QueueEntryModel>[]);
  }

  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId.isEmpty) {
    return Stream.value(<QueueEntryModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('queueEntries')
      .where('branchId', isEqualTo: branchId)
      .where('status', whereIn: ['COMPLETED', 'NO_SHOW', 'SKIPPED', 'TRANSFERRED', 'CANCELLED'])
      .orderBy('completedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) => QueueEntryModel.fromFirestore(d)).toList());
});

final employeesStreamProvider = StreamProvider.autoDispose<List<StaffMemberModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<StaffMemberModel>[]);
  }

  final bizId = ref.watch(selectedBusinessIdProvider);
  if (bizId.isEmpty) {
    return Stream.value(<StaffMemberModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(bizId)
      .collection('employees')
      .snapshots()
      .map((snap) => snap.docs.map((d) => StaffMemberModel.fromFirestore(d)).toList());
});

final appointmentsStreamProvider = StreamProvider.autoDispose<List<AppointmentModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<AppointmentModel>[]);
  }

  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId.isEmpty) {
    return Stream.value(<AppointmentModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('appointments')
      .where('branchId', isEqualTo: branchId)
      .orderBy('scheduledTime')
      .snapshots()
      .map((snap) => snap.docs.map((d) => AppointmentModel.fromFirestore(d)).toList());
});

final auditLogsStreamProvider = StreamProvider.autoDispose<List<AuditLogModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<AuditLogModel>[]);
  }

  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId.isEmpty) {
    return Stream.value(<AuditLogModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('operations')
      .where('branchId', isEqualTo: branchId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) => AuditLogModel.fromFirestore(d)).toList());
});
