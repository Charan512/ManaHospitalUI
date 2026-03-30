import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

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
            // Locale is managed manually via LocaleProvider — no l10n delegates needed
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
/// Uses StreamBuilder on FirebaseAuth.authStateChanges() as the primary gate.
/// Once Firebase confirms an active session, delegates to AuthProvider
/// (which loaded the backend JWT + role from secure storage) to pick the UI.
///
///  ┌──────────────────────────────────────────────────────────────────┐
///  │ Firebase User = null  →  LoginScreen                             │
///  │ Firebase User ≠ null  →  AuthProvider.isAdmin ?                  │
///  │                             AdminHome : PatientHome              │
///  └──────────────────────────────────────────────────────────────────┘
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ── Loading state ────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoadingScreen();
        }

        final firebaseUser = snapshot.data;

        // ── Not authenticated ────────────────────────────────────────────
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // ── Authenticated — check role from backend JWT ───────────────────
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // If the backend JWT session hasn't loaded yet, show splash
            if (!(auth.isAuthenticated)) {
              return const _SplashLoadingScreen();
            }

            // Route based on role embedded in JWT
            return auth.isAdmin ? const AdminDashboard() : const PatientDashboard();
          },
        );
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
