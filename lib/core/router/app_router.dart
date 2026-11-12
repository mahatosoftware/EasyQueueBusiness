import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/appointments/appointments_screen.dart';
import '../../features/audit/audit_logs_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/branches/branches_screen.dart';
import '../../features/counters/counters_screen.dart';
import '../../features/counters/operator_workspace_screen.dart';
import '../../features/customers/walk_in_registration_screen.dart';
import '../../features/display/tv_display_screen.dart';
import '../../features/employees/employees_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/qr/qr_poster_screen.dart';
import '../../features/queues/queues_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/services/services_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/subscription/subscription_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Stream<dynamic> _getAuthStream() {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return const Stream.empty();
  }
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  refreshListenable: GoRouterRefreshStream(_getAuthStream()),
  redirect: (context, state) {
    bool isLoggedIn = false;
    try {
      isLoggedIn = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      isLoggedIn = true;
    }
    final isGoingToLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const SignInScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/queues',
          builder: (context, state) => const QueuesScreen(),
        ),
        GoRoute(
          path: '/counters',
          builder: (context, state) => const CountersScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const WalkInRegistrationScreen(),
          routes: [
            GoRoute(
              path: 'walk-in',
              builder: (context, state) => const WalkInRegistrationScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/more',
          builder: (context, state) => const MoreScreen(),
        ),
      ],
    ),
    // Full screen routes outside bottom shell
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/counters/workspace/:counterId',
      builder: (context, state) {
        final counterId = state.pathParameters['counterId'] ?? 'c1';
        return OperatorWorkspaceScreen(counterId: counterId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/branches',
      builder: (context, state) => const BranchesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/services',
      builder: (context, state) => const ServicesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/display',
      builder: (context, state) => const TvDisplayScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/qr',
      builder: (context, state) => const QrPosterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/appointments',
      builder: (context, state) => const AppointmentsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/employees',
      builder: (context, state) => const EmployeesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/audit',
      builder: (context, state) => const AuditLogsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
  ],
);
