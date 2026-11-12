import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { Counter } from '../types/queue';

export async function openCounter(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    operatorId: string;
    operatorName: string;
  }
) {
  const { businessId, branchId, counterId, operatorId, operatorName } = params;
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const counterSnap = await transaction.get(counterRef);
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const now = Timestamp.now();
    transaction.update(counterRef, {
      status: 'AVAILABLE',
      currentOperatorId: operatorId,
      lastHeartbeatAt: now,
      updatedAt: now,
    });

    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      action: 'OPEN',
      previousState: counterSnap.data()?.status || 'CLOSED',
      newState: 'AVAILABLE',
      timestamp: now,
    });

    return { success: true, status: 'AVAILABLE' };
  });
}

export async function pauseCounter(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    operatorId: string;
    operatorName: string;
    reason: string;
  }
) {
  const { businessId, branchId, counterId, operatorId, operatorName, reason } = params;
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const counterSnap = await transaction.get(counterRef);
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const counter = counterSnap.data() as Counter;
    const now = Timestamp.now();

    transaction.update(counterRef, {
      status: 'PAUSED',
      pauseReason: reason,
      updatedAt: now,
    });

    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      action: 'PAUSE',
      previousState: counter.status,
      newState: 'PAUSED',
      reason,
      timestamp: now,
    });

    return { success: true, status: 'PAUSED' };
  });
}

export async function resumeCounter(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    operatorId: string;
    operatorName: string;
  }
) {
  const { businessId, branchId, counterId, operatorId, operatorName } = params;
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const counterSnap = await transaction.get(counterRef);
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const counter = counterSnap.data() as Counter;
    const now = Timestamp.now();
    const nextStatus = counter.currentEntryId ? 'BUSY' : 'AVAILABLE';

    transaction.update(counterRef, {
      status: nextStatus,
      pauseReason: FieldValue.delete(),
      updatedAt: now,
    });

    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      action: 'RESUME',
      previousState: 'PAUSED',
      newState: nextStatus,
      timestamp: now,
    });

    return { success: true, status: nextStatus };
  });
}

export async function closeCounter(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    operatorId: string;
    operatorName: string;
  }
) {
  const { businessId, branchId, counterId, operatorId, operatorName } = params;
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const counterSnap = await transaction.get(counterRef);
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const counter = counterSnap.data() as Counter;
    if (counter.currentEntryId) {
      throw new Error(`Cannot close counter with active customer (${counter.currentTokenNumber}). Please complete or transfer first.`);
    }

    const now = Timestamp.now();
    transaction.update(counterRef, {
      status: 'CLOSED',
      currentOperatorId: FieldValue.delete(),
      updatedAt: now,
    });

    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      action: 'CLOSE',
      previousState: counter.status,
      newState: 'CLOSED',
      timestamp: now,
    });

    return { success: true, status: 'CLOSED' };
  });
}
