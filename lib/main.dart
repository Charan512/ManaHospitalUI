import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'core/router.dart';
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

class ManaHospitalApp extends StatefulWidget {
  const ManaHospitalApp({super.key});

  @override
  State<ManaHospitalApp> createState() => _ManaHospitalAppState();
}

class _ManaHospitalAppState extends State<ManaHospitalApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;
  late final LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider()..tryAutoLogin();
    _router = createRouter(_authProvider);
    _localeProvider = LocaleProvider()..loadSavedLocale();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localeProvider),
        ChangeNotifierProvider.value(value: _authProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            routerConfig: _router,
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
          );
        },
      ),
    );
  }
}

