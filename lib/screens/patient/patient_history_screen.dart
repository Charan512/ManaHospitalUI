import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/localizations.dart';
import '../../providers/locale_provider.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().jwtToken!;
      final result = await ApiService.getMyAppointments(token);
      setState(() {
        _appointments = List<Map<String, dynamic>>.from(result['appointments']);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to load history.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Color coding for different statuses
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'accepted':
      case 'on_hold':
      case 'pending':
        return AppColors.medicalBlue;
      case 'missed':
      case 'rejected':
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String locale = context.watch<LocaleProvider>().locale;
    final AppL10n l10n  = AppL10n(locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('myHistoryTitle')),
      ),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, (_) => ShimmerLoading.buildHistoryCardSkeleton()),
            )
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _appointments.isEmpty
                  ? Center(
                      child: Text(
                        l10n.tr('noAppointments'),
                        style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textSecondary, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.medicalBlue,
                      onRefresh: _fetchHistory,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final appt = _appointments[index];
                          final date = appt['date'] ?? '';
                          final slot = appt['slot'] ?? '';
                          final isFollowUp = appt['isFollowUp'] == true;
                          final status = (appt['status'] ?? 'pending').toString();
                          final prescription = appt['prescription']?.toString().trim();
                          final validUntil = appt['validUntil']?.toString().trim();

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      date,
                                      style: AppTextStyles.titleLarge.copyWith(
                                          color: AppColors.medicalBlue, fontSize: 16),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(slot, style: const TextStyle(color: AppColors.textPrimary)),
                                  ],
                                ),
                                if (isFollowUp) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.refresh_rounded, size: 16, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(l10n.tr('followUpAppt'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                                if (prescription != null && prescription.isNotEmpty) ...[
                                  const Divider(height: 24, color: AppColors.cardBorder),
                                  Text(l10n.tr('prescriptionNotes'), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepBlue)),
                                  const SizedBox(height: 4),
                                  Text(prescription, style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                                if (validUntil != null && validUntil.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('${l10n.tr('nextVisit')} $validUntil', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
