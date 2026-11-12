"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.closeCounter = exports.resumeCounter = exports.pauseCounter = exports.openCounter = exports.transferCustomer = exports.skipCustomer = exports.markCustomerNoShow = exports.recallCustomer = exports.completeService = exports.startServing = exports.callNextCustomer = exports.joinQueue = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const allocationEngine_1 = require("./services/allocationEngine");
const queueService_1 = require("./services/queueService");
const operatorService_1 = require("./services/operatorService");
const transferService_1 = require("./services/transferService");
const counterService_1 = require("./services/counterService");
// Initialize Firebase Admin
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
/**
 * 1. Join Queue (Walk-in, QR, or Customer App)
 */
exports.joinQueue = (0, https_1.onCall)({ cors: true }, async (request) => {
    const data = request.data;
    if (!data.businessId || !data.branchId || !data.serviceId || !data.customerName) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required fields: businessId, branchId, serviceId, customerName.');
    }
    try {
        return await (0, queueService_1.joinQueue)(db, {
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
    }
    catch (error) {
        throw new https_1.HttpsError('internal', error.message);
    }
});
/**
 * 2. Concurrency-Safe Call Next Customer (Operator Workspace)
 */
exports.callNextCustomer = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    }
    const { businessId, branchId, counterId, targetServiceId } = request.data;
    if (!businessId || !branchId || !counterId) {
        throw new https_1.HttpsError('invalid-argument', 'Missing businessId, branchId, or counterId.');
    }
    try {
        return await (0, allocationEngine_1.callNextCustomerForCounter)(db, {
            businessId,
            branchId,
            counterId,
            operatorId: request.auth.uid,
            operatorName: request.auth.token.name || 'Operator',
            targetServiceId,
        });
    }
    catch (error) {
        throw new https_1.HttpsError('aborted', error.message);
    }
});
/**
 * 3. Start Serving Customer
 */
exports.startServing = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId, entryId } = request.data;
    if (!businessId || !branchId || !counterId || !entryId) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required parameters.');
    }
    try {
        return await (0, operatorService_1.startServing)(db, {
            businessId,
            branchId,
            counterId,
            entryId,
            operatorId: request.auth.uid,
            operatorName: request.auth.token.name || 'Operator',
        });
    }
    catch (error) {
        throw new https_1.HttpsError('aborted', error.message);
    }
});
/**
 * 4. Complete Service
 */
exports.completeService = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId, entryId, notes } = request.data;
    if (!businessId || !branchId || !counterId || !entryId) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required parameters.');
    }
    try {
        return await (0, operatorService_1.completeService)(db, {
            businessId,
            branchId,
            counterId,
            entryId,
            operatorId: request.auth.uid,
            operatorName: request.auth.token.name || 'Operator',
            notes,
        });
    }
    catch (error) {
        throw new https_1.HttpsError('aborted', error.message);
    }
});
/**
 * 5. Recall Customer
 */
exports.recallCustomer = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId, entryId } = request.data;
    try {
        return await (0, operatorService_1.recallCustomer)(db, {
            businessId,
            branchId,
            counterId,
            entryId,
            operatorId: request.auth.uid,
            operatorName: request.auth.token.name || 'Operator',
        });
    }
    catch (error) {
        throw new https_1.HttpsError('aborted', error.message);
    }
});
/**
 * 6. Mark Customer as No-Show
 */
exports.markCustomerNoShow = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId, entryId, reason } = request.data;
    try {
        return await (0, operatorService_1.markCustomerNoShow)(db, {
            businessId,
            branchId,
            counterId,
            entryId,
            operatorId: request.auth.uid,
            operatorName: request.auth.token.name || 'Operator',
            reason,
        });
    }
    catch (error) {
        throw new https_1.HttpsError('aborted', error.message);
    }
});
/**
 * 7. Skip Customer
 */
exports.skipCustomer = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId, entryId, reason, requeuePolicy } = request.data;
    try {
        return await (0, operatorService_1.skipCustomer)(db, {
            businessId,
            branchId,
            counterId,
            entryId,
            operatorId: request.auth.uid,
            operatorName: request.auth.token.name || 'Operator',
            reason: reason || 'Customer not at counter',
            requeuePolicy,
        });
    }
    catch (error) {
        throw new https_1.HttpsError('aborted', error.message);
    }
});
/**
 * 8. Transfer Customer (Cross-Service or Cross-Branch Journey)
 */
exports.transferCustomer = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, sourceBranchId, sourceCounterId, sourceEntryId, targetServiceId, targetBranchId, transferReason, priorityOverride, } = request.data;
    try {
        return await (0, transferService_1.transferCustomer)(db, {
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
    }
    catch (error) {
        throw new https_1.HttpsError('aborted', error.message);
    }
});
/**
 * 9. Counter Lifecycle: Open, Pause, Resume, Close
 */
exports.openCounter = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId } = request.data;
    return await (0, counterService_1.openCounter)(db, {
        businessId,
        branchId,
        counterId,
        operatorId: request.auth.uid,
        operatorName: request.auth.token.name || 'Operator',
    });
});
exports.pauseCounter = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId, reason } = request.data;
    return await (0, counterService_1.pauseCounter)(db, {
        businessId,
        branchId,
        counterId,
        operatorId: request.auth.uid,
        operatorName: request.auth.token.name || 'Operator',
        reason: reason || 'Break',
    });
});
exports.resumeCounter = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId } = request.data;
    return await (0, counterService_1.resumeCounter)(db, {
        businessId,
        branchId,
        counterId,
        operatorId: request.auth.uid,
        operatorName: request.auth.token.name || 'Operator',
    });
});
exports.closeCounter = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Operator must be authenticated.');
    const { businessId, branchId, counterId } = request.data;
    return await (0, counterService_1.closeCounter)(db, {
        businessId,
        branchId,
        counterId,
        operatorId: request.auth.uid,
        operatorName: request.auth.token.name || 'Operator',
    });
});
//# sourceMappingURL=index.js.map