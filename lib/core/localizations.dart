library;

/// ─────────────────────────────────────────────────────────────────────────────
/// Mana Hospital — Localization
/// ─────────────────────────────────────────────────────────────────────────────
/// Supports English and spoken Telugu (simple, everyday language).
/// Keys are accessed via AppL10n.of(context).keyName
/// ─────────────────────────────────────────────────────────────────────────────

class AppL10n {
  final String locale;
  const AppL10n(this.locale);

  static AppL10n of(context) {
    // Resolved via LocaleProvider — see providers/locale_provider.dart
    throw UnimplementedError('Use AppL10n directly with locale string');
  }

  /// Returns the correct translation map based on locale code.
  String tr(String key) {
    final map = locale == 'te' ? _te : _en;
    return map[key] ?? _en[key] ?? key;
  }

  // ── English ────────────────────────────────────────────────────────────────
  static const Map<String, String> _en = {
    // App
    'appName':            'Mana Hospital',
    'tagline':            'Bhimavaram\'s Trusted Care',

    // Auth
    'enterPhone':         'Enter your phone number',
    'sendOtp':            'Send OTP',
    'enterOtp':           'Enter OTP',
    'verifyOtp':          'Verify OTP',
    'resendOtp':          'Resend OTP',
    'phoneHint':          '+91 98765 43210',

    // Navigation
    'home':               'Home',
    'appointments':       'Appointments',
    'profile':            'Profile',

    // Booking
    'bookAppointment':    'Book Appointment',
    'selectDate':         'Select Date',
    'selectSlot':         'Select Slot',
    'myself':             'Myself',
    'someoneElse':        'Someone Else',
    'patientName':        'Patient Name',
    'patientPhone':       'Patient Phone',
    'confirmBooking':     'Confirm Booking',
    'bookNow':            'Book Now',
    'slotMorning':        '10:00 AM – 2:00 PM',
    'slotEvening':        '3:00 PM – 7:00 PM',

    // Slot status
    'slotAvailable':      'Available',
    'slotFull':           'Slot Full',
    'slotsLeft':          'slots left',

    // Appointment status labels (NO Red/Green/Yellow)
    'statusPending':      'Pending Review',
    'statusAccepted':     'Confirmed',
    'statusRejected':     'Not Available',
    'statusOnHold':       'On Hold',

    // Admin
    'adminDashboard':     'Management Dashboard',
    'addWalkIn':          'Add Walk-In Patient',
    'accept':             'Confirm',
    'reject':             'Decline',
    'hold':               'Hold',
    'todaySlots':         'Today\'s Slots',

    // Profile
    'language':           'Language',
    'english':            'English',
    'telugu':             'Telugu',
    'logout':             'Logout',

    // Messages
    'bookingSuccess':     'Appointment booked! We\'ll review your request shortly.',
    'bookingFailed':      'Booking failed. Please try again.',
    'slotFullMessage':    'This slot is fully booked. Please choose another.',
    'noAppointments':     'No appointments yet.',
  };

  // ── Spoken Telugu ──────────────────────────────────────────────────────────
  static const Map<String, String> _te = {
    // App
    'appName':            'మన హాస్పిటల్',
    'tagline':            'భీమవరం నమ్మకమైన వైద్యం',

    // Auth
    'enterPhone':         'మీ ఫోన్ నంబర్ ఇవ్వండి',
    'sendOtp':            'OTP పంపండి',
    'enterOtp':           'OTP నమోదు చేయండి',
    'verifyOtp':          'OTP నిర్ధారించండి',
    'resendOtp':          'OTP మళ్ళీ పంపండి',
    'phoneHint':          '+91 98765 43210',

    // Navigation
    'home':               'హోమ్',
    'appointments':       'అపాయింట్మెంట్లు',
    'profile':            'ప్రొఫైల్',

    // Booking
    'bookAppointment':    'అపాయింట్మెంట్ తీసుకోండి',
    'selectDate':         'తేదీ ఎంచుకోండి',
    'selectSlot':         'సమయం ఎంచుకోండి',
    'myself':             'నా కోసం',
    'someoneElse':        'వేరే ఎవరికైనా',
    'patientName':        'రోగి పేరు',
    'patientPhone':       'రోగి ఫోన్',
    'confirmBooking':     'బుకింగ్ నిర్ధారించండి',
    'bookNow':            'ఇప్పుడు బుక్ చేయండి',
    'slotMorning':        'పొద్దున 10 – మధ్యాహ్నం 2',
    'slotEvening':        'మధ్యాహ్నం 3 – సాయంత్రం 7',

    // Slot status
    'slotAvailable':      'అందుబాటులో ఉంది',
    'slotFull':           'సీట్లు నిండిపోయాయి',
    'slotsLeft':          'సీట్లు మిగిలాయి',

    // Appointment status
    'statusPending':      'సమీక్షలో ఉంది',
    'statusAccepted':     'నిర్ధారించబడింది',
    'statusRejected':     'అందుబాటు లేదు',
    'statusOnHold':       'వెయిటింగ్',

    // Admin
    'adminDashboard':     'మేనేజ్మెంట్ డ్యాష్‌బోర్డ్',
    'addWalkIn':          'వాక్-ఇన్ రోగిని చేర్చండి',
    'accept':             'నిర్ధారించు',
    'reject':             'తిరస్కరించు',
    'hold':               'వెయిటింగ్‌లో పెట్టు',
    'todaySlots':         'నేటి స్లాట్లు',

    // Profile
    'language':           'భాష',
    'english':            'ఇంగ్లీష్',
    'telugu':             'తెలుగు',
    'logout':             'లాగ్ అవుట్',

    // Messages
    'bookingSuccess':     'అపాయింట్మెంట్ బుక్ అయింది! మేము త్వరలో నిర్ధారిస్తాం.',
    'bookingFailed':      'బుకింగ్ విఫలమైంది. మళ్ళీ ప్రయత్నించండి.',
    'slotFullMessage':    'ఈ స్లాట్ నిండిపోయింది. మరో సమయం ఎంచుకోండి.',
    'noAppointments':     'ఇంకా అపాయింట్మెంట్లు లేవు.',
  };
}
