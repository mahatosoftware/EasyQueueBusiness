import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'EasyQueue Business';
  static const String packageName = 'in.mahato.easyqueue.business';

  // Assets
  static const String logoPath = 'assets/images/logo.png';
  static const String logoIconPath = 'assets/images/logo_icon.png';

  // Firestore Collection Names
  static const String colUsers = 'users';
  static const String colBusinesses = 'businesses';
  static const String colMembers = 'members';
  static const String colBranches = 'branches';
  static const String colServices = 'services';
  static const String colCounters = 'counters';
  static const String colQueues = 'queues';
  static const String colEntries = 'entries';
  static const String colQueueEntries = 'queueEntries';
  static const String colOperations = 'operations';
  static const String colAppointments = 'appointments';
  static const String colDisplayDevices = 'displayDevices';
  static const String colAuditLogs = 'auditLogs';

  // Priority Weights
  static const Map<String, int> priorityWeights = {
    'NORMAL': 1,
    'SENIOR_CITIZEN': 2,
    'PREGNANT': 2,
    'DISABILITY': 2,
    'VIP': 3,
    'EMERGENCY': 10,
  };

  // Status Colors
  static const Color statusAvailable = Color(0xFF10B981); // Emerald Green
  static const Color statusBusy = Color(0xFF3B82F6);      // Blue
  static const Color statusPaused = Color(0xFFF59E0B);    // Amber
  static const Color statusClosed = Color(0xFF6B7280);    // Gray
  static const Color statusEmergency = Color(0xFFEF4444); // Red

  // Layout & Navigation Padding
  static const double bottomNavPadding = 80.0;
  static const double floatingActionBottomPadding = 88.0;

  // Cloud Functions Region
  static const String functionsRegion = 'us-central1';
}
