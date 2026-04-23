# Mana Hospital - Patient & Admin App (Frontend)

This repository contains the Flutter frontend application for Mana Hospital. It provides distinct interfaces for hospital administrators and patients with a focus on real-time appointment booking, triage, and daily log tracking.

## Architecture & Tech Stack

- **Framework**: Flutter (Dart)
- **Routing**: `go_router` for strict, declarative state-driven navigation.
- **Authentication**: Firebase Phone Auth coupled with a secure backend-issued JWT.
- **Local Storage**: `flutter_secure_storage` for persisting session tokens securely.

## Key Workflows & Features

### 1. Robust Authentication & Reactive Routing
The entire application routing logic is declaratively mapped to a singleton `AuthProvider`. 
- Logging in caches the JWT and user metadata.
- Pushing a logout natively drops the token; `go_router` passively triggers a teardown back to `LoginScreen` instantly, preventing widget-tree deadlocks and race conditions.

### 2. Patient Booking Wizard
A highly responsive 3-step wizard workflow designed for non-technical users.
- **Family & Friend Quotas**: Patients can book an appointment for themselves (limited to 1 active), and act as caretakers booking for others (up to 5 active slots globally).
- **Graceful Error Handling**: Overbooking errors trigger dynamic conflict dialogs pulled straight from the backend API.

### 3. Admin Offline Walk-In Portal
A specific workflow allowing hospital administrators to bypass the patient limits.
- **Unlimited Overrides**: Admins can force walk-in patients into a fully booked slot (e.g. 6/5 bookings).
- **Chronological Time-Gates**: The native `showDatePicker` disables passed dates, forces "Tomorrow" as the default selection after 7:00 PM, and automatically grays-out and disables slots that have natively elapsed for the day.

### 4. Patient Feed & Slot Logs
- Patients have a customized feed showing their history and prescriptions.
- Admins possess a central Slot Log where they monitor all appointments chronologically per day, accepting/rejecting or marking patients as 'Completed' with native Follow-up scheduling.

## Build Instructions (Release)

To compile the application routing to your live backend endpoint:
```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=BACKEND_URL=https://manahospitalapi.onrender.com/api
```
