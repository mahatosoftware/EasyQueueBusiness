// ignore_for_file: use_null_aware_elements
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final functionsServiceProvider = Provider<FunctionsService>((ref) {
  try {
    return FunctionsService(FirebaseFunctions.instanceFor(region: AppConstants.functionsRegion));
  } catch (_) {
    try {
      return FunctionsService(FirebaseFunctions.instance);
    } catch (_) {
      // Allows instantiation in test environments without initialized FirebaseApp
      return FunctionsService(null);
    }
  }
});

class FunctionsService {
  final FirebaseFunctions? _functions;

  FunctionsService(this._functions);

  bool _isFunctionUnavailable(dynamic error) {
    if (error is FirebaseFunctionsException) {
      final code = error.code.toLowerCase();
      return code == 'not-found' ||
          code == 'unavailable' ||
          code == 'unimplemented' ||
          code == 'deadline-exceeded' ||
          code == 'internal';
    }
    final str = error.toString().toLowerCase();
    return str.contains('not-found') ||
        str.contains('not_found') ||
        str.contains('not found') ||
        str.contains('unavailable') ||
        str.contains('failed-precondition') ||
        str.contains('404');
  }

  // 1. Call Next Customer
  Future<Map<String, dynamic>> callNextCustomer({
    required String businessId,
    required String branchId,
    required String counterId,
    String? targetServiceId,
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('callNextCustomer');
        final response = await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'counterId': counterId,
          if (targetServiceId != null) 'targetServiceId': targetServiceId,
        });
        return Map<String, dynamic>.from(response.data as Map);
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function callNextCustomer unavailable ($e). Executing via Firestore fallback.');
      }
    }
    return await _callNextCustomerViaFirestore(
      businessId: businessId,
      branchId: branchId,
      counterId: counterId,
      targetServiceId: targetServiceId,
    );
  }

  // 2. Start Serving
  Future<void> startServing({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('startServing');
        await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'counterId': counterId,
          'entryId': entryId,
        });
        return;
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function startServing unavailable ($e). Executing via Firestore fallback.');
      }
    }
    await _startServingViaFirestore(
      businessId: businessId,
      branchId: branchId,
      counterId: counterId,
      entryId: entryId,
    );
  }

  // 3. Complete Service
  Future<void> completeService({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
    String? notes,
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('completeService');
        await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'counterId': counterId,
          'entryId': entryId,
          if (notes != null) 'notes': notes,
        });
        return;
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function completeService unavailable ($e). Executing via Firestore fallback.');
      }
    }
    await _completeServiceViaFirestore(
      businessId: businessId,
      branchId: branchId,
      counterId: counterId,
      entryId: entryId,
      notes: notes,
    );
  }

  // 4. Recall Customer
  Future<void> recallCustomer({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('recallCustomer');
        await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'counterId': counterId,
          'entryId': entryId,
        });
        return;
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function recallCustomer unavailable ($e). Executing via Firestore fallback.');
      }
    }
    await _recallCustomerViaFirestore(entryId: entryId);
  }

  // 5. Mark Customer No-Show
  Future<void> markCustomerNoShow({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
    String? reason,
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('markCustomerNoShow');
        await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'counterId': counterId,
          'entryId': entryId,
          if (reason != null) 'reason': reason,
        });
        return;
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function markCustomerNoShow unavailable ($e). Executing via Firestore fallback.');
      }
    }
    await _markCustomerNoShowViaFirestore(
      businessId: businessId,
      branchId: branchId,
      counterId: counterId,
      entryId: entryId,
      reason: reason,
    );
  }

  // 6. Skip Customer
  Future<void> skipCustomer({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
    required String reason,
    String requeuePolicy = 'END_OF_QUEUE',
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('skipCustomer');
        await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'counterId': counterId,
          'entryId': entryId,
          'reason': reason,
          'requeuePolicy': requeuePolicy,
        });
        return;
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function skipCustomer unavailable ($e). Executing via Firestore fallback.');
      }
    }
    await _skipCustomerViaFirestore(
      businessId: businessId,
      branchId: branchId,
      counterId: counterId,
      entryId: entryId,
      reason: reason,
      requeuePolicy: requeuePolicy,
    );
  }

  // 7. Transfer Customer
  Future<Map<String, dynamic>> transferCustomer({
    required String businessId,
    required String sourceBranchId,
    required String sourceCounterId,
    required String sourceEntryId,
    required String targetServiceId,
    required String transferReason,
    String? targetBranchId,
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('transferCustomer');
        final response = await callable.call({
          'businessId': businessId,
          'sourceBranchId': sourceBranchId,
          'sourceCounterId': sourceCounterId,
          'sourceEntryId': sourceEntryId,
          'targetServiceId': targetServiceId,
          'transferReason': transferReason,
          if (targetBranchId != null) 'targetBranchId': targetBranchId,
        });
        return Map<String, dynamic>.from(response.data as Map);
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function transferCustomer unavailable ($e). Executing via Firestore fallback.');
      }
    }
    return await _transferCustomerViaFirestore(
      businessId: businessId,
      sourceBranchId: sourceBranchId,
      sourceCounterId: sourceCounterId,
      sourceEntryId: sourceEntryId,
      targetServiceId: targetServiceId,
      transferReason: transferReason,
      targetBranchId: targetBranchId,
    );
  }

  // 8. Toggle Counter Status
  Future<void> toggleCounterStatus({
    required String action, // 'OPEN' | 'PAUSE' | 'RESUME' | 'CLOSE'
    required String businessId,
    required String branchId,
    required String counterId,
    String? reason,
  }) async {
    final functionName = switch (action) {
      'OPEN' => 'openCounter',
      'PAUSE' => 'pauseCounter',
      'RESUME' => 'resumeCounter',
      'CLOSE' => 'closeCounter',
      _ => throw ArgumentError('Unknown counter action: $action'),
    };
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable(functionName);
        await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'counterId': counterId,
          if (reason != null) 'reason': reason,
        });
        return;
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function $functionName unavailable ($e). Executing via Firestore fallback.');
      }
    }
    await _toggleCounterStatusViaFirestore(
      action: action,
      businessId: businessId,
      branchId: branchId,
      counterId: counterId,
      reason: reason,
    );
  }

  // 9. Join Queue
  Future<Map<String, dynamic>> joinQueue({
    required String businessId,
    required String branchId,
    required String serviceId,
    required String customerName,
    String? phoneNumber,
    int numberOfPeople = 1,
    String priorityCategory = 'NORMAL',
    String source = 'WALK_IN',
    String? notes,
  }) async {
    if (_functions != null) {
      try {
        final callable = _functions.httpsCallable('joinQueue');
        final response = await callable.call({
          'businessId': businessId,
          'branchId': branchId,
          'serviceId': serviceId,
          'customerName': customerName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          'numberOfPeople': numberOfPeople,
          'priorityCategory': priorityCategory,
          'source': source,
          if (notes != null) 'notes': notes,
        });
        return Map<String, dynamic>.from(response.data as Map);
      } catch (e) {
        if (!_isFunctionUnavailable(e)) rethrow;
        debugPrint('Cloud Function joinQueue unavailable ($e). Executing via Firestore fallback.');
      }
    }
    return await _joinQueueViaFirestore(
      businessId: businessId,
      branchId: branchId,
      serviceId: serviceId,
      customerName: customerName,
      phoneNumber: phoneNumber,
      numberOfPeople: numberOfPeople,
      priorityCategory: priorityCategory,
      source: source,
      notes: notes,
    );
  }

  // ==========================================
  // DIRECT FIRESTORE FALLBACK IMPLEMENTATIONS
  // ==========================================

  Future<Map<String, dynamic>> _callNextCustomerViaFirestore({
    required String businessId,
    required String branchId,
    required String counterId,
    String? targetServiceId,
  }) async {
    final db = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    final operatorId = currentUser?.uid ?? 'operator';
    final operatorName = currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Operator';

    final counterRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('counters')
        .doc(counterId);

    final counterSnap = await counterRef.get();
    if (!counterSnap.exists) {
      throw Exception('Counter $counterId not found.');
    }
    final counterData = counterSnap.data() as Map<String, dynamic>;
    final status = (counterData['status'] as String? ?? 'CLOSED').toUpperCase();

    if (status == 'CLOSED' || status == 'PAUSED') {
      throw Exception('Counter is currently $status. Please open or resume counter first.');
    }

    if (counterData['currentEntryId'] != null) {
      throw Exception('Counter is already serving token ${counterData['currentTokenNumber']}. Complete or transfer current service first.');
    }

    final supportedServices = List<String>.from(counterData['supportedServiceIds'] ?? []);
    List<String> targetServices = supportedServices;
    if (targetServiceId != null) {
      if (!supportedServices.contains(targetServiceId)) {
        throw Exception('Target service $targetServiceId is not supported by this counter.');
      }
      targetServices = [targetServiceId];
    }

    // Query waiting entries for this branch
    final waitingSnaps = await db
        .collection('queueEntries')
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'WAITING')
        .get();

    if (waitingSnaps.docs.isEmpty) {
      return {'hasCustomer': false, 'message': 'No customers waiting in queue.'};
    }

    // 1. Filter by supported services if specified
    var eligibleDocs = waitingSnaps.docs.where((d) {
      final data = d.data();
      final sId = data['serviceId'] as String?;
      return targetServices.isEmpty || (sId != null && targetServices.contains(sId));
    }).toList();

    // 2. If no customers found matching this counter's specific services,
    // fallback to any waiting customer in this branch so operators can always call next
    if (eligibleDocs.isEmpty) {
      eligibleDocs = waitingSnaps.docs;
    }

    // Sort by priorityWeight DESC, then joinedAt ASC
    eligibleDocs.sort((a, b) {
      final aWeight = (a.data()['priorityWeight'] as num?)?.toInt() ?? 1;
      final bWeight = (b.data()['priorityWeight'] as num?)?.toInt() ?? 1;
      if (aWeight != bWeight) return bWeight.compareTo(aWeight);

      final aJoined = (a.data()['joinedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bJoined = (b.data()['joinedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return aJoined.compareTo(bJoined);
    });

    final candidateDoc = eligibleDocs.first;
    final candidateData = candidateDoc.data();
    final candidateRef = candidateDoc.reference;

    final tokenNumber = candidateData['tokenNumber'] as String? ?? 'Q000';
    final customerMap = candidateData['customer'] as Map<String, dynamic>? ?? {};
    final customerName = customerMap['name'] as String? ?? 'Customer';
    final counterName = counterData['name'] as String? ?? 'Counter';
    final serviceId = candidateData['serviceId'] as String? ?? '';

    // Atomic transaction to claim candidate token
    return await db.runTransaction((transaction) async {
      final freshEntrySnap = await transaction.get(candidateRef);
      if (!freshEntrySnap.exists || freshEntrySnap.data()?['status'] != 'WAITING') {
        return {'hasCustomer': false, 'message': 'Token was claimed by another counter. Please retry.'};
      }

      transaction.update(candidateRef, {
        'status': 'CALLED',
        'assignedCounterId': counterId,
        'counterName': counterName,
        'assignedOperatorId': operatorId,
        'operatorName': operatorName,
        'calledAt': FieldValue.serverTimestamp(),
        'recallCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(counterRef, {
        'status': 'BUSY',
        'currentEntryId': candidateDoc.id,
        'currentTokenNumber': tokenNumber,
        'currentOperatorName': operatorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'hasCustomer': true,
        'entry': {
          'entryId': candidateDoc.id,
          'tokenNumber': tokenNumber,
          'customerName': customerName,
          'serviceId': serviceId,
          'priorityCategory': candidateData['priorityCategory'] ?? 'NORMAL',
        },
      };
    });
  }

  Future<void> _startServingViaFirestore({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
  }) async {
    final db = FirebaseFirestore.instance;
    final entryRef = db.collection('queueEntries').doc(entryId);
    final counterRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('counters')
        .doc(counterId);

    final batch = db.batch();
    batch.update(entryRef, {
      'status': 'SERVING',
      'serviceStartedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(counterRef, {
      'status': 'BUSY',
      'serviceStartedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> _completeServiceViaFirestore({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
    String? notes,
  }) async {
    final db = FirebaseFirestore.instance;
    final entryRef = db.collection('queueEntries').doc(entryId);
    final counterRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('counters')
        .doc(counterId);

    final batch = db.batch();
    batch.update(entryRef, {
      'status': 'COMPLETED',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    batch.update(counterRef, {
      'status': 'AVAILABLE',
      'currentEntryId': FieldValue.delete(),
      'currentTokenNumber': FieldValue.delete(),
      'serviceStartedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> _recallCustomerViaFirestore({
    required String entryId,
  }) async {
    final db = FirebaseFirestore.instance;
    final entryRef = db.collection('queueEntries').doc(entryId);
    await entryRef.update({
      'recallCount': FieldValue.increment(1),
      'calledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markCustomerNoShowViaFirestore({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
    String? reason,
  }) async {
    final db = FirebaseFirestore.instance;
    final entryRef = db.collection('queueEntries').doc(entryId);
    final counterRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('counters')
        .doc(counterId);

    final batch = db.batch();
    batch.update(entryRef, {
      'status': 'NO_SHOW',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.isNotEmpty) 'cancellationReason': reason,
    });
    batch.update(counterRef, {
      'status': 'AVAILABLE',
      'currentEntryId': FieldValue.delete(),
      'currentTokenNumber': FieldValue.delete(),
      'serviceStartedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> _skipCustomerViaFirestore({
    required String businessId,
    required String branchId,
    required String counterId,
    required String entryId,
    required String reason,
    String requeuePolicy = 'END_OF_QUEUE',
  }) async {
    final db = FirebaseFirestore.instance;
    final entryRef = db.collection('queueEntries').doc(entryId);
    final counterRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('counters')
        .doc(counterId);

    final batch = db.batch();
    if (requeuePolicy == 'END_OF_QUEUE') {
      batch.update(entryRef, {
        'status': 'WAITING',
        'assignedCounterId': FieldValue.delete(),
        'counterName': FieldValue.delete(),
        'assignedOperatorId': FieldValue.delete(),
        'operatorName': FieldValue.delete(),
        'joinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.update(entryRef, {
        'status': 'SKIPPED',
        'completedAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.update(counterRef, {
      'status': 'AVAILABLE',
      'currentEntryId': FieldValue.delete(),
      'currentTokenNumber': FieldValue.delete(),
      'serviceStartedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<Map<String, dynamic>> _transferCustomerViaFirestore({
    required String businessId,
    required String sourceBranchId,
    required String sourceCounterId,
    required String sourceEntryId,
    required String targetServiceId,
    required String transferReason,
    String? targetBranchId,
  }) async {
    final db = FirebaseFirestore.instance;
    final entryRef = db.collection('queueEntries').doc(sourceEntryId);
    final counterRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(sourceBranchId)
        .collection('counters')
        .doc(sourceCounterId);

    final batch = db.batch();
    batch.update(entryRef, {
      'status': 'WAITING',
      'serviceId': targetServiceId,
      'transferredToServiceId': targetServiceId,
      'assignedCounterId': FieldValue.delete(),
      'counterName': FieldValue.delete(),
      'assignedOperatorId': FieldValue.delete(),
      'operatorName': FieldValue.delete(),
      'notes': transferReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(counterRef, {
      'status': 'AVAILABLE',
      'currentEntryId': FieldValue.delete(),
      'currentTokenNumber': FieldValue.delete(),
      'serviceStartedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return {'success': true};
  }

  Future<void> _toggleCounterStatusViaFirestore({
    required String action,
    required String businessId,
    required String branchId,
    required String counterId,
    String? reason,
  }) async {
    final db = FirebaseFirestore.instance;
    final counterRef = db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('counters')
        .doc(counterId);

    final newStatus = switch (action.toUpperCase()) {
      'OPEN' => 'AVAILABLE',
      'RESUME' => 'AVAILABLE',
      'PAUSE' => 'PAUSED',
      'CLOSE' => 'CLOSED',
      _ => 'AVAILABLE',
    };

    await counterRef.update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> _joinQueueViaFirestore({
    required String businessId,
    required String branchId,
    required String serviceId,
    required String customerName,
    String? phoneNumber,
    int numberOfPeople = 1,
    String priorityCategory = 'NORMAL',
    String source = 'WALK_IN',
    String? notes,
  }) async {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    String prefix = 'Q';
    try {
      final serviceDoc = await db
          .collection('businesses')
          .doc(businessId)
          .collection('branches')
          .doc(branchId)
          .collection('services')
          .doc(serviceId)
          .get();
      if (serviceDoc.exists) {
        prefix = (serviceDoc.data()?['code'] as String? ?? 'Q').toUpperCase();
      }
    } catch (_) {}

    final todayEntries = await db
        .collection('queueEntries')
        .where('branchId', isEqualTo: branchId)
        .where('serviceId', isEqualTo: serviceId)
        .where('status', isEqualTo: 'WAITING')
        .get();

    final positionInQueue = todayEntries.docs.length + 1;
    final tokenNumber = '$prefix-${(todayEntries.docs.length + 101).toString().padLeft(3, '0')}';
    final entryId = 'entry_${DateTime.now().millisecondsSinceEpoch}';

    final entryRef = db.collection('queueEntries').doc(entryId);
    await entryRef.set({
      'id': entryId,
      'businessId': businessId,
      'branchId': branchId,
      'serviceId': serviceId,
      'tokenNumber': tokenNumber,
      'status': 'WAITING',
      'customer': {
        'name': customerName,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
        if (auth.currentUser != null) 'id': auth.currentUser!.uid,
        'numberOfPeople': numberOfPeople,
      },
      'joinedAt': FieldValue.serverTimestamp(),
      'priorityCategory': priorityCategory,
      'priorityWeight': AppConstants.priorityWeights[priorityCategory] ?? 1,
      'recallCount': 0,
      'estimatedWaitMinutes': positionInQueue * 10,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return {
      'tokenNumber': tokenNumber,
      'positionInQueue': positionInQueue,
      'estimatedWaitMinutes': positionInQueue * 10,
      'entryId': entryId,
    };
  }
}
