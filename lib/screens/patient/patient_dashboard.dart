import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import 'patient_history_screen.dart';
import 'booking_wizard.dart';
import 'notification_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Patient Dashboard
/// ─────────────────────────────────────────────────────────────────────────────
/// The primary landing page for patients after successfully logging in.
/// Implements the "Dashboard-First" architecture with two clear calls to action:
///   1. Book New Appointment (Triage Flow)
///   2. My Appointment History
/// ─────────────────────────────────────────────────────────────────────────────
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final l10n   = AppL10n(locale);
    final auth   = context.watch<AuthProvider>();

    final userName = auth.userName ?? 'Patient';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('appName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.medicalBlue),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              // AppWrapper natively reacts to !auth.isAuthenticated and returns LoginScreen.
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          // Language toggle snippet from previous Home
          GestureDetector(
            onTap: () => context.read<LocaleProvider>().toggleLocale(),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.paleSkyBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                locale == 'en' ? 'తెలు' : 'EN',
                style: const TextStyle(
                  color: AppColors.medicalBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting Hero ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.medicalBlue, AppColors.deepBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.medicalBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.tr('welcome')}$userName!',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.tr('tagline'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Quick Actions Heading ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.tr('whatToDo'),
                style: AppTextStyles.titleLarge,
              ),
            ),
            const SizedBox(height: 16),

            // ── Triage / Booking Card ──────────────────────────────────────
            _DashboardCard(
              title: l10n.tr('bookNew'),
              subtitle: l10n.tr('bookNewSub'),
              icon: Icons.calendar_month_rounded,
              color: AppColors.medicalBlue,
              bgLight: AppColors.paleSkyBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingWizardScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── History Card ───────────────────────────────────────────────
            _DashboardCard(
              title: l10n.tr('myHistory'),
              subtitle: l10n.tr('myHistorySub'),
              icon: Icons.history_rounded,
              color: AppColors.textPrimary,
              bgLight: AppColors.cardBorder.withValues(alpha: 0.5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientHistoryScreen()),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Helper widget to render the large dashboard action cards.
class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgLight;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.cardBorder,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
