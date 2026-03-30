import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Approvals Screen (Triage)
/// ─────────────────────────────────────────────────────────────────────────────
/// Specifically pulls only 'pending' appointments that are Today or Future.
/// Provides Accept (Green), Hold (Orange), Reject (Red) mappings directly.
/// ─────────────────────────────────────────────────────────────────────────────
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingList = [];

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      final body = await ApiService.getPendingApprovals(auth.jwtToken!);
      if (mounted) {
        setState(() {
          _pendingList = List<Map<String, dynamic>>.from(body['appointments'] as List);
        });
      }
    } catch (e) {
      debugPrint('Error fetching approvals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final auth = context.read<AuthProvider>();
    try {
      await ApiService.updateAppointmentStatus(
        token: auth.jwtToken!,
        appointmentId: id,
        status: status,
      );
      // Remove from list immediately
      setState(() {
        _pendingList.removeWhere((app) => app['_id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${status.toUpperCase()}'),
          backgroundColor: AppColors.medicalBlue,
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Approvals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.medicalBlue),
            tooltip: 'Refresh',
            onPressed: _fetchApprovals,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.medicalBlue))
        : RefreshIndicator(
            color: AppColors.medicalBlue,
            onRefresh: _fetchApprovals,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Pending Triage Feed', 
                    style: TextStyle(
                      fontFamily: 'Outfit', 
                      fontSize: 22, 
                      fontWeight: FontWeight.w700, 
                      color: AppColors.textPrimary,
                    )
                  ),
                ),
                if (_pendingList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No pending approvals matching filter criteria.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ..._pendingList.map((appt) => _ApprovalCard(
                      appt: appt,
                      onUpdateStatus: _updateStatus,
                    )),
                const SizedBox(height: 80),
              ],
            ),
        ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final Future<void> Function(String id, String status) onUpdateStatus;

  const _ApprovalCard({
    required this.appt,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final id = appt['_id'] as String;
    final String name = appt['patientName'] ?? '—';
    final String phone = appt['patientPhone'] ?? '';
    final String date = appt['date'] ?? '';
    final String slot = appt['slot'] ?? '';
    final String ageStr = appt['age'] != null ? '${appt['age']} yrs' : 'N/A';
    final String reason = appt['issueDescription'] ?? '';
    final String userType = (appt['isSelf'] ?? true) ? 'Self' : 'Booking for Other';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.paleSkyBlue, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    userType,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.medicalBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(phone, style: AppTextStyles.caption),
                const SizedBox(width: 12),
                const Icon(Icons.cake_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(ageStr, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            
            // Slot Info Frame
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.medicalBlue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(slot, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Reason for Visit:', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(reason, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                // Accept
                Expanded(
                  child: _TriageAction(
                    label: 'Accept',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    bg: Colors.green.shade50,
                    onTap: () => onUpdateStatus(id, 'accepted'),
                  ),
                ),
                const SizedBox(width: 8),
                // Hold
                Expanded(
                  child: _TriageAction(
                    label: 'On-Hold',
                    icon: Icons.pause_circle_filled_rounded,
                    color: AppColors.skyBlue300,
                    bg: AppColors.paleSkyBlue,
                    onTap: () => onUpdateStatus(id, 'on_hold'),
                  ),
                ),
                const SizedBox(width: 8),
                // Reject
                Expanded(
                  child: _TriageAction(
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    color: Colors.red.shade600,
                    bg: Colors.red.shade50,
                    onTap: () => onUpdateStatus(id, 'rejected'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TriageAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _TriageAction({required this.label, required this.icon, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
