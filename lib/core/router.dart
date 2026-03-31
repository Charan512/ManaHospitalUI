import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/patient/patient_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/patient/booking_wizard.dart';
import '../screens/patient/patient_history_screen.dart';
import '../screens/patient/notification_screen.dart';
import '../screens/admin/approvals_screen.dart';
import '../screens/admin/slot_log_screen.dart';
import '../screens/splash_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GoRouter Configuration
/// ─────────────────────────────────────────────────────────────────────────────
/// Takes the `AuthProvider` instance so we can inject its `ChangeNotifier` as
/// the single source of truth for all redirects.

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isBootstrapping = authProvider.isBootstrapping;
      final isAuthenticated = authProvider.isAuthenticated;
      final isAdmin = authProvider.isAdmin;

      // Until Secure Storage loads, force splash.
      if (isBootstrapping) {
        if (state.matchedLocation != '/splash') {
          return '/splash';
        }
        return null; 
      }

      // If they are not logged in, force them to the login page no matter what URI they request.
      if (!isAuthenticated) {
        if (state.matchedLocation != '/login') {
          return '/login';
        }
        return null; // Already at /login
      }

      // If authenticated but stuck on /login OR /splash, push to correct dashboard.
      // This handles BOTH first-time login AND cold-start auto-login scenarios.
      if (state.matchedLocation == '/login' || state.matchedLocation == '/splash') {
        return isAdmin ? '/admin' : '/patient';
      }

      // Allow all other routes to process normally
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashLoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Admin Routes ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'approvals',
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: 'slot_log',
            builder: (context, state) => const SlotLogScreen(),
          ),
        ],
      ),

      // ── Patient Routes ────────────────────────────────────────────────────────
      GoRoute(
        path: '/patient',
        builder: (context, state) => const PatientDashboard(),
        routes: [
          GoRoute(
            path: 'booking',
            builder: (context, state) => const BookingWizardScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const PatientHistoryScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
        ],
      ),
    ],
  );
}
