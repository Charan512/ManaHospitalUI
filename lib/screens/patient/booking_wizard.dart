import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/slot_gradient_card.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Booking Wizard Screen
/// ─────────────────────────────────────────────────────────────────────────────
/// Implements a rigorous 3-step triage wizard for booking an appointment.
/// 1. Patient Details
/// 2. Date Selection
/// 3. Slot Confirmation & Booking
/// ─────────────────────────────────────────────────────────────────────────────
class BookingWizardScreen extends StatefulWidget {
  const BookingWizardScreen({super.key});

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // ── Step 1 Data: Patient Details
  final _nameController     = TextEditingController();
  final _ageController      = TextEditingController();
  final _phoneController    = TextEditingController();
  final _issueController    = TextEditingController();
  final _commentsController = TextEditingController();

  bool _isSelf = true;

  // ── Step 2 Data: Date Selection
  DateTime? _selectedDate;
  String get _dateString {
    if (_selectedDate == null) return '';
    return '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
  }

  // ── Step 3 Data: Slot Selection
  List<Map<String, dynamic>> _slots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _issueController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  // ── Core Navigation Methods ───────────────────────────────────────────────

  void _nextPage() {
    // Validate Step 1 before proceeding
    if (_currentPage == 0) {
      if (!_formKey.currentState!.validate()) return;
    }

    // Step 2 Logic: Requires Date Selection
    if (_currentPage == 1) {
      if (_selectedDate == null) {
        if (mounted) {
          final l10n = AppL10n(context.read<LocaleProvider>().locale);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.tr('selectDateFirst')),
            backgroundColor: AppColors.deepBlue,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      _fetchSlots(); // Load slots proactively just before switching to page 3
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ── Data Fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchSlots() async {
    if (_selectedDate == null) return;
    setState(() => _isLoadingSlots = true);
    
    try {
      final body = await ApiService.getSlots(_dateString);
      setState(() {
        _slots = List<Map<String, dynamic>>.from(body['slots'] as List);
      });
    } on ApiException catch (e) {
      debugPrint('getSlots error: ${e.message}');
    } catch (_) {}
    
    setState(() => _isLoadingSlots = false);
  }

  // ── Booking Submission ────────────────────────────────────────────────────

  Future<void> _submitBooking(String slot) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final l10n = AppL10n(context.read<LocaleProvider>().locale);

    try {
      await ApiService.bookAppointment(
        token: auth.jwtToken!,
        date: _dateString,
        slot: slot,
        isSelf: _isSelf,
        patientName: _isSelf
            ? (_nameController.text.trim().isEmpty ? null : _nameController.text.trim())
            : _nameController.text.trim(),
        patientPhone: _isSelf ? null : _phoneController.text.trim(),
        age: _ageController.text.trim(),
        issueDescription: _issueController.text.trim(),
        comments: _commentsController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.tr('bookingSuccess')),
        backgroundColor: AppColors.medicalBlue,
        behavior: SnackBarBehavior.floating,
      ));
      
      // Successfully booked! Return to Dashboard
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      final String msg = e.hasActiveAppointment
          ? 'You already have an active appointment. Please wait until it is reviewed.'
          : e.message;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.deepBlue,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.tr('bookingFailed')),
        backgroundColor: AppColors.deepBlue,
        behavior: SnackBarBehavior.floating,
      ));
    }

    setState(() => _isSubmitting = false);
  }

  // ── Step Widgets ──────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final auth = context.read<AuthProvider>();
    final locale = context.watch<LocaleProvider>().locale;
    final l10n = AppL10n(locale);
    final bool selfNeedsName = _isSelf && (auth.userName == null || auth.userName!.isEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1 of 3: Patient Details',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.medicalBlue),
            ),
            const SizedBox(height: 8),
            Text(
              'Who is this appointment for?',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 20),

            // Toggle "Myself" / "Someone Else"
            Row(
              children: [
                Expanded(
                  child: _ToggleOption(
                    label: l10n.tr('myself'),
                    icon: Icons.person_rounded,
                    selected: _isSelf,
                    onTap: () => setState(() {
                      _isSelf = true;
                      _nameController.clear();
                      _phoneController.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ToggleOption(
                    label: l10n.tr('someoneElse'),
                    icon: Icons.people_rounded,
                    selected: !_isSelf,
                    onTap: () => setState(() {
                      _isSelf = false;
                      _nameController.clear();
                      _phoneController.clear();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Variable Patient Data fields
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: (!_isSelf || selfNeedsName)
                  ? Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.tr('patientName'),
                            prefixIcon: const Icon(Icons.person_outline,
                                color: AppColors.medicalBlue),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            return null;
                          },
                        ),
                        if (!_isSelf) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: l10n.tr('patientPhone'),
                              prefixIcon: const Icon(Icons.phone_outlined,
                                  color: AppColors.medicalBlue),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length < 10) return 'Enter a valid phone number';
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Patient Age field (Required for clinical details)
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.tr('patientAge'),
                prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.medicalBlue),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Age is required';
                if (int.tryParse(v) == null || int.parse(v) <= 0 || int.parse(v) > 130) {
                  return 'Please enter a valid age';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Reason for Visit',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _issueController,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.tr('issueDesc'),
                hintText: l10n.tr('issueHint'),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 42),
                  child: Icon(Icons.medical_information_outlined,
                      color: AppColors.medicalBlue),
                ),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please describe the issue';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _commentsController,
              maxLines: 2,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.tr('otherComments'),
                hintText: 'Any allergies, prior conditions…',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Icon(Icons.comment_outlined, color: AppColors.medicalBlue),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final locale = context.watch<LocaleProvider>().locale;
    final l10n = AppL10n(locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2 of 3: Date Selection',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.medicalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            'Select Appointment Date',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_month_rounded, 
                  color: AppColors.medicalBlue, 
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedDate == null 
                      ? 'No date selected' 
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _selectedDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Note: The clinic is closed on Sundays.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final today = DateTime.now();
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? today,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 90)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.medicalBlue,
                              onPrimary: AppColors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                      selectableDayPredicate: (DateTime val) {
                        return val.weekday != 7; // Physically block Sundays from selection
                      },
                    );

                    if (selected != null) {
                      setState(() => _selectedDate = selected);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paleSkyBlue,
                    foregroundColor: AppColors.medicalBlue,
                    elevation: 0,
                  ),
                  child: Text(l10n.tr('openCalendar')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final locale = context.watch<LocaleProvider>().locale;
    final l10n = AppL10n(locale);

    return RefreshIndicator(
      color: AppColors.medicalBlue,
      onRefresh: _fetchSlots,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 3 of 3: Confirm Time Slot',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.medicalBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available slots for $_dateString',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          if (_isLoadingSlots)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.medicalBlue),
              ),
            )
          else if (_slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(l10n.tr('noSlotData'))),
            )
          else
            ..._slots.map((slot) => Stack(
              children: [
                SlotGradientCard(
                  bookedCount: (slot['booked'] as num).toInt(),
                  timeSlot: slot['slot'] as String,
                  locale: locale,
                  showCounts: false,
                  isExpired: slot['isExpired'] == true,
                  onTap: () {
                    // Triggers the booking process specifically for this slot
                    _submitBooking(slot['slot'] as String);
                  },
                ),
                if (_isSubmitting)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )
              ],
            )),
          
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.deepBlue),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (_currentPage > 0 && !_isSubmitting) {
              _prevPage();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disallow manual swipe to enforce step constraints
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
      bottomSheet: Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Button: Back or Cancel
            TextButton(
              onPressed: _isSubmitting 
                ? null 
                : () {
                    if (_currentPage == 0) {
                      Navigator.pop(context);
                    } else {
                      _prevPage();
                    }
                  },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text(
                _currentPage == 0 ? 'Cancel' : 'Back',
                style: const TextStyle(
                  fontFamily: 'Outfit', 
                  fontSize: 15, 
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Right Button: Progress dynamically mapped (Next Step, Finish)
            if (_currentPage < 2)
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue', 
                  style: TextStyle(
                    fontFamily: 'Outfit', 
                    fontSize: 15, 
                    fontWeight: FontWeight.w600,
                  )
                ),
              )
            else
              const SizedBox.shrink(), // Uses the SlotCard's "Book Now" natively
          ],
        ),
      ),
    );
  }
}

/// Toggle option chip for Myself / Someone Else (Imported from old form code)
class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.medicalBlue : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.medicalBlue : AppColors.cardBorder,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.medicalBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.white : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
