import 'package:flutter/material.dart';
import '../core/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SlotGradientCard
/// ─────────────────────────────────────────────────────────────────────────────
/// Visualises appointment slot availability using a calm White→SkyBlue gradient.
/// STRICTLY no Red, Green, or Yellow colors — per project mandate.
///
/// Parameters:
///   [bookedCount]  0–5  Number of active bookings in this slot
///   [timeSlot]          Display string e.g. "10:00 AM – 2:00 PM"
///   [onTap]             Called when user taps to book. Null = disabled.
///   [locale]            'en' or 'te' for localized labels
/// ─────────────────────────────────────────────────────────────────────────────
class SlotGradientCard extends StatelessWidget {
  final int bookedCount;
  final String timeSlot;
  final VoidCallback? onTap;
  final String locale;
  final bool showCounts;
  final bool showBookButton;
  final bool isExpired;

  const SlotGradientCard({
    super.key,
    required this.bookedCount,
    required this.timeSlot,
    this.onTap,
    this.locale = 'en',
    this.showCounts = true,
    this.showBookButton = true,
    this.isExpired = false,
  });

  bool get _isDisabled => bookedCount >= 5 || isExpired;

  /// Gradient stops based on occupancy level
  List<Color> get _gradientColors => isExpired
      ? [AppColors.textSecondary.withValues(alpha: 0.1), AppColors.textSecondary.withValues(alpha: 0.2)]
      : AppColors.slotGradient(bookedCount);

  /// Text color flips to white when background is dark blue (full) or grey (expired)
  Color get _textColor =>
      _isDisabled ? AppColors.textOnBlue : AppColors.textPrimary;

  Color get _subTextColor =>
      _isDisabled ? AppColors.white.withValues(alpha: 0.85) : AppColors.textSecondary;

  String get _statusLabel {
    if (isExpired) return locale == 'te' ? 'సమయం ముగిసింది' : 'Slot Expired';
    if (locale == 'te') {
      if (_isDisabled) return 'సీట్లు నిండిపోయాయి';
      final left = 5 - bookedCount;
      return '$left సీట్లు మిగిలాయి';
    }
    if (_isDisabled) return 'Slot Full';
    final left = 5 - bookedCount;
    return '$left slot${left == 1 ? '' : 's'} left';
  }

  String get _bookLabel =>
      locale == 'te' ? 'ఇప్పుడు బుక్ చేయండి' : 'Book Now';

  String get _disabledLabel {
    if (isExpired) return locale == 'te' ? 'ముగిసింది' : 'Expired';
    return locale == 'te' ? 'నిండిపోయింది' : 'Full';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: _isDisabled
                ? AppColors.deepBlue
                : AppColors.cardBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpired 
                  ? Colors.black.withValues(alpha: 0.05) 
                  : AppColors.medicalBlue.withValues(alpha: _isDisabled ? 0.25 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Slot icon + time ────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: _isDisabled ? AppColors.white : AppColors.medicalBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeSlot,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Occupancy progress bar ──────────────────────────────────
              if (!isExpired) _OccupancyBar(booked: bookedCount, isFull: _isDisabled),
              if (!isExpired) const SizedBox(height: 12),

              // ── Status label + CTA ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Occupancy fraction chip
                  if (showCounts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isDisabled
                            ? AppColors.white.withValues(alpha: 0.2)
                            : AppColors.paleSkyBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$bookedCount / 5',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _isDisabled
                              ? AppColors.white
                              : AppColors.medicalBlue,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isDisabled
                            ? AppColors.white.withValues(alpha: 0.2)
                            : AppColors.paleSkyBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isDisabled ? _disabledLabel : 'Available',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _isDisabled
                              ? AppColors.white
                              : AppColors.medicalBlue,
                        ),
                      ),
                    ),

                  // Status label (only if showing counts)
                  if (showCounts)
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _subTextColor,
                      ),
                    ),
                ],
              ),

              if (showBookButton) ...[
                const SizedBox(height: 16),

                // ── Action button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: _isDisabled
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isExpired 
                              ? AppColors.textSecondary.withValues(alpha: 0.1) 
                              : AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _disabledLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isExpired ? AppColors.textPrimary : AppColors.white,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.medicalBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _bookLabel,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              ], // End of showBookButton spread
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Occupancy progress bar — 5 discrete segments, White→SkyBlue fill
/// ─────────────────────────────────────────────────────────────────────────────
class _OccupancyBar extends StatelessWidget {
  final int booked;
  final bool isFull;

  const _OccupancyBar({required this.booked, required this.isFull});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < booked;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            height: 8,
            margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: filled
                  ? (isFull ? AppColors.white.withValues(alpha: 0.7) : AppColors.medicalBlue)
                  : (isFull
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.cardBorder),
            ),
          ),
        );
      }),
    );
  }
}
