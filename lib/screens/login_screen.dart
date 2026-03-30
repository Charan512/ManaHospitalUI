import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

/// Login screen — Phone number entry → OTP verification
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController   = TextEditingController();
  final _nameController  = TextEditingController();
  final _formKey         = GlobalKey<FormState>();

  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth   = context.read<AuthProvider>();
    final locale = context.read<LocaleProvider>().locale;
    final l10n   = AppL10n(locale);

    final rawPhone = _phoneController.text.trim();
    // Ensure E.164 format
    final phone = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';

    await auth.sendOtp(
      phone: phone,
      onCodeSent: (_) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('otpSentMsg')),
            backgroundColor: AppColors.medicalBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onError: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.deepBlue),
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(
      smsCode: _otpController.text.trim(),
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'OTP verification failed.'),
          backgroundColor: AppColors.deepBlue,
        ),
      );
    }
    // On success, main.dart StreamBuilder automatically routes to
    // PatientHome or AdminHome based on JWT role.
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final l10n   = AppL10n(locale);
    final auth   = context.watch<AuthProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _otpSent
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.medicalBlue),
                onPressed: () => setState(() => _otpSent = false),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.white, AppColors.paleSkyBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Hospital Logo / Icon ──────────────────────────────
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.medicalBlue.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/icon.png'),
                          fit: BoxFit.contain, // Ensuring entire logo is visible
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      l10n.tr('appName'),
                      style: AppTextStyles.displayLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.tr('tagline'),
                      style: AppTextStyles.bodyMedium,
                    ),

                    const SizedBox(height: 40),

                    // ── Card ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.medicalBlue.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (auth.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          if (!_otpSent) ...[
                            // Name field (optional at login, stored on backend)
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: l10n.tr('optionalNameHint'),
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: AppColors.medicalBlue),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l10n.tr('enterPhone'),
                                hintText: '98765 43210',
                                prefixIcon: const Icon(Icons.phone_outlined,
                                    color: AppColors.medicalBlue),
                                prefixText: '+91  ',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 10) {
                                  return l10n.tr('invalidPhone');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _sendOtp,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(l10n.tr('sendOtp')),
                              ),
                            ),
                          ] else ...[
                            // OTP field
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: l10n.tr('enterOtp'),
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppColors.medicalBlue),
                                counterText: '',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 6) {
                                  return l10n.tr('invalidOtpReq');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _verifyOtp,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(l10n.tr('verifyOtp')),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextButton(
                              onPressed: () => setState(() => _otpSent = false),
                              child: Text(
                                l10n.tr('resendOtp'),
                                style: const TextStyle(
                                  color: AppColors.medicalBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Language toggle ───────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          locale == 'en' ? 'Switch to Telugu' : 'English కి మారండి',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              context.read<LocaleProvider>().toggleLocale(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.paleSkyBlue,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              locale == 'en' ? 'తెలుగు' : 'English',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.medicalBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
