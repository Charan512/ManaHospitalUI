import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/slot_gradient_card.dart';
import '../../services/api_service.dart';
import 'offline_entry_form.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Slot Log Screen (Refactored from AdminHome)
/// ─────────────────────────────────────────────────────────────────────────────
/// Acts as the daily operational view. Allows Admins to select ANY date, view
/// the live slot counts, and intrinsically nests all booked patients accurately 
/// below their respective time block.
/// ─────────────────────────────────────────────────────────────────────────────
class SlotLogScreen extends StatefulWidget {
  const SlotLogScreen({super.key});

  @override
  State<SlotLogScreen> createState() => _SlotLogScreenState();
}

class _SlotLogScreenState extends State<SlotLogScreen> {
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  String get _dateString {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchSlots(), _fetchAppointments()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchSlots() async {
    try {
      final body = await ApiService.getSlots(_dateString);
      _slots = List<Map<String, dynamic>>.from(body['slots'] as List);
    } catch (_) {}
  }

  Future<void> _fetchAppointments() async {
    final auth = context.read<AuthProvider>();
    try {
      final body = await ApiService.getAdminDailyAppointments(
        token: auth.jwtToken!,
        date: _dateString,
      );
      _appointments = List<Map<String, dynamic>>.from(body['appointments'] as List);
    } catch (_) {}
  }

  Future<void> _updateStatus(String id, String status) async {
    final auth = context.read<AuthProvider>();
    try {
      await ApiService.updateAppointmentStatus(
        token: auth.jwtToken!,
        appointmentId: id,
        status: status,
      );
      await _refresh();
    } catch (_) {}
  }

  Future<void> _completeAppt(String id, String? prescription, String? nextDbDate, String? nextSlot) async {
    final auth = context.read<AuthProvider>();
    try {
      await ApiService.markCompleted(
        token: auth.jwtToken!,
        appointmentId: id,
        prescription: prescription,
        nextVisitDate: nextDbDate,
        nextVisitSlot: nextSlot,
      );
      await _refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Slot Log & Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.medicalBlue),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OfflineEntryForm()),
          );
          _refresh();
        },
        backgroundColor: AppColors.medicalBlue,
        icon: const Icon(Icons.person_add_rounded, color: AppColors.white),
        label: const Text(
          'Add Walk-in',
          style: TextStyle(
            color: AppColors.white,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Date Calendar Picker Strip ────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.paleSkyBlue, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.medicalBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Viewing Date', style: AppTextStyles.caption),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.medicalBlue, onPrimary: AppColors.white, onSurface: AppColors.textPrimary),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (dt != null) {
                      setState(() => _selectedDate = dt);
                      _refresh();
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.medicalBlue),
                  child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.medicalBlue))
                : RefreshIndicator(
                    color: AppColors.medicalBlue,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 12),
                        
                        // Render dynamically nested slot arrays
                        ..._slots.map((slotData) {
                          final slotName = slotData['slot'] as String;
                          final slotAppts = _appointments.where((a) => a['slot'] == slotName).toList();
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SlotGradientCard(
                                  bookedCount: (slotData['booked'] as num).toInt(),
                                  timeSlot: slotName,
                                  locale: locale,
                                  isExpired: slotData['isExpired'] == true,
                                  showBookButton: false, // Admin view
                                ),
                                if (slotAppts.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 36, top: 8),
                                    child: Text('No patients booked yet.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: slotAppts.map((appt) => _NestedPatientTile(
                                        appt: appt,
                                        onUpdateStatus: _updateStatus,
                                        onComplete: _completeAppt,
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        
                        const SizedBox(height: 100), // clearance for FAB
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NestedPatientTile extends StatelessWidget {
  final Map<String, dynamic> appt;
  final Future<void> Function(String id, String status) onUpdateStatus;
  final Future<void> Function(String id, String? prescription, String? nextDate, String? nextSlot) onComplete;

  const _NestedPatientTile({
    required this.appt,
    required this.onUpdateStatus,
    required this.onComplete,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppColors.medicalBlue;
      case 'on_hold':  return AppColors.skyBlue300;
      case 'completed': return Colors.green;
      case 'pending':  return Colors.amber.shade700;
      case 'rejected': return AppColors.textSecondary;
      default:         return AppColors.deepBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = appt['status'] as String;
    final id     = appt['_id'] as String;
    final isOffline = appt['isOffline'] as bool? ?? false;
    final String name = appt['patientName'] ?? '—';
    final ageStr = appt['age'] != null ? '${appt['age']} yrs' : '';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 16)),
                        if (isOffline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.paleSkyBlue, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Walk-in', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppColors.medicalBlue, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${appt['patientPhone'] ?? ''} • $ageStr', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                 child: Text(status.toUpperCase(), style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor(status))),
              ),
            ],
          ),
          
          if (status == 'accepted' && !isOffline) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CompletionModal(
                          patientName: name,
                          onSave: (pres, dateStr, slotStr) async => await onComplete(id, pres, dateStr, slotStr),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Complete Appt', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onUpdateStatus(id, 'missed'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0),
                    icon: const Icon(Icons.person_off_rounded, size: 16),
                    label: const Text('Mark Missed', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

/// Completion Modal Hooked exactly as it was in old admin home
class CompletionModal extends StatefulWidget {
  final String patientName;
  final Future<void> Function(String? pres, String? dateStr, String? slotStr) onSave;

  const CompletionModal({super.key, required this.patientName, required this.onSave});

  @override
  State<CompletionModal> createState() => _CompletionModalState();
}

class _CompletionModalState extends State<CompletionModal> {
  final _presController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedSlot;
  bool _isSubmitting = false;

  void _submit() async {
    setState(() => _isSubmitting = true);
    String? dbDate;
    if (_selectedDate != null) {
      dbDate = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    }
    try {
      await widget.onSave(_presController.text, dbDate, _selectedSlot);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complete ${widget.patientName}', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            const Text('Prescription / Notes', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(controller: _presController, maxLines: 4, decoration: const InputDecoration(hintText: 'Enter notes...')),
            const SizedBox(height: 20),
            const Text('Follow-up Appointment (Optional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final dt = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (dt != null) setState(() => _selectedDate = dt);
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(_selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    hint: const Text('Slot'),
                    initialValue: _selectedSlot,
                    items: const [
                      DropdownMenuItem(value: '10:00 AM - 02:00 PM', child: Text('10AM - 2PM', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: '03:00 PM - 07:00 PM', child: Text('3PM - 7PM', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _selectedSlot = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Mark Completed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
