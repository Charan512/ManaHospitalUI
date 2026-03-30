import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

/// Authentication state and user data provider.
/// Wraps Firebase Phone Auth + Backend JWT issuance.
class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _jwtKey = 'jwt_token';
  static const _userKey = 'user_data';

  // ── Internal state ────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _verificationId;
  String? _jwtToken;
  Map<String, dynamic>? _userData; // { id, phone, role, name }
  String? _errorMessage;

  // ── Public getters ────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _jwtToken != null;
  String? get jwtToken => _jwtToken;
  String? get role => _userData?['role'];
  String? get userName => _userData?['name'];
  String? get userPhone => _userData?['phone'];
  bool get isAdmin => role == 'admin';
  String? get errorMessage => _errorMessage;

  // ── Backend URL is resolved via Config.backendUrl (--dart-define=BACKEND_URL) ─

  /// Restore authenticated session from secure storage on app start.
  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: _jwtKey);
    final userJson = await _storage.read(key: _userKey);

    if (token != null && userJson != null) {
      _jwtToken = token;
      _userData = jsonDecode(userJson) as Map<String, dynamic>;
      notifyListeners();
    }
  }

  /// Step 1: Send OTP to phone number via Firebase.
  /// [phone] should be in E.164 format: "+917989101146"
  Future<void> sendOtp({
    required String phone,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval on Android — sign in automatically
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        _setLoading(false);
        _errorMessage = e.message ?? 'OTP verification failed.';
        onError(_errorMessage!);
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _setLoading(false);
        onCodeSent(verificationId);
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Step 2: Verify the OTP code entered by the user.
  Future<bool> verifyOtp({
    required String smsCode,
    String? fcmToken,
    String? name,
  }) async {
    if (_verificationId == null) {
      _errorMessage = 'Session expired. Please request a new OTP.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      return await _signInWithCredential(
        credential,
        fcmToken: fcmToken,
        name: name,
      );
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Invalid OTP. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Internal: exchanges Firebase credential for backend JWT.
  Future<bool> _signInWithCredential(
    PhoneAuthCredential credential, {
    String? fcmToken,
    String? name,
  }) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        _errorMessage = 'Firebase sign-in failed.';
        notifyListeners();
        return false;
      }

      // Exchange Firebase ID token for backend JWT
      return await _loginWithBackend(
        idToken: idToken,
        fcmToken: fcmToken,
        name: name,
      );
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Calls ApiService.firebaseLogin() and stores JWT + user data.
  Future<bool> _loginWithBackend({
    required String idToken,
    String? fcmToken,
    String? name,
  }) async {
    try {
      final body = await ApiService.firebaseLogin(
        idToken: idToken,
        fcmToken: fcmToken,
        name: name,
      );

      _jwtToken = body['token'] as String;
      _userData  = body['user']  as Map<String, dynamic>;

      // Persist session
      await _storage.write(key: _jwtKey, value: _jwtToken);
      await _storage.write(key: _userKey, value: jsonEncode(_userData));

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setLoading(false);
      await logout(); // Only destroy session if the backend explicitly rejects the credentials
      _errorMessage = e.message;
      debugPrint('🚨 BACKEND API ERROR: ${e.statusCode} - ${e.message} - ${e.body}');
      notifyListeners();
      return false;
    } on OfflineException catch (e) {
      _setLoading(false);
      // We MUST logout because if Firebase auth succeeded but Backend failed, 
      // the user will be permanently deadlocked on the Splash screen!
      await logout();
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _setLoading(false);
      await logout();
      _errorMessage = 'Unexpected error: $e';
      debugPrint('🚨 UNKNOWN ERROR: $e');
      notifyListeners();
      return false;
    }
  }

  /// Logs the user out and clears all stored credentials.
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _userKey);
    _jwtToken = null;
    _userData = null;
    _verificationId = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
