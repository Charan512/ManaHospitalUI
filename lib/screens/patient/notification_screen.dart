import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Notification Screen
/// ─────────────────────────────────────────────────────────────────────────────
/// Scans Patient's historical appointments to map rejected/missed entries into
/// actionable Recovery Cards synced with LIVE slot recommendations.
/// ─────────────────────────────────────────────────────────────────────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  bool _isRecovering = false;
  
  List<Map<String, dynamic>> _alerts = [];
  
  String? _suggestedDate;
  String? _suggestedSlot;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final token = auth.jwtToken!;

    try {
      // 1. Fetch appointments & parse alerts
      final myResp = await ApiService.getMyAppointments(token);
      final rawAppts = List<Map<String, dynamic>>.from(myResp['appointments'] as List);
      
      final alerts = rawAppts.where((a) {
        final status = a['status'] as String?;
        final acknowledged = a['recoveryAcknowledged'] == true;
        return (status == 'rejected' || status == 'missed') && !acknowledged;
      }).toList();

      // 2. If alerts exist, fetch the very next slot dynamically
      if (alerts.isNotEmpty) {
        try {
          final suggestResp = await ApiService.getSuggestedNextSlot(token);
          if (suggestResp['success'] == true) {
            _suggestedDate = suggestResp['date'];
            _suggestedSlot = suggestResp['slot'];
          }
        } catch (e) {
          debugPrint('No suggested slots found or network err: $e');
        }
      }

      if (mounted) {
        setState(() {
          _alerts = alerts;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDismiss(String id) async {
    final token = context.read<AuthProvider>().jwtToken!;
    try {
      await ApiService.dismissRecovery(token: token, appointmentId: id);
      setState(() {
        _alerts.removeWhere((a) => a['_id'] == id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to dismiss: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _handleRecover(String oldId) async {
    if (_suggestedDate == null || _suggestedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No available slots to recover into right now.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isRecovering = true);
    final token = context.read<AuthProvider>().jwtToken!;

    try {
      await ApiService.recoverAppointment(
        token: token,
        oldId: oldId,
        date: _suggestedDate!,
        slot: _suggestedSlot!,
      );

      // Successfully re-booked. Remove from list automatically
      setState(() {
        _alerts.removeWhere((a) => a['_id'] == oldId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Re-booking request sent to Admin!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recovery failed: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isRecovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.medicalBlue))
        : RefreshIndicator(
            color: AppColors.medicalBlue,
            onRefresh: _fetchData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 16),
                if (_alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_active_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('You have no new alerts.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('System Alerts', style: AppTextStyles.titleLarge),
                  ),
                  const SizedBox(height: 12),
                  ..._alerts.map((alert) {
                    final status = alert['status'] as String; // 'rejected' or 'missed'
                    final oldDate = alert['date'];
                    final oldSlot = alert['slot'];
                    final statusDisplay = status == 'missed' ? 'Missed' : 'Rejected';
                    final String cardTitle = 'Appointment $statusDisplay';

                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: status == 'rejected' ? Colors.redAccent.withValues(alpha: 0.4) : Colors.orangeAccent.withValues(alpha: 0.4)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(status == 'rejected' ? Icons.cancel_rounded : Icons.calendar_month_rounded, color: status == 'rejected' ? Colors.redAccent : Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  Text(cardTitle, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your previous appointment for $oldDate at $oldSlot was $status.',
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.paleSkyBlue, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on_rounded, color: AppColors.medicalBlue, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _suggestedDate == null 
                                          ? const Text('Searching for next available slot...', style: TextStyle(color: AppColors.medicalBlue, fontWeight: FontWeight.w600))
                                          : Text('Would you like to re-book for the next available slot:\n$_suggestedDate at $_suggestedSlot?', style: const TextStyle(color: AppColors.medicalBlue, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isRecovering ? null : () => _handleDismiss(alert['_id']),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: BorderSide(color: AppColors.cardBorder)),
                                      child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: (_isRecovering || _suggestedDate == null) ? null : () => _handleRecover(alert['_id']),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.medicalBlue, foregroundColor: AppColors.white, elevation: 0),
                                      child: const Text('Yes, Book Now'),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        if (_isRecovering)
                           Positioned.fill(
                             child: Container(
                               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
                               child: const Center(child: CircularProgressIndicator(color: AppColors.medicalBlue)),
                             )
                           )
                      ],
                    );
                  })
                ]
              ]
            )
        )
    );
  }
}
