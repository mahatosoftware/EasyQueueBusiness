"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPriorityWeight = getPriorityWeight;
exports.joinQueue = joinQueue;
const firestore_1 = require("firebase-admin/firestore");
function getPriorityWeight(category) {
    switch (category) {
        case 'EMERGENCY':
            return 10;
        case 'VIP':
            return 3;
        case 'DISABILITY':
        case 'PREGNANT':
        case 'SENIOR_CITIZEN':
            return 2;
        case 'NORMAL':
        default:
            return 1;
    }
}
async function joinQueue(db, params) {
    const { businessId, branchId, serviceId, customerName, phoneNumber, numberOfPeople = 1, priorityCategory = 'NORMAL', source, deviceToken, notes, customerId } = params;
    const serviceRef = db.doc(`businesses/${businessId}/branches/${branchId}/services/${serviceId}`);
    const queueRef = db.doc(`businesses/${businessId}/branches/${branchId}/queues/${serviceId}`);
    const entryRef = db.collection('queueEntries').doc();
    return await db.runTransaction(async (transaction) => {
        // 1. Validate service
        const serviceSnap = await transaction.get(serviceRef);
        if (!serviceSnap.exists) {
            throw new Error(`Service ${serviceId} not found.`);
        }
        const service = serviceSnap.data();
        if (service.status !== 'ACTIVE') {
            throw new Error(`Service ${service.name} is currently not active.`);
        }
        // 2. Fetch or initialize Queue
        const queueSnap = await transaction.get(queueRef);
        const todayStr = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
        let nextSequence = 1;
        let currentWaiting = 0;
        if (queueSnap.exists) {
            const queueData = queueSnap.data();
            currentWaiting = queueData.waitingCount || 0;
            // Capacity check
            if (service.maxQueueCapacity > 0 && currentWaiting >= service.maxQueueCapacity) {
                throw new Error(`Queue is currently at maximum capacity (${service.maxQueueCapacity}). Please try again later.`);
            }
            if (queueData.tokenSequenceDate === todayStr) {
                nextSequence = (queueData.lastTokenNumber || 0) + 1;
            }
            else {
                nextSequence = 1;
            }
        }
        const prefix = service.code || 'Q';
        const tokenNumber = `${prefix}${String(nextSequence).padStart(3, '0')}`;
        const now = firestore_1.Timestamp.now();
        const priorityWeight = getPriorityWeight(priorityCategory);
        // Approximate wait estimation
        const estimatedMinutes = Math.max(5, (currentWaiting + 1) * (service.estimatedDurationMinutes || 10));
        // 3. Create QueueEntry
        const newEntry = {
            id: entryRef.id,
            businessId,
            branchId,
            serviceId,
            queueId: serviceId,
            tokenNumber,
            tokenSequence: nextSequence,
            customer: {
                id: customerId,
                name: customerName,
                phoneNumber,
                numberOfPeople,
                notes,
                deviceToken,
            },
            source,
            priorityCategory,
            priorityWeight,
            status: 'WAITING',
            recallCount: 0,
            joinedAt: now,
            estimatedWaitMinutes: estimatedMinutes,
        };
        transaction.set(entryRef, newEntry);
        // 4. Update Queue aggregate
        transaction.set(queueRef, {
            id: serviceId,
            businessId,
            branchId,
            serviceId,
            tokenPrefix: prefix,
            tokenSequenceDate: todayStr,
            lastTokenNumber: nextSequence,
            waitingCount: firestore_1.FieldValue.increment(1),
            status: 'OPEN',
            updatedAt: now,
        }, { merge: true });
        return {
            entryId: entryRef.id,
            tokenNumber,
            positionInQueue: currentWaiting + 1,
            estimatedWaitMinutes: estimatedMinutes,
            joinedAt: now.toDate().toISOString(),
        };
    });
}
//# sourceMappingURL=queueService.js.map