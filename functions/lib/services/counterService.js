"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.openCounter = openCounter;
exports.pauseCounter = pauseCounter;
exports.resumeCounter = resumeCounter;
exports.closeCounter = closeCounter;
const firestore_1 = require("firebase-admin/firestore");
async function openCounter(db, params) {
    const { businessId, branchId, counterId, operatorId, operatorName } = params;
    const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);
    return await db.runTransaction(async (transaction) => {
        const counterSnap = await transaction.get(counterRef);
        if (!counterSnap.exists)
            throw new Error('Counter not found.');
        const now = firestore_1.Timestamp.now();
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
async function pauseCounter(db, params) {
    const { businessId, branchId, counterId, operatorId, operatorName, reason } = params;
    const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);
    return await db.runTransaction(async (transaction) => {
        const counterSnap = await transaction.get(counterRef);
        if (!counterSnap.exists)
            throw new Error('Counter not found.');
        const counter = counterSnap.data();
        const now = firestore_1.Timestamp.now();
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
async function resumeCounter(db, params) {
    const { businessId, branchId, counterId, operatorId, operatorName } = params;
    const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);
    return await db.runTransaction(async (transaction) => {
        const counterSnap = await transaction.get(counterRef);
        if (!counterSnap.exists)
            throw new Error('Counter not found.');
        const counter = counterSnap.data();
        const now = firestore_1.Timestamp.now();
        const nextStatus = counter.currentEntryId ? 'BUSY' : 'AVAILABLE';
        transaction.update(counterRef, {
            status: nextStatus,
            pauseReason: firestore_1.FieldValue.delete(),
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
async function closeCounter(db, params) {
    const { businessId, branchId, counterId, operatorId, operatorName } = params;
    const counterRef = db.doc(`businesses/${businessId}/branches/${branchId}/counters/${counterId}`);
    return await db.runTransaction(async (transaction) => {
        const counterSnap = await transaction.get(counterRef);
        if (!counterSnap.exists)
            throw new Error('Counter not found.');
        const counter = counterSnap.data();
        if (counter.currentEntryId) {
            throw new Error(`Cannot close counter with active customer (${counter.currentTokenNumber}). Please complete or transfer first.`);
        }
        const now = firestore_1.Timestamp.now();
        transaction.update(counterRef, {
            status: 'CLOSED',
            currentOperatorId: firestore_1.FieldValue.delete(),
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
//# sourceMappingURL=counterService.js.map