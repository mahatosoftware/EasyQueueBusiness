import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { callNextCustomerForCounter } from './services/allocationEngine';
import { joinQueue as execJoinQueue } from './services/queueService';
import {
  startServing as execStartServing,
  completeService as execCompleteService,
  recallCustomer as execRecallCustomer,
  markCustomerNoShow as execMarkCustomerNoShow,
  skipCustomer as execSkipCustomer,
} from './services/operatorService';
import { transferCustomer as execTransferCustomer } from './services/transferService';
import {
  openCounter as execOpenCounter,
  pauseCounter as execPauseCounter,
  resumeCounter as execResumeCounter,
  closeCounter as execCloseCounter,
} from './services/counterService';

// Initialize Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * 1. Join Queue (Walk-in, QR, or Customer App)
 */
export const joinQueue = onCall({ cors: true }, async (request) => {
  const data = request.data;
  if (!data.businessId || !data.branchId || !data.serviceId || !data.customerName) {
    throw new HttpsError('invalid-argument', 'Missing required fields: businessId, branchId, serviceId, customerName.');
  }

  try {
    return await execJoinQueue(db, {
      businessId: data.businessId,
      branchId: data.branchId,
      serviceId: data.serviceId,
      customerName: data.customerName,
      phoneNumber: data.phoneNumber,
      numberOfPeople: data.numberOfPeople,
      priorityCategory: data.priorityCategory,
      source: data.source || 'WALK_IN',
      deviceToken: data.deviceToken,
      notes: data.notes,
      customerId: request.auth?.uid,
    });
  } catch (error: any) {
    throw new HttpsError('internal', error.message);
  }
});

/**
 * 2. Concurrency-Safe Call Next Customer (Operator Workspace)
 */
export const callNextCustomer = onCall({ cors: true }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  }

  const { businessId, branchId, counterId, targetServiceId } = request.data;
  if (!businessId || !branchId || !counterId) {
    throw new HttpsError('invalid-argument', 'Missing businessId, branchId, or counterId.');
  }

  try {
    return await callNextCustomerForCounter(db, {
      businessId,
      branchId,
      counterId,
      operatorId: request.auth.uid,
      operatorName: request.auth.token.name || 'Operator',
      targetServiceId,
    });
  } catch (error: any) {
    throw new HttpsError('aborted', error.message);
  }
});

/**
 * 3. Start Serving Customer
 */
export const startServing = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId, entryId } = request.data;
  if (!businessId || !branchId || !counterId || !entryId) {
    throw new HttpsError('invalid-argument', 'Missing required parameters.');
  }

  try {
    return await execStartServing(db, {
      businessId,
      branchId,
      counterId,
      entryId,
      operatorId: request.auth.uid,
      operatorName: request.auth.token.name || 'Operator',
    });
  } catch (error: any) {
    throw new HttpsError('aborted', error.message);
  }
});

/**
 * 4. Complete Service
 */
export const completeService = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId, entryId, notes } = request.data;
  if (!businessId || !branchId || !counterId || !entryId) {
    throw new HttpsError('invalid-argument', 'Missing required parameters.');
  }

  try {
    return await execCompleteService(db, {
      businessId,
      branchId,
      counterId,
      entryId,
      operatorId: request.auth.uid,
      operatorName: request.auth.token.name || 'Operator',
      notes,
    });
  } catch (error: any) {
    throw new HttpsError('aborted', error.message);
  }
});

/**
 * 5. Recall Customer
 */
export const recallCustomer = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId, entryId } = request.data;

  try {
    return await execRecallCustomer(db, {
      businessId,
      branchId,
      counterId,
      entryId,
      operatorId: request.auth.uid,
      operatorName: request.auth.token.name || 'Operator',
    });
  } catch (error: any) {
    throw new HttpsError('aborted', error.message);
  }
});

/**
 * 6. Mark Customer as No-Show
 */
export const markCustomerNoShow = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId, entryId, reason } = request.data;

  try {
    return await execMarkCustomerNoShow(db, {
      businessId,
      branchId,
      counterId,
      entryId,
      operatorId: request.auth.uid,
      operatorName: request.auth.token.name || 'Operator',
      reason,
    });
  } catch (error: any) {
    throw new HttpsError('aborted', error.message);
  }
});

/**
 * 7. Skip Customer
 */
export const skipCustomer = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId, entryId, reason, requeuePolicy } = request.data;

  try {
    return await execSkipCustomer(db, {
      businessId,
      branchId,
      counterId,
      entryId,
      operatorId: request.auth.uid,
      operatorName: request.auth.token.name || 'Operator',
      reason: reason || 'Customer not at counter',
      requeuePolicy,
    });
  } catch (error: any) {
    throw new HttpsError('aborted', error.message);
  }
});

/**
 * 8. Transfer Customer (Cross-Service or Cross-Branch Journey)
 */
export const transferCustomer = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const {
    businessId,
    sourceBranchId,
    sourceCounterId,
    sourceEntryId,
    targetServiceId,
    targetBranchId,
    transferReason,
    priorityOverride,
  } = request.data;

  try {
    return await execTransferCustomer(db, {
      businessId,
      sourceBranchId,
      sourceCounterId,
      sourceEntryId,
      targetServiceId,
      targetBranchId,
      transferReason: transferReason || 'Referred for subsequent service',
      operatorId: request.auth.uid,
      operatorName: request.auth.token.name || 'Operator',
      priorityOverride,
    });
  } catch (error: any) {
    throw new HttpsError('aborted', error.message);
  }
});

/**
 * 9. Counter Lifecycle: Open, Pause, Resume, Close
 */
export const openCounter = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId } = request.data;
  return await execOpenCounter(db, {
    businessId,
    branchId,
    counterId,
    operatorId: request.auth.uid,
    operatorName: request.auth.token.name || 'Operator',
  });
});

export const pauseCounter = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId, reason } = request.data;
  return await execPauseCounter(db, {
    businessId,
    branchId,
    counterId,
    operatorId: request.auth.uid,
    operatorName: request.auth.token.name || 'Operator',
    reason: reason || 'Break',
  });
});

export const resumeCounter = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId } = request.data;
  return await execResumeCounter(db, {
    businessId,
    branchId,
    counterId,
    operatorId: request.auth.uid,
    operatorName: request.auth.token.name || 'Operator',
  });
});

export const closeCounter = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Operator must be authenticated.');
  const { businessId, branchId, counterId } = request.data;
  return await execCloseCounter(db, {
    businessId,
    branchId,
    counterId,
    operatorId: request.auth.uid,
    operatorName: request.auth.token.name || 'Operator',
  });
});
