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

    // New Auth / Login
    'optionalNameHint':   'Your Name (optional)',
    'invalidPhone':       'Enter a valid 10-digit phone number',
    'invalidOtpReq':      'Enter the 6-digit OTP',
    'otpSentMsg':         'OTP sent! Check your messages.',
    'sessionExpired':     'Session expired. Please request a new OTP.',
    'invalidOtp':         'Invalid OTP. Please try again.',

    // Dashboard
    'welcome':            'Welcome, ',
    'whatToDo':           'What would you like to do?',
    'bookNew':            'Book New Appointment',
    'bookNewSub':         'Start our step-by-step triage to schedule your visit.',
    'myHistory':          'My Appointment History',
    'myHistorySub':       'View your upcoming appointments and past medical prescriptions.',

    // Booking Wizard
    'patientAge':         'Patient Age *',
    'issueDesc':          'Issue Description *',
    'issueHint':          'e.g. Fever, Headache',
    'otherComments':      'Other Comments (optional)',
    'pastHistory':        'Any past medical history?',
    'selectDateFirst':    'Please select a date first.',
    'openCalendar':       'Open Calendar',
    'noSlotData':         'No slot data found for this date.',

    // Patient History
    'myHistoryTitle':     'My History',
    'followUpAppt':       'Follow-up Appointment',
    'prescriptionNotes':  'Prescription / Notes:',
    'nextVisit':          'Next Visit Needed On:',

    // Notifications
    'notificationCenter': 'Notification Center',
    'systemAlerts':       'System Alerts',
    'noAlerts':           'You have no new alerts.',
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

    // New Auth / Login
    'optionalNameHint':   'మీ పేరు (ఐచ్ఛికం)',
    'invalidPhone':       'సరైన 10 అంకెల నంబరు ఇవ్వండి',
    'invalidOtpReq':      '6-అంకెల OTP నమోదు చేయండి',
    'otpSentMsg':         'OTP పంపబడింది! మీ మెసేజ్ చూడండి.',
    'sessionExpired':     'సెషన్ ముగిసింది. దయచేసి కొత్త OTP పొందండి.',
    'invalidOtp':         'తప్పు OTP. దయచేసి మళ్ళీ ప్రయత్నించండి.',

    // Dashboard
    'welcome':            'స్వాగతం, ',
    'whatToDo':           'మీరు ఏమి చేయాలనుకుంటున్నారు?',
    'bookNew':            'కొత్త అపాయింట్మెంట్',
    'bookNewSub':         'మా వైద్య సేవ కోసం సమయాన్ని బుక్ చేసుకోండి.',
    'myHistory':          'నా అపాయింట్మెంట్ చరిత్ర',
    'myHistorySub':       'గత అపాయింట్మెంట్లు మరియు మందుల వివరాలు చూడండి.',

    // Booking Wizard
    'patientAge':         'రోగి వయస్సు *',
    'issueDesc':          'సమస్య వివరణ *',
    'issueHint':          'ఉదా. జ్వరం, తలనొప్పి',
    'otherComments':      'ఇతర వ్యాఖ్యలు (ఐచ్ఛికం)',
    'pastHistory':        'గత వైద్య చరిత్ర ఏదైనా ఉందా?',
    'selectDateFirst':    'దయచేసి ముందుగా తేదీ ఎంచుకోండి.',
    'openCalendar':       'క్యాలెండర్ తెరవండి',
    'noSlotData':         'ఈ తేదీకి స్లాట్లు అందుబాటులో లేవు.',

    // Patient History
    'myHistoryTitle':     'నా చరిత్ర',
    'followUpAppt':       'ఫాలో-అప్ అపాయింట్మెంట్',
    'prescriptionNotes':  'మందుల చీటీ / సూచనలు:',
    'nextVisit':          'తదుపరి విజిట్:',

    // Notifications
    'notificationCenter': 'నోటిఫికేషన్ సెంటర్',
    'systemAlerts':       'సిస్టమ్ అలర్ట్స్',
    'noAlerts':           'మీకు కొత్త నోటిఫికేషన్లు లేవు.',
  };
}
