library;

/// ─────────────────────────────────────────────────────────────────────────────
/// App Configuration — Environment Variables
/// ─────────────────────────────────────────────────────────────────────────────
/// Flutter reads env vars at BUILD TIME via --dart-define flags.
///
/// HOW TO SET:
///   For local dev (Android emulator):
///     flutter run --dart-define=API_URL=http://10.0.2.2:3000/api
///
///   For local dev (iOS simulator):
///     flutter run --dart-define=API_URL=http://localhost:3000/api
///
///   For physical device / staging:
///     flutter run --dart-define=API_URL=https://api.manahospital.com/api
///
///   For release APK:
///     flutter build apk --dart-define=API_URL=https://api.manahospital.com/api
///
/// WHY NOT .env FILES?
///   Flutter compiles to native code. A .env file at runtime is not accessible
///   in the same way as Node.js. The --dart-define approach bakes the value
///   into the compiled binary at build time, which is the correct Flutter pattern.
///   For truly secret values, use a backend proxy — never ship private keys in APKs.
///
/// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  AppConfig._();

  /// Base URL for the Mana Hospital backend API.
  /// Set via --dart-define=API_URL=`your-url` at build/run time.
  /// Defaults to Android emulator localhost if not set.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android emulator → host machine
  );

  /// Convenience getter for iOS simulator default
  /// (override at run time with --dart-define=API_URL=http://localhost:3000/api)
  static String get apiBase => apiUrl;

  // ── Derived endpoint helpers ──────────────────────────────────────────────
  static String get authLogin      => '$apiBase/auth/firebase-login';
  static String get authFcmToken   => '$apiBase/auth/fcm-token';
  static String get slotsEndpoint  => '$apiBase/appointments/slots';
  static String get bookEndpoint   => '$apiBase/appointments/book';
  static String get offlineEndpoint => '$apiBase/appointments/offline';
  static String get myAppointments => '$apiBase/appointments/my';
  static String adminDaily(String date) =>
      '$apiBase/appointments/admin/daily?date=$date';
  static String appointmentStatus(String id) =>
      '$apiBase/appointments/$id/status';
}
