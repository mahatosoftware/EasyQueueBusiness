"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.transferCustomer = transferCustomer;
const firestore_1 = require("firebase-admin/firestore");
const queueService_1 = require("./queueService");
async function transferCustomer(db, params) {
    const { businessId, sourceBranchId, sourceCounterId, sourceEntryId, targetServiceId, targetBranchId = sourceBranchId, transferReason, operatorId, operatorName, priorityOverride, } = params;
    const sourceEntryRef = db.doc(`queueEntries/${sourceEntryId}`);
    const sourceCounterRef = db.doc(`businesses/${businessId}/branches/${sourceBranchId}/counters/${sourceCounterId}`);
    const targetServiceRef = db.doc(`businesses/${businessId}/branches/${targetBranchId}/services/${targetServiceId}`);
    const targetQueueRef = db.doc(`businesses/${businessId}/branches/${targetBranchId}/queues/${targetServiceId}`);
    const newEntryRef = db.collection('queueEntries').doc();
    return await db.runTransaction(async (transaction) => {
        const [sourceEntrySnap, targetServiceSnap, targetQueueSnap] = await Promise.all([
            transaction.get(sourceEntryRef),
            transaction.get(targetServiceRef),
            transaction.get(targetQueueRef),
        ]);
        if (!sourceEntrySnap.exists)
            throw new Error('Source queue entry not found.');
        if (!targetServiceSnap.exists)
            throw new Error('Target service not found.');
        const sourceEntry = sourceEntrySnap.data();
        const targetService = targetServiceSnap.data();
        if (sourceEntry.status !== 'SERVING' && sourceEntry.status !== 'CALLED') {
            throw new Error(`Cannot transfer customer in status ${sourceEntry.status}. Must be SERVING or CALLED.`);
        }
        const todayStr = new Date().toISOString().slice(0, 10);
        let nextSequence = 1;
        let currentWaiting = 0;
        if (targetQueueSnap.exists) {
            const qData = targetQueueSnap.data();
            currentWaiting = qData.waitingCount || 0;
            if (qData.tokenSequenceDate === todayStr) {
                nextSequence = (qData.lastTokenNumber || 0) + 1;
            }
        }
        const prefix = targetService.code || 'T';
        const newTokenNumber = `${prefix}${String(nextSequence).padStart(3, '0')}`;
        const now = firestore_1.Timestamp.now();
        const journeyId = sourceEntry.parentJourneyId || sourceEntry.id;
        const priorityCategory = priorityOverride || sourceEntry.priorityCategory;
        const priorityWeight = (0, queueService_1.getPriorityWeight)(priorityCategory);
        // 1. Mark source entry as TRANSFERRED
        transaction.update(sourceEntryRef, {
            status: 'TRANSFERRED',
            completedAt: now,
            transferredToServiceId: targetServiceId,
            transferredToEntryId: newEntryRef.id,
            transferReason,
        });
        // 2. Free source counter
        transaction.update(sourceCounterRef, {
            status: 'AVAILABLE',
            currentEntryId: firestore_1.FieldValue.delete(),
            currentTokenNumber: firestore_1.FieldValue.delete(),
            serviceStartedAt: firestore_1.FieldValue.delete(),
            updatedAt: now,
        });
        // 3. Decrement source queue active count
        const sourceQueueRef = db.doc(`businesses/${businessId}/branches/${sourceBranchId}/queues/${sourceEntry.serviceId}`);
        transaction.set(sourceQueueRef, {
            [sourceEntry.status === 'SERVING' ? 'servingCount' : 'calledCount']: firestore_1.FieldValue.increment(-1),
            updatedAt: now,
        }, { merge: true });
        // 4. Create new linked queue entry
        const newEntry = {
            id: newEntryRef.id,
            businessId,
            branchId: targetBranchId,
            serviceId: targetServiceId,
            queueId: targetServiceId,
            tokenNumber: newTokenNumber,
            tokenSequence: nextSequence,
            customer: sourceEntry.customer,
            source: sourceEntry.source,
            priorityCategory,
            priorityWeight,
            status: 'WAITING',
            recallCount: 0,
            joinedAt: now,
            parentJourneyId: journeyId,
            estimatedWaitMinutes: Math.max(5, (currentWaiting + 1) * (targetService.estimatedDurationMinutes || 10)),
        };
        transaction.set(newEntryRef, newEntry);
        // 5. Increment target queue count
        transaction.set(targetQueueRef, {
            id: targetServiceId,
            businessId,
            branchId: targetBranchId,
            serviceId: targetServiceId,
            tokenPrefix: prefix,
            tokenSequenceDate: todayStr,
            lastTokenNumber: nextSequence,
            waitingCount: firestore_1.FieldValue.increment(1),
            status: 'OPEN',
            updatedAt: now,
        }, { merge: true });
        // 6. Record transfer operation
        const opRef = db.collection(`businesses/${businessId}/branches/${sourceBranchId}/operations`).doc();
        transaction.set(opRef, {
            id: opRef.id,
            businessId,
            branchId: sourceBranchId,
            counterId: sourceCounterId,
            operatorId,
            operatorName,
            entryId: sourceEntry.id,
            tokenNumber: sourceEntry.tokenNumber,
            serviceId: sourceEntry.serviceId,
            action: 'TRANSFER',
            previousState: sourceEntry.status,
            newState: 'TRANSFERRED',
            reason: transferReason,
            metadata: {
                targetServiceId,
                targetBranchId,
                newTokenNumber,
                newEntryId: newEntryRef.id,
            },
            timestamp: now,
        });
        return {
            success: true,
            newEntryId: newEntryRef.id,
            newTokenNumber,
            estimatedWaitMinutes: newEntry.estimatedWaitMinutes,
        };
    });
}
//# sourceMappingURL=transferService.js.map