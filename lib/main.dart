import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/api_service.dart';
import 'widgets/connection_overlay.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Mana Hospital — App Entry Point
/// ─────────────────────────────────────────────────────────────────────────────
/// Bootstrap order:
///   1. Firebase.initializeApp()
///   2. Load persisted locale + auth session from secure storage
///   3. StreamBuilder listens to FirebaseAuth.authStateChanges()
///   4. If authenticated → fetch role from JWT → route to Admin or Patient
///   5. If not authenticated → LoginScreen
/// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ManaHospitalApp());
}

class ManaHospitalApp extends StatelessWidget {
  const ManaHospitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadSavedLocale()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Mana Hospital',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) {
              return Stack(
                children: [
                  if (child != null) child,
                  ValueListenableBuilder<bool>(
                    valueListenable: ApiService.isOffline,
                    builder: (context, isOffline, _) {
                      if (isOffline) return const ConnectionOverlay();
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
            home: const AppWrapper(),
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// AppWrapper — The Dual-Interface Switchboard
/// ─────────────────────────────────────────────────────────────────────────────
/// Defers routing entirely to `AuthProvider`, which accurately tracks both
/// the async Secure Storage bootstrap and the remote API JWT acquisition.
///
///  ┌──────────────────────────────────────────────────────────────────┐
///  │ auth.isBootstrapping  →  _SplashLoadingScreen                    │
///  │ !auth.isAuthenticated →  LoginScreen                             │
///  │ auth.isAdmin          →  AdminDashboard                          │
///  │ otherwise             →  PatientDashboard                        │
///  └──────────────────────────────────────────────────────────────────┘
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isBootstrapping) {
          return const _SplashLoadingScreen();
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        return auth.isAdmin ? const AdminDashboard() : const PatientDashboard();
      },
    );
  }
}

/// Minimal loading screen shown during bootstrap
class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MH Logo
            Image.asset(
              'assets/icon.png',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 24),
            const Text(
              'Mana Hospital',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bhimavaram\'s Trusted Care',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppColors.medicalBlue,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
