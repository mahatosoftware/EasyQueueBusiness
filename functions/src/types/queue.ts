import { Timestamp } from 'firebase-admin/firestore';

export type UserRole = 
  | 'OWNER' 
  | 'BRANCH_MANAGER' 
  | 'SUPERVISOR' 
  | 'RECEPTIONIST' 
  | 'OPERATOR';

export type CounterStatus = 
  | 'CLOSED' 
  | 'AVAILABLE' 
  | 'BUSY' 
  | 'PAUSED' 
  | 'BREAK' 
  | 'OFFLINE' 
  | 'MAINTENANCE';

export type EntryStatus = 
  | 'WAITING' 
  | 'CALLED' 
  | 'SERVING' 
  | 'COMPLETED' 
  | 'SKIPPED' 
  | 'NO_SHOW' 
  | 'TRANSFERRED' 
  | 'CANCELLED';

export type PriorityCategory = 
  | 'NORMAL' 
  | 'SENIOR_CITIZEN' 
  | 'PREGNANT' 
  | 'DISABILITY' 
  | 'VIP' 
  | 'EMERGENCY';

export type EntrySource = 
  | 'WALK_IN' 
  | 'MOBILE_APP' 
  | 'QR_CODE' 
  | 'APPOINTMENT' 
  | 'KIOSK';

export interface Business {
  id: string;
  name: string;
  ownerId: string;
  category: string;
  contactNumber: string;
  email: string;
  country: string;
  timeZone: string;
  status: 'ACTIVE' | 'SUSPENDED' | 'DRAFT';
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Branch {
  id: string;
  businessId: string;
  name: string;
  code: string;
  contactNumber: string;
  timeZone: string;
  status: 'ACTIVE' | 'PAUSED' | 'CLOSED';
  stats: {
    activeCounters: number;
    waitingCustomers: number;
    servedToday: number;
  };
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Service {
  id: string;
  businessId: string;
  branchId: string;
  name: string;
  code: string; // Token Prefix like 'B'
  estimatedDurationMinutes: number;
  averageServiceMinutes: number;
  maxQueueCapacity: number;
  allowWalkIn: boolean;
  allowOnlineJoin: boolean;
  supportsPriority: boolean;
  priorityWeightMultiplier: number;
  allocationPolicy: 'FIFO' | 'LEAST_BUSY' | 'ROUND_ROBIN' | 'SHORTEST_SERVICE';
  status: 'ACTIVE' | 'PAUSED' | 'DISABLED';
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Counter {
  id: string;
  businessId: string;
  branchId: string;
  name: string;
  counterNumber: number;
  displayLabel: string;
  supportedServiceIds: string[];
  assignedOperatorIds: string[];
  currentOperatorId?: string;
  status: CounterStatus;
  pauseReason?: string;
  currentEntryId?: string;
  currentTokenNumber?: string;
  serviceStartedAt?: Timestamp;
  maxSimultaneousCapacity: number;
  autoAllocationEnabled: boolean;
  allocationPriority: number;
  lastHeartbeatAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Queue {
  id: string;
  businessId: string;
  branchId: string;
  serviceId: string;
  tokenPrefix: string;
  tokenSequenceDate: string; // YYYY-MM-DD
  lastTokenNumber: number;
  waitingCount: number;
  calledCount: number;
  servingCount: number;
  completedCount: number;
  noShowCount: number;
  status: 'OPEN' | 'PAUSED' | 'CLOSED';
  estimatedWaitMinutes: number;
  updatedAt: Timestamp;
}

export interface QueueEntry {
  id: string;
  businessId: string;
  branchId: string;
  serviceId: string;
  queueId: string;
  tokenNumber: string;
  tokenSequence: number;
  customer: {
    id?: string;
    name: string;
    phoneNumber?: string;
    numberOfPeople: number;
    notes?: string;
    deviceToken?: string;
  };
  source: EntrySource;
  priorityCategory: PriorityCategory;
  priorityWeight: number;
  appointmentId?: string;
  status: EntryStatus;
  assignedCounterId?: string;
  assignedOperatorId?: string;
  counterName?: string;
  operatorName?: string;
  joinedAt: Timestamp;
  calledAt?: Timestamp;
  recallCount: number;
  lastRecalledAt?: Timestamp;
  serviceStartedAt?: Timestamp;
  completedAt?: Timestamp;
  waitDurationSeconds?: number;
  serviceDurationSeconds?: number;
  parentJourneyId?: string;
  transferredToServiceId?: string;
  transferredToEntryId?: string;
  transferReason?: string;
  cancellationReason?: string;
  noShowReason?: string;
  estimatedWaitMinutes: number;
}

export interface CounterOperation {
  id: string;
  businessId: string;
  branchId: string;
  counterId: string;
  operatorId: string;
  operatorName: string;
  entryId: string;
  tokenNumber: string;
  serviceId: string;
  action: string;
  previousState: string;
  newState: string;
  reason?: string;
  timestamp: Timestamp;
  metadata?: Record<string, any>;
}
