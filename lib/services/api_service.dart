import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ApiService — Centralised HTTP layer for Mana Hospital
/// ─────────────────────────────────────────────────────────────────────────────
/// ALL network calls to the backend must go through this class.
/// Never import `http` or reference URLs directly in screens/providers.
///
/// Base URL is read from:   Config.backendUrl
/// which is set via:        --dart-define=BACKEND_URL=`url`
///
/// Authentication:
///   Most endpoints require a JWT (issued by the backend after Firebase OTP).
///   Pass it as [token] to any method that needs it.
///   The header format is: Authorization: Bearer `token`
/// ─────────────────────────────────────────────────────────────────────────────
class ApiService {
  ApiService._();

  // ── Internal helpers ───────────────────────────────────────────────────────

  static Uri _uri(String path) => Uri.parse('${Config.backendUrl}$path');

  static Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Decodes the response body and throws a descriptive error on non-2xx.
  static Map<String, dynamic> _decode(http.Response resp) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 200 && resp.statusCode < 300) return body;
    final msg = body['message'] as String? ?? 'Request failed (${resp.statusCode})';
    throw ApiException(msg, statusCode: resp.statusCode, body: body);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════════════════════

  /// Exchanges a Firebase ID token for a backend JWT.
  ///
  /// [idToken]   Firebase ID token from Phone OTP sign-in
  /// [fcmToken]  Optional device FCM token for push notifications
  /// [name]      Optional display name to store/update in the DB
  ///
  /// Returns: { token, user: { id, phone, role, name } }
  static Future<Map<String, dynamic>> firebaseLogin({
    required String idToken,
    String? fcmToken,
    String? name,
  }) async {
    final resp = await http.post(
      _uri('/auth/firebase-login'),
      headers: _headers(),
      body: jsonEncode({
        'idToken': idToken,
        if (fcmToken != null) 'fcmToken': fcmToken,
        if (name != null && name.isNotEmpty) 'name': name,
      }),
    );
    return _decode(resp);
  }

  /// Updates the FCM token for the authenticated user.
  static Future<void> updateFcmToken({
    required String token,
    required String fcmToken,
  }) async {
    final resp = await http.patch(
      _uri('/auth/fcm-token'),
      headers: _headers(token: token),
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    _decode(resp);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLOTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches occupancy counts for both slots on [date] ("YYYY-MM-DD").
  ///
  /// Returns: { date, slots: [ { slot, booked, available, isFull } ] }
  static Future<Map<String, dynamic>> getSlots(String date) async {
    final resp = await http.get(_uri('/appointments/slots?date=$date'));
    return _decode(resp);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS — PATIENT
  // ══════════════════════════════════════════════════════════════════════════

  /// Books an appointment. Atomic 5-slot check enforced server-side.
  ///
  /// [isSelf] true  → backend auto-fills patient name/phone from JWT user
  /// [isSelf] false → must supply [patientName] and [patientPhone]
  ///
  /// Returns: { appointment } on 201  |  throws ApiException(slotFull:true) on 409
  static Future<Map<String, dynamic>> bookAppointment({
    required String token,
    required String date,
    required String slot,
    required bool isSelf,
    String? patientName,
    String? patientPhone,
    String? age,
    String? issueDescription,
    String? comments,
  }) async {
    final resp = await http.post(
      _uri('/appointments/book'),
      headers: _headers(token: token),
      body: jsonEncode({
        'date': date,
        'slot': slot,
        'isSelf': isSelf,
        if (patientName != null && patientName.isNotEmpty)
          'patientName': patientName,
        if (!isSelf && patientPhone != null) 'patientPhone': patientPhone,
        if (age != null && age.isNotEmpty) 'age': age,
        if (issueDescription != null && issueDescription.isNotEmpty)
          'issueDescription': issueDescription,
        if (comments != null && comments.isNotEmpty) 'comments': comments,
      }),
    );
    return _decode(resp);
  }

  /// Fetches the authenticated patient's appointment history.
  ///
  /// Returns: { appointments: [ ... ] }
  static Future<Map<String, dynamic>> getMyAppointments(String token) async {
    final resp = await http.get(
      _uri('/appointments/my'),
      headers: _headers(token: token),
    );
    return _decode(resp);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS — RECOVERY & NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Scans for the immediate next available slot automatically.
  /// Returns: { date, slot }
  static Future<Map<String, dynamic>> getSuggestedNextSlot(String token) async {
    final resp = await http.get(
      _uri('/appointments/suggest-next'),
      headers: _headers(token: token),
    );
    return _decode(resp);
  }

  /// Recovers a Rejected/Missed appointment seamlessly into a new slot.
  static Future<Map<String, dynamic>> recoverAppointment({
    required String token,
    required String oldId,
    required String date,
    required String slot,
  }) async {
    final resp = await http.post(
      _uri('/appointments/recover/$oldId'),
      headers: _headers(token: token),
      body: jsonEncode({'date': date, 'slot': slot}),
    );
    return _decode(resp);
  }

  /// Dismisses a notification permanently from the Feed.
  static Future<Map<String, dynamic>> dismissRecovery({
    required String token,
    required String appointmentId,
  }) async {
    final resp = await http.patch(
      _uri('/appointments/$appointmentId/dismiss-recovery'),
      headers: _headers(token: token),
    );
    return _decode(resp);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS — ADMIN
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches global dashboard stats: pending count & recent logs.
  /// 
  /// Returns: { pendingCount, recentLogs: [ ... ] }
  static Future<Map<String, dynamic>> getDashboardStats(String token) async {
    final resp = await http.get(
      _uri('/admin/dashboard-stats'),
      headers: _headers(token: token),
    );
    return _decode(resp);
  }

  /// Fetches strongly-filtered future pending approvals for Triage.
  /// 
  /// Returns: { appointments: [ ... ] }
  static Future<Map<String, dynamic>> getPendingApprovals(String token) async {
    final resp = await http.get(
      _uri('/admin/approvals'),
      headers: _headers(token: token),
    );
    return _decode(resp);
  }

  /// Registers a walk-in patient (Admin only, no OTP, status: accepted).
  ///
  /// Returns: { appointment }
  static Future<Map<String, dynamic>> addOfflinePatient({
    required String token,
    required String date,
    required String slot,
    required String patientName,
    required String patientPhone,
    String? age,
  }) async {
    final resp = await http.post(
      _uri('/appointments/offline'),
      headers: _headers(token: token),
      body: jsonEncode({
        'date': date,
        'slot': slot,
        'patientName': patientName,
        'patientPhone': patientPhone,
        if (age != null && age.isNotEmpty) 'age': age,
      }),
    );
    return _decode(resp);
  }

  /// Fetches all appointments for a date (Admin only).
  ///
  /// Returns: { date, appointments: [ ... ] }
  static Future<Map<String, dynamic>> getAdminDailyAppointments({
    required String token,
    required String date,
  }) async {
    final resp = await http.get(
      _uri('/appointments/admin/daily?date=$date'),
      headers: _headers(token: token),
    );
    return _decode(resp);
  }

  /// Updates the status of an appointment (Admin only).
  ///
  /// [status] must be one of: 'accepted' | 'rejected' | 'on_hold' | 'missed'
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String token,
    required String appointmentId,
    required String status,
  }) async {
    final resp = await http.patch(
      _uri('/appointments/$appointmentId/status'),
      headers: _headers(token: token),
      body: jsonEncode({'status': status}),
    );
    return _decode(resp);
  }

  /// Marks an appointment as completed and optionally creates a follow-up.
  ///
  /// Returns: { appointment, followUp }
  static Future<Map<String, dynamic>> markCompleted({
    required String token,
    required String appointmentId,
    String? prescription,
    String? nextVisitDate,
    String? nextVisitSlot,
  }) async {
    final resp = await http.post(
      _uri('/appointments/$appointmentId/complete'),
      headers: _headers(token: token),
      body: jsonEncode({
        if (prescription != null && prescription.isNotEmpty) 'prescription': prescription,
        if (nextVisitDate != null) 'nextVisitDate': nextVisitDate,
        if (nextVisitSlot != null) 'nextVisitSlot': nextVisitSlot,
      }),
    );
    return _decode(resp);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiException — structured error from the backend
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> body;

  const ApiException(this.message, {required this.statusCode, required this.body});

  /// True when the backend rejected because the slot is at capacity (5/5).
  bool get isSlotFull => body['slotFull'] == true;

  /// True when the patient already has an active (pending/accepted/on_hold) appointment.
  bool get hasActiveAppointment => body['hasActiveAppointment'] == true;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
