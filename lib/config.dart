/// ─────────────────────────────────────────────────────────────────────────────
/// Mana Hospital — App Config
/// ─────────────────────────────────────────────────────────────────────────────
/// All environment-level configuration lives here.
/// Values are injected at BUILD TIME using --dart-define flags.
///
/// Usage:
///   flutter run  --dart-define=BACKEND_URL=http://10.0.2.2:3001/api
///   flutter build apk --dart-define=BACKEND_URL=https://api.manahospital.com/api
///
/// All API calls must go through ApiService (lib/services/api_service.dart)
/// which reads Config.backendUrl — never hardcode URLs elsewhere.
/// ─────────────────────────────────────────────────────────────────────────────
class Config {
  Config._();

  /// Backend REST API base URL.
  /// Injected via --dart-define=BACKEND_URL=`value` at build/run time.
  ///
  /// Defaults:
  ///   Android emulator → 10.0.2.2 routes to host machine's localhost
  ///   iOS simulator    → pass --dart-define=BACKEND_URL=http://localhost:3001/api
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3001/api',
  );

  // ── Admin ──────────────────────────────────────────────────────────────────
  /// Seeded admin phone (E.164). Role is determined server-side, but
  /// kept here for any client-side UX hints if needed.
  static const String adminPhone = '+917989101146';

  // ── Slot definitions ───────────────────────────────────────────────────────
  static const String slotMorning = '10:00 AM - 02:00 PM';
  static const String slotEvening = '03:00 PM - 07:00 PM';
  static const int maxPatientsPerSlot = 5;
}
