"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.callNextCustomerForCounter = callNextCustomerForCounter;
const firestore_1 = require("firebase-admin/firestore");
/**
 * Concurrency-Safe Transactional Token Call
 * Ensures that even if multiple counters trigger callNext simultaneously,
 * each customer token is atomically claimed exactly once.
 */
async function callNextCustomerForCounter(db, params) {
    const { businessId, branchId, counterId, operatorId, operatorName, targetServiceId } = params;
    const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);
    return await db.runTransaction(async (transaction) => {
        // 1. Fetch & validate Counter
        const counterSnap = await transaction.get(counterRef);
        if (!counterSnap.exists) {
            throw new Error(`Counter ${counterId} not found.`);
        }
        const counter = counterSnap.data();
        // Counter must be AVAILABLE or have no active customer
        if (counter.status === 'CLOSED' || counter.status === 'PAUSED' || counter.status === 'BREAK' || counter.status === 'OFFLINE') {
            throw new Error(`Counter is currently ${counter.status}. Please open or resume counter first.`);
        }
        if (counter.currentEntryId) {
            throw new Error(`Counter is already serving token ${counter.currentTokenNumber}. Complete or transfer current service first.`);
        }
        // Determine eligible services
        let eligibleServices = counter.supportedServiceIds || [];
        if (targetServiceId) {
            if (!eligibleServices.includes(targetServiceId)) {
                throw new Error(`Target service ${targetServiceId} is not supported by this counter.`);
            }
            eligibleServices = [targetServiceId];
        }
        // 2. Query next eligible customer token (Ordered by priority weight DESC, then FIFO joinedAt ASC)
        const entriesRef = db.collection('queueEntries');
        let candidateSnaps = null;
        if (eligibleServices.length > 0) {
            const query = entriesRef
                .where('branchId', '==', branchId)
                .where('serviceId', 'in', eligibleServices.slice(0, 10))
                .where('status', '==', 'WAITING')
                .orderBy('priorityWeight', 'desc')
                .orderBy('joinedAt', 'asc')
                .limit(1);
            candidateSnaps = await transaction.get(query);
        }
        // Fallback: If no customer found matching the specific service or no services mapped,
        // query any waiting customer in this branch so counters are never blocked
        if (!candidateSnaps || candidateSnaps.empty) {
            const fallbackQuery = entriesRef
                .where('branchId', '==', branchId)
                .where('status', '==', 'WAITING')
                .orderBy('priorityWeight', 'desc')
                .orderBy('joinedAt', 'asc')
                .limit(1);
            candidateSnaps = await transaction.get(fallbackQuery);
        }
        if (candidateSnaps.empty) {
            return { hasCustomer: false, message: 'No waiting customers in queue.' };
        }
        const candidateDoc = candidateSnaps.docs[0];
        const candidateData = candidateDoc.data();
        // 3. Re-verify the candidate's status within the transaction
        if (candidateData.status !== 'WAITING') {
            return { hasCustomer: false, message: 'Selected token was claimed by another counter. Please retry.' };
        }
        const now = firestore_1.Timestamp.now();
        const waitSeconds = Math.max(0, Math.round((now.toMillis() - candidateData.joinedAt.toMillis()) / 1000));
        // 4. Update the QueueEntry
        transaction.update(candidateDoc.ref, {
            status: 'CALLED',
            assignedCounterId: counterId,
            assignedOperatorId: operatorId,
            counterName: counter.name,
            operatorName: operatorName,
            calledAt: now,
            recallCount: 0,
            waitDurationSeconds: waitSeconds,
        });
        // 5. Update the Counter state
        transaction.update(counterRef, {
            status: 'BUSY',
            currentEntryId: candidateDoc.id,
            currentTokenNumber: candidateData.tokenNumber,
            currentOperatorId: operatorId,
            updatedAt: now,
        });
        // 6. Update Queue aggregations
        const queueRef = db.doc(`businesses/${businessId}/branches/${branchId}/queues/${candidateData.serviceId}`);
        transaction.set(queueRef, {
            waitingCount: firestore_1.FieldValue.increment(-1),
            calledCount: firestore_1.FieldValue.increment(1),
            updatedAt: now,
        }, { merge: true });
        // 7. Record immutable audit operation
        const opRef = db.collection(`businesses/${businessId}/branches/${branchId}/operations`).doc();
        transaction.set(opRef, {
            id: opRef.id,
            businessId,
            branchId,
            counterId,
            operatorId,
            operatorName,
            entryId: candidateDoc.id,
            tokenNumber: candidateData.tokenNumber,
            serviceId: candidateData.serviceId,
            action: 'CALL_NEXT',
            previousState: 'WAITING',
            newState: 'CALLED',
            timestamp: now,
        });
        return {
            hasCustomer: true,
            entry: {
                entryId: candidateDoc.id,
                tokenNumber: candidateData.tokenNumber,
                customerName: candidateData.customer.name,
                serviceId: candidateData.serviceId,
                priorityCategory: candidateData.priorityCategory,
                waitDurationSeconds: waitSeconds,
                notes: candidateData.customer.notes,
            },
        };
    });
}
//# sourceMappingURL=allocationEngine.js.map