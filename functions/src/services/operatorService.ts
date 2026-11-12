import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { Counter, QueueEntry } from '../types/queue';

export async function startServing(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    entryId: string;
    operatorId: string;
    operatorName: string;
  }
) {
  const { businessId, branchId, counterId, entryId, operatorId, operatorName } = params;
  const entryRef = db.doc(`queueEntries/${entryId}`);
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const [entrySnap, counterSnap] = await Promise.all([
      transaction.get(entryRef),
      transaction.get(counterRef),
    ]);

    if (!entrySnap.exists) throw new Error('Queue entry not found.');
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const entry = entrySnap.data() as QueueEntry;
    const counter = counterSnap.data() as Counter;

    if (counter.status === 'CLOSED') {
      throw new Error('Counter is closed.');
    }

    if (entry.status !== 'CALLED') {
      throw new Error(`Cannot start service. Customer is in state ${entry.status}. Must be CALLED.`);
    }

    if (entry.assignedCounterId !== counterId) {
      throw new Error(`Customer is assigned to counter ${entry.counterName || entry.assignedCounterId}, not this counter.`);
    }

    const now = Timestamp.now();

    transaction.update(entryRef, {
      status: 'SERVING',
      serviceStartedAt: now,
    });

    transaction.update(counterRef, {
      status: 'BUSY',
      serviceStartedAt: now,
      updatedAt: now,
    });

    const queueRef = db.doc(`businesses/${businessId}/branches/${branchId}/queues/${entry.serviceId}`);
    transaction.set(
      queueRef,
      {
        calledCount: FieldValue.increment(-1),
        servingCount: FieldValue.increment(1),
        updatedAt: now,
      },
      { merge: true }
    );

    // Audit operation
    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      entryId,
      tokenNumber: entry.tokenNumber,
      serviceId: entry.serviceId,
      action: 'START_SERVICE',
      previousState: 'CALLED',
      newState: 'SERVING',
      timestamp: now,
    });

    return { success: true, serviceStartedAt: now.toDate().toISOString() };
  });
}

export async function completeService(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    entryId: string;
    operatorId: string;
    operatorName: string;
    notes?: string;
  }
) {
  const { businessId, branchId, counterId, entryId, operatorId, operatorName, notes } = params;
  const entryRef = db.doc(`queueEntries/${entryId}`);
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const [entrySnap, counterSnap] = await Promise.all([
      transaction.get(entryRef),
      transaction.get(counterRef),
    ]);

    if (!entrySnap.exists) throw new Error('Queue entry not found.');
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const entry = entrySnap.data() as QueueEntry;
    const now = Timestamp.now();

    const startedTime = entry.serviceStartedAt || entry.calledAt || now;
    const durationSeconds = Math.max(0, Math.round((now.toMillis() - startedTime.toMillis()) / 1000));

    transaction.update(entryRef, {
      status: 'COMPLETED',
      completedAt: now,
      serviceDurationSeconds: durationSeconds,
      ...(notes ? { notes } : {}),
    });

    // Reset counter back to AVAILABLE
    transaction.update(counterRef, {
      status: 'AVAILABLE',
      currentEntryId: FieldValue.delete(),
      currentTokenNumber: FieldValue.delete(),
      serviceStartedAt: FieldValue.delete(),
      updatedAt: now,
    });

    // Update queue aggregates
    const queueRef = db.doc(`businesses/${businessId}/branches/${branchId}/queues/${entry.serviceId}`);
    transaction.set(
      queueRef,
      {
        servingCount: FieldValue.increment(-1),
        completedCount: FieldValue.increment(1),
        updatedAt: now,
      },
      { merge: true }
    );

    // Audit operation
    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      entryId,
      tokenNumber: entry.tokenNumber,
      serviceId: entry.serviceId,
      action: 'COMPLETE',
      previousState: entry.status,
      newState: 'COMPLETED',
      timestamp: now,
      metadata: { durationSeconds },
    });

    return { success: true, serviceDurationSeconds: durationSeconds };
  });
}

export async function recallCustomer(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    entryId: string;
    operatorId: string;
    operatorName: string;
  }
) {
  const { businessId, branchId, counterId, entryId, operatorId, operatorName } = params;
  const entryRef = db.doc(`queueEntries/${entryId}`);

  return await db.runTransaction(async (transaction) => {
    const entrySnap = await transaction.get(entryRef);
    if (!entrySnap.exists) throw new Error('Queue entry not found.');

    const entry = entrySnap.data() as QueueEntry;
    if (entry.status !== 'CALLED') {
      throw new Error(`Customer can only be recalled when in CALLED status (current: ${entry.status}).`);
    }

    const now = Timestamp.now();
    const newRecallCount = (entry.recallCount || 0) + 1;

    transaction.update(entryRef, {
      recallCount: newRecallCount,
      lastRecalledAt: now,
    });

    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      entryId,
      tokenNumber: entry.tokenNumber,
      serviceId: entry.serviceId,
      action: 'RECALL',
      previousState: 'CALLED',
      newState: 'CALLED',
      timestamp: now,
      metadata: { recallCount: newRecallCount },
    });

    return { success: true, recallCount: newRecallCount };
  });
}

export async function markCustomerNoShow(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    entryId: string;
    operatorId: string;
    operatorName: string;
    reason?: string;
  }
) {
  const { businessId, branchId, counterId, entryId, operatorId, operatorName, reason = 'Customer did not show up within grace period' } = params;
  const entryRef = db.doc(`queueEntries/${entryId}`);
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const [entrySnap, counterSnap] = await Promise.all([
      transaction.get(entryRef),
      transaction.get(counterRef),
    ]);

    if (!entrySnap.exists) throw new Error('Queue entry not found.');
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const entry = entrySnap.data() as QueueEntry;
    const now = Timestamp.now();

    transaction.update(entryRef, {
      status: 'NO_SHOW',
      noShowReason: reason,
      completedAt: now,
    });

    transaction.update(counterRef, {
      status: 'AVAILABLE',
      currentEntryId: FieldValue.delete(),
      currentTokenNumber: FieldValue.delete(),
      serviceStartedAt: FieldValue.delete(),
      updatedAt: now,
    });

    const queueRef = db.doc(`businesses/${businessId}/branches/${branchId}/queues/${entry.serviceId}`);
    transaction.set(
      queueRef,
      {
        calledCount: FieldValue.increment(-1),
        noShowCount: FieldValue.increment(1),
        updatedAt: now,
      },
      { merge: true }
    );

    const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
    transaction.set(opRef, {
      id: opRef.id,
      businessId,
      branchId,
      counterId,
      operatorId,
      operatorName,
      entryId,
      tokenNumber: entry.tokenNumber,
      serviceId: entry.serviceId,
      action: 'NO_SHOW',
      previousState: entry.status,
      newState: 'NO_SHOW',
      reason,
      timestamp: now,
    });

    return { success: true };
  });
}

export async function skipCustomer(
  db: FirebaseFirestore.Firestore,
  params: {
    businessId: string;
    branchId: string;
    counterId: string;
    entryId: string;
    operatorId: string;
    operatorName: string;
    reason: string;
    requeuePolicy?: 'END_OF_QUEUE' | 'CLOSE_AS_SKIPPED';
  }
) {
  const { businessId, branchId, counterId, entryId, operatorId, operatorName, reason, requeuePolicy = 'END_OF_QUEUE' } = params;
  const entryRef = db.doc(`queueEntries/${entryId}`);
  const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);

  return await db.runTransaction(async (transaction) => {
    const [entrySnap, counterSnap] = await Promise.all([
      transaction.get(entryRef),
      transaction.get(counterRef),
    ]);

    if (!entrySnap.exists) throw new Error('Queue entry not found.');
    if (!counterSnap.exists) throw new Error('Counter not found.');

    const entry = entrySnap.data() as QueueEntry;
    const now = Timestamp.now();

    if (requeuePolicy === 'END_OF_QUEUE') {
      // Return customer to WAITING at the back of the line
      transaction.update(entryRef, {
        status: 'WAITING',
        joinedAt: now, // Moves to back of FIFO
        assignedCounterId: FieldValue.delete(),
        assignedOperatorId: FieldValue.delete(),
        counterName: FieldValue.delete(),
        operatorName: FieldValue.delete(),
      });

      const queueRef = db.doc(`businesses/${businessId}/branches/${branchId}/queues/${entry.serviceId}`);
      transaction.set(
        queueRef,
        {
          calledCount: FieldValue.increment(-1),
          waitingCount: FieldValue.increment(1),
          updatedAt: now,
        },
        { merge: true }
      );
    } else {
      transaction.update(entryRef, {
        status: 'SKIPPED',
        completedAt: now,
      });

      const queueRef = db.doc(`businesses/${businessId}/branches/${branchId}/queues/${entry.serviceId}`);
      transaction.set(
        queueRef,
        {
          calledCount: FieldValue.increment(-1),
          updatedAt: now,
        },
        { merge: true }
      );
    }

    transaction.update(counterRef, {
      status: 'AVAILABLE',
      currentEntryId: FieldValue.delete(),
      currentTokenNumber: FieldValue.delete(),
      serviceStartedAt: FieldValue.delete(),
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
      entryId,
      tokenNumber: entry.tokenNumber,
      serviceId: entry.serviceId,
      action: 'SKIP',
      previousState: entry.status,
      newState: requeuePolicy === 'END_OF_QUEUE' ? 'WAITING' : 'SKIPPED',
      reason,
      timestamp: now,
    });

    return { success: true, newStatus: requeuePolicy === 'END_OF_QUEUE' ? 'WAITING' : 'SKIPPED' };
  });
}
