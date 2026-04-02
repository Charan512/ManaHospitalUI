import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';

/// Offline Walk-In Entry Form (Admin Only)
/// ─────────────────────────────────────────────────────────────────────────────
/// Used by hospital staff to register walk-in patients directly.
/// Bypasses OTP. Status is immediately 'accepted'. isOffline = true.
class OfflineEntryForm extends StatefulWidget {
  const OfflineEntryForm({super.key});

  @override
  State<OfflineEntryForm> createState() => _OfflineEntryFormState();
}

class _OfflineEntryFormState extends State<OfflineEntryForm> {

  final _formKey         = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedSlot = '10:00 AM - 02:00 PM';
  bool _isSubmitting = false;

  final List<String> _slots = [
    '10:00 AM - 02:00 PM',
    '03:00 PM - 07:00 PM',
  ];

  DateTime _selectedDate = DateTime.now();
  String get _dateString {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  bool _isSlotExpired(String slot) {
    final now = DateTime.now();
    // Only apply expiration rules if the selected date is today.
    if (_selectedDate.year != now.year ||
        _selectedDate.month != now.month ||
        _selectedDate.day != now.day) {
      return false; 
    }

    final hour = now.hour;
    final minute = now.minute;
    if (slot == '10:00 AM - 02:00 PM') {
      return hour > 14 || (hour == 14 && minute > 0);
    } else if (slot == '03:00 PM - 07:00 PM') {
      return hour > 19 || (hour == 19 && minute > 0);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    // If BOTH slots have expired today (i.e. past 7 PM), default to tomorrow.
    final now = DateTime.now();
    if (now.hour > 19 || (now.hour == 19 && now.minute > 0)) {
      _selectedDate = now.add(const Duration(days: 1));
    } else if (_isSlotExpired('10:00 AM - 02:00 PM')) {
      _selectedSlot = '03:00 PM - 07:00 PM';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // Disable past dates natively
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.medicalBlue,
            colorScheme: const ColorScheme.light(primary: AppColors.medicalBlue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Default back to first slot if moving to a future date
        if (!_isSlotExpired('10:00 AM - 02:00 PM')) {
          _selectedSlot = '10:00 AM - 02:00 PM';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final l10n = AppL10n(context.read<LocaleProvider>().locale);

    try {
      final body = await ApiService.addOfflinePatient(
        token:        auth.jwtToken!,
        date:         _dateString,
        slot:         _selectedSlot,
        patientName:  _nameController.text.trim(),
        patientPhone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(body['message'] as String? ?? 'Walk-in registered!'),
        backgroundColor: AppColors.medicalBlue,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.isSlotFull ? l10n.tr('slotFullMessage') : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.deepBlue,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Network error. Please try again.'),
        backgroundColor: AppColors.deepBlue,
      ));
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final l10n   = AppL10n(locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('addWalkIn')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paleSkyBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.medicalBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Walk-in entries are confirmed immediately and count '
                        'toward the 5-patient slot limit.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.medicalBlue),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Patient Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.tr('patientName'),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.medicalBlue),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Patient name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Patient Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.tr('patientPhone'),
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.medicalBlue),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Date selection
              Text(
                'Select Date',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.medicalBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _dateString,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Slot selection
              Text(
                l10n.tr('selectSlot'),
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              ..._slots.map(
                (slot) {
                  final bool isExpired = _isSlotExpired(slot);
                  final bool isSelected = _selectedSlot == slot;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: isExpired ? null : () => setState(() => _selectedSlot = slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isExpired 
                              ? AppColors.background 
                              : (isSelected ? AppColors.medicalBlue : AppColors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isExpired 
                                ? AppColors.cardBorder 
                                : (isSelected ? AppColors.medicalBlue : AppColors.cardBorder),
                            width: 1.5,
                          ),
                          boxShadow: isSelected && !isExpired
                              ? [
                                  BoxShadow(
                                    color: AppColors.medicalBlue.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: isExpired 
                                  ? AppColors.textSecondary 
                                  : (isSelected ? AppColors.white : AppColors.medicalBlue),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              slot,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isExpired 
                                    ? AppColors.textSecondary 
                                    : (isSelected ? AppColors.white : AppColors.textPrimary),
                                decoration: isExpired ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (isExpired) ...[
                              const Spacer(),
                              Text(
                                'Closed',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_rounded),
                  label: Text(l10n.tr('addWalkIn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
