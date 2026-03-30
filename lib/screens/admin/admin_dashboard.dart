import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/shimmer_loading.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Admin Dashboard
/// ─────────────────────────────────────────────────────────────────────────────
/// High-level Command Center replacing the single monolithic list.
/// Polls /api/admin/dashboard-stats to feed Live Badges and Recent Logs.
/// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  int _pendingCount = 0;
  List<Map<String, dynamic>> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    
    try {
      final body = await ApiService.getDashboardStats(auth.jwtToken!);
      if (mounted) {
        setState(() {
          _pendingCount = (body['pendingCount'] as num).toInt();
          _recentLogs = List<Map<String, dynamic>>.from(body['recentLogs'] as List);
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin dashboard stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Admin status colors safely mapped to non-destructive tones
  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppColors.medicalBlue;
      case 'completed': return Colors.green;
      case 'on_hold':  return AppColors.skyBlue300;
      case 'pending':  return Colors.amber.shade700;
      case 'rejected': return AppColors.textSecondary;
      default:         return AppColors.deepBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Management Interface'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.medicalBlue),
            tooltip: 'Refresh Stats',
            onPressed: _fetchStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
          GestureDetector(
            onTap: () => context.read<LocaleProvider>().toggleLocale(),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.paleSkyBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                locale == 'en' ? 'తెలు' : 'EN',
                style: const TextStyle(
                  color: AppColors.medicalBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.medicalBlue,
        onRefresh: _fetchStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Banner ──────────────────────────────────────────
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
                        Icons.shield_rounded,
                        color: AppColors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Console',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage hospital workflow efficiently.',
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

              // ── Main Action Cards ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Workspace', style: AppTextStyles.titleLarge),
              ),

              // 1. Approvals Card (with live badge)
              GestureDetector(
                onTap: () async {
                  await context.push('/admin/approvals');
                  // Refresh specific counts when returning
                  _fetchStats();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          color: AppColors.paleSkyBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rule_rounded, color: AppColors.medicalBlue, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manage Approvals',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Accept, Reject, or On-Hold pending appointments.',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      // Live Pending Badge
                      if (_pendingCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_pendingCount',
                            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        )
                      else
                         const Icon(Icons.chevron_right_rounded, color: AppColors.cardBorder, size: 28),
                    ],
                  ),
                ),
              ),

              // 2. Slot Log Card
              GestureDetector(
                onTap: () async {
                  await context.push('/admin/slot_log');
                  _fetchStats(); // Refresh just in case they added walk-ins
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          color: AppColors.cardBorder.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.textPrimary, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Slot Log & Booking',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Filter dates to view live occupancy or add Walk-Ins.',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.cardBorder, size: 28),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Recent Patient Logs ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Patient Logs', style: AppTextStyles.titleLarge),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              if (_isLoading)
                ...List.generate(3, (_) => ShimmerLoading.buildRecentLogSkeleton())
              else if (_recentLogs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No recent logs found.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
              // Renders recent log items
              ..._recentLogs.map((log) {
                final String name = log['patientName'] ?? 'Unknown';
                final String ageStr = log['age'] != null ? '${log['age']} yrs' : 'Age Unknown';
                final String status = log['status'] ?? 'pending';
                final String date = log['date'] ?? '';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.paleSkyBlue,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.medicalBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.cake_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(ageStr, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
